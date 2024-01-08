// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Strings.sol";
import "./IFactoryERC721.sol";
import "./Card.sol";
import "./ProxyRegistry.sol";

contract Pack is Ownable, IFactoryERC721 {
    using Strings for uint256;

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    string private _name;
    string private _symbol;
    string private _baseTokenURI;

    uint256 private _numPack;
    uint256 private _numCardPerPack;

    address private _proxyRegistryAddress;
    address private _cardAddress;

    mapping(uint256 => bool) private isPackOpened;

    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseTokenURI,
        uint256 numPack,
        uint256 numCardPerPack,
        address proxyRegistryAddress,
        address cardAddress
    ) {
        _name = name_;
        _symbol = symbol_;
        _baseTokenURI = baseTokenURI;
        _numPack = numPack;
        _numCardPerPack = numCardPerPack;
        _proxyRegistryAddress = proxyRegistryAddress;
        _cardAddress = cardAddress;
        for (uint256 i = 1; i <= numPack; i++) {
            emit Transfer(address(0), msg.sender, i);
        }
    }

    function isValidPackId(uint256 packId) private view returns (bool) {
        return (packId > 0 && packId <= numOptions());
    }

    function name() external view override returns (string memory) {
        return _name;
    }

    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    function numOptions() public view override returns (uint256) {
        return _numPack;
    }

    function canMint(uint256 packId) public view override returns (bool) {
        if (!isValidPackId(packId) || isPackOpened[packId]) {
            return false;
        }
        return true;
    }

    function tokenURI(uint256 packId) external view override returns (string memory) {
        require(isValidPackId(packId), "Pack: URI query for invalid pack");
        return bytes(_baseTokenURI).length > 0 ? string(abi.encodePacked(_baseTokenURI, packId.toString())) : "";
    }

    function supportsFactoryInterface() external pure override returns (bool) {
        return true;
    }

    function mint(uint256 packId, address to) public override {
        ProxyRegistry proxyRegistry = ProxyRegistry(_proxyRegistryAddress);
        require(
            address(proxyRegistry.proxies(owner())) == _msgSender(),
            "Pack: must be called by proxy registry owner"
        );
        require(canMint(packId), "Pack: pack id is invalid");
        emit Transfer(owner(), address(0), packId);
        Card card = Card(_cardAddress);
        uint256 mintStartAt = (packId - 1) * _numCardPerPack;
        for (uint256 i = 1; i <= _numCardPerPack; i++) {
            uint256 tokenId = mintStartAt + i;
            card.mint(to, tokenId);
        }
        isPackOpened[packId] = true;
    }

    function updateBaseURI(string memory baseTokenURI) public onlyOwner {
        _baseTokenURI = baseTokenURI;
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external {
        mint(tokenId, to);
    }

    function isApprovedForAll(address owner_, address operator) external view returns (bool) {
        ProxyRegistry proxyRegistry = ProxyRegistry(_proxyRegistryAddress);
        if (owner() == owner_ && address(proxyRegistry.proxies(owner_)) == operator) {
            return true;
        }
        return false;
    }

    function ownerOf(uint256 packId) external view returns (address) {
        require(canMint(packId), "Pack: owner query for invalid pack");
        return owner();
    }
}
