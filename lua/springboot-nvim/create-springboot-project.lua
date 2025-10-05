local table_utils = require("springboot-nvim.table-utils")
local spring_utils = require("springboot-nvim.utils")
local M = {}

--TODO: Add support for picker (snacks in my instance)
--TODO: Try changing fn.input to vim.ui.select
--TODO: Snacks picker supports multi-select but others dont, for others have it loop over the table removing objects as they are selected and confirm table when 'Done' option is submitted

---Adds data to a table handling springboot project data. This function is only for decoding the spring web request!!!
---@param data table The table that is the result of decoding the spring web request.
---@return table spring_data A table containing data holding the ids of spring project values
local handle_start_springboot_data = function(data)
  local spring_data = {}
  for _, value in pairs(data.values) do
    table.insert(spring_data, value.id)
  end
  return spring_data
end

--TODO: when using vim.ui.select, the user picks from provided input instead of providing their own, making the nil return possibly obselete
---Asks the user for the build type
---@param data_available table<string> Table containing available values
---@return string|nil build_type The build type or nil if no valid option is given
M.get_build_type = function(data_available)
  local build_type_available = table_utils.list_to_string(data_available, false)
  local options_err = table_utils.list_to_string(data_available, true)
  local build_type =
    vim.fn.input("Enter build type (" .. build_type_available .. "): ", "maven")
  if not table_utils.contains(data_available, build_type) then
    print("Invalid build type. Please enter " .. options_err .. ".")
    return nil
  end

  return build_type
end

---Asks the user which language package to use
---@param data_available table<string> the options from which the user can pick from
---@return string|nil The language package or nil if no valid option is provided
M.get_language = function(data_available)
  local language_available = table_utils.list_to_string(data_available, false)
  local options_err = table_utils.list_to_string(data_available, true)

  local language =
    vim.fn.input("Enter Language (" .. language_available .. "): ", "java")
  if not table_utils.contains(data_available, language) then
    print("Invalid language. Please enter " .. options_err .. ".")
    return nil
  end

  return language
end

---Asks the user for the java version
---@param data_available table<string> Table containing the version options for java
---@return string|nil Version The selected java version or nil if no valid version is given
M.get_java_version = function(data_available)
  local version_available = table_utils.list_to_string(data_available, false)
  local options_err = table_utils.list_to_string(data_available, true)

  local java_version =
    vim.fn.input("Enter Java Version (" .. version_available .. "): ", "21")
  if not table_utils.contains(data_available, java_version) then
    print(
      "Invalid Java version. Please enter a valid version "
        .. options_err
        .. "."
    )
    return nil
  end

  return java_version
end

---Asks the user for the spring boot version
---@param data_available table<string> The versions the user can pick from
---@return string|nil boot_version string of the selected version or nil if not valid version is given
M.get_boot_version = function(data_available)
  local version_available = table_utils.list_to_string(data_available, false)
  local options_err = table_utils.list_to_string(data_available, true)

  local boot_version = vim.fn.input(
    "Enter Spring Boot Version (" .. version_available .. "): ",
    data_available[#data_available]
  )
  if not table_utils.contains(data_available, boot_version) then
    print(
      "Invalid Spring Boot version. Please enter a valid version "
        .. options_err
        .. "."
    )
    return nil
  end

  return boot_version
end

---Asks the user which form of packaging to use
---@param data_available table<string> The options the user can pick from
---@return string|nil packaging string of selected packaging or nil if no valid option is given
M.get_packaging = function(data_available)
  local packaging_available = table_utils.list_to_string(data_available, false)
  local options_err = table_utils.list_to_string(data_available, true)

  local packaging =
    vim.fn.input("Enter Packaging(" .. packaging_available .. "): ", "jar")
  if packaging ~= "jar" and packaging ~= "war" then
    print("Invalid packaging. Please enter " .. options_err .. ".")
    return nil
  end
  return packaging
end

--TODO: loop over a list of dependencies using vim.ui.select
--TODO: reconstruct the output from that into a valid string (comma separated,no spaces)

---Request the dependencies based on id, not the name
---@return string dependencies A comma separated string listing the dependencies
M.get_dependencies = function()
  local dependencies = vim.fn.input(
    "Enter dependencies (comma separated): ",
    "devtools,web,data-jpa,h2,thymeleaf"
  )
  return dependencies
end

---Asks the user for a group id
---@return string group_id
M.get_group_id = function()
  local group_id = vim.fn.input("Enter Group ID: ", "com.example")
  return group_id
end

---Asks the user for an artifact id
---@return string artifact_id
M.get_artifact_id = function()
  local artifact_id = vim.fn.input("Enter Artifact ID: ", "myproject")
  return artifact_id
end

---Asks the user for a project name
---@param artifact_id string The artifact id
---@return string project_name
M.get_project_name = function(artifact_id)
  local project_name = vim.fn.input("Enter project name: ", artifact_id)
  return project_name
end

---Asks the user for a package Name
---@param group_id string The group id
---@param artifact_id string The artifact id
---@return string Package_name
M.get_package_name = function(group_id, artifact_id)
  local package_name =
    vim.fn.input("Enter package name: ", group_id .. "." .. artifact_id)
  return package_name
end

---The main method for starting a new springboot project
M.springboot_new_project = function()
  local request =
    spring_utils.safe_request("https://start.spring.io/metadata/client")

  if not request then
    vim.notify("Failed to make a request to the URL.", vim.log.levels.ERROR)
    return false
  end

  local springboot_data = spring_utils.safe_json_decode(request.stdout)

  if not springboot_data then
    vim.notify("Failed to decode JSON from the request.", vim.log.levels.ERROR)
    return false
  end
  local build_types = { "maven", "gradle" }
  local languages = handle_start_springboot_data(springboot_data.language)
  local java_versions =
    handle_start_springboot_data(springboot_data.javaVersion)
  local boot_versions =
    handle_start_springboot_data(springboot_data.bootVersion)
  local packagings = handle_start_springboot_data(springboot_data.packaging)

  --TODO: needs checking which would mean decoding the dependencies section from the spring web request (dependencies{values[{values[{id, name}]}]})
  local dependencies = M.get_dependencies()

  local build_type = M.get_build_type(build_types)
  if not build_type then
    return
  end

  local language = M.get_language(languages)
  if not language then
    return
  end

  local java_version = M.get_java_version(java_versions)
  if not java_version then
    return
  end

  local boot_version = M.get_boot_version(boot_versions)
  if not boot_version then
    return
  end

  local packaging = M.get_packaging(packagings)
  if not packaging then
    return
  end

  local group_id = M.get_group_id()
  local artifact_id = M.get_artifact_id()
  local name = M.get_project_name(artifact_id)
  local package_name = M.get_package_name(group_id, artifact_id)

  local command = string.format(
    "spring init --boot-version=%s --java-version=%s --build=%s --dependencies=%s --groupId=%s --artifactId=%s --name=%s --package-name=%s %s",
    boot_version,
    java_version,
    build_type,
    dependencies,
    group_id,
    artifact_id,
    name,
    package_name,
    name
  )

  local output = vim.fn.system(command)
  if vim.v.shell_error ~= 0 then
    print("Erro ao executar: " .. output)
  else
    print(output)
    vim.fn.chdir(name)
    local pathJava = vim.fn.system("fd -I java src/main/java")

    vim.cmd("e " .. pathJava)
    if spring_utils.is_nvim_tree_available() then
      vim.cmd("NvimTreeFindFileToggle")
    end
  end

  print("Project created successfully!")
end

vim.api.nvim_create_user_command(
  "SpringBootNewProject",
  M.springboot_new_project,
  {}
)

return M
