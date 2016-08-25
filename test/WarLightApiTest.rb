# coding: utf-8
require 'json'

req = {
  'email' => 'test@test.com',
  'APIToken' => '0123456789',
  "mapID" => 999999999,
  "commands"  =>  [
  { "command" =>  "setTerritoryName", "id"=> 12, "name"=> "Kamchatka" },
  { "command"  => "setTerritoryName", "id"=> 34, "name"=> "Ukraine" }
  ]
}

json = req.to_json
print json
