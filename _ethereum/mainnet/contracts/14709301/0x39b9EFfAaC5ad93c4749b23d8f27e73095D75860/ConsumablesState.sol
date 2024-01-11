// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Initializable.sol";
import "./ERC1155OnChainBaseUpgradeable.sol";
import "./AdminableUpgradeable.sol";
import "./Base64ableUpgradeable.sol";

abstract contract ConsumablesState is Initializable, AdminableUpgradeable, Base64ableUpgradeable, ERC1155OnChainBaseUpgradeable {

    struct TypeInfo {
        uint256 mints;
        uint256 burns;
        uint256 maxSupply;
    }

    mapping(uint256 => TypeInfo) public typeInfo;

    function __ConsumablesState_init() internal initializer {
        AdminableUpgradeable.__Adminable_init();
        Base64ableUpgradeable.__Base64able_init();
    }
}