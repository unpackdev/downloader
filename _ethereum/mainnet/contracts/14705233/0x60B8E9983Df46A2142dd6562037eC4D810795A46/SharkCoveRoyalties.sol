// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./PaymentSplitterMod.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";


contract SharkCoveRoyalties is Ownable, PaymentSplitterMod, ReentrancyGuard {
    constructor () {
        addPayee(0x5f021171446E26FF23f907724E5B7f5d5Cb3C46F, 286);
        addPayee(0x54EA59B0493E5C914eb9F25D992FE95740c701C4, 237);
        addPayee(0x3fc07298a14fE9d8D74a17Ef4d9B4237f996eE6C, 200);
        addPayee(0xFF60F3a6eE2D7D2047EfaABA780E6a938DCa8f58, 128);
        addPayee(0xF7205A618d4347cd964d23FFcD89971Ea4BE3D9b, 93);
        addPayee(0x484749B9d349B3053DfE23BAD67137821D128433, 47);
        addPayee(0x6E6E7ecD39193FDFCa1384Fb063270C714591BE7, 9);
    }

    function releaseAll () public nonReentrant {
        for (uint256 i = 0; i < _payees.length; i++) {
            release(payable(_payees[i]));
        }
    }

    function addPayee(address account, uint256 shares_) public onlyOwner {
        _addPayee( account, shares_ );
    }

    function resetCounters() external onlyOwner {
        _resetCounters();
    }

    function setPayee( uint index, address account, uint newShares ) external onlyOwner {
        _setPayee(index, account, newShares);
    }
}
