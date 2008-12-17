module TypusHelper

  ##
  # Applications list on the dashboard
  #
  def applications

    if Typus.applications.empty?
      return display_error("There are not defined applications in config/typus/*.yml")
    end

    html = ""

    Typus.applications.each do |app|

      available = []

      Typus.application(app).each do |resource|
        available << resource if @current_user.resources.include?(resource)
      end

      unless available.empty?

        html << <<-HTML
<table>
<tr>
  <th colspan="2">#{app}</th>
</tr>
        HTML

        available.each do |model|
          description = Typus.module_description(model)
          html << <<-HTML
<tr class=\"#{cycle('even', 'odd')}\">
<td>#{link_to model.titleize.pluralize, send("admin_#{model.tableize}_url")}<br /><small>#{description}</small></td>
<td class=\"right\"><small>
  #{link_to 'Add', send("new_admin_#{model.tableize.singularize}_url") if @current_user.can_perform?(model, 'create')}
</small></td>
</tr>
          HTML
        end

        html << <<-HTML
</table>
        HTML

      end

    end

    return html

  end

  ##
  # Resources (wich are not models) on the dashboard.
  #
  def resources

    available = []

    Typus.resources.each do |resource|
      available << resource if @current_user.resources.include?(resource)
    end

    unless available.empty?

      html = <<-HTML
<table>
<tr>
  <th colspan="2">Resources</th>
</tr>
      HTML

      available.each do |resource|
        html << <<-HTML
<tr class="#{cycle('even', 'odd')}">
  <td>#{link_to resource.titleize, "#{Typus::Configuration.options[:prefix]}/#{resource.underscore}"}</td>
  <td align="right" style="vertical-align: bottom;"></td>
</tr>
        HTML
      end

      html << <<-HTML
</table>
      HTML

    end

    return html

  end

  def typus_block(*args)
    options = args.extract_options!
    file = ([] << "admin" << options[:model] << options[:location] << options[:partial])
    render :partial => file.compact.join('/') rescue nil
  end

  def page_title
    crumbs = []
    crumbs << Typus::Configuration.options[:app_name]
    crumbs << @resource[:class_name_humanized].pluralize if @resource
    crumbs << params[:action].titleize unless %w( index ).include?(params[:action])
    return crumbs.compact.map { |x| x }.join(" &rsaquo; ")
  end

  def header
    "<h1>#{Typus::Configuration.options[:app_name]} <small>#{link_to "View site", root_url, :target => 'blank' rescue ''}</small></h1>"
  end

  def login_info
    returning(String.new) do |html|
      html << <<-HTML
<ul>
  <li>Logged as #{link_to @current_user.full_name(true), :controller => 'admin/typus_users', :action => 'edit', :id => @current_user.id}</li>
  <li>#{link_to "Logout", typus_logout_url}</li>
</ul>
      HTML
    end
  end

  def display_flash_message
    return if flash.empty?
    flash_type = flash.keys.first
    returning(String.new) do |html|
      html << <<-HTML
<div id="flash" class="#{flash_type}"><p>#{flash[flash_type]}</p></div>
      HTML
    end
  end

  def display_error(error)
    log_error(error)
    returning(String.new) do |html|
      html << <<-HTML
<div id="flash" class="error"><p>#{error}</p></div>
      HTML
    end
  end

  ##
  #
  #
  def log_error(exception)
    ActiveSupport::Deprecation.silence do
        logger.fatal(
        "Typus Error:\n\n#{exception.class} (#{exception.message}):\n    " +
        exception.backtrace.join("\n    ") +
        "\n\n"
        )
    end
  end

end