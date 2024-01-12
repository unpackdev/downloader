// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract HoneyCrazedBears is ERC721Enumerable, Ownable {
    uint public constant MAX_TOTAL_SUPPLY = 200;

    string public baseURI;  // base metadata URI
    string public URISuffix;  // URI suffix (file extension)
    bool public frozen = false; // whether metadata is frozen

    event PermanentURI(string _value, uint256 indexed _id);

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _newBaseURI,
        string memory _URISuffix
    ) ERC721(_name, _symbol) {
        baseURI = _newBaseURI;
        URISuffix = _URISuffix;
    }

    // PUBLIC

    // @dev A more efficient way to calculate token URI
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "HoneyCrazedBears: URI query for nonexistent token");

        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, Strings.toString(tokenId), URISuffix)) : "";
    }

    // OWNER

    /**
     * @dev Mints every remaining token
     */
    function mint() external onlyOwner {
        require(totalSupply() < MAX_TOTAL_SUPPLY, "HoneyCrazedBears: Already minted every token");

        while (totalSupply() < MAX_TOTAL_SUPPLY) {
            _safeMint(msg.sender, totalSupply() + 1);  // indexing from 1
        }
    }

    function setURI(string memory _newBaseURI, string memory _uriSuffix) external onlyOwner {
        require(!frozen, "HoneyCrazedBears: Metadata already frozen");

        baseURI = _newBaseURI;
        URISuffix = _uriSuffix;
    }

    function freeze() external onlyOwner {
        require(!frozen, "HoneyCrazedBears: Metadata already frozen");
        require(totalSupply() == MAX_TOTAL_SUPPLY, "HoneyCrazedBears: Tokens must be minted before freezing metadata");

        for (uint i = 0; i < totalSupply(); i++) {
            emit PermanentURI(tokenURI(i + 1), i + 1); // indexing from 1
        }

        frozen = true;
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer((address(this).balance));
    }

    // INTERNALS

    // used internally by ERC721.prototype.tokenURI, not used in this class
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
}
