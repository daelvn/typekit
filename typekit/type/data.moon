-- typekit.type.data
-- Datatypes for typekit
-- By daelvn
import DEBUG        from  require "typekit.config"
import inspect, log from (require "typekit.debug") DEBUG
import typeError    from  require "typekit.type.error"
import metatype     from  require "typekit.commons"

-- Maybe = Data "Maybe a",
--   Just:    "a"
--   Nothing: ""

{}