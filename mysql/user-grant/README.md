# user-grant

## Usage
```hcl
module user1_localhost {
  source = "github.com/ridi/terraform-modules//mysql/user-grant"

  user     = "user1@localhost"
  password = "user1secret"
  
  grants = {
    database_a = {
      "*" = ["SELECT"]
    },
    database_b = {
      tb_foo = ["SELECT", "INSERT", "UPDATE", "DELETE"]
      tb_bar = ["SELECT", "INSERT", "UPDATE", "DELETE"]
    }
  }
}

module user1_remote {
  source = "github.com/ridi/terraform-modules//mysql/user-grant"
  
  user     = "user1@10.0.%"
  password = "user1secret"
  
  grants = {
    database_a = {
      "*" = ["SELECT"]
    },
    database_b = {
      tb_foo = ["SELECT"]
      tb_bar = ["SELECT"]
    }
  }
}
```
## Input Variables
- `user`: The MySQL account in form of MYSQL_ID@HOST. if no '@' character exists, the host is 'losthost'
- `password`: The password of the account
- `grants`: The grants map for each databases and tables
