import getConstant from './constants';
import debounce from './debounce';
import { toggleConditionalFields } from './conditional';

$(() => {
  const debounceAutocompleteMap = {};

  const getId = (context, attrName) => {
    if (context.length > 0) {
      const nameParts = context.attr(attrName).split('-');
      return nameParts[nameParts.length - 1]
    }
  };

  const relatedAutocomplete = (id) => {
    return $(`[list="autocomplete-list-${id}"]`);
  };

  const relatedNotInListCheckbox = (id) => {
    return $(`[context="not-in-list-${id}"]`);
  };

  const relatedUserEnteredOrg = (id) => {
    return $(`.user-entered-org-${id}`);
  };

  const relatedWarning = (id) => {
    return $(`.autocomplete-warning-${id}`);
  };

  const relatedDataList = (id) => {
    return $(`#autocomplete-list-${id}`);
  };

  const toggleWarning = (autocomplete, displayIt) => {
    const warning = relatedWarning(getId(autocomplete, 'list'));

    if (warning.length > 0) {
      if (displayIt) {
        warning.removeClass('hide').show();
      } else {
        warning.addClass('hide').hide();
      }
    }
  };

  const forceRailsRemote = debounce((autocomplete) => {
    if (autocomplete.length > 0) {
      // Force the Rails remote call
      autocomplete.blur().focus();
    }
  }, 600);

  const handleAutocompleteUserInput = (autocomplete) => {
    if (autocomplete.length > 0) {
      const id = getId(autocomplete, 'list');
      const dataList = relatedDataList(id);

      // Clear the existing results and show a 'Searching ...' message
      if (dataList.length > 0) {
        dataList.html(`<option>${getConstant('AUTOCOMPLETE_SEARCHING')}</option>`);
      }

      // See if we already have a user action in the queue
      if (!debounceAutocompleteMap[id]) {
        // Setup a debounce for the action (e.g. wait a few milliseconds for further user input)
        debounceAutocompleteMap[id] = forceRailsRemote(autocomplete);
      } else {
        // Cancel the prior action
        debounceAutocompleteMap[id].cancel();
      }
    }
  };

  $('body').on('keyup', '.auto-complete', (e) => {
    const autocomplete = $(e.currentTarget);
    const code = (e.keyCode || e.which);

    if (autocomplete.length > 0 && autocomplete.val().length > 2) {
      // Only pay attention to key presses that would actually change the contents of the field
      if ((code >= 48 && code <= 111) || (code >= 144 && code <= 222) || code === 8 || code === 9) {
        const checkbox = relatedNotInListCheckbox(getId(autocomplete, 'list'));

        if (checkbox.length > 0) {
          // Uncheck the Not in List checkbox
          checkbox.prop('checked', false);
          toggleConditionalFields(checkbox, false);
        }
        toggleWarning(autocomplete, false);
        handleAutocompleteUserInput(autocomplete);
      } else {
        e.preventDefault();
      }
    } else {
      e.preventDefault();
    }
  });

  $('body').on('change', '.auto-complete', (e) => {
    const autocomplete = $(e.currentTarget);
    const dataList = relatedDataList(getId(autocomplete, 'list'));
    const selection = dataList.find(`option[id="${autocomplete.val()}"]`);

    if (selection.length <= 0) {
      toggleWarning(autocomplete, true);
    } else {
      toggleWarning(autocomplete, false);
    }
  });

  // Initialize any related 'not in list' conditionals
  $('.new-org-entry').on('click', (e) => {
    const checkbox = $(e.currentTarget);
    const id = getId(checkbox, 'context');
    const autocomplete = relatedAutocomplete(id);
    const userEnteredOrg = relatedUserEnteredOrg(id);

    // Display the conditional field and then copy the contents of the autocomplete into the new org box
    const checked = checkbox.prop('checked');
    toggleConditionalFields(checkbox, checked);
    userEnteredOrg.val(checked ? autocomplete.val() : '');
    autocomplete.val('');
  });

  // Hide the new org textbox on initial page load
  $('.new-org-entry').each((_idx, el) => {
    toggleConditionalFields($(el), false);
  });
});
