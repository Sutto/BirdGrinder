# BirdGrinder Events #

BirdGrinder dispatches the following events, all of which can be processed
in `on_event` blocks / calls on `BirdGrinder::Base` subclasses.

When mentioned, a nashified-version of the api data refers to a OpenStruct like
object / an object you can use much like an object in javascript (options by default
is always used as a Nash), meaning `options.user.screen_name` is equivalent to
`options[:user][:screen_name]`.

## Event: `:outgoing_follow` ##

When `BirdGrinder::Tweeter#follow(user, opts = {})` is called (usually via
`client.tweeter.follow` in a `BirdGrinder::Base` subclass), this event is
dispatched once completed successfully, meaning the user was followed.

The `options` value for this event has:
- `user` - the user who was followed.

## Event: `:outgoing_unfollow` ##

When `BirdGrinder::Tweeter#unfollow(user, opts = {})` is called (usually via
`client.tweeter.unfollow` in a `BirdGrinder::Base` subclass), this event is
dispatched once completed successfully, meaning the user was unfollowed.

The `options` value for this event has:
- `user` - the user who was unfollowed.

## Event: `:outgoing_tweet` ##

When a normal tweet is sent (e.g. via `reply` or `tweet`), the `:outgoing_tweet`
event will be dispatched on success.

The `options` value for this event has holds a standard tweet nash (see below).

## Event: `:outgoing_direct_message` ##

When a normal tweet is sent (e.g. via `reply` or `dm`), the `:outgoing_direct_message`
event will be dispatched on success.

The `options` value for this event has holds a standard direct message nash (see below).

## Event: `:incoming_mention` ##

As expected, incoming mentions are dispatched when encountered as a part
of the event loop. Using a timer specified in `config/settings.yml` as
`check_every`, it will fetch mentions and direct messages then dispatch
an `:incoming_mention` event.

The `options` value for this event has holds a standard tweet nash (see below).

## Event: `:incoming_direct_message` ##

Like mentions, incoming dm's are automatically fetched based on a timer.
When fetched, it dispatches a `:incoming_direct_message` event for each
tweeter.

The `options` value for this event has holds a standard direct message nash (see below).

## Event: `:incoming_follower_ids` ##

When `BirdGrinder::Tweeter#follower_ids(user_id, opts = {})` is called (usually via
`client.tweeter.follower_ids` in a `BirdGrinder::Base` subclass), the response yields
this event. If a `:cursor` option is present, the follow is held in `options`:

- `cursor` - the cursor for the current page
- `user_id` - who the followers belong to
- `ids` - an array of follower user ids for this page
- `next_cursor` - either, the next page cursor or zero
- `previous_cursor` - either, the previous page cursor or zero
- `all` - true / false, reflecting if this page holds all of the users followers

Otherwise, `options` holds:

- `user_id` - who the followers belong to
- `ids` - an array of all of the follower user ids
- `all` - true

## Event: `:incoming_search` ##

Called when a new search result is retrieved, usually using `BirdGrinder::Tweeter#search(query, opts = {})`
(or via `client.search(query, opts = {})`).

In this case, `options` holds:

- `text` - the tweet text
- `to_user_id` - search api specific user id it is @-replied to
- `to_user` - screen name of the user it is @-replied to
- `from_user` - screen name of tweeter
- `id` - the id of the tweet
- `from_user_id` - search api specific user id of the sender
- `iso_language_code` - the tweets ISO language code
- `source` - where the tweet came from (html)
- `profile_image_url` - the users profile image
- `created_at` - when the tweet was created

## Event: `:incoming_stream`

The stream events are handled slightly different to others. For started, all
stream tweets are dispatched when a stream recieves another item / line, and consist
of the following items in `options`:

- `stream_type` - on of `:tweet`, `:limit` or `:delete` (corresponding to stream events)
- `streaming_source` - the name of the method used to generate the stream (e.g. `:filter`, `:sample`, `:track` or `:follow`)
- `meta` - any data passed to the streaming method call via a `:meta` option (e.g. `client.stream :meta => 'hello!'`)

Finally, each of the `stream_type` values has some extra data:

`:delete` also has:
- `id` - the id of the message delete
- `user_id` - the user id of who owned the tweet

`:limit` has:
- `track` - the number of missed tweets

And lastly, `:tweet` should also hold the standard tweet data referenced below.

## Default Tweet Data / Responses ##

Where mentioned above, most tweets contain the following data (note that
you don't always receive the same keys, but text and screen name are usually
correct. If in doubt, check the API).

