//Contract based on https://docs.openzeppelin.com/contracts/3.x/erc721
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";

struct Merch {
    uint8 id;
    string tokenURI;
    uint8 quantity;
}

contract DebutNFT is ERC721, Ownable {
    //=========== PUBLIC ===========//
    uint8 public merchCounter;
    // Item keys
    uint8[] public merchKeys;

    mapping(uint8 => uint8) public claimedTokens;

    // NFT token counter
    uint8 public tokenCounter;

    // Merch
    mapping(uint8 => Merch) public merch;

    string public couponTokenURI;

    //=========== PRIVATE ===========//

    // NFTs
    mapping(uint256 => string) private _tokenURIs;

    mapping(bytes32 => bool) private _redeemedCoupons;

    // For process some methods.
    mapping(address => bool) public delegates;

    string public contractURI;

    constructor(
        string memory name,
        string memory symbol,
        string memory contractURIInput,
        string memory couponTokenURIInput,
        uint8 mintAmount
    ) ERC721(name, symbol) {
        contractURI = contractURIInput;
        couponTokenURI = couponTokenURIInput;
        for (uint8 i = 0; i < mintAmount; i++) {
            uint8 newItemId = ++tokenCounter;
            _mint(msg.sender, newItemId);
        }
    }

    function addMerch(
        uint8 id,
        string memory _tokenURI,
        uint8 quantity
    ) public onlyOwner {
        Merch memory newMerch;
        newMerch.id = id;
        newMerch.tokenURI = _tokenURI;
        newMerch.quantity = quantity;

        merch[id] = newMerch;
        merchKeys.push(id);
        merchCounter++;
    }

    function redeemMerch(uint8 tokenId, uint8 merchId) public {
        require(
            ownerOf(tokenId) == msg.sender ||
                owner() == msg.sender ||
                delegates[msg.sender],
            "ERC721Metadata: Access denied."
        );
        require(
            merch[merchId].quantity > 0,
            "ERC721Metadata: Insufficient item."
        );
        require(
            claimedTokens[tokenId] == 0,
            "ERC721Metadata: This token already claimed."
        );
        _tokenURIs[tokenId] = merch[merchId].tokenURI;
        claimedTokens[tokenId] = merchId;
        merch[merchId].quantity--;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI set of nonexistent token"
        );
        if(bytes(_tokenURIs[_tokenId]).length > 0) {
            return _tokenURIs[_tokenId];
        }
        return couponTokenURI;
    }

    function setDelegate(address delegate, bool on) public onlyOwner {
        delegates[delegate] = on;
    }

    function redeemToken(address targetAddress, uint256 tokenId)
        public
    {
        require(
                owner() == msg.sender ||
                delegates[msg.sender],
                "ERC721Metadata: Access denied."
        );
        require(tokenId != 0, "ERC721Metadata: Invalid token id");
        require(
            owner() == ownerOf(tokenId),
            "ERC721Metadata: This coupon code is alredy redeemed."
        );

        _transfer(ownerOf(tokenId), targetAddress, tokenId);
    }
}
