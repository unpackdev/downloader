//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/// @title Splitter child contract for splitting ether
/// @author The Systango Team

import "./SafeMath.sol";
import "./Killable.sol";

contract Splitter is Killable {

    // The struct of ethereum addresses and its respective share provided at the time 
    // of contract genertaion in which the funds will be spiltted.
    struct Payee {
        address payable payeeAddress;
        uint256 share;
    }

    // Payee struct array for the splitter addresses
    Payee[] public payees;

    // Lock splitter constant
    bool public lock = false;

    // The address of Factory owner address
    address payable public ownerAddress;

    // Owner share of 0.1% represented in wei pattern
    uint256 ownerShare = 1000000000000000;

    // Representation of 100% in wei pattern
    uint256 fullPercentage = 1000000000000000000;

    // Representation of 1% in wei pattern
    uint256 OnePercentage = 10000000000000000;

    // Event to trigger the receiving of ether amount.
    event ReceivedEth(address indexed fromAddress, uint256 amount);

    // Event to trigger the split of ether amount successfully.
    event SplittedEth(uint256 amount, Payee[] payees);

    using SafeMath for uint256;

    // This is the constructor of the contract. It is called at deploy time.
    
    /// @param _ownerAddress The factory owner address  
    /// @param _paused The pause status of teh child contract  
    /// @param payeeAddresses The address array of the new contract in which the funds 
    /// will be splitted.
    /// @param payeeShare The precentage array of the respective ethereum addresses
    /// provided for the funds to get splitted.

    constructor(
        address payable _ownerAddress,
        bool _paused,
        address payable[] memory payeeAddresses,
        uint256[] memory payeeShare
    ) Pausable(_paused) {
        ownerAddress = _ownerAddress;
        sanityCheck(payeeAddresses, payeeShare);
        for (uint256 i = 0; i < payeeAddresses.length; i++) {
            Payee memory payee = Payee(payeeAddresses[i], (payeeShare[i].mul(OnePercentage)));
            payees.push(payee);
        }
    }

    // This function is the intermediate function to implement a few checks over the 
    // constructor of the contract when it is called.

    /// @param payeeAddresses The address array of the new contract in which the funds 
    /// will be splitted.
    /// @param payeeShares The precentage array of the respective ethereum addresses
    /// provided for the funds to get splitted.

    function sanityCheck(
        address payable[] memory payeeAddresses,
        uint256[] memory payeeShares
    ) internal view {
        uint256 length = payeeAddresses.length;
        require(
            length == payeeShares.length,
            "Mismatch between payees and share arrays"
        );

        uint256 shareSum;
        for (uint256 i; i < payeeShares.length; i++) {
            shareSum += payeeShares[i].mul(OnePercentage);
        }
        require(shareSum <= fullPercentage, "The sum of payee share cannot exceed 100%");
    }

    // This function will be run when a transaction is sent to the contract
    // without any data and call the split method to split the fund in the percentage 
    // ratio as provided at the time of creation of the contract.

    receive() 
    external payable whenRunning whenAlive {
        require(!lock, "Splitter is currently locked");
        lock = true;

        emit ReceivedEth(msg.sender, address(this).balance);
        require(address(this).balance > 0, "Fund value 0 is not allowed");
        split(address(this).balance);

        lock = false;
    }

    // This function would split the ethers in the perccentage ratio as provided at the time 
    // of creation of the contract.

    /// @param amount The ether amount which will be splitted.

    function split(
        uint256 amount
    ) internal {
        ownerAddress.transfer(amount.mul(ownerShare).div(fullPercentage));
        uint256 balance = address(this).balance;
        for (uint256 i = 0; i < payees.length; i++) {
            address payable payee = payees[i].payeeAddress;
            payee.transfer(balance.mul(payees[i].share).div(fullPercentage)); // transfer percentage share
        }
        emit SplittedEth(amount, payees);
    }
}
