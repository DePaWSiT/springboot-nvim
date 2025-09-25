local table_utils = require("springboot-nvim.table_utils")
local spring_utils = require("springboot-nvim.utils")
local M = {}

---Adds data to a table handling springboot project data. This function is only for decoding the spring web request!!!
---@param data table The table that is the result of decoding the spring web request.
---@return table spring_data A table containing data holding the ids of spring project values
M.handle_start_springboot_data = function(data)
  local spring_data = {}
  for _, value in pairs(data.values) do
    table.insert(spring_data, value.id)
  end
  return spring_data
end

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

---Request the dependencies based on id, not the name
---@return string dependencies A comma separated string listing the dependencies
M.get_dependencies = function()
  local dependencies = vim.fn.input(
    "Enter dependencies (comma separated): ",
    "devtools,web,data-jpa,h2,thymeleaf"
  )
  return dependencies
end

M.get_group_id = function()
  local group_id = vim.fn.input("Enter Group ID: ", "com.example")
  return group_id
end

M.get_artifact_id = function()
  local artifact_id = vim.fn.input("Enter Artifact ID: ", "myproject")
  return artifact_id
end

M.get_project_name = function(artifact_id)
  local project_name = vim.fn.input("Enter project name: ", artifact_id)
  return project_name
end

M.get_package_name = function(group_id, artifact_id)
  local package_name =
    vim.fn.input("Enter package name: ", group_id .. "." .. artifact_id)
  return package_name
end

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
  local languages = M.handle_start_springboot_data(springboot_data.language)
  local java_versions =
    M.handle_start_springboot_data(springboot_data.javaVersion)
  local boot_versions =
    M.handle_start_springboot_data(springboot_data.bootVersion)
  local packagings = M.handle_start_springboot_data(springboot_data.packaging)

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
