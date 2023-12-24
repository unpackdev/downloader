// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Strings.sol";

/**
 * @title ERC721Tradable
 * ERC721Tradable - ERC721 contract that whitelists a trading address, and has minting functionality.
 */
contract MoonlandPass is ERC721, Ownable {

    uint256 private _currentTokenId = 0;
    mapping (address => bool) public isMinted;

    constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) {}

    function mintAndTransfer(address[] calldata accounts) external onlyOwner() {
        uint256 len = accounts.length;
        require(_currentTokenId + len <= 420, "");
        uint256 ii;
        for (ii = 0; ii < len; ii++) {
            address account = accounts[ii];
            require(!isMinted[account], "Already minted");
            isMinted[account] = true;
            _mint(account, ++_currentTokenId);
        }

    }

    function baseTokenURI() public pure returns (string memory) {
        return "https://nftimage.mypinata.cloud/ipfs/QmdMpoXzZhnTemWZqikjpP2x2adxhupM92HShTq22GgN7u/";
    }

    function tokenURI(uint256 _tokenId) public pure override returns (string memory) {
        return string(abi.encodePacked(baseTokenURI(), Strings.toString(_tokenId), ".json"));
    }

    function totalSupply() external view returns(uint256) {
        return _currentTokenId;
    }
}
