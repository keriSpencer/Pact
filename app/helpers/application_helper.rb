module ApplicationHelper
  def sort_link(label, column)
    direction = (params[:sort] == column && params[:direction] == "asc") ? "desc" : "asc"
    arrow = if params[:sort] == column
              params[:direction] == "asc" ? " \u2191" : " \u2193"
            else
              ""
            end
    link_to "#{label}#{arrow}".html_safe, request.params.merge(sort: column, direction: direction), class: "hover:text-gray-700"
  end
end
