// SPDX-License-Identifier: GPL-3.0

/// @title SharkDAO Bidding Management Contract

/***********************************************************
------------------------░░░░░░░░----------------------------
--------------------------░░░░░░░░░░------------------------
----------------------------░░░░░░░░░░----------------------
----░░----------------------░░░░░░░░░░░░--------------------
------░░----------------░░░░░░░░░░░░░░░░░░░░░░--------------
------░░░░----------░░░░░░░░░░░░░░░░░░░░░░░░░░░░------------
------░░░░░░----░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░----------
--------░░░░░░--░░░███████████░░███████████░░░░░░░░░--------
--------░░░░░░░░░░░██    █████░░██    █████░░░░░░░░░░░------
----------░░█████████    █████████    █████░░░░░░░░░░░------
----------░░██░░░░░██    █████░░██    █████░░░░░░░░░--------
--------░░░░░░--░░░███████████░░███████████░░░░░░░----------
--------░░░░----░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░----------
--------░░------░░░░░░░░░░░░░░░░░░░░  ░░  ░░  ░░------------
------░░--------░░░░░░░░░░░░░░░░░░  ░░  ░░  ░░░░------------
----------------░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░--------------
----------------░░░░░░████░░░░░██░░░░░██░░░░----------------
----------------░░░░--██░░██░██░░██░██░░██░░----------------
----------------░░░░--██░░██░██████░██░░██░░----------------
----------------░░░░--████░░░██░░██░░░██░░░░----------------
----------------░░░░--░░░░░░░░░░░░░░░░░░░░░░----------------
************************************************************/

pragma solidity ^0.8.6;

import "./INounsAuctionHouse.sol";
import "./IERC721.sol";
import "./Ownable.sol";


contract SharkDaoBidder is Ownable {
    event AddedBidder(address indexed bidder);
    event RemovedBidder(address indexed bidder);

    mapping(address => bool) public daoBidders;
    INounsAuctionHouse public auctionHouse;
    IERC721 public nouns;

    // Equivalent to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    bytes4 internal constant ONERC721RECEIVED_FUNCTION_SIGNATURE = 0x150b7a02;

    constructor(address _nounsAuctionHouseAddress, address _nounsTokenAddress) {
        auctionHouse = INounsAuctionHouse(_nounsAuctionHouseAddress);
        nouns = IERC721(_nounsTokenAddress);
    }


    /**
        Modifier for Ensuring DAO Member Transactions
     */
    modifier onlyDaoBidder() {
        require(msg.sender == owner() || daoBidders[msg.sender], "Only usable by Owner or authorized DAO members");
        _;
    }

    modifier pullAssetsFirst() {
        require(address(this).balance == 0, "Pull funds before changing ownership");
        require(nouns.balanceOf(address(this)) == 0, "Pull nouns before changing ownership");
        _;
    }


    /**
        Owner-only Privileged Methods for Contract & Access Expansion
     */
    function transferOwnership(address _newOwner) public override onlyOwner pullAssetsFirst {
        super.transferOwnership(_newOwner);
    }

    function renounceOwnership() public override onlyOwner pullAssetsFirst {
        super.renounceOwnership();
    }


    function addDaoBidder(address _bidder) public onlyOwner {
        daoBidders[_bidder] = true;
        emit AddedBidder(_bidder);
    }


    /**
        Authorized Bidder Functions for Bidding, Pulling Funds & Access
     */
    function addFunds() external payable {} // Convenience function for Etherscan, etc.

    function pullFunds() external onlyDaoBidder {
        address ownerAddress = payable(owner()); // Funds MUST go to Owner
        (bool sent, ) = ownerAddress.call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");
    }

    function pullNoun(uint256 _nounId) external onlyDaoBidder {
        nouns.safeTransferFrom(address(this), owner(), _nounId); // Nouns MUST go to Owner
    }

    function removeDaoBidder(address _bidder) public onlyDaoBidder {
        delete daoBidders[_bidder];
        emit RemovedBidder(_bidder);
    }

    function submitBid(uint256 _nounId, uint256 _proposedBid) public onlyDaoBidder {
        // Bids can be submitted by ANYONE in the DAO
        require(_proposedBid <= address(this).balance, "Proposed bid is above available contract funds");
        auctionHouse.createBid{value: _proposedBid}(_nounId);
    }


    /**
        ETH & Nouns ERC-721 Receiving and Sending
     */
    receive() external payable {} // Receive Ether w/o msg.data
    fallback() external payable {} // Receive Ether w/ msg.data

    function onERC721Received(address, address, uint256, bytes memory) pure external returns (bytes4) {
        return ONERC721RECEIVED_FUNCTION_SIGNATURE; // Required per EIP-721
    }
}
