module Fino::Adapter
  def read_multi(settings)
    raise NotImplementedError
  end

  def write(setting_name, section_name, value)
    raise NotImplementedError
  end
end
