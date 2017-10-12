# WarLight Tools

This is a collection of ruby scripts that help with map creation for WarLight.
Currently there are 3 tools:

* centerpoints.rb - Calculates centerpoints of territory polygons
* connections.rb - Calculates which territory pairs border each other
* territory_names.rb - reads the `inkscape:label` attribute of each territory
  and uses it as the territory name

Each of the scripts the submits its findings to the WarLight server via the
HTTP API.


## Usage

1. Copy `config/sample.yml` to `config/production.yml`
2. Enter correct settings in `config/production.yml`
3. Prepare SVG in inkscape (set id of territory paths to `Territory_<n>`, set
   territory name into inkscape label)
4. call the scripts:

    ```
    ruby centerpoints.rb
    ruby connections.rb
    ruby territory_names.rb
    ```
 

## Further ideas

* add command line arguments at least for map ID and SVG file
* wrapper script as entry point, something like `warlight connections` and
  `warlight centerpoints`...
* use GetAPIToken API call to configure password instead of APIToken
* read additional territory info from path description in SVG
  * use info for API command `addTerritoryToBonus`
  * use info for API command `addTerritoryToDistribution`
* alternatively read complete information about bonus definitions, distribution
  modes and their territory relationships from a spreadsheet?


## Old Forum Threads

* http://warlight.net/Forum/Thread.aspx?ThreadID=2452
* http://warlight.net/Forum/Thread.aspx?ThreadID=2668
