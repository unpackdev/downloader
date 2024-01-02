// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";

contract OrdRegistrar is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    // 0 Registration fee for a .ord domain
    uint256 public registrationFee;

    // Mapping from token ID to .ord name
    mapping(uint256 => string) private _tokenURIs;

    // Mapping from .ord name to token ID
    mapping(string => uint256) private _nameToTokenId;

    // Event emitted when a .ord name is registered
    event OrdRegistered(string indexed name, uint256 indexed tokenId);

    constructor(uint256 _registrationFee) ERC721("Ordinal Domains", "ORDomains") Ownable(msg.sender) {
        registrationFee = _registrationFee;
    }


    // Register a new .ord name
    function registerOrd(string memory name) public payable {
        require(msg.value == registrationFee, "Registration fee is not correct.");
        require(_nameToTokenId[name] == 0, "Name is already taken.");
        require(isValidName(name), "Invalid name format.");

        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();

        _mint(msg.sender, tokenId);
        _setTokenURI(tokenId, name);

        // Emit an event for the new registration
        emit OrdRegistered(name, tokenId);
    }

    // Helper function to validate the .ord name format
    function isValidName(string memory name) private pure returns (bool) {
        bytes memory b = bytes(name);
        if(b.length < 3 || b.length > 64) return false; // Ensures length is between 3 and 64 characters

        // Check first and last character are not hyphens
        if(b[0] == '-' || b[b.length - 1] == '-') return false;

        // Check the name only contains valid characters and no consecutive hyphens
        bool lastWasHyphen = false;

        for(uint i; i < b.length; i++){
            bytes1 char = b[i];

            // If the character is a hyphen, check that the last character wasn't also a hyphen
            if(char == '-') {
                if(lastWasHyphen) return false; // Consecutive hyphens are not allowed
                lastWasHyphen = true;
            } else {
                if(
                    !(char >= '0' && char <= '9') && // '0' to '9'
                    !(char >= 'a' && char <= 'z')    // 'a' to 'z'
                )
                    return false; // Invalid character

                lastWasHyphen = false; // Reset the flag if the current character is not a hyphen
            }
        }

        return true; // If all checks passed, the name is valid
    }


    // Set the .ord name for a token ID
    function _setTokenURI(uint256 tokenId, string memory name) internal {
        require(bytes(_tokenURIs[tokenId]).length == 0, "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = name;
        _nameToTokenId[name] = tokenId;
    }

    // Get the .ord name for a token ID
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(bytes(_tokenURIs[tokenId]).length > 0, "ERC721URIStorage: URI query for nonexistent token");
        return _tokenURIs[tokenId];
    }

    // Get the token ID for a .ord name
    function nameToTokenId(string memory name) public view returns (uint256) {
        return _nameToTokenId[name];
    }

    // Withdraw the contract's balance to the contract owner
    function withdraw() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}