// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./IELFee.sol";
import "./IVault.sol";
import "./ReentrancyGuard.sol";

contract ELFee is IELFee, ReentrancyGuard {
    uint public elFee;
    uint public claimedUserAmount;
    address public withdrawalAddr;
    address public vaultAddr;

    constructor(uint _elFee, address _withdrawalAddr) {
        elFee = _elFee;
        withdrawalAddr = _withdrawalAddr;
        vaultAddr = msg.sender;
    }

    function splitFee() external nonReentrant {
        require(address(this).balance > 0, "no balance");
        uint protocolAmount = (address(this).balance * elFee) / 10000;
        uint userAmount = address(this).balance - protocolAmount;
        IVault(vaultAddr).onSplitFee{value: protocolAmount}();
        payable(withdrawalAddr).transfer(userAmount);

        claimedUserAmount += userAmount;
        emit SplitFee(protocolAmount, userAmount);
    }

    function setELFee(uint _elFee) external {
        require(msg.sender == vaultAddr, "invalid caller");
        elFee = _elFee;
    }
}
