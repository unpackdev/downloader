//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./ERC721A.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract AscendedAzuki is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;
    using Counters for Counters.Counter;

    string public baseExtension = ".json";
    string public baseURI;
    string public notRevealedUri;   
    uint256 public cost = 0.03 ether; 
    uint256 public presaleMintPrice = 0 ether;

    uint256 public maxSupply = 10000; 
    uint256 public publicMaxSupply = 9500; 
    uint256 public presaleSupplyLimit = 500;
    uint256 public publicNftPerTransactionLimit = 10;
    uint256 public whitelistNftPerTransactionLimit = 10;
    uint256 public freeNftLimit = 1;

    uint256 public airdropTotalMintSupply = 0; // by default - 0
    uint256 public presaleTotalMintSupply = 0; // by default - 0
    uint256 public publicTotalMintSupply = 0; // by default - 0

    bool public paused = false;
    bool public revealed = false;

    address[] public whitelistedAddresses;
    mapping(address => uint256) public addressMintedBalance;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _notRevealedUri
    ) ERC721A(_name, _symbol) {
        setNotRevealedURI(_notRevealedUri);
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function reserveNFTs(uint256 _count) public onlyOwner {
        uint256 n = totalSupply() + _count;
        require(_count > 0, "need to mint at least 1 NFT");
        require(n < maxSupply, "Not enough NFTs left to reserve");
        _safeMint(msg.sender, _count);
    }

    function airDrop(address to, uint256 _count) public onlyOwner{
        uint256 n = totalSupply() + _count;
        require(_count > 0, "need to mint at least 1 NFT");
        require(n < maxSupply, "Not enough NFTs left to reserve");
        airdropTotalMintSupply += _count;
        _safeMint(to, _count);
    }

    // public 
    function mint(uint256 quantity) public payable {
        require(!paused, "Mint is not enable now.");
        uint256 supply = totalSupply();
        require(quantity > 0, "need to mint at least 1 NFT");
        require(supply + quantity <= maxSupply, "Max NFT limit exceeded");
        uint256 ownerMintedCount = addressMintedBalance[msg.sender];

        if(isWhitelisted(msg.sender) && (ownerMintedCount + quantity) <= freeNftLimit) {
            require(quantity <= freeNftLimit, "Max NFT per transaction exceeded");
            presaleTotalMintSupply += quantity;
            addressMintedBalance[msg.sender]++;
            _safeMint(msg.sender, quantity);  
        } else {
            require(msg.value >= cost * quantity, "Insufficient funds");
            require(publicTotalMintSupply + quantity <= publicMaxSupply, "Max NFT limit exceeded");
            require(quantity <= publicNftPerTransactionLimit, "Max NFT per transaction exceeded");
            publicTotalMintSupply += quantity;
            addressMintedBalance[msg.sender]++;
            _safeMint(msg.sender, quantity);
        }        
    }

    function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        if(revealed == false) {
            return notRevealedUri;
        }

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
    }

    function reveal(bool _state) public onlyOwner {
        revealed = _state;
    }

    function setWhitelistNftPerTransactionLimit(uint256 _limit) public onlyOwner {
        whitelistNftPerTransactionLimit = _limit;
    }

    function setPublicNftPerTransactionLimit(uint256 _limit) public onlyOwner {
        publicNftPerTransactionLimit = _limit;
    }

    function setFreeNftLimit(uint256 _limit) public onlyOwner {
        freeNftLimit = _limit;
    }

    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    function setPresaleMintPrice(uint256 _newCost) public onlyOwner {
        presaleMintPrice = _newCost;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function pause(bool _state) public onlyOwner nonReentrant {
        paused = _state;
    }

    function setPresaleSupplyLimit(uint256 _newSupply) public onlyOwner {
        require(presaleTotalMintSupply <= _newSupply, "new limit lower than total supply");
        presaleSupplyLimit = _newSupply;
    }

    function setPublicMaxSupply(uint256 _newPublicMaxSupply) public onlyOwner {
        require(publicTotalMintSupply <= _newPublicMaxSupply, "new limit lower than total supply");
        publicMaxSupply = _newPublicMaxSupply;
    }

    function setMaxSupply(uint256 _newMaxSupply) public onlyOwner nonReentrant {
        maxSupply = _newMaxSupply;
    }

    function whitelistUsers(address[] calldata _users) public onlyOwner nonReentrant {
        delete whitelistedAddresses;
        whitelistedAddresses = _users;
    }

    function isWhitelisted(address _user) public view returns (bool) {
        for (uint i = 0; i < whitelistedAddresses.length; i++) {
            if (whitelistedAddresses[i] == _user) {
                return true;
            }
        }
        return false;
    }

    function removeWhitelistUser(address _user) public onlyOwner nonReentrant {
        for (uint i = 0; i < whitelistedAddresses.length; i++) {
            if (whitelistedAddresses[i] == _user) {
                delete whitelistedAddresses[i];
            }
        }
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function tokensOfOwner(address owner) public view returns (uint256[] memory) {
        uint256 holdingAmount = balanceOf(owner);
        uint256 currSupply    = _currentIndex;
        uint256 tokenIdsIdx;
        address currOwnershipAddr;

        uint256[] memory list = new uint256[](holdingAmount);

        unchecked {
            for (uint256 i; i < currSupply; i++) {
                TokenOwnership memory ownership = _ownerships[i];

                if (ownership.burned) {
                    continue;
                }

                // Find out who owns this sequence
                if (ownership.addr != address(0)) {
                    currOwnershipAddr = ownership.addr;
                }

                // Append tokens the last found owner owns in the sequence
                if (currOwnershipAddr == owner) {
                    list[tokenIdsIdx++] = i;
                }

                // All tokens have been found, we don't need to keep searching
                if(tokenIdsIdx == holdingAmount) {
                    break;
                }
            }
        }

        return list;
    }

    function _startTokenId() internal virtual override view returns (uint256) {
        return 1;
    }

    function withdraw() public payable onlyOwner nonReentrant {
        uint balance = address(this).balance;
        require(balance > 0, "No ether left to withdraw");
        // This will payout the owner the contract balance.
        // Do not remove this otherwise you will not be able to withdraw the funds.
        // =============================================================================
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
        // =============================================================================
    }
}