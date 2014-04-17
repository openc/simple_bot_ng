# Example bots

These are some example bots to show how the new bot framework could
work.

Bots, when executed, should write JSON to STDOUT. So you can try
running a sample scraper just with:

    ruby bots/bm_insurance_licenses/scrape.rb

Note that that example has an exit condition to stop after just 10
rows - you can change that if you like.

If you wish to send data to Turbot, you must first register it:

    ./turbot.rb register -c bots/bm_insurance_licenses/config.js

You can check what you've registered so far with:

    ./turbot.rb list

You can send data with:

    ./turbot.rb send bm_insurance_licences_raw

Or:

    ./turbot.rb send bm_insurance_licences

(That depends on the previous bot having run -- dependency resolution
hasn't been implemented yet)

You can review data you've submitted at the URL returned by the above
function.  There's a search interface at http://datasets1:8080

When you are happy your data is ready to be submitted, run:

    ./turbot.rb submit bm_insurance_licences_raw

This signals the end of a run. Trying to submit data against without
re-registering the bot will not succeed.  When a run is completed,
OpenCorporates will start the QA process which will end up with the
data appearing in our database.
