{ lib, ... }: {
  options.myProfile = {
    username = lib.mkOption {
      type = lib.types.str;
      description = "The system username";
    };
    fullName = lib.mkOption {
      type = lib.types.str;
      description = "The user's full name";
    };
    email = lib.mkOption {
      type = lib.types.str;
      description = "The user's primary email address";
    };
    timezone = lib.mkOption {
      type = lib.types.str;
      description = "The system timezone";
    };
  };
}
