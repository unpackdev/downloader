// SPDX-License-Identifier: MIT
// Smart Contract Written by: Ian Olson

pragma solidity ^0.8.4;
pragma abicoder v2;

import "./SafeMath.sol";

contract SouvenirRoyalty {
    using SafeMath for uint256;

    // ---
    // Constants
    // ---
    uint256 constant public charityBps = 1000; // 10%
    
    // ---
    // Properties
    // ---
    address private _charityPayoutAddress;
    address private _artistPayoutAddress;

    // ---
    // Mappings
    // ---
    mapping(address => bool) isAdmin;

    // ---
    // Modifiers
    // ---
    modifier onlyAdmin() {
        require(isAdmin[msg.sender], "Only admins.");
        _;
    }

    // ---
    // Constructor
    // ---

    constructor() {
        _artistPayoutAddress = address(0x711c0385795624A338E0399863dfdad4523C46b3);
        _charityPayoutAddress = address(0x1aF22Cd405C980e90E9c7dF1cE58CD3b53B3CAE1);

        isAdmin[msg.sender] = true; // imnotArt Deployer Address
        isAdmin[address(0x12b66baFc99D351f7e24874B3e52B1889641D3f3)] = true; // imnotArt Gnosis Safe
        isAdmin[_artistPayoutAddress] = true; // Brendan Fernandes Address
    }

    // ---
    // Receive and Split Payments
    // ---

    // @dev Royalty contract can receive ETH via transfer.
    // @author Ian Olson
    receive() payable external {
        if (msg.value > 0) {
            uint256 royaltyPayment = msg.value;
            uint256 charityPayout = SafeMath.div(SafeMath.mul(royaltyPayment, charityBps), 10000);

            if (charityPayout > 0) {
                royaltyPayment = royaltyPayment.sub(charityPayout);
                payable(_charityPayoutAddress).transfer(charityPayout);
            }

            payable(_artistPayoutAddress).transfer(royaltyPayment);
        }
    }

    // ---
    // Get Functions
    // ---

    // @dev Get the artist payout address.
    // @author Ian Olson
    function artistPayoutAddress() public view returns (address) {
        return _artistPayoutAddress;
    }

    // @dev Get the charity payout address.
    // @author Ian Olson
    function charityPayoutAddress() public view returns (address) {
        return _charityPayoutAddress;
    }

    // ---
    // Update Functions
    // ---

    // @dev Update the artist payout address.
    // @author Ian Olson
    function updateArtistPayoutAddress(address payoutAddress) public onlyAdmin {
        _artistPayoutAddress = payoutAddress;
    }

    // @dev Update the charity payout address.
    // @author Ian Olson
    function updateCharityPayoutAddress(address payoutAddress) public onlyAdmin {
        _charityPayoutAddress = payoutAddress;
    }

    // ---
    // Withdraw
    // ---

    // @dev Withdraw the balance of the contract.
    // @author Ian Olson
    function withdraw() public onlyAdmin {
        uint256 amount = address(this).balance;
        require(amount > 0, "Contract balance empty.");
        payable(msg.sender).transfer(amount);
    }
}