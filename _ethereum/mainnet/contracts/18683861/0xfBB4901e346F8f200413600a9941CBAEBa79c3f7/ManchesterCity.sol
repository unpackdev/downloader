// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./AccessControl.sol";
import "./ERC721Enumerable.sol";

contract ManchesterCity is ERC721, ERC721Enumerable,  AccessControl {
    using Strings for uint256;

    // URI
    string private _baseTokenURI;

    // Minting state
    bool private _mintingEnabled = false;

    // Roles
    bytes32 public constant DEVELOPER_ROLE = keccak256("DEVELOPER_ROLE");

    // Prices
    uint256 private _basicPrice = 0.05 ether;
    uint256 private _vipPrice = 0.5 ether;

    // Supply
    uint8 private constant BASIC_SUPPLY = 80;
    uint8 private constant VIP_SUPPLY = 4;
    uint8 private constant CATEGORY_SUPPLY = 20;

    // Mint Limit
    mapping(address => uint8) private _mintBasicLimit;
    mapping(address => uint8) private _mintVipLimit;
    uint8 private _basicMintLimit = 2;
    uint8 private _vipMintLimit = 1;

    // Redeem Map
    mapping(uint256 => bool) private _redeemMap;

    // Messages
    string private constant _NOT_ENOUGH_ETHER = "Not enough Ether";
    string private constant _MINTING_NOT_ENABLED = "Minting is not enabled";
    string private constant _VIP_AMOUNT_MUST_BE_ONE = "VIP amount must be 1";
    string private constant _MINT_LIMIT_EXCEEDED = "Mint limit exceeded";
    string private constant _BAD_BASIC_MINT_TOKEN_ID = "Basic mint token id must be more than 3 and less than 84";
    string private constant _ALREADY_REDEEMED = "Already redeemed";
    string private constant _ONLY_OWNER_CAN_REDEEM = "Only owner can redeem";
    string private constant _CATEGORY_OUT_OF_BOUNDS = "Category out of bounds";

    constructor(string memory baseURI) ERC721("BrewedForTrebleSuccess","BFTS") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(DEVELOPER_ROLE, msg.sender);
        _baseTokenURI = baseURI;
        _safeMint(msg.sender, 51);
    }

    // Price check modifiers
    modifier checkPrice(uint256 tokenId) {
        uint256 price = tokenId < VIP_SUPPLY ? _vipPrice : _basicPrice;
        require(msg.value >= price, _NOT_ENOUGH_ETHER);
        _;
    }

    // Mint Limit check modifiers
    modifier checkMintLimit(uint256 tokenId, address to) {
        bool isVIPMint = tokenId < VIP_SUPPLY;
        if (isVIPMint) {
            require(_mintVipLimit[to] < _vipMintLimit, _MINT_LIMIT_EXCEEDED);
        } else {
            require(_mintBasicLimit[to] < _basicMintLimit, _MINT_LIMIT_EXCEEDED);
        }
        _;
    }

    // Minting state modifier
    modifier mintingEnabled() {
        require(_mintingEnabled, _MINTING_NOT_ENABLED);
        _;
    }

    // Minting state setter and getter
    function setMintingState(bool newValue) public onlyRole(DEVELOPER_ROLE) {
        _mintingEnabled = newValue;
    }

    function getMintingState() public view returns (bool) {
        return _mintingEnabled;
    }

    // Mint Limit setters and getters
    function setBasicMintLimit(uint8 limit) public onlyRole(DEVELOPER_ROLE) {
        _basicMintLimit = limit;
    }

    function setVipMintLimit(uint8 limit) public onlyRole(DEVELOPER_ROLE) {
        _vipMintLimit = limit;
    }

    function getBasicMintLimit() public view returns (uint8) {
        return _basicMintLimit;
    }

    function getVipMintLimit() public view returns (uint8) {
        return _vipMintLimit;
    }

    // Price setters and getters
    function setBasicPrice(uint256 price) public onlyRole(DEVELOPER_ROLE) {
        _basicPrice = price;
    }

    function setVipPrice(uint256 price) public onlyRole(DEVELOPER_ROLE) {
        _vipPrice = price;
    }

    function getBasicPrice() public view returns (uint256) {
        return _basicPrice;
    }

    function getVipPrice() public view returns (uint256) {
        return _vipPrice;
    }

    // Base URI getter and setter
    function getBaseURI() public view returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) public onlyRole(DEVELOPER_ROLE) {
        _baseTokenURI = baseURI;
    }

    // Token URI override
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = getBaseURI();
        string memory endURI = isRedeemed(tokenId) ? "_redeemed.json" : ".json";

        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), endURI)) : "";
    }

    // Base Minting functions
    function _safeMintBasic(address to, uint256 tokenId) private {
        require(tokenId >= VIP_SUPPLY && tokenId < (BASIC_SUPPLY + VIP_SUPPLY), _BAD_BASIC_MINT_TOKEN_ID);

        _mintBasicLimit[to]++;
        _safeMint(to, tokenId);
    }

    function _safeMintVip(address to, uint256 tokenId) private {
        _mintVipLimit[to]++;
        _safeMint(to, tokenId);
    }

    // Normal minting function
    function safeMint(address to, uint256 tokenId) public payable mintingEnabled() checkPrice(tokenId) checkMintLimit(tokenId, to) {
        if (tokenId < VIP_SUPPLY) {
            _safeMintVip(to, tokenId);
        } else {
            _safeMintBasic(to, tokenId);
        }
    }

    // Redeem function
    function redeem(uint256 tokenId) public {
        _requireMinted(tokenId);
        require(!_redeemMap[tokenId], _ALREADY_REDEEMED);
        require(ownerOf(tokenId) == msg.sender, _ONLY_OWNER_CAN_REDEEM);

        _redeemMap[tokenId] = true;
    }

    // Helper functions
    function isVIP(address account) public view returns (bool) {
        for (uint8 i = 0; i < VIP_SUPPLY; i++) {
            if (_ownerOf(i) == account) {
                return true;
            }
        }
        return false;
    }

    function isRedeemed(uint256 tokenId) public view returns (bool) {
        _requireMinted(tokenId);
        return _redeemMap[tokenId];
    }

    function remainingByCategory(uint8 category) public view returns (uint8) {
        uint8 counterStart = (category * CATEGORY_SUPPLY) + VIP_SUPPLY;
        require(counterStart < BASIC_SUPPLY, _CATEGORY_OUT_OF_BOUNDS);

        uint8 remainingCounter = 0;
        for (uint8 i = 0; i <  CATEGORY_SUPPLY; i++) {
            if (_ownerOf(counterStart + i) == address(0)) {
                remainingCounter++;
            }
        }

        return remainingCounter;
    }

    // Withdraw function
    function withdraw() public onlyRole(DEFAULT_ADMIN_ROLE) {
        payable(msg.sender).transfer(address(this).balance);
    }

    // Overrides required by Solidity
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    // The following functions are overrides required by Solidity.
    function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721, ERC721Enumerable, AccessControl)
    returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
