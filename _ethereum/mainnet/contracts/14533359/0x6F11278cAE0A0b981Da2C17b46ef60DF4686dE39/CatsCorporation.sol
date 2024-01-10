// SPDX-License-Identifier: MIT

// Join the CatsCorporationClub 10000k Cats!

// Twitter https://twitter.com/catscorporation
// Web http://thecatscorporation.com/
// Cooperation: catscorpopation@gmail.com

pragma solidity ^0.8.13;

import "./ERC721.sol"; // Default NFT setup
import "./ERC721Enumerable.sol"; // Token indexing globally and by owner, total supply
import "./Ownable.sol"; // Allows to get owner of contract and transfer ownership
import "./Pausable.sol"; // Allows to pause mint and transfer
import "./Strings.sol"; // To be able to convert integers to strings

contract CatsCorporation is ERC721Enumerable, Pausable, Ownable {
    // Token URI: `${baseURI}${tokenId}${baseExtension}`
    string public baseURI;
    string public baseExtension;

    // Contract parameters
    uint256 public cost = 0.03 ether; // cost of NFT (can be changed by setCost)
    uint256 public maxSupply = 10000; // total count of NFT that can ever exist (can not be changed)
    uint256 public nftPerAddressLimit = 10; // how much NFT can be minted by one address (can be changed by setNftPerAddressLimit)

    bool public onlyWhitelisted = true; // To be able to enable/disable minting for anyone (can be changed by setOnlyWhitelisted)
    mapping(address => bool) private whitelistedAddresses; // Addresses added to whitelist (can be change by setWhitelistedUsers)

    address public parentContract; // Address of parent contract, which can burn NFTs in exchange of another NFTs

    // Init
    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI,
        string memory _initBaseExtension
    ) ERC721(_name, _symbol) {
        setBaseURI(_initBaseURI);
        setBaseExtension(_initBaseExtension);
    }

    // Token URI construction
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }
    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
        baseExtension = _newBaseExtension;
    }
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory base = _baseURI();
        return bytes(base).length > 0 ? string(abi.encodePacked(base, Strings.toString(tokenId), baseExtension)) : "";
    }

    // Minting
    function mint(uint256 _mintAmount) public payable whenNotPaused {
        require(_mintAmount > 0, "need to mint at least 1 NFT");

        // All NFTs ever created
        uint256 supply = totalSupply();
        require(supply + _mintAmount <= maxSupply, "max NFT limit exceeded");

        uint256 costToMint = cost * _mintAmount;
        if (msg.sender != owner()) { // Owner can mint any amount of NFTs for free without limitations per address
            if (onlyWhitelisted) {
                require(isWhitelisted(msg.sender), "user is not whitelisted");
            }

            uint256 ownerMintedCount = balanceOf(msg.sender);
            require(ownerMintedCount + _mintAmount <= nftPerAddressLimit, "max NFT per address exceeded");

            require(msg.value >= costToMint, "insufficient funds");
        }

        for (uint256 i = 1; i <= _mintAmount; i++) {
            _safeMint(msg.sender, supply + i);
        }

        Address.sendValue(payable(owner()), msg.value);
    }
    function isMinted(uint256 tokenId) external view returns (bool) {
        require(
            tokenId <= maxSupply,
            "tokenId outside collection bounds"
        );
        return _exists(tokenId);
    }
    function getTokensByAddress(address _owner) public view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    // Burning
    function burn(uint256[] calldata tokenIds) public whenNotPaused {
        if (msg.sender != owner() && msg.sender != parentContract) {
            for (uint256 i = 0; i < tokenIds.length; i++) {
                require(msg.sender == ownerOf(tokenIds[i]), 'only owner can burn their tokens');
            }
        }

        for (uint256 i = 0; i < tokenIds.length; i++) {
            _burn(tokenIds[i]);
            maxSupply--;
        }
    }

    // Whitelisting
    function setOnlyWhitelisted(bool _state) public onlyOwner {
        onlyWhitelisted = _state;
    }
    function isWhitelisted(address _user) public view returns (bool) {
        return whitelistedAddresses[_user];
    }
    function pushWhitelistedUsers(address[] calldata _whitelistedAddresses) public onlyOwner {
        for (uint i = 0; i < _whitelistedAddresses.length; i++) {
            whitelistedAddresses[_whitelistedAddresses[i]] = true;
        }
    }
    function removeWhitelistedUsers(address[] calldata _whitelistedAddresses) public onlyOwner {
        for (uint i = 0; i < _whitelistedAddresses.length; i++) {
            delete whitelistedAddresses[_whitelistedAddresses[i]];
        }
    }

    // Contract parameters setters
    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }
    function setNftPerAddressLimit(uint256 _limit) public onlyOwner {
        nftPerAddressLimit = _limit;
    }
    function setParentContract(address _newParentContract) public onlyOwner {
        parentContract = _newParentContract;
    }

    // Pause
    function pause() public onlyOwner whenNotPaused {
        _pause();
    }
    function unpause() public onlyOwner whenPaused {
        _unpause();
    }

    // Hooks
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override(ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
        require(!paused(), "ERC721Pausable: token transfer while paused");
    }
}