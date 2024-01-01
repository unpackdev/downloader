// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;
import "./Ownable.sol";


contract ParallelAlternateWalletAssigner is Ownable{

    mapping(address => mapping(uint=>address)) public contractWalletToAssignedWallet;
    uint256 public currentDropId = 701;

    event Selected(address manifestWallet, address selectedWallet, uint _dropId);

    /// @notice Assign your wallet's manifest entry to a different wallet
    /// @param selectedWallet the address you'd like to assign to (can't be a contract, can't be yourself)
    function selectWallet(address selectedWallet) external {
        require(msg.sender != selectedWallet, "can't assign to self");

        uint size;
        assembly { size := extcodesize(selectedWallet) }
        require(size == 0, "can't assign to a contract");

        contractWalletToAssignedWallet[msg.sender][currentDropId] = selectedWallet;
        emit Selected(msg.sender, selectedWallet, currentDropId);
    }

    function setcurrentDropId(uint _dropId) external onlyOwner {
        currentDropId = _dropId;
    }

}
