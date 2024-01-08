// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Strings.sol";

import "./ImmortalzInterface.sol";
import "./ImmortalzMetadataInterface.sol";

contract Immortalz is ERC721Enumerable, Ownable, ImmortalzInterface, ImmortalzMetadataInterface {
    using Strings for uint256;

    uint256 public constant IMMORTALZ_RESERVE = 150;
    uint256 public constant IMMORTALZ_MAX = 9_850;
    uint256 public constant IMMORTALZ_MAX_MINT = IMMORTALZ_RESERVE + IMMORTALZ_MAX;
    uint256 public constant PURCHASE_LIMIT = 10;
    uint256 public constant PRICE = 0.07 ether;

    uint256 public presaleListMaxMint = 1;

    uint256 public totalGiftSupply;
    uint256 public totalPublicSupply;

    bool public isActive = false;
    bool public isPresaleListActive = false;

    mapping(address => bool) private _presaleList;
    mapping(address => uint256) private _presaleListClaimed;

    string private _contractURI = '';
    string private _tokenBaseURI = '';

    constructor(string memory name, string memory symbol) ERC721(name, symbol) {}

    function addToPresaleList(address[] calldata addresses) external override onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "Can't add the null address");

            _presaleList[addresses[i]] = true;
            _presaleListClaimed[addresses[i]] > 0 ? _presaleListClaimed[addresses[i]] : 0;
        }
    }

    function onPresaleList(address addr) external view override returns (bool) {
        return _presaleList[addr];
    }

    function removeFromPresaleList(address[] calldata addresses) external override onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "Can't add the null address");

            _presaleList[addresses[i]] = false;
        }
    }

    function presaleListClaimedBy(address owner) external view override returns (uint256){
        require(owner != address(0), 'Zero address not on Allow List');

        return _presaleListClaimed[owner];
    }

    function purchase(uint256 numberOfTokens) external override payable {
        require(isActive, 'Contract is not active');
        require(!isPresaleListActive, 'Only allowing from Allow List');
        require(totalSupply() < IMMORTALZ_MAX_MINT, 'All tokens have been minted');
        require(numberOfTokens <= PURCHASE_LIMIT, 'Would exceed PURCHASE_LIMIT');
        require(totalPublicSupply < IMMORTALZ_MAX, 'Purchase would exceed IMMORTALZ_MAX');
        require(PRICE * numberOfTokens <= msg.value, 'ETH amount is not sufficient');

        for (uint256 i = 0; i < numberOfTokens; i++) {
            if (totalPublicSupply < IMMORTALZ_MAX) {
                uint256 tokenId = IMMORTALZ_RESERVE + totalPublicSupply + 1;

                totalPublicSupply += 1;
                _safeMint(msg.sender, tokenId);
            }
        }
    }

    function purchasePresaleList(uint256 numberOfTokens) external override payable {
        require(isActive, 'Contract is not active');
        require(isPresaleListActive, 'Allow List is not active');
        require(_presaleList[msg.sender], 'You are not on the Presale List');
        require(totalSupply() < IMMORTALZ_MAX_MINT, 'All tokens have been minted');
        require(numberOfTokens <= presaleListMaxMint, 'Cannot purchase this many NFTs');
        require(totalPublicSupply + numberOfTokens <= IMMORTALZ_MAX, 'Purchase would exceed IMMORTALZ_MAX');
        require(_presaleListClaimed[msg.sender] + numberOfTokens <= presaleListMaxMint, 'Purchase exceeds max allowed');
        require(PRICE * numberOfTokens <= msg.value, 'ETH amount is not sufficient');

        for (uint256 i = 0; i < numberOfTokens; i++) {
            uint256 tokenId = IMMORTALZ_RESERVE + totalPublicSupply + 1;

            totalPublicSupply += 1;
            _presaleListClaimed[msg.sender] += 1;
            _safeMint(msg.sender, tokenId);
        }
    }

    function mintReserve(uint256 _count, address _to) public onlyOwner {
        require(totalSupply() < IMMORTALZ_MAX_MINT, 'All tokens have been minted');
        require(totalGiftSupply + _count <= IMMORTALZ_RESERVE, 'Not enough tokens left to reserve');

        for(uint256 i = 0; i < _count; i++) {
            uint256 tokenId = totalGiftSupply + 1;

            totalGiftSupply += 1;
            _safeMint(_to, tokenId);
        }
    }

    function setIsActive(bool _isActive) external override onlyOwner {
        isActive = _isActive;
    }

    function setIsPresaleListActive(bool _isPresaleListActive) external override onlyOwner {
        isPresaleListActive = _isPresaleListActive;
    }

    function setPresaleListMaxMint(uint256 maxMint) external override onlyOwner {
        presaleListMaxMint = maxMint;
    }

    function withdraw() external override onlyOwner {
        uint256 balance = address(this).balance;

        payable(msg.sender).transfer(balance);
    }

    function setContractURI(string calldata URI) external override onlyOwner {
        _contractURI = URI;
    }

    function setBaseURI(string calldata URI) external override onlyOwner {
        _tokenBaseURI = URI;
    }

    function contractURI() public view override returns (string memory) {
        return _contractURI;
    }

    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
        require(_exists(tokenId), 'Token id does not exist');

        return _tokenBaseURI;
    }
}
