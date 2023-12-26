// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./Ownable.sol";

contract OperatorFilterV1 is Ownable {
    event OperationModeUpdate(bool indexed isBlacklist);
    event BlacklistUpdate(address indexed operator, bool indexed isBlacklisted);
    event WhitelistUpdate(address indexed operator, bool indexed isWhitelisted);

    struct OperatorBlacklistData {
        address operator;
        bool isBlacklisted;
    }

    struct OperatorWhitelistData {
        address operator;
        bool isWhitelisted;
    }

    // This value here toggles the operation mode between Whitelist and Blacklist.
    bool public isBlacklistMode = true;

    // A "true" value in this map means the corresponding operator should be blocked.
    mapping(address => bool) public isBlacklisted;

    // A "true" value in this map means the corresponding operator should be allowed.
    mapping(address => bool) public isWhitelisted;

    function isWhitelistMode() public view returns (bool) {
        return !isBlacklistMode;
    }

    function updateMode(bool _isBlacklist) public onlyOwner {
        isBlacklistMode = _isBlacklist;

        emit OperationModeUpdate(_isBlacklist);
    }

    function updateBlacklist(OperatorBlacklistData[] memory _operatorData) public onlyOwner {
        uint256 i = 0;
        for (;;) {
            isBlacklisted[_operatorData[i].operator] = _operatorData[i].isBlacklisted;

            emit BlacklistUpdate(_operatorData[i].operator, _operatorData[i].isBlacklisted);

            if (_operatorData.length == ++i) break;
        }
    }

    function updateWhitelist(OperatorWhitelistData[] memory _operatorData) public onlyOwner {
        uint256 i = 0;
        for (;;) {
            isWhitelisted[_operatorData[i].operator] = _operatorData[i].isWhitelisted;

            emit WhitelistUpdate(_operatorData[i].operator, _operatorData[i].isWhitelisted);

            if (_operatorData.length == ++i) break;
        }
    }

    function isDenied(address _operator) external view returns (bool) {
        if (isBlacklistMode) {
            return isBlacklisted[_operator];
        }

        return !isWhitelisted[_operator];
    }
}
