module ApplicationHelper
  def sort_link(label, column)
    direction = (params[:sort] == column && params[:direction] == "asc") ? "desc" : "asc"
    arrow = if params[:sort] == column
              params[:direction] == "asc" ? " \u2191" : " \u2193"
            else
              ""
            end
    link_to safe_join([label, arrow]), url_for(request.query_parameters.merge(sort: column, direction: direction)), class: "hover:text-gray-700 transition-colors"
  end
end