See [The API Wiki](http://apiwiki.twitter.com/Return-Values) for more indepth
information.

### Direct Messages ####

- `type` - should usually contain `:direct_message`
- `id` - the tweet id
- `text` - the contents of the direct message
- `created_at` - Time when the tweet was created at
- `sender_id` - the id of the sender
- `sender_screen_name` - screen name of the sender
- `sender` - a nash with:
  - `id` - id of the sender
  - `name` - full name of the sender
  - `screen_name` - screen name of the sender
  - `location` - location of the sender
  - `description` - sender's profile description
  - `profile_image_url` - sender's avatar url
  - `url` - sender's url
  - `protected` - whether or not the senders profile is protected
  - `followers_count` - how many followers the send has
  - `profile_background_colour` - hex for senders profile background color
  - `profile_text_colour` - hex for senders profile text color
  - `profile_link_colour` - hex for senders profile link color
  - `profile_sidebar_fill_colour` - hex for senders profile sidebar fill color
  - `profile_sidebar_border_colour` - hex for senders profile sidebar border color
  - `friends_count` - number of friends the sender has
  - `created_at` - when the sender joined twitter
  - `favourites_count` - how many favourites the sender has
  - `utc_offset` - the senders utc offset
  - `time_zone` - the senders time zone
  - `profile_background_image_url` - url for the senders background image
  - `profile_background_tile` - whether the senders profile background image tiles
  - `statuses_count` - how many tweets the sender has made
  - `notifications` - whether the sender receives notifications
  - `following` - whether the sender is following the recipient
  - `verified` - whether the sender is a verified user
- `recipient_id` - the id of the recipient
- `recipient_screen_name` - screen name of the recipient
- `recipient` - a nash with the following:
  - `id` - id of the recipient
  - `name` - full name of the recipient
  - `screen_name` - screen name of the recipient
  - `location` - location of the recipient
  - `description` - recipient's profile description
  - `profile_image_url` - recipient's avatar url
  - `url` - recipient's url
  - `protected` - whether or not the recipients profile is protected
  - `followers_count` - how many followers the send has
  - `profile_background_colour` - hex for recipients profile background color
  - `profile_text_colour` - hex for recipients profile text color
  - `profile_link_colour` - hex for recipients profile link color
  - `profile_sidebar_fill_colour` - hex for recipients profile sidebar fill color
  - `profile_sidebar_border_colour` - hex for recipients profile sidebar border color
  - `friends_count` - number of friends the recipient has
  - `created_at` - when the recipient joined twitter
  - `favourites_count` - how many favourites the recipient has
  - `utc_offset` - the recipients utc offset
  - `time_zone` - the recipients time zone
  - `profile_background_image_url` - url for the recipients background image
  - `profile_background_tile` - whether the recipients profile background image tiles
  - `statuses_count` - how many tweets the recipient has made
  - `notifications` - whether the recipient receives notifications
  - `following` - whether the recipient is following the sender
  - `verified` - whether the recipient is a verified user

### Tweets (Mentions etc) ###

- `type` - should usually either `:tweet` or `:mention`
- `id` - the tweet id
- `text` - the contents of the mention
- `source` - here the tweet came from (html)
- `truncated` - whether or not the tweet was truncated
- `in_reply_to_status_id` - the status id it replies to if present
- `in_reply_to_user_id` - the user id it replies to if present
- `favorited` - whether you have favourited this tweet
- `in_reply_to_screen_name` - who it was in reply to
- `user` - a nash with:
  - `id` - id of the user
  - `name` - full name of the user
  - `screen_name` - screen name of the user
  - `location` - location of the user
  - `description` - user's profile description
  - `profile_image_url` - user's avatar url
  - `url` - user's url
  - `protected` - whether or not the users profile is protected
  - `followers_count` - how many followers the send has
  - `profile_background_colour` - hex for users profile background color
  - `profile_text_colour` - hex for users profile text color
  - `profile_link_colour` - hex for users profile link color
  - `profile_sidebar_fill_colour` - hex for users profile sidebar fill color
  - `profile_sidebar_border_colour` - hex for users profile sidebar border color
  - `friends_count` - number of friends the user has
  - `created_at` - when the user joined twitter
  - `favourites_count` - how many favourites the user has
  - `utc_offset` - the users utc offset
  - `time_zone` - the users time zone
  - `profile_background_image_url` - url for the users background image
  - `profile_background_tile` - whether the users profile background image tiles
  - `statuses_count` - how many tweets the user has made
  - `notifications` - whether the user receives notifications
  - `following` - whether the user is following you
  - `verified` - whether the user is a verified user
