// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**************************************

    security-contact:
    - security@angelblock.io

    maintainers:
    - marcin@angelblock.io
    - piotr@angelblock.io
    - mikolaj@angelblock.io
    - sebastian@angelblock.io

    contributors:
    - domenico@angelblock.io

**************************************/

// Local imports
import "./AccessTypes.sol";
import "./LibAccessControl.sol";

/**************************************

    Fundraising admin transfer

 **************************************/

contract FundraisingAdminTransfer {

    // args
    struct Arguments {
        address receiver;

    }

    // init
    function init(Arguments calldata _args) external {

        // grant role
        LibAccessControl.grantRole(
            LibAccessControl.ADMIN_ROLE,
            _args.receiver
        );

        // revoke role
        LibAccessControl.renounceRole(
            LibAccessControl.ADMIN_ROLE,
            msg.sender
        );

    }

}
