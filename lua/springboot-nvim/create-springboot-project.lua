---@type BasicPicker
local basic_picker = require("springboot-nvim.pickers.basic")
---@type SnacksPicker
local snacks_picker = require("springboot-nvim.pickers.snacks")
---@type Utils
local spring_utils = require("springboot-nvim.utils")
---@type ConfigOptions
local config = require("springboot-nvim.config")

---@class Create_Springboot_Project
local M = {}

---@type New_Project_Info
local project_info = {
  boot_version = "",
  language = "",
  java_version = "",
  build_type = "",
  dependencies = "",
  group_id = "",
  artifact_id = "",
  name = "",
  package_name = "",
}

---Adds data to a table handling springboot project data. This function is only for decoding the spring web request!!!
---@param data table The table that is the result of decoding the spring web request.
---@return string[] spring_data A table containing data holding the ids of spring project values
local handle_start_springboot_data = function(data)
  local spring_data = {}
  for _, value in pairs(data.values) do
    table.insert(spring_data, value.id)
  end
  return spring_data
end

---Helper function for doing some error reporting on input
---@param input_stage string which part of the input an error was triggered
local abort_input = function(input_stage)
  vim.notify(
    string.format("Failure on input: %s", input_stage),
    vim.log.levels.ERROR
  )
end

---Final (helper) function to be called for running the command to create a new project
local run_new_project_command = function()
  local command = string.format(
    "spring init --boot-version=%s --language=%s --java-version=%s --build=%s --dependencies=%s --groupId=%s --artifactId=%s --name=%s --package-name=%s %s",
    project_info.boot_version,
    project_info.language,
    project_info.java_version,
    project_info.build_type,
    project_info.dependencies,
    project_info.group_id,
    project_info.artifact_id,
    project_info.name,
    project_info.package_name,
    project_info.name
  )

  local output = vim.fn.system(command)
  if vim.v.shell_error ~= 0 then
    vim.notify(
      "Someting went wrong executing spring command: \n"
        .. output
        .. "Command executed: \n"
        .. command,
      vim.log.levels.WARN
    )
  else
    vim.notify("Succesfully created spring project", vim.log.levels.INFO)
    vim.fn.chdir(project_info.name)
  end
end

---Helper function for project naming
---@param value string|nil value to be assigned or nil if action was cancelled
---@param key string Key from project_info table
---@param default_value string value to be used when no value is provided
---@return boolean continue Whether the action can continue or not
local naming_helper = function(value, key, default_value)
  if not value then
    abort_input(key)
    return false
  elseif value == "" then
    project_info[key] = default_value
  else
    project_info[key] = value
  end
  return true
end

---Callback method handling the naming scheme for new project creation
local naming_input = function()
  local continue = false
  vim.ui.input({ prompt = "Enter Group(com.example): " }, function(group_id)
    continue = naming_helper(group_id, "group_id", "com.example")
    if not continue then
      abort_input("Group ID")
      return
    end
    vim.ui.input({ prompt = "Enter Artifact(demo): " }, function(artifact_id)
      continue = naming_helper(artifact_id, "artifact_id", "demo")
      if not continue then
        abort_input("Arifact ID")
        return
      end
      vim.ui.input(
        { prompt = "Enter project name(demo): " },
        function(project_name)
          continue = naming_helper(project_name, "name", "demo")
          if not continue then
            abort_input("Project Name")
            return
          end
          vim.ui.input(
            { prompt = "Enter package name(com.example.demo): " },
            function(package_name)
              continue = naming_helper(
                package_name,
                "package_name",
                project_info.group_id .. "." .. project_info.artifact_id
              )
              if not continue then
                abort_input("Package Name")
                return
              end
              run_new_project_command()
            end
          )
        end
      )
    end)
  end)
end

---Callback method to be called after choosing dependencies
---@param dependencies string[]|nil Array containing the dependencies chosen
local choose_dependencies_callback = function(dependencies)
  if dependencies == nil then
    abort_input("dependencies")
    return
  end
  local dependency_string = table.concat(dependencies, ",")
  project_info.dependencies = dependency_string
  naming_input()
end

---The main method for starting a new springboot project
M.springboot_new_project = function()
  local request =
    spring_utils.safe_request("https://start.spring.io/metadata/client")

  if not request then
    vim.notify("Failed to make a request to the URL.", vim.log.levels.ERROR)
    return
  end

  local springboot_data = spring_utils.safe_json_decode(request.stdout)

  if not springboot_data then
    vim.notify("Failed to decode JSON from the request.", vim.log.levels.ERROR)
    return
  end

  local build_types = { "maven", "gradle" }
  local languages = handle_start_springboot_data(springboot_data.language)
  local java_versions =
    handle_start_springboot_data(springboot_data.javaVersion)
  local boot_versions =
    handle_start_springboot_data(springboot_data.bootVersion)
  local packagings = handle_start_springboot_data(springboot_data.packaging)

  vim.ui.select(
    build_types,
    { prompt = "Select build type: " },
    function(build_type)
      if build_type == nil then
        abort_input("build_type")
        return
      end
      project_info.build_type = tostring(build_type)
      vim.ui.select(
        languages,
        { prompt = "Select language: " },
        function(language)
          if language == nil then
            abort_input("language")
            return
          end
          project_info.language = tostring(language)
          vim.ui.select(
            java_versions,
            { prompt = "Select java version: " },
            function(java_version)
              if java_version == nil then
                abort_input("java_version")
                return
              end
              project_info.java_version = tostring(java_version)
              vim.ui.select(
                boot_versions,
                { prompt = "Select Spring version: " },
                function(boot_version)
                  if boot_version == nil then
                    abort_input("boot_version")
                    return
                  end
                  project_info.boot_version = tostring(boot_version)
                  vim.ui.select(
                    packagings,
                    { prompt = "Select Packaging: " },
                    function(packaging)
                      if packaging == nil then
                        abort_input("packaging")
                        return
                      end

                      vim.notify(vim.inspect(config), vim.log.levels.DEBUG)
                      --add pickers here
                      if config.picker == "vim" then
                        basic_picker.choose_spring_dependencies(
                          springboot_data,
                          { prompt = "List of possible dependencies: " },
                          nil,
                          function(dependencies)
                            choose_dependencies_callback(dependencies)
                          end
                        )
                      elseif config.picker == "snacks" then
                        snacks_picker.choose_spring_dependencies(
                          springboot_data,
                          function(dependencies)
                            choose_dependencies_callback(dependencies)
                          end
                        )
                      end
                    end
                  )
                end
              )
            end
          )
        end
      )
    end
  )
end

return M
