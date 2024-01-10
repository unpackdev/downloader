// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;
pragma experimental ABIEncoderV2;

contract Variables {
    struct Data {
        address _user;
    }

    string public _connectorName;
    string public _actionId;
    address public _dsaAddress;
    uint256 public _dsaId;
}
