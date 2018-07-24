module SectionsHelper
  # HREF attribute value for headers in the section partials. If the section
  # is modifiable, returns the section path, otherwise the edit section path.
  #
  # @param section [Section] The section to return a URL for
  # @param phase [Phase] The phase that section belongs
  # @param template [Template] The template that phase belongs to
  #
  # @return String
  def header_path_for_section(section, phase, template)
    if section.modifiable?
      edit_org_admin_template_phase_section_path(template_id: template.id,
                                                 phase_id: phase.id,
                                                 id: section.id)
    else
      org_admin_template_phase_section_path(template_id: template.id,
                                            phase_id: phase.id,
                                            id: section.id)
    end
  end
end
