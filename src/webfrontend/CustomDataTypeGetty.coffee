class CustomDataTypeGetty extends CustomDataTypeWithCommons

  #######################################################################
  # return name of plugin
  getCustomDataTypeName: ->
    "custom:base.custom-data-type-getty.getty"


  #######################################################################
  # return name (l10n) of plugin
  getCustomDataTypeNameLocalized: ->
    $$("custom.data.type.getty.name")


  #######################################################################
  # if type is DifferentiatedPerson or CorporateBody, get short info about entry from entityfacts
  __getAdditionalTooltipInfo: (uri, tooltip, extendedInfo_xhr) ->
    # extract gndID from uri
    gndID = uri
    gndID = gndID.split "/"
    gndID = gndID.pop()
    # download infos
    if extendedInfo_xhr.xhr != undefined
      # abort eventually running request
      extendedInfo_xhr.abort()
    # start new request
    xurl = location.protocol + '//jsontojsonp.gbv.de/?url=http://hub.culturegraph.org/entityfacts/' + gndID
    extendedInfo_xhr = new (CUI.XHR)(url: xurl)
    extendedInfo_xhr.start()
    .done((data, status, statusText) ->
      htmlContent = ''
      htmlContent += '<table style="border-spacing: 10px; border-collapse: separate;">'
      htmlContent += '<tr><td colspan="2"><h4>Informationen über den Eintrag</h4></td></tr>'
      ##########################
      # DifferentiatedPerson and CorporateBody

      # Vollständiger Name (DifferentiatedPerson + CorporateBody)
      htmlContent += "<tr><td>Name:</td><td>" + data.preferredName + "</td></tr>"
      # Abbildung (DifferentiatedPerson + CorporateBody)
      depiction = data.depiction
      if depiction
        if depiction.thumbnail
          htmlContent += '<tr><td>Abbildung:</td><td><img src="' + depiction.thumbnail['@id'] + '" style="border: 0; max.width:120px; max-height:150px;" /></td></tr>'
      # Lebensdaten (DifferentiatedPerson)
      dateOfBirth = data.dateOfBirth
      dateOfDeath = data.dateOfDeath
      if dateOfBirth or dateOfDeath
        htmlContent += "<tr><td>Lebensdaten:</td><td>"
        if dateOfBirth and dateOfDeath
          htmlContent += dateOfBirth + " bis " + dateOfDeath
        else if dateOfBirth and !dateOfDeath
          htmlContent += dateOfBirth + " bis unbekannt"
        else if !dateOfBirth and dateOfDeath
          htmlContent += "unbekannt bis " + dateOfDeath
        htmlContent += "</td></tr>"
      # Date of Establishment (CorporateBody)
      dateOfEstablishment = data.dateOfEstablishment
      if dateOfEstablishment
        htmlContent += "<tr><td>Gründung:</td><td>" + dateOfEstablishment[0] + "</td></tr>"
      # Place of Business (CorporateBody)
      placeOfBusiness = data.placeOfBusiness
      places = []
      if placeOfBusiness
        if placeOfBusiness.length > 0
          for place in placeOfBusiness
            places.push(place.preferredName)
          htmlContent += "<tr><td>Niederlassung(en):</td><td>" + places.join("<br />") + "</td></tr>"
      # Übergeordnete Körperschaft (CorporateBody)
      hierarchicallySuperiorOrganisation = data.hierarchicallySuperiorOrganisation
      organisations = []
      if hierarchicallySuperiorOrganisation
        if hierarchicallySuperiorOrganisation.length > 0
          for organisation in hierarchicallySuperiorOrganisation
            organisations.push(organisation.preferredName)
          htmlContent += "<tr><td>Übergeordnete Körperschaft(en):</td><td>" + organisations.join("<br />") + "</td></tr>"
      # Geburtsort (DifferentiatedPerson)
      placeOfBirth = data.placeOfBirth
      if placeOfBirth
        htmlContent += "<tr><td>Geburtsort:</td><td>" + placeOfBirth[0].preferredName + "</td></tr>"
      # Sterbeort (DifferentiatedPerson)
      placeOfDeath = data.placeOfDeath
      if placeOfDeath
        htmlContent += "<tr><td>Sterbeort:</td><td>" + placeOfDeath[0].preferredName + "</td></tr>"
      # Berufe (DifferentiatedPerson)
      professionOrOccupation = data.professionOrOccupation
      professions = []
      if professionOrOccupation
        if professionOrOccupation.length > 0
          for profession in professionOrOccupation
            professions.push(profession.preferredName)
          htmlContent += "<tr><td>Beruf(e):</td><td>" + professions.join("<br />") + "</td></tr>"
      # Biographie (DifferentiatedPerson)
      biographicalOrHistoricalInformation = data.biographicalOrHistoricalInformation
      if biographicalOrHistoricalInformation
        htmlContent += "<tr><td>Biographie:</td><td>" + biographicalOrHistoricalInformation + "</td></tr>"
      # Thema (CorporateBody)
      topic = data.topic
      topics = []
      if topic
        if topic.length > 0
          for t in topic
            topics.push(t.preferredName)
          htmlContent += "<tr><td>Themen:</td><td>" + topics.join("<br />") + "</td></tr>"

      # Synonyme (DifferentiatedPerson + CorporateBody)
      variantName = data.variantName
      if variantName
        if variantName.length > 0
          variantNames = variantName.join("<br />")
          htmlContent += "<tr><td>Synonyme:</td><td>" + variantNames + "</td></tr>"

      htmlContent += "</table>"
      tooltip.DOM.innerHTML = htmlContent
      tooltip.autoSize()
    )

    return


  #######################################################################
  # handle suggestions-menu
  __updateSuggestionsMenu: (cdata, cdata_form, suggest_Menu, searchsuggest_xhr) ->
    that = @

    delayMillisseconds = 200

    setTimeout ( ->
      getty_searchterm = cdata_form.getFieldsByName("searchbarInput")[0].getValue()

      getty_searchtype = cdata_form.getFieldsByName("gettySelectType")[0].getValue()
      # if "search-all-types", search all allowed types
      if getty_searchtype == 'all_supported_types'
        getty_searchtype = []
        if that.getCustomSchemaSettings().add_aat?.value
          getty_searchtype.push 'aat'
        if that.getCustomSchemaSettings().add_tgn?.value
          getty_searchtype.push 'tgn'
        if that.getCustomSchemaSettings().add_ulan?.value
          getty_searchtype.push 'ulan'
        getty_searchtype = getty_searchtype.join(',')

      getty_countSuggestions = cdata_form.getFieldsByName("countOfSuggestions")[0].getValue()

      if getty_searchterm.length == 0
          return

      # run autocomplete-search via xhr
      if searchsuggest_xhr.xhr != undefined
          # abort eventually running request
          searchsuggest_xhr.xhr.abort()

      # start new request
      searchsuggest_xhr.xhr = new (CUI.XHR)(url: location.protocol + '//ws.gbv.de/suggest/getty/?searchstring=' + getty_searchterm + '&voc=' + getty_searchtype + '&count=' + getty_countSuggestions)
      searchsuggest_xhr.xhr.start().done((data, status, statusText) ->

          # init xhr for tooltipcontent
          extendedInfo_xhr = { "xhr" : undefined }
          # create new menu with suggestions
          menu_items = []
          for suggestion, key in data[1]
            do(key) ->
              # the actual Featureclass...
              aktType = data[2][key]
              lastType = ''
              if key > 0
                lastType = data[2][key-1]
              if aktType != lastType
                item =
                  divider: true
                menu_items.push item
                item =
                  label: aktType
                menu_items.push item
                item =
                  divider: true
                menu_items.push item
              item =
                text: suggestion
                value: data[3][key]
                tooltip:
                  markdown: true
                  placement: "e"
                  content: (tooltip) ->
                    # if enabled in mask-config
                    if that.getCustomMaskSettings().show_infopopup?.value
                      # if type is ready for infopopup
                      if aktType == "DifferentiatedPerson" or aktType == "CorporateBody"
                        that.__getAdditionalTooltipInfo(data[3][key], tooltip, extendedInfo_xhr)
                        new Label(icon: "spinner", text: "lade Informationen")
              menu_items.push item

          # set new items to menu
          itemList =
            onClick: (ev2, btn) ->
              # lock in save data
              cdata.conceptURI = btn.getOpt("value")
              cdata.conceptName = btn.getText()
              # lock in form
              cdata_form.getFieldsByName("conceptName")[0].storeValue(cdata.conceptName).displayValue()
              # nach eadb5-Update durch "setText" ersetzen und "__checkbox" rausnehmen
              cdata_form.getFieldsByName("conceptURI")[0].__checkbox.setText(cdata.conceptURI)
              cdata_form.getFieldsByName("conceptURI")[0].show()

              # clear searchbar
              cdata_form.getFieldsByName("searchbarInput")[0].setValue('')
              # hide suggest-menu
              suggest_Menu.hide()
              @
            items: menu_items

          # if no hits set "empty" message to menu
          if itemList.items.length == 0
            itemList =
              items: [
                text: "kein Treffer"
                value: undefined
              ]

          suggest_Menu.setItemList(itemList)

          suggest_Menu.show()
      )
    ), delayMillisseconds


  #######################################################################
  # create form
  __getEditorFields: (cdata) ->
    # read searchtypes from datamodell-options
    dropDownSearchOptions = []
    # offer DifferentiatedPerson
    if @getCustomSchemaSettings().add_aat?.value
        option = (
            value: 'aat'
            text: 'Art & Architecture Thesaurus'
          )
        dropDownSearchOptions.push option
    # offer CorporateBody?
    if @getCustomSchemaSettings().add_tgn?.value
        option = (
            value: 'tgn'
            text: 'Getty Thesaurus of Geographic Names'
          )
        dropDownSearchOptions.push option
    # offer PlaceOrGeographicName?
    if @getCustomSchemaSettings().add_ulan?.value
        option = (
            value: 'ulan'
            text: 'Union List of Artist Names'
          )
        dropDownSearchOptions.push option
    # add "Alle"-Option? If count of options > 1!
    #if dropDownSearchOptions.length > 1
    #    option = (
    #        value: 'all_supported_types'
    #        text: 'Alle'
    #      )
    #    dropDownSearchOptions.unshift option
    # if empty options -> offer all
    if dropDownSearchOptions.length == 0
        dropDownSearchOptions = [
          (
            value: 'aat'
            text: 'Art & Architecture Thesaurus'
          )
          (
            value: 'tgn'
            text: 'Getty Thesaurus of Geographic Names'
          )
          (
            value: 'ulan'
            text: 'Union List of Artist Names'
          )
        ]
    [{
      type: CUI.Select
      undo_and_changed_support: false
      form:
          label: $$('custom.data.type.getty.modal.form.text.type')
      options: dropDownSearchOptions
      name: 'gettySelectType'
      class: 'commonPlugin_Select'
    }
    {
      type: CUI.Select
      undo_and_changed_support: false
      class: 'commonPlugin_Select'
      form:
          label: $$('custom.data.type.getty.modal.form.text.count')
      options: [
        (
            value: 10
            text: '10 Vorschläge'
        )
        (
            value: 20
            text: '20 Vorschläge'
        )
        (
            value: 50
            text: '50 Vorschläge'
        )
        (
            value: 100
            text: '100 Vorschläge'
        )
      ]
      name: 'countOfSuggestions'
    }
    {
      type: CUI.Input
      undo_and_changed_support: false
      form:
          label: $$("custom.data.type.getty.modal.form.text.searchbar")
      placeholder: $$("custom.data.type.getty.modal.form.text.searchbar.placeholder")
      name: "searchbarInput"
      class: 'commonPlugin_Input'
    }
    {
      form:
        label: "Gewählter Eintrag"
      type: CUI.Output
      name: "conceptName"
      data: {conceptName: cdata.conceptName}
    }
    {
      form:
        label: "Verknüpfte URI"
      type: CUI.FormButton
      name: "conceptURI"
      icon: new CUI.Icon(class: "fa-lightbulb-o")
      text: cdata.conceptURI
      onClick: (evt,button) =>
        window.open cdata.conceptURI, "_blank"
      onRender : (_this) =>
        if cdata.conceptURI == ''
          _this.hide()
    }
    ]


  #######################################################################
  # renders the "result" in original form (outside popover)
  __renderButtonByData: (cdata) ->

    # when status is empty or invalid --> message

    switch @getDataStatus(cdata)
      when "empty"
        return new CUI.EmptyLabel(text: $$("custom.data.type.getty.edit.no_getty")).DOM
      when "invalid"
        return new CUI.EmptyLabel(text: $$("custom.data.type.getty.edit.no_valid_getty")).DOM

    # if status is ok
    conceptURI = CUI.parseLocation(cdata.conceptURI).url

    # if conceptURI .... ... patch abwarten

    tt_text = $$("custom.data.type.getty.url.tooltip", name: cdata.conceptName)

    # output Button with Name of picked Entry and Url to the Source

    # replace conceptUri with better human-readable website
    # http://vocab.getty.edu/aat/300386183 turns http://vocab.getty.edu/page/aat/300386183
    displayUri = cdata.conceptURI.replace('http://vocab.getty.edu', 'http://vocab.getty.edu/page')

    new CUI.ButtonHref
      appearance: "link"
      href: displayUri
      target: "_blank"
      tooltip:
        markdown: true
        text: tt_text
      text: cdata.conceptName
    .DOM



  #######################################################################
  # zeige die gewählten Optionen im Datenmodell unter dem Button an
  getCustomDataOptionsInDatamodelInfo: (custom_settings) ->
    tags = []

    console.log custom_settings

    if custom_settings.add_aat?.value
      tags.push "✓ AAT"
    else
      tags.push "✘ AAT"

    if custom_settings.add_tgn?.value
      tags.push "✓ TGN"
    else
      tags.push "✘ TGN"

    if custom_settings.add_ulan?.value
      tags.push "✓ ULAN"
    else
      tags.push "✘ ULAN"

    tags


CustomDataType.register(CustomDataTypeGetty)
