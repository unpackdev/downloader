// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./SafeMath.sol";

contract AlphaCheetahClub is ERC721, Ownable {
    using Strings for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    uint256 public constant CHEETAH_PRICE = 0.05 ether;

    uint public constant MAX_CHEETAH_PURCHASE = 20;

    uint256 public constant MAX_SUPPLY = 7100;

    uint256 public CHEETAH_RESERVE = 71; // Reserve 1% Cheetahs for team & community (Used in giveaways, events etc...)

    uint256 public constant SALE_START_DATE = 1662026400;

    bool public saleIsActive = true;

    uint private constant MAX_MINTS_PER_ADDRESS_SALE = 10;

    string public baseTokenURI;
    string public notRevealedUri;
    string private baseExtension = ".json";

    address[] public whitelistedAddresses;

    bool public onlyWhitelisted = false;

    bool public revealed = false;

    mapping(address => uint) public mintedTokensByAddress;

    constructor(string memory _initBaseURI, string memory _initNotRevealedUri) ERC721("AlphaCheetahClub", "ACC") {
        baseTokenURI = _initBaseURI;
        setNotRevealedURI(_initNotRevealedUri);
    }

    function isSaleOpen() public view returns(bool) {
        if (block.timestamp >= SALE_START_DATE && saleIsActive) { 
            return true;
        }
        else {
            return false;
        }
    }

    function isWhitelisted(address _user) public view returns (bool) {
        for (uint i = 0; i < whitelistedAddresses.length; i++) {
            if (whitelistedAddresses[i] == _user) {
                return true;
            }
        }
        return false;
    }

    function withdraw() public payable onlyOwner {
        uint balance = address(this).balance;
        require(balance > 0, "No ether left to withdraw");

        (bool success, ) = (msg.sender).call{value: balance}("");
        require(success, "Transfer failed.");
    }

    function reserveCheetahs(address receiver, uint amount) public onlyOwner {
        require(amount > 0 && amount <= CHEETAH_RESERVE, "Not enough Chetaahs left to reserve");
        for (uint256 i = 0; i < amount; i++) {
            safeMint(receiver);
        }
        CHEETAH_RESERVE = CHEETAH_RESERVE - amount;
    }

    function mintCheetah(uint256 numberOfTokens) public payable {
        require(isSaleOpen(), "Sale must be active to mint Cheetah");
        require(numberOfTokens <= MAX_CHEETAH_PURCHASE, "Can only mint 20 tokens at a time");
        require(totalSupply() + numberOfTokens <= mintableSupply(), "Max Supply reached");
        require(mintedTokensByAddress[msg.sender] + numberOfTokens <= MAX_MINTS_PER_ADDRESS_SALE, "max NFT per address exceeded");
        require(msg.value >= CHEETAH_PRICE * numberOfTokens, "Ether value sent is not correct");

        if (msg.sender != owner()) {
            if(onlyWhitelisted == true) {
                require(isWhitelisted(msg.sender), "User is not whitelisted");
            }
        }
        
        for(uint256 i = 0; i < numberOfTokens; i++) {
            if (totalSupply() < MAX_SUPPLY) {
                safeMint(msg.sender);
                mintedTokensByAddress[msg.sender]++;
            }
        }
    }

    function safeMint(address to) private {
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        _safeMint(to, tokenId);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
    
        if(revealed == false) {
            return notRevealedUri;
        }

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
            : "";
    }

    function walletOfOwner(address _owner) external view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = 1;
        uint256 ownedTokenIndex = 0;
        while (ownedTokenIndex < ownerTokenCount && currentTokenId <= MAX_SUPPLY) {
            address currentTokenOwner = ownerOf(currentTokenId);
            if (currentTokenOwner == _owner) {
                ownedTokenIds[ownedTokenIndex] = currentTokenId;
                ownedTokenIndex++;
            }
            currentTokenId++;
        }
        return ownedTokenIds;
    }

    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function mintableSupply() private view returns(uint) {
        return MAX_SUPPLY - CHEETAH_RESERVE;
    }

    function totalSupply() public view returns(uint) {
        return _tokenIdCounter.current();
    }

    function setOnlyWhitelisted(bool _state) public onlyOwner {
        onlyWhitelisted = _state;
    }

    function whitelistUsers(address[] calldata _users) public onlyOwner {
        delete whitelistedAddresses;
        whitelistedAddresses = _users;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory newBaseUri) external onlyOwner {
        baseTokenURI = newBaseUri;
    }

    function setBaseExtension(string memory newBaseExtension) external onlyOwner {
        baseExtension = newBaseExtension;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function reveal() public onlyOwner {
        revealed = true;
    }
}