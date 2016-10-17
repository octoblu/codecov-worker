#!/usr/bin/env node

require('coffee-script/register');
var Command = require('./healthcheck.coffee');
var command = new Command(process.argv);
command.run();
