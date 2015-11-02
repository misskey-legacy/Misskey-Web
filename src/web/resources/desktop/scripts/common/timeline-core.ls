prelude = require 'prelude-ls'

window.TIMELINE_CORE = {}
	..init = ($tl) ->
		window.TIMELINE_CORE.tl = $tl
		$tl.find '> .posts > .post' .each ->
			window.TIMELINE_CORE.set-event $ @

	..set-event = ($post) ->
		function check-favorited
			($post.attr \data-is-favorited) == \true

		function check-reposted
			($post.attr \data-is-reposted) == \true

		function activate-display-state
			animation-speed = 200ms
			if ($post.attr \data-display-html-is-active) == \false
				reply-form-text = $post.children \article .find '.form-and-replies .reply-form textarea' .val!
				window.TIMELINE_CORE.tl.find '> .posts > .ppst' .each ->
					$ @
						..attr \data-display-html-is-active \false
						..remove-class \display-html-active-status-prev
						..remove-class \display-html-active-status-next
				window.TIMELINE_CORE.tl.find '> .posts > .ppst > article > .talk > i' .each ->
					$ @ .show animation-speed
				window.TIMELINE_CORE.tl.find '> .posts > .ppst > article > .talk > .posts' .each ->
					$ @ .hide animation-speed
				window.TIMELINE_CORE.tl.find '> .posts > .ppst > article > .reply-info' .each ->
					$ @ .show animation-speed
				window.TIMELINE_CORE.tl.find '> .posts > .ppst > article > .form-and-replies' .each ->
					$ @ .hide animation-speed
				$post
					..attr \data-display-html-is-active \true
					..parent!.prev!.add-class \display-html-active-status-prev
					..parent!.next!.add-class \display-html-active-status-next
					..children \article .find  '.talk > i' .hide animation-speed
					..children \article .find  '.talk > .statuses' .show animation-speed
					..children \article .find  '.reply-info' .hide animation-speed
					..children \article .find  '.form-and-replies' .show animation-speed
					..children \article .find  '.form-and-replies .reply-form textarea' .val ''
					..children \article .find  '.form-and-replies .reply-form textarea' .focus! .val reply-form-text
			else
				$post
					..attr \data-display-html-is-active \false
					..parent!.prev!.remove-class \display-html-active-status-prev
					..parent!.next!.remove-class \display-html-active-status-next
					..children \article .find  '.talk > i' .show animation-speed
					..children \article .find  '.talk > .statuses' .hide animation-speed
					..children \article .find  '.reply-info' .show animation-speed
					..children \article .find  '.form-and-replies' .hide animation-speed

		$post
			# Click event
			..click (event) ->
				can-event = ! (((<[ input textarea button i time a ]>
					|> prelude.map (element) -> $ event.target .is element)
					.index-of yes) >= 0)

				if document.get-selection!.to-string! != ''
					can-event = no

				if $ event.target .closest \.repost-form .length > 0
					can-event = no

				if can-event
					activate-display-state!

			# Images
			..find '.main .attached-images > .images > .image' .each ->
				$image = $ @
				$img = $image.find \img
				$button = $image.find \button
				$back = $image.find \.background

				$img.click ->
					if ($image.attr \data-is-expanded) == \true
						$image.attr \data-is-expanded \false
						$back.animate {
							opacity: 0
						} 100ms \linear ->
							$back.css \display \none
				$back.click ->
					if ($image.attr \data-is-expanded) == \true
						$image.attr \data-is-expanded \false
						$back.animate {
							opacity: 0
						} 100ms \linear ->
							$back.css \display \none
				$button.click ->
					if ($image.attr \data-is-expanded) == \true
						$image.attr \data-is-expanded \false
						$back.animate {
							opacity: 0
						} 100ms \linear ->
							$back.css \display \none
					else
						$image.attr \data-is-expanded \true
						$back.css \display \block
						$back.animate {
							opacity: 1
						} 100ms \linear

			# Ajax setting of reply-form
			..find \.reply-form .submit (event) ->
				event.prevent-default!
				$form = $ @
				$submit-button = $form.find \.submit-button
					..attr \disabled on
				$.ajax "#{config.api-url}/web/status/reply.plain" {
					type: \post
					data: new FormData $form.0
					-processData
					-contentType
					data-type: \text
					xhr-fields: {+with-credentials}}
				.done (html) ->
					$reply = $ html
					$submit-button.attr \disabled off
					$reply.append-to $status.find '.replies > .statuses'
					$i = $ '<i class="fa fa-ellipsis-v reply-info" style="display: none;"></i>'
					$i.append-to $status.find '.article-main'
					$form.remove!
					window.display-message '返信しました！'
				.fail ->
					$submit-button.attr \disabled off

			# Preview attache image
			..find '.image-attacher input[name=image]' .change ->
				$input = $ @
				file = $input.prop \files .0
				if file.type.match 'image.*'
					reader = new FileReader!
						..onload = ->
							$img = $ '<img>' .attr \src reader.result
							$input.parent '.image-attacher' .find 'p, img' .remove!
							$input.parent '.image-attacher' .append $img
						..readAsDataURL file

			## Init tag input of reply-form
			#..find '.reply-form .tag'
			#	.tagit {placeholder-text: 'タグ', field-name: 'tags[]'}

			# Init favorite button
			..find 'article > .article-main > .footer > .actions > .favorite > .favorite-button' .click ->
				$button = $ @
					..attr \disabled on
				if check-favorited!
					$status.attr \data-is-favorited \false
					$.ajax "#{config.api-url}/status/unfavorite" {
						type: \delete
						data: {'status-id': $status.attr \data-id}
						data-type: \json
						xhr-fields: {+withCredentials}}
					.done ->
						$button.attr \disabled off
					.fail ->
						$button.attr \disabled off
						$status.attr \data-is-favorited \true
				else
					$status.attr \data-is-favorited \true
					$.ajax "#{config.api-url}/status/favorite" {
						type: \post
						data: {'status-id': $status.attr \data-id}
						data-type: \json
						xhr-fields: {+withCredentials}}
					.done ->
						$button.attr \disabled off
					.fail ->
						$button.attr \disabled off
						$status.attr \data-is-favorited \false

			# Init reply button
			..find 'article > .article-main > .footer > .actions > .reply > .reply-button' .click ->
				activate-display-state!

			# Init repost button
			..find 'article > .article-main > .footer > .actions > .repost > .repost-button' .click ->
				if check-reposted!
					$status.attr \data-is-reposted \false
					$.ajax "#{config.api-url}/status/unrepost" {
						type: \delete
						data: {'status-id': $status.attr \data-id}
						data-type: \json
						xhr-fields: {+withCredentials}}
					.done ->
						$button.attr \disabled off
					.fail ->
						$button.attr \disabled off
						$status.attr \data-is-reposted \true
				else
					$status.find '.repost-form .background' .css \display \block
					$status.find '.repost-form .background' .animate {
						opacity: 1
					} 100ms \linear
					$status.find '.repost-form .form' .css \display \block
					$status.find '.repost-form .form' .animate {
						opacity: 1
					} 100ms \linear

			# Init repost form
			..find '.repost-form > .form' .submit (event) ->
				event.prevent-default!
				$form = $ @
				$submit-button = $form.find \.accept
					..attr \disabled on
					..attr \data-reposting \true
				$status.attr \data-is-reposted \true
				$.ajax "#{config.api-url}/status/repost" {
					type: \post
					data:
						'status-id': $status.attr \data-id
						text: $status.find '.repost-form > form > .comment-form > input[name=text]' .val!
					data-type: \json
					xhr-fields: {+withCredentials}}
				.done ->
					$submit-button
						..attr \disabled off
						..attr \data-reposting \false
					window.display-message 'Reposted!'
					$status.find '.repost-form .background' .animate {
						opacity: 0
					} 100ms \linear -> $status.find '.repost-form .background' .css \display \none
					$status.find '.repost-form .form' .animate {
						opacity: 0
					} 100ms \linear -> $status.find '.repost-form .form' .css \display \none
				.fail ->
					$submit-button
						..attr \disabled off
						..attr \data-reposting \false
					$status.attr \data-is-reposted \false
					window.display-message 'Repostに失敗しました。再度お試しください。'
			..find '.repost-form > .form > .actions > .cancel' .click ->
				$status.find '.repost-form .background' .animate {
					opacity: 0
				} 100ms \linear -> $status.find '.repost-form .background' .css \display \none
				$status.find '.repost-form .form' .animate {
					opacity: 0
				} 100ms \linear -> $status.find '.repost-form .form' .css \display \none
			..find '.repost-form .background' .click ->
				$status.find '.repost-form .background' .animate {
					opacity: 0
				} 100ms \linear -> $status.find '.repost-form .background' .css \display \none
				$status.find '.repost-form .form' .animate {
					opacity: 0
				} 100ms \linear -> $status.find '.repost-form .form' .css \display \none

	..add = ($post) ->
		new Audio '/resources/sounds/pop.mp3' .play!

		#$recent-status = ($ ($tl.children '.statuses' .children '.status')[0]) .children \.status
		#if ($recent-status.attr \data-display-html-is-active) == \true
		#	$status.children \.status .add-class \display-html-active-status-prev
		window.TIMELINE_CORE.set-event $post
		$post.prepend-to ((window.TIMELINE_CORE.tl.children '.posts')[0])
