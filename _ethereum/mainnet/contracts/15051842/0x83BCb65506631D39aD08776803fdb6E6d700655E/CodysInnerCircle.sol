// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

// struct Holder {
//     address holder;
//     uint256 amount;
// }

contract CodysInnerCircle is ERC721Enumerable, Ownable {
    event ThisAddress(address addr);

    using Strings for uint256;

    string public ogHolderBaseURI;
    string public newHolderBaseURI;
    string public baseExtension = "";
    string public notRevealedUri;
    uint256 public cost = 0.15 ether;
    uint256 public maxSupply = 1000;
    uint256 public maxMintAmount = 1000;
    uint256 public nftPerAddressLimit = 1000;
    uint256 public numOgHolders = 0;
    bool public paused = false;
    bool public revealed = true;
    bool public onlyWhitelisted = false;
    address[] public whitelistedAddresses;
    mapping(address => uint256) public addressMintedBalance;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initOgHolderBaseUri,
        string memory _initNewHolderBaseUri,
        uint256 _initNumOgHolders,
        string memory _initNotRevealedUri
    ) ERC721(_name, _symbol) {
        setOgHolderBaseURI(_initNotRevealedUri);
        setNotRevealedURI(_initNotRevealedUri);
        setNumOgHolders(_initNumOgHolders);
        setOgHolderBaseURI(_initOgHolderBaseUri);
        setNewHolderBaseURI(_initNewHolderBaseUri);

        // Set Initial Holding State
        // for (uint256 i = 0; i < _initialHolders.length; i++) {
        //     mint(_initialHolders[i].amount, _initialHolders[i].holder);
        // }
    }

    // public
    function mint(uint256 _mintAmount, address to) public payable {
        require(!paused, "the contract is paused");
        uint256 supply = totalSupply();
        require(_mintAmount > 0, "need to mint at least 1 NFT");
        require(
            _mintAmount <= maxMintAmount,
            "max mint amount per session exceeded"
        );
        require(supply + _mintAmount <= maxSupply, "max NFT limit exceeded");

        if (msg.sender != owner()) {
            if (onlyWhitelisted == true) {
                require(isWhitelisted(msg.sender), "user is not whitelisted");
                uint256 ownerMintedCount = addressMintedBalance[msg.sender];
                require(
                    ownerMintedCount + _mintAmount <= nftPerAddressLimit,
                    "max NFT per address exceeded"
                );
            }
            require(msg.value >= cost * _mintAmount, "insufficient funds");
        }

        for (uint256 i = 1; i <= _mintAmount; i++) {
            addressMintedBalance[to]++;
            _safeMint(to, supply + i);
        }
    }

    function isWhitelisted(address _user) public view returns (bool) {
        for (uint256 i = 0; i < whitelistedAddresses.length; i++) {
            if (whitelistedAddresses[i] == _user) {
                return true;
            }
        }
        return false;
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (tokenId <= numOgHolders) {
            return ogHolderBaseURI;
        }
        return newHolderBaseURI;
    }

    //only owner
    function reveal() public onlyOwner {
        revealed = true;
    }

    function setNftPerAddressLimit(uint256 _limit) public onlyOwner {
        nftPerAddressLimit = _limit;
    }

    function setNumOgHolders(uint256 _numOgHolders) public onlyOwner {
        numOgHolders = _numOgHolders;
    }

    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
        maxMintAmount = _newmaxMintAmount;
    }

    function setOgHolderBaseURI(string memory _ogHolderBaseURI)
        public
        onlyOwner
    {
        ogHolderBaseURI = _ogHolderBaseURI;
    }

    function setNewHolderBaseURI(string memory _newHolderBaseURI)
        public
        onlyOwner
    {
        newHolderBaseURI = _newHolderBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension)
        public
        onlyOwner
    {
        baseExtension = _newBaseExtension;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    function setOnlyWhitelisted(bool _state) public onlyOwner {
        onlyWhitelisted = _state;
    }

    function whitelistUsers(address[] calldata _users) public onlyOwner {
        delete whitelistedAddresses;
        whitelistedAddresses = _users;
    }

    function withdraw() public payable onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }
}
