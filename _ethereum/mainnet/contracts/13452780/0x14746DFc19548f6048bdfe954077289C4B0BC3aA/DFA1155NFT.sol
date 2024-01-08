// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./ERC1155.sol";
import "./Ownable.sol";

contract DFA1155NFT is ERC1155, Ownable {
    bool private whitelistEnabled = true;
    string public baseUri;
    string public name;
    string public symbol;
    
    mapping (address => bool) public whitelisted;
    
    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseUri
        ) ERC1155(baseUri) {
            name = _name;
            symbol = _symbol;
            baseUri = _baseUri;
            _setURI(_baseUri);
        }
    
    modifier onlyWhitelist() {
        if (whitelistEnabled == true) {
            require(whitelisted[msg.sender] == true, 'invalid call');
        }
        _;
    }

    function _baseURI() internal view returns (string memory) {
        return baseUri;
    }
    
    function setBaseUri(string memory _baseUri) external onlyOwner {
        baseUri = _baseUri;
    }
    
    function mint(address minter, uint256 tokenId, uint256 amount, bytes calldata data) external onlyWhitelist returns (uint256) {
        _mint(minter, tokenId, amount, data);
        emit Mint(minter, tokenId, amount);
        return tokenId;
    }
    
    function whitelist(address _address) external onlyOwner {
        whitelisted[_address] = true;
    }
    
    function blacklist(address _address) external onlyOwner {
        whitelisted[_address] = false;
    }
    
    function toogleWhitelist(bool state) external onlyOwner {
        whitelistEnabled = state;
    }
    
    function getStatus(address _address) public view returns (bool) {
        if (whitelistEnabled == false) {
            return true;
        } else {
            return whitelisted[_address];
        }
    }
    
    event Mint(address indexed minter, uint256 indexed tokenId, uint256 indexed amount);
}