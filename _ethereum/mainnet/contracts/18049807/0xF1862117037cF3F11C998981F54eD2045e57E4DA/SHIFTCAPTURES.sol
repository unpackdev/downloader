// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./Base64.sol";
import "./console.sol";

contract SHIFTCAPTURES is ERC1155, Ownable {
    using Counters for Counters.Counter;
    address public manager;
    string public name = "SHIFT CAPTURES";

    event TokenMinted(uint256 tokenId, address minter);

    struct CaptureCollection {
        string title;
        string employer;
        bool mintingEnabled;
        uint256 closingDate;
        uint256 royaltyPercentage;
        string place;
    }

    Counters.Counter public collectionIdTracker;
    Counters.Counter public tokenIdTracker;

    mapping(uint256 => CaptureCollection) public collections;
    mapping(uint256 => string) private _tokenURIs;
    mapping(uint256 => uint256) public tokenMintCount;
    mapping(uint256 => uint256) public tokenMinterCount;
    mapping(uint256 => mapping(address => bool)) private hasMinted;
    mapping(uint256 => address payable) public tokenRoyaltyRecipients;
    mapping(uint256 => uint256) public tokenToCollection;

    constructor() ERC1155("") {
        manager = 0x5eB336F4FfF71e31e378948Bf2B07e6BffDc7C86;
    }

    function contractURI() external pure returns (string memory) {
        string
            memory json = '{"name": "SHIFT CAPTURES","description": "Claim an off-chain proof-of-work NFT artwork capturing the labor performed live by an actual worker, signed and timestamped by SHIFT in the city the IRL performance takes place."}';
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(bytes(json))
                )
            );
    }

    modifier ownerOrMgr() {
        require(
            msg.sender == owner() || msg.sender == manager,
            "Not owner or manager"
        );
        _;
    }

    function setManager(address _manager) external ownerOrMgr {
        manager = _manager;
    }

    function createCollection(
        string memory title,
        string memory employer,
        bool mintingEnabled,
        uint256 closingDate,
        uint256 royaltyPercentage,
        string memory place
    ) external ownerOrMgr returns (uint256) {
        collectionIdTracker.increment();
        uint256 newCollectionId = collectionIdTracker.current();

        collections[newCollectionId] = CaptureCollection({
            title: title,
            employer: employer,
            mintingEnabled: mintingEnabled,
            closingDate: closingDate,
            royaltyPercentage: royaltyPercentage,
            place: place
        });

        return newCollectionId;
    }

    function createShiftNFT(
        uint256 blueprintId,
        string memory metadataURI,
        address payable royaltyRecipient
    ) external ownerOrMgr returns (uint256) {
        tokenIdTracker.increment();
        uint256 newTokenId = tokenIdTracker.current();

        _tokenURIs[newTokenId] = metadataURI;

        _mint(msg.sender, newTokenId, 1, "");

        emit TokenMinted(newTokenId, msg.sender);

        tokenToCollection[newTokenId] = blueprintId;

        tokenMintCount[newTokenId]++;

        tokenRoyaltyRecipients[newTokenId] = royaltyRecipient;

        hasMinted[newTokenId][msg.sender] = true;
        tokenMinterCount[newTokenId]++;

        return newTokenId;
    }

    function mint(address account, uint256 tokenId, uint256 amount) public {
        uint256 blueprintId = tokenToCollection[tokenId];

        require(
            collections[blueprintId].mintingEnabled,
            "Minting is not enabled for this collection."
        );
        require(
            block.timestamp * 1000 < collections[blueprintId].closingDate,
            "You're too late. Minting for this collection expired."
        );

        _mint(account, tokenId, amount, "");
        tokenMintCount[tokenId]++;

        if (!hasMinted[tokenId][account]) {
            hasMinted[tokenId][account] = true;
            tokenMinterCount[tokenId]++;
        }
        emit TokenMinted(tokenId, account);
    }

    function royaltyInfo(
        uint256 tokenId,
        uint256 salePrice
    ) external view returns (address receiver, uint256 royaltyAmount) {
        uint256 royaltyPercentage = collections[tokenId].royaltyPercentage;
        address payable recipient = tokenRoyaltyRecipients[tokenId];
        royaltyAmount = (salePrice * royaltyPercentage) / 10000;
        return (recipient, royaltyAmount);
    }

    function setTokenURI(
        uint256 tokenId,
        string memory newURI
    ) external ownerOrMgr {
        require(
            bytes(_tokenURIs[tokenId]).length > 0,
            "Token ID does not exist"
        );
        _tokenURIs[tokenId] = newURI;
    }

    function setMintingEnabled(
        uint256 collectionId,
        bool enabled
    ) external ownerOrMgr {
        require(
            collections[collectionId].mintingEnabled != enabled,
            "Already set to the provided value."
        );
        collections[collectionId].mintingEnabled = enabled;
    }

    function uri(uint256 tokenId) public view override returns (string memory) {
        return _tokenURIs[tokenId];
    }
}
