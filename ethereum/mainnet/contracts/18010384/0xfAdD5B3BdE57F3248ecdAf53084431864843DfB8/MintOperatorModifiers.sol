// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./OwnableStorage.sol";
import "./AccessControlStorage.sol";
import "./ConfigLib.sol";
import "./EnumerableSet.sol";

abstract contract MintOperatorModifiers {
    using EnumerableSet for EnumerableSet.AddressSet;
    error NotOwnerOrMintOperator(address);

    function _isOwnerOrMintOperator() internal view returns (bool) {
        bytes32 role = ConstantsLib.KEEPERS_MINT_OPERATOR;
        bool isOwner = OwnableStorage.layout().owner == msg.sender;
        bool hasMintOperatorRole = AccessControlStorage.layout().roles[role].members.contains(msg.sender);

        return isOwner || hasMintOperatorRole;
    }

    modifier onlyOwnerOrMintOperator() {
        if (!_isOwnerOrMintOperator()) {
            revert NotOwnerOrMintOperator(msg.sender);
        }
        _;
    }
}
