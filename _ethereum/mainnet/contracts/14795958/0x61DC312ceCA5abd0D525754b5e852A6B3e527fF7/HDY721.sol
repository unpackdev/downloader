// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./IERC721Enumerable.sol";
import "./Ownable.sol";
import "./ECDSA.sol";

contract HDY721 is ERC721URIStorage, Ownable {

    //this mapping is necessary to save the important data like
    //collections name, and the price of NFT
    mapping(uint256 => string) public collectionsName;
    mapping (uint256 => uint256) priceNFT;
    address public marketAddress;

    //the platform will be used to sign the message signature
    address public platformAddress;
    event Minted(
        address owner,
        uint256 tokenId,
        string CollectionName,
        string tokenURI
    );
    event PlatformUpdated(
        address newPlatformAddress,
        uint256 timestamp
    );
    struct Sig {
        bytes32 r;
        bytes32 s;
        uint8 v;
    }

    constructor() ERC721("Hiroshima Dragonfly", "HDY") {}

    function mint(
        address callerAddress,
        uint256 tokenId,
        string memory _collectionName,
        string memory tokenURI,
        Sig memory MintRSV
    ) public {
        require(!(_exists(tokenId)), "Token ID already minted!");
        require(_msgSender() == marketAddress, "The caller must be marketplace contract!");
        //this will check is the one who sign the message really from platform or not.
        require(
            verifySigner(
                platformAddress,
                messageHash(abi.encodePacked(callerAddress, tokenId)),
                MintRSV
            ),
            "Mint Signature Invalid"
        );
        _mint(callerAddress, tokenId);
        _setTokenURI(tokenId, tokenURI);
        collectionsName[tokenId] = _collectionName;

        emit Minted(callerAddress, tokenId, _collectionName, tokenURI);
    }
    
    function setPriceNFT(address callerAdress, uint256 tokenID, uint256 price) public {
        require(_exists(tokenID), "Token ID Doesn't exist!");
        require(_msgSender() == marketAddress, "The caller must be marketplace contract!");
        require(callerAdress == ownerOf(tokenID), "You're not the owner of this nft.");
        priceNFT[tokenID] = price;
    }
    
    function getPriceNFT(uint256 tokenID) public view returns (uint256) {
        return priceNFT[tokenID];
    }

    function setMarketAddress(address _marketAddress) public onlyOwner {
        require(_marketAddress != address(0), "Address must not be zero!");
        marketAddress = _marketAddress;
    }

    function updatePlatform(address newAddress) public onlyOwner {
        require(newAddress != address(0), "Address must not be zero!");
        platformAddress = newAddress;
        emit PlatformUpdated(newAddress, block.timestamp);
    }

    function messageHash(bytes memory abiEncode)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    keccak256(abiEncode)
                )
            );
    }

    function verifySigner(
        address signer,
        bytes32 ethSignedMessageHash,
        Sig memory rsv
    ) internal pure returns (bool) {
        return
            ECDSA.recover(ethSignedMessageHash, rsv.v, rsv.r, rsv.s) == signer;
    }
}
