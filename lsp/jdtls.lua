return {
  cmd = (function()
    local lombok = vim.env.LOMBOK_JAR
    if lombok and lombok ~= "" and vim.fn.filereadable(lombok) == 1 then
      return { "jdtls", string.format("--jvm-arg=-javaagent:%s", lombok) }
    end
    return { "jdtls" }
  end)(),
}
