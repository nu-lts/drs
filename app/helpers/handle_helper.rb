module HandleHelper

  def make_handle(url, client = nil)
    client || client = Rails.application.config.handles_connection

    if client != nil
      handler = Proc.new do |exception, attempt_number, total_delay|
        logger.warn "Handler saw a #{exception.class}; retry attempt #{attempt_number}; #{total_delay} seconds have passed."
        client.query("ROLLBACK;")
      end

      with_retries(:max_tries => 10, :handler => handler) do
        uts                      = Time.now.to_i
        caldate                  = Date.today.strftime("%Y-%m-%d")
        handleInt                = client.query("SELECT max(right(handle,8)) + 1 FROM handles").first.first[1].to_i
        handleForDB              = "2047/D#{handleInt}"
        handleForUser            = "http://hdl.handle.net/#{handleForDB}"

        client.query("START TRANSACTION;")

        client.query("INSERT INTO handles(handle, idx, type, data, ttl_type, ttl, timestamp, admin_read, admin_write, pub_read, pub_write)values('#{handleForDB}',1,'URL','#{url}',0,86400,'#{uts}',1,1,1,0);")
        client.query("INSERT INTO handles(handle, idx, type, data, ttl_type, ttl, timestamp, admin_read, admin_write, pub_read, pub_write)values('#{handleForDB}',100,'HS_ADMIN','ADMIN 300:110011111111:0.NA/2047',0,86400,'#{uts}',1,1,0,0);")
        client.query("INSERT INTO handles(handle, idx, type, data, ttl_type, ttl, timestamp, admin_read, admin_write, pub_read, pub_write)values('#{handleForDB}',300,'HS_SECKEY','UTF8',0,86400,'#{uts}',1,1,0,0);")
        # The 22 refers to the cerberus admin user in the members table
        client.query("INSERT INTO transactions(transaction, member, handle, URL, date) values('CREATE','22','#{handleForDB}','#{url}','#{caldate}')")

        client.query("COMMIT;")

        return handleForUser
      end
    end
  end

  def handle_exists?(url, client = nil)
    client || client = Rails.application.config.handles_connection
    if client != nil
      query = "SELECT handle FROM handles WHERE type=\"URL\" and data=\"#{url}\";"
      mysql_response = client.query(query)
      if mysql_response.count == 0
        return false
      end

      return true
    end
  end

  def retrieve_handle(url, client = nil)
    client || client = Rails.application.config.handles_connection
    if client != nil
      if handle_exists?(url, client)
        query = "SELECT handle FROM handles WHERE type=\"URL\" and data=\"#{url}\";"
        mysql_response = client.query(query)
        handle = mysql_response.first["handle"]
        return "http://hdl.handle.net/#{handle}"
      else
        return nil
      end
    end
  end

end
