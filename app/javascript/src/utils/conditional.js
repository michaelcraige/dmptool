// Toggle (hide/show) the additional fields related to the context

export const toggleConditionalFields = (context, displayFields) => {
  if (context.length > 0) {
    const container = $(context).closest('conditional');

console.log(`container: ${container.length} -> ${displayFields} :: ${displayFields === true}`);

    if (container.length > 0) {
      if (displayFields === true) {
        container.find('.toggleable-field').show();
      } else {
        container.find('.toggleable-field').find('input, textarea').val('');
        container.find('.toggleable-field').hide();
      }
    }
  }
};
