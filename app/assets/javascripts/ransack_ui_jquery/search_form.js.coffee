(($) ->
  $.widget 'ransack.search_form',
    options: {}

    _create: ->
      el = this.element
      el.on 'click', '.add_fields',       $.proxy(this.add_fields, this)
      el.on 'click', '.remove_fields',    $.proxy(this.remove_fields, this)
      el.on 'change', 'select.ransack_predicate', $.proxy(this.predicate_changed, this)
      el.on 'change', 'select.ransack_attribute', $.proxy(this.attribute_changed, this)
      el.on 'click focus', 'input.ransack_query', $.proxy(this.query_focus, this)

      # Set up Select2 on select lists in .filters
      this.init_select2(this.element.find('.filters'))

      # show spinner and disable the form when the search is underway
      el.find("form input:submit").click $.proxy(this.form_submit, this)

      # Fire change event for any existing selects.
      el.find(".filters select").change()

      # For basic search, remove placeholder text on focus, restore on blur
      $('#query').focusin (e) ->
        $(this).data('placeholder', $(this).attr('placeholder')).attr('placeholder', '')
      $('#query').focusout (e) ->
        $(this).attr('placeholder', $(this).data('placeholder'))

    predicate_changed: (e) ->
      target   = $(e.currentTarget)
      base_id = target.attr('id').slice(0, -1)
      query_input = $('input#' + base_id + "v_0_value")
      if target.val() in ["true", "false", "blank", "present", "null", "not_null"]
        query_input.val("true")
        query_input.hide()
      else
        unless query_input.is(":visible")
          query_input.val("")
          query_input.show()

    attribute_changed: (e) ->
      target = $(e.currentTarget)
      selected = target.find('option:selected')
      column_type = selected.data('type')

      base_id = target.attr('id').slice(0, -8)
      predicate_select  = this.element.find('select#' + base_id + 'p')
      predicate_select2 = this.element.find('#s2id_' + base_id + 'p')
      query_input = $('input#' + base_id + "v_0_value")

      # Clear any datepicker from query input
      query_input.datepicker('destroy')

      if selected.data('ajax-url') and Select2?
        controller = selected.data('controller')

        # Hide predicate Select2
        predicate_select2.hide()
        # Clear predicates, and set 'eq' predicate
        predicate_select.find('option').each (i, o) -> $(o).remove()
        predicate_select.append $('<option selected="selected" value="eq">is</option>')

        # Set up Select2 for query input
        query_input.val('')
        query_input.select2
          placeholder: "Search #{selected.data('ajax-entity')}"
          minimumInputLength: 1
          allowClear: true
          ajax:
            url: selected.data('ajax-url')
            dataType: 'json'
            type: selected.data('ajax-type')
            data: (query, page) ->
              obj = {}
              obj[selected.data('ajax-key')] = query
              obj
            results: (data, page) ->
              {results: $.map(data, (text, id) -> {id: id, text: text}) }
      else
        predicate_select2.show()
        # If Select2 is on query input, remove and set defaults
        if query_select2 = this.element.find('#s2id_' + base_id + 'v_0_value')
          query_input.select2('destroy')
          query_input.val('')
          previous_val = ''
        else
          previous_val = predicate_select.val()

        # Build array of supported predicates
        available = predicate_select.data['predicates']
        predicates = Ransack.type_predicates[column_type] || []
        predicates = $.map predicates, (p) -> [p, Ransack.predicates[p]]

        # Remove all predicates, and add any supported predicates
        predicate_select.find('option').each (i, o) -> $(o).remove()

        $.each available, (i, p) =>
          [val, label] = [p[0], p[1]]
          if val in predicates
            # Get alternative predicate label depending on column type
            label = this.alt_predicate_label_or_default(val, column_type, label)
            predicate_select.append $('<option value='+val+'>'+label+'</option>')

        # Select first predicate if current selection is invalid
        predicate_select.select2('val', previous_val)

        # Run predicate_changed callback
        predicate_select.change()

      return true

    query_focus: (e) ->
      if $.ui?.timepicker?
        target = $(e.currentTarget)
        base_id = target.attr('id').slice(0, -9)
        query_input = $('input#' + base_id + "v_0_value")

        # Only set up new datepicker if not already initialized
        if query_input.not('.hasDatePicker')
          selected_attr = this.element.find('select#' + base_id + 'a_0_name option:selected')

          datepicker_options =
            changeMonth: true
            constrainInput: false
            dateFormat: 'yy-mm-dd'
            # Always prefer custom input text over selected date
            onClose: (date) -> $(this).val(date)

          switch selected_attr.data('type')
            when "date"
              query_input.datepicker(datepicker_options)
            when "datetime"
              query_input.datetimepicker(datepicker_options)
            when "time"
              query_input.datetimepicker $.extend(datepicker_options, {timeOnly: true})

    # Attempts to find a predicate translation for the specific column type,
    # or returns the default label.
    # For example, 'lt' on an integer column will be translated to 'is less than',
    # while a date column will have it translated as 'is before'.
    # This is mainly to avoid confusion when building conditions using Chronic strings.
    # 'created_at is less than 2 weeks ago' is misleading, and
    # 'created_at is before 2 weeks ago' is much easier to understand.
    alt_predicate_label_or_default: (p, type, default_label) ->
      return default_label unless Ransack?.alt_predicates_i18n?

      alt_labels = {}
      switch type
        when "date", "datetime", "time"
          alt_labels = Ransack.alt_predicates_i18n["date"] || {}
        else
          alt_labels = Ransack.alt_predicates_i18n[type] || {}

      alt_labels[p] || default_label


    form_submit: (e) ->
      $("#loading").show()
      this.element.css({ opacity: 0.4 })
      $('div.list').html('')
      true

    add_fields: (e) ->
      target  = $(e.currentTarget)
      type    = target.data("fieldType")
      content = target.data("content")
      new_id = new Date().getTime()
      regexp = new RegExp('new_' + type, 'g')
      container = target.closest('p')
      container.before content.replace(regexp, new_id)
      this.init_select2 container.prev()
      # Fire change event on any new selects.
      container.prev().find("select").change()
      false

    remove_fields: (e) ->
      target    = $(e.currentTarget)
      container = target.closest('.fields')
      if (container.siblings().length > 1)
        container.remove()
      else
        container.parent().closest('.fields').remove()
      false

    init_select2: (container) ->
      if Select2?
        # Store current predicates in data attribute
        predicate_select = container.find('select.ransack_predicate')
        unless predicate_select.data['predicates']
          predicates = []
          predicate_select.find('option').each (i, o) ->
            $o = $(o)
            predicates.push [$o.val(), $o.text()]
          predicate_select.data['predicates'] = predicates

        container.find('select.ransack_predicate').select2
          width: '130px'
          formatNoMatches: (term) ->
            "No predicates found"

        container.find('select.ransack_attribute').select2
          width: '220px'
          placeholder: "Select a Field"
          allowClear: true
          formatSelection: (object, container) ->
            # Return 'Model: field' unless column is on root model
            if $(object.element).data('root-model')
              object.text
            else
              group_label = $(object.element).parent().attr('label')
              # Avoid labels like 'Contact: Contact'
              if group_label == object.text
                object.text
              else
                $(object.element).parent().attr('label') + ': ' + object.text
) jQuery
