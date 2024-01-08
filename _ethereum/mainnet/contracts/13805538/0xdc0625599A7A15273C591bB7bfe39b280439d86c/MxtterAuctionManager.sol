// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IMxtterToken.sol";
import "./IAuctionHouse.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./ERC721Holder.sol";

/**
 *  __    __     __  __     ______   ______   ______     ______
 * /\ "-./  \   /\_\_\_\   /\__  _\ /\__  _\ /\  ___\   /\  == \
 * \ \ \-./\ \  \/_/\_\/_  \/_/\ \/ \/_/\ \/ \ \  __\   \ \  __<
 *  \ \_\ \ \_\   /\_\/\_\    \ \_\    \ \_\  \ \_____\  \ \_\ \_\
 *   \/_/  \/_/   \/_/\/_/     \/_/     \/_/   \/_____/   \/_/ /_/
 *
 * @title Auction manager contract for Mxtter
 * @dev This contract mints and auctions Mxtter Tokens
 *
 *
 * MXTTER X BLOCK::BLOCK
 *
 * Smart contract work done by joshpeters.eth
 */

contract MxtterAuctionManager is Ownable, ERC721Holder {
    using Address for address;

    IMxtterToken public mxtterToken;
    IAuctionHouse public auctionHouse;

    string public preGenerativeURI;
    uint256 public duration;
    uint256 public reservePrice;
    uint256 public curAuctionId;

    event NewAuction(
        uint256 indexed tokenId,
        uint256 indexed auctionId,
        bytes32 tokenHash
    );

    event NewToken(uint256 indexed tokenId, bytes32 tokenHash);

    event TokenUriUpdated(uint256 indexed tokenId, string uri);

    event Log(string msg, uint256 indexed auctionId);

    constructor(
        address mxtterTokenAddress,
        address auctionHouseAddress,
        string memory _preGenerativeURI
    ) {
        mxtterToken = IMxtterToken(mxtterTokenAddress);
        auctionHouse = IAuctionHouse(auctionHouseAddress);
        preGenerativeURI = _preGenerativeURI;

        duration = 79200; // 22 hours
        reservePrice = 10000000000000000; // 0.01 ETH

        mxtterToken.setApprovalForAll(address(auctionHouse), true);
    }

    // @dev 1) Ends the previous auction if it hasn't been ended already
    //      2) Mints a new Mxtter Token
    //      3) Create a new zora auction with the minted token
    //      4) Creates a min bid on the auction to kick off the timer
    //      5) Updates curent auction ID
    function newAuction() external onlyOwner {
        // Will revert if auction was already ended by someone else
        try auctionHouse.endAuction(curAuctionId) {
            emit Log("ended auction", curAuctionId);
        } catch {
            emit Log("auction already ended", curAuctionId);
        }

        uint256 tokenId = mxtterToken.mintToken(
            address(this),
            preGenerativeURI
        );
        uint256 auctionId = auctionHouse.createAuction(
            tokenId,
            address(mxtterToken),
            duration,
            reservePrice,
            payable(0x0000000000000000000000000000000000000000),
            0,
            0x0000000000000000000000000000000000000000
        );
        auctionHouse.createBid{value: reservePrice}(auctionId, reservePrice);
        curAuctionId = auctionId;

        emit NewAuction(tokenId, auctionId, mxtterToken.getTokenHash(tokenId));
    }

    // @dev Mints a new Mxtter Token
    // @param to The address to mint token to
    function mintToken(address to) external onlyOwner {
        uint256 tokenId = mxtterToken.mintToken(to, preGenerativeURI);
        emit NewToken(tokenId, mxtterToken.getTokenHash(tokenId));
    }

    // @dev Updates a Mxtter Token URI
    // @param tokenId The token ID to update
    // @param uri The URI to set
    function updateTokenURI(uint256 tokenId, string memory uri)
        external
        onlyOwner
    {
        mxtterToken.setTokenURI(tokenId, uri);
        emit TokenUriUpdated(tokenId, uri);
    }

    // @dev Set a URI to use when token is created
    // @param _preGenerativeURI The new URI
    function setPreGenerativeURI(string memory _preGenerativeURI)
        external
        onlyOwner
    {
        preGenerativeURI = _preGenerativeURI;
    }

    // @dev Set a new auction duration, in seconds
    // @param _duration The new duration in seconds
    function setDuration(uint256 _duration) external onlyOwner {
        duration = _duration;
    }

    // @dev Set a new auction reserve price, in wei
    // @param _reservePrice The new reserve price in wei
    function setReservePrice(uint256 _reservePrice) external onlyOwner {
        reservePrice = _reservePrice;
    }

    // @dev Set a new zora auction house contract
    // @param auctionHouseAddress The address of the contract
    function setAuctionHouse(address auctionHouseAddress) external onlyOwner {
        auctionHouse = IAuctionHouse(auctionHouseAddress);
        mxtterToken.setApprovalForAll(address(auctionHouse), true);
    }

    // @dev Withdraw NFT as failsafe incase inital reserve bid wins
    // @param tokenId Mxtter Token ID
    function withdrawNFT(uint256 tokenId) external onlyOwner {
        mxtterToken.safeTransferFrom(address(this), msg.sender, tokenId);
    }

    // @dev Withdraw ETH from contract
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    receive() external payable {}
}
