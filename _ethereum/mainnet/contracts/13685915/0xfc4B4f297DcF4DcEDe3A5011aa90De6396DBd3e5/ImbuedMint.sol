//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;

import "./Ownable.sol";

import "./ImbuedNFT.sol";

/** @title Imbued Minter v1
    Controls the ImbuedNFT contract and allows users to mint new weaves, and the
    owner to mint a major weave, that is sent to the auction contract.
 */
contract ImbuedMint is Ownable {

    ImbuedNFT immutable public nftContract;

    address public auctionContract;
    
    uint256 constant public NUM_EDITIONS = 7;
    uint256 constant public EDITION_SIZE = 100;

    uint256 public mintPrice = 0.1 ether;

    bool[] public minorMintOngoing = new bool[](NUM_EDITIONS);
    uint8[] public nextMinorId = new uint8[](NUM_EDITIONS);
    uint8[] public maxMinorId = new uint8[](NUM_EDITIONS);


    constructor(address _nftContract) {
        nftContract = ImbuedNFT(_nftContract);
    }

    // External user functions.

    // NFT functions.

    function mintMinor(uint256 edition) external payable {
        mintMinor(edition, 1);
    }

    function mintMinor(uint256 edition, uint256 amount) public payable {
        require(minorMintOngoing[edition], "Mint is not active");
        require(msg.value == mintPrice * amount, "Wrong price");
        require(nextMinorId[edition] - 1 + amount <= maxMinorId[edition]
            , "That amount is too large to mint, or all tokens have been minted");
        for (uint256 i = 0; i < amount; i++) {
            uint256 tokenId = edition * EDITION_SIZE + nextMinorId[edition];
            nextMinorId[edition] += 1;
            // _safeMint allows reentrancy, so we put this last.
            nftContract.mint(msg.sender, tokenId);
        }
    }

    // Only owner functions.

    /** There is room for 7 major editions, 0..6.
    The contract starts on edition 0.
     */
    function startNewEdition(uint256 edition, uint8 newMaxMinorId) external onlyOwner() {
        require(edition < NUM_EDITIONS, "That edition number is too high");
        require(nextMinorId[edition] == 0, "Edition has already been started");
        require(newMaxMinorId < EDITION_SIZE, "New max minor ID too high");
        nextMinorId[edition] = 1;
        minorMintOngoing[edition] = true;
        maxMinorId[edition] = newMaxMinorId;
    }

    function setMaxMinorId(uint256 edition, uint8 newMaxMinorId) public onlyOwner() {
        require(newMaxMinorId < EDITION_SIZE, "New max minor ID too high");
        maxMinorId[edition] = newMaxMinorId;
    }

    function mintMajor(uint256 edition) external onlyOwner() {
        minorMintOngoing[edition] = false;
        require(auctionContract != address(0), "Set the auction contract first");
        nftContract.mint(address(auctionContract), edition * EDITION_SIZE);
    }

    function setMintPrice(uint256 newPrice) external onlyOwner() {
        mintPrice = newPrice;
    }

    function setAuctionContract(address _auctionContract) external onlyOwner() {
        auctionContract = _auctionContract;
    }

    function withdraw(uint256 amount, address payable recipient) public onlyOwner() {
       recipient.call{value: amount}("");
    }

    // Currently unsafe, can withdraw even unclaimed bids.
    function withdrawAll(address payable recipient) external onlyOwner() {
        withdraw(address(this).balance, recipient);
    }
}