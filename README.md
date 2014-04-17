# Example bots

These are some example bots to show how the new bot framework could
work.

Bots, when executed, should write JSON to STDOUT.

If you wish to send data to Turbot, you must first register it:

    ./turbot.rb register -c bots/us_fl_flofr_finance_license/config.js

You can check what you've registered with:

    ./turbot.rb list

You can send data with:

    ./turbot.rb send us_fl_insurance_licences_raw

You can review data you've submitted at the URL returned by the above
function.  There's a search interface at http://datasets1:8080

When you are happy your data is ready to be submitted, run:

    ./turbot.rb submit us_fl_insurance_licences_raw

This signals the end of a run. Trying to submit data against without
re-registering the bot will not succeed.  When a run is completed,
OpenCorporates will start the QA process which will end up with the
data appearing in our database.
