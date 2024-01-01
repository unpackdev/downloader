// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IAny2EVMMessageReceiver.sol";
import "./Client.sol";
import "./IERC165.sol";

abstract contract CCIPReceiver is IAny2EVMMessageReceiver, IERC165 {
    address i_router;

    constructor(address router) {
        if (router == address(0)) revert InvalidRouter(address(0));
        i_router = router;
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public pure override returns (bool) {
        return
            interfaceId == type(IAny2EVMMessageReceiver).interfaceId ||
            interfaceId == type(IERC165).interfaceId;
    }

    function ccipReceive(
        Client.Any2EVMMessage calldata message
    ) external virtual override onlyRouter {
        _ccipReceive(message);
    }

    function _ccipReceive(
        Client.Any2EVMMessage memory message
    ) internal virtual;

    function getRouter() public view returns (address) {
        return address(i_router);
    }

    error InvalidRouter(address router);

    modifier onlyRouter() {
        if (msg.sender != address(i_router)) revert InvalidRouter(msg.sender);
        _;
    }
}
