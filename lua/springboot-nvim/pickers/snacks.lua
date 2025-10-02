local snacks = require("snacks")

--TODO: Use API to get list
local function choose_spring_dependencies(callback)
  local dependencies = {
    "Spring Web",
    "Spring Data JPA",
    "Spring Security",
    "Spring Boot DevTools",
    "Spring Validation",
    "Thymeleaf",
    "Spring Batch",
    "Spring Kafka",
    "Spring Actuator",
    "MySQL Driver",
    "PostgreSQL Driver",
    "Lombok",
    "Flyway",
    "MongoDB",
    "Redis",
  }

  local done_label = "Done"
  local wrapped = {}
  for _, dep in ipairs(dependencies) do
    table.insert(wrapped, { kind = "dep", value = dep })
  end
  table.insert(wrapped, { kind = "done", value = done_label })

  snacks.picker({
    items = wrapped,
    prompt = string.format(
      "Select Spring Boot dependencies (TAB to select, ENTER on '%s')",
      done_label
    ),
    format = function(entry)
      return entry.value
    end,
    confirm = function(picker)
      local selected = picker:selected()
      local chosen = {}
      for _, entry in ipairs(selected) do
        if entry.kind == "dep" then
          table.insert(chosen, entry.value)
        end
      end
      callback(chosen)
    end,
  })
end

choose_spring_dependencies(function(selected_deps)
  if #selected_deps == 0 then
    --TODO: If no dependencies are selected, use default (config)
  else
    vim.notify(
      "Selected dependencies:\n- " .. table.concat(selected_deps, "\n- "),
      vim.log.levels.INFO
    )
  end
end)
