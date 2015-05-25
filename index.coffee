###!
# node-tvdb
#
# Node.js library for accessing TheTVDB API at <http://www.thetvdb.com/wiki/index.php?title=Programmers_API>
#
# Copyright (c) 2014-2015 Edward Wellbrook <edwellbrook@gmail.com>
# MIT Licensed
###

"use strict"
request = require("superagent").get
parser = require("xml2js").parseString
# available providers for remote ids
REMOTE_PROVIDERS =
  imdbid: /^tt/i
  zap2it: /^ep/i
# options for xml2js parser
PARSER_OPTS =
  trim: true
  normalize: true
  ignoreAttrs: true
  explicitArray: false
  emptyTag: null
#
# API Client
#

class Client
    ###*
    # Set up tvdb client with API key and optional language (defaults to "en")
    #
    # @param {String} token
    # @param {String} [language]
    # @api public
    ###

  constructor: (token, language) ->
    if !token
      throw new Error("Access token must be set.")
    @token = token
    @language = language or "en"
    @baseURL = "http://www.thetvdb.com/api"

  getLanguages: (callback) ->
    path = "#{this.baseURL}/${this.token}/languages.xml"
    sendRequest path, ((response, done) ->
      done if response and response.Languages then response.Languages.Language else null
    ), callback
  
  getTime: (callback) ->
    path = "#{this.baseURL}/Updates.php?type=none"
    sendRequest path, ((response, done) ->
      done if response and response.Items then response.Items.Time else null
    ), callback
  
  getSeriesByName: (name, callback) ->
    path = "#{this.baseURL}/GetSeries.php?seriesname=${name}&language=${this.language}"
    sendRequest path, ((response, done) ->
      response = if response and response.Data then response.Data.Series else null
      done if !response or Array.isArray(response) then response else [ response ]
    ), callback
  
  getSeriesById: (id, callback) ->
    path = "#{this.baseURL}/${this.token}/series/${id}/${this.language}.xml"
    sendRequest path, ((response, done) ->
      done if response and response.Data then response.Data.Series else null
    ), callback
  
  getSeriesByRemoteId: (remoteId, callback) ->
    keys = Object.keys(REMOTE_PROVIDERS)
    provider = ""
    len = keys.length
    while len-- and provider == ""
      if REMOTE_PROVIDERS[keys[len]].exec(remoteId)
        provider = keys[len]
    path = "#{this.baseURL}/GetSeriesByRemoteID.php?${provider}=${remoteId}&language=${this.language}"
    sendRequest path, ((response, done) ->
      done if response and response.Data then response.Data.Series else null
    ), callback
  
  getSeriesAllById: (id, callback) ->
    path = "#{this.baseURL}/${this.token}/series/${id}/all/${this.language}.xml"
    sendRequest path, ((response, done) ->
      if response and response.Data and response.Data.Series
        response.Data.Series.Episodes = response.Data.Episode
      done if response then response.Data.Series else null
    ), callback
  
  getActors: (id, callback) ->
    path = "#{this.baseURL}/${this.token}/series/${id}/actors.xml"
    sendRequest path, ((response, done) ->
      done if response and response.Actors then response.Actors.Actor else null
    ), callback
  
  getBanners: (id, callback) ->
    path = "#{this.baseURL}/${this.token}/series/${id}/banners.xml"
    sendRequest path, ((response, done) ->
      done if response and response.Banners then response.Banners.Banner else null
    ), callback

  getEpisodeById: (id, callback) ->
    path = "#{this.baseURL}/${this.token}/episodes/${id}"
    sendRequest path, ((response, done) ->
      done if response and response.Data then response.Data.Episode else null
    ), callback

  getUpdates: (time, callback) ->
    path = "#{this.baseURL}/Updates.php?type=all&time=${time}"
    sendRequest path, ((response, done) ->
      done if response then response.Items else null
    ), callback

#
# Exports
#
#
# Utilities
#

###*
# Send and handle http request
#
# @param {String} url
# @param {Function} normaliser - to normalise response object
# @param {Function} [callback]
# @return {Promise} promise
# @api private
###

sendRequest = (url, normaliser, callback) ->
  new Promise((resolve, reject) ->
    request url, (error, data) ->
      if data and data.statusCode == 200 and data.text != "" and data.text.indexOf("404 Not Found") == -1
        parseXML data.text, (error, results) ->
          normaliser results, (response) ->
            if callback
              callback error, response
            else
              if error then reject(error) else resolve(response)
            return
          return
      else
        if !error
          error = new Error("Could not complete the request")
        error.statusCode = if data then data.statusCode else undefined
        if callback
          callback error
        else
          reject error
      return
    return
)

###*
# Parse XML response
#
# @param {String} xml data
# @param {Function} callback
# @api private
###

parseXML = (data, callback) ->
  parser data, PARSER_OPTS, (error, results) ->
    if results and results.Error
      callback new Error(results.Error)
    else
      callback error, results
    return
  return

###*
# Parse pipe list string to javascript array
#
# @param {String} list
# @return {Array} parsed list
# @api public
###

parsePipeList = (list) ->
  list.replace(/(^\|)|(\|$)/g, "").split "|"

Client.utils = parsePipeList: parsePipeList
module.exports = Client

# ---
# generated by js2coffee 2.0.4