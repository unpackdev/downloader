// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./Address.sol";
import "./Strings.sol";

// This is the official CPI Technologies Fox NFT
// Created with <3 by CPI

// More information available at cpitech.io
contract CPIFox is ERC721, Ownable {
    using Strings for uint;
    using Address for address;
    using Address for address payable;
    using Counters for Counters.Counter;

    string internal constant INITIAL_PATH = "https://cdn.cpi.dev/nft/fox/meta/";

    Counters.Counter private _tokenIds;
    mapping(address => bool) private _mintAllowance;
    bool private _pathChanged = false;
    string private _metaPath;
    string private _metaPathPostfix = ".json";

    uint internal _totalTokenCount;

    event EthersWithdrawn(address indexed operator, address indexed to, uint amount);
    
    constructor(uint maxTokens) ERC721("The official CPI Technologies FOX-NFT", "CPIFOX") {
        _totalTokenCount = maxTokens;
    }

    function totalTokenCount() public view returns(uint) {
       return _totalTokenCount;
    }

    function changePath(string memory metaPath, string memory metaPathPostfix) external onlyOwner {
       _pathChanged = true;
       _metaPath = metaPath;
       _metaPathPostfix = metaPathPostfix;
    }

    /*
        Allow a new minter address
    */
    function allowMint(address[] calldata addresses) external onlyOwner {
        for (uint i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0) && !addresses[i].isContract(), "CPI-Fox: wrong address");
            _mintAllowance[addresses[i]] = true;
        }
    }

    /*
        This function will mint multiple NFT tokens to multiple addresses given in an array
    */
    function bulkMint(address[] calldata addresses, uint number) external {
        if (!_mintAllowance[msg.sender]) {
            revert("CPI-Fox: You are not allowed to mint these special CPI tokens!");
        }

        for (uint i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0) && !addresses[i].isContract(), "CPI-Fox: wrong address");
            require((_tokenIds.current() + number) <= totalTokenCount(), "CPI-Fox: the limit of the tokens is going to be exceeded");

            for (uint j = 0; j < number; j++) {
                _tokenIds.increment();
                uint newTokenId = _tokenIds.current();
                _mint(addresses[i], newTokenId);
            }
        }
    }

    function checkMintingAllowance(address addr) external view returns (bool) {
        return _mintAllowance[addr];
    }

    function tokenURI(uint tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory imgPath = _pathChanged ? _metaPath : INITIAL_PATH;
        return string(abi.encodePacked(imgPath, tokenId.toString(), _metaPathPostfix));
    }

    /*
        Performs a minting action to a given address. Can only be done by an authorized minter
    */
    function mint(address to, uint number) external {
        require(to != address(0) && !to.isContract(), "CPI-Fox: wrong address");
        require((_tokenIds.current() + number) <= totalTokenCount(), "CPI-Fox: the limit of the tokens is going to be exceeded");

        if (!_mintAllowance[msg.sender]) {
            revert("CPI-Fox: You are not allowed to mint these special CPI tokens!");
        }

        for (uint i = 0; i < number; i++) {
            _tokenIds.increment();
            uint newTokenId = _tokenIds.current();
            _mint(to, newTokenId);
        }
    }

    function withdrawEthers(uint amount, address payable to) public virtual onlyOwner {
        to.sendValue(amount);
        emit EthersWithdrawn(_msgSender(), to, amount);
    }
}