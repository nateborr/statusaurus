statusaurus
===========

Description
---------------

A Sinatra widget to update a HipChat room topic with information about GitHub PRs deployed to different Heroku applications.

Configure each Heroku app to send a post-deploy hook to the `/deployment` route. In response to each deployment, Statusaurus will:

- Check the SHA of the deployed commit against the open PRs in the configured GitHub repo
- Get the existing topic from the configured HipChat room
- Parse the topic for information about which PR is deployed to which Heroku app
- Update the topic based on the latest deployment

HipChat room topic format
---------------

The room topic is maintained as a list, delimited by `::`, in which each element is a PR name (or an abbreviated SHA, if the deployed commit does not correspond to a PR) followed by a hyphen and then the Heroku app name. For example:

`PR 1 - my-first-app :: PR 2 - my-2nd-app`


Configuration
---------------

The following environment variables must be set:

- HIPCHAT_TOKEN
- HIPCHAT_ROOM_ID

- GITHUB_ACCESS_TOKEN
- GITHUB_OWNER
- GITHUB_REPO

- HEROKU_APP_NAME_PREFIX
(e.g. "my-app-" if you have Heroku applications named "my-app-shakeout", "my-app-qa", etc. that you would like to abbreviate to "SHAKEOUT", "QA", etc.)