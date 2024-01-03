// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract WLHub {
    mapping(address => mapping(address => bool)) public isWhitelisted;

    event Whitelisted(address indexed token, address indexed user, bool status);

    function _owner(address token) internal view returns (address) {
        (bool success, bytes memory result) = token.staticcall(
            abi.encodeWithSignature("owner()")
        );
        return success ? abi.decode(result, (address)) : address(0);
    }

    function _canWhitelist(address token, address caller) internal view returns (bool) {
        (bool success, bytes memory result) = token.staticcall(
            abi.encodeWithSignature("canWhitelist(address)", caller)
        );
        return success ? abi.decode(result, (bool)) : true;
    }

    function whitelist(address token, address user, bool status) public {
        require(
            msg.sender == token || msg.sender == _owner(token),
            "WLHub: Not authorized"
        );
        require(_canWhitelist(token, msg.sender), "WLHub: Not authorized");
        isWhitelisted[token][user] = status;
        emit Whitelisted(token, user, status);
    }

    function register(address token) external {
        require(_canWhitelist(token, msg.sender), "WLHub: Not authorized");
        isWhitelisted[token][msg.sender] = true;
        emit Whitelisted(token, msg.sender, true);
    }

    function check(address user) external view returns (bool) {
        return isWhitelisted[msg.sender][user];
    }
}