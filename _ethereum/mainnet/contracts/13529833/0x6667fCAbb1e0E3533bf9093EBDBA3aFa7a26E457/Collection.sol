// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./Pausable.sol";
import "./Ownable.sol";

contract Collection is
    ERC721,
    ERC721Enumerable,
    ERC721URIStorage,
    Pausable,
    Ownable
{
    // token mint price - 0.03 ether
    uint256 public mintPrice =  0.03 ether;

    // Maximum supply
    uint256 public maxSupply = 9999;

    // Maximum purchase at once
    uint256 public maxPurchase = 20;

    // Reserve max 99 tokens for founding NFT owners, giveaways, partners, marketing and team
    uint256 public reserve = 99;

    // Limit single reserve amount
    uint256 private reserveLimit = 20;

    // Sale state
    bool public saleIsActive = false;

    // Base URI
    string private baseURI;

    // Events
    event AssetMinted(address indexed to, uint256 indexed tokenId);

    // Presale
    mapping(address => bool) presaleAccessAddresses;
    uint256 public presaleAccessCount = 0;
    bool public presaleIsActive = false;


    constructor() ERC721("Who's gonna kill Bill?", "SUSP") {}

    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function flipPreSaleState() public onlyOwner {
        presaleIsActive = !presaleIsActive;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function setBaseURI(string memory baseURI_) public onlyOwner {
        baseURI = baseURI_;
    }

    function getBaseURI() public view onlyOwner returns (string memory) {
        return baseURI;
    }

    function addPresaleAddresses(address[] calldata addresses) public onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            presaleAccessAddresses[addresses[i]] = true;
        }
        presaleAccessCount += addresses.length;
    }

    function canAccessPresale() public view returns (bool) {
        return presaleAccessAddresses[msg.sender];
    }

    function canAccessPresale(address addr) public view returns (bool) {
        return presaleAccessAddresses[addr];
    }

    function mint(uint256 numberOfTokens) public payable whenNotPaused {
        require(presaleIsActive || saleIsActive, "Sale must be active to mint");
        if (presaleIsActive && !saleIsActive) {
            require(canAccessPresale(), "Not in pre-sale list");
        }
        require(numberOfTokens > 0, "At least one token must be minted");
        require(
            numberOfTokens <= maxPurchase,
            "Maximum 20 tokens can be minted at once"
        );
        require(
            totalSupply() + numberOfTokens <= maxSupply,
            "Purchase would exceed the max supply"
        );
        if (owner() != msg.sender) {
            require(
                msg.value == mintPrice * numberOfTokens,
                "ETH value sent is not correct"
            );
        } else {
            require(
                msg.value == 0,
                "ETH value sent is not correct"
            );
        }

        for (uint256 i = 0; i < numberOfTokens; i++) {
            uint256 mintIndex = totalSupply() + 1;

            if (mintIndex <= maxSupply) {
                _safeMint(msg.sender, mintIndex);
                emit AssetMinted(msg.sender, mintIndex);
            }
        }
    }

    function reserveTokens(address to, uint256 numberOfTokens) public onlyOwner {
        require(numberOfTokens > 0, "At least one token must be reserved");
        require(
            numberOfTokens <= reserve,
            "There's not enough tokens left in reserve"
        );
        require(
            numberOfTokens <= reserveLimit,
            "Exceeded token reserve limit"
        );

        for (uint256 i = 0; i < numberOfTokens; i++) {
            uint256 mintIndex = totalSupply() + 1;
            if (mintIndex <= maxSupply) {
                _safeMint(to, mintIndex);
            }
        }

        reserve = reserve - numberOfTokens;
    }

    function withdraw() public onlyOwner {
        address payable to = payable(msg.sender);
        uint256 balance = address(this).balance;

        to.transfer(balance);
    }

    function tokensOfOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);

        if (tokenCount > 0) {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;

            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }

            return result;
        }

        return new uint256[](0);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}