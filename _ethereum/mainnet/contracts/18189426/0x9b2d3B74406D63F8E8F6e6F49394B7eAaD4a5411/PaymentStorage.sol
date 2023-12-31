// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import "./Structs.sol";

library PaymentStorage {

    bytes32 internal constant STORAGE_SLOT = keccak256('contracts.storage.Payment');

    struct Layout {
        address template;
        uint baseFee;
        mapping(address => bool) registeredToken;
        mapping(address => uint) protocolIncome;
        mapping(address => Account) userAccounts;
        mapping(bytes32 => Service) subscription;

        uint[60] _gaps;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    function calculateServiceFee(address _user, uint _amount) internal view returns (uint) {
        Layout storage data = layout();
        uint baseFee = data.baseFee;
        if (baseFee == 0) return 0;
        unchecked {
            uint discount = data.userAccounts[_user].feeDiscount;

            if (discount == 0) {
                return _amount * baseFee / 100_000;
            }

            return _amount * baseFee * discount / 10_000_000;
        }
    }
}