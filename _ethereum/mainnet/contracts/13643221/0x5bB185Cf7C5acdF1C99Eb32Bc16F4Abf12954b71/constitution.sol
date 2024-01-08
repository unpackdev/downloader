// SPDX-License-Identifier: MIT

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./AccessControl.sol";
import "./kpst.sol";

pragma solidity ^0.8.0;


contract Constitution is ERC721Enumerable, AccessControl, ERC721URIStorage, ReentrancyGuard, Ownable {
    using Counters for Counters.Counter;
    address private constant TREASURY_ADDRESS = 0xe748a5D1C557308868d187c647DBdcd2adA445DB;

    Counters.Counter private totalMinted;

    // Flag that the sale has started.
    bool private _saleStarted = false;

    uint256 public constant MAX_SUPPLY = 7497;

    // Default price for the drop
    uint256 private _defaultPrice = 1776 * 10**13; // This is .01776 eth

    // Base token URI
    string private _baseTokenURI;

    // Is everything fully revealed?
    bool private _isRevealed = false;
    
    constructor() ERC721("Words of the Constitution", "CONSTITUENT") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function mint(uint256 _count) public payable {
        require(_count <= 5, "Only 5 at a time");
        uint256 totalSupply = totalMinted.current();
        require(
            totalSupply + _count < MAX_SUPPLY,
            "A transaction of this size would surpass the token limit."
        );

        require(_count > 0, "Must mint something");
        
        for (uint256 i; i < _count; i++) {
            _safeMint(msg.sender, totalSupply + i);
            totalMinted.increment();
        }
    }

    function getTotalMintCount() public view returns (uint256) {
        return totalMinted.current();
    }

    function getPrice() public view returns (uint256) {
        return _defaultPrice;
    }


    function setBaseURI(string memory baseURI) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Must be an admin to set the base URI");
        require(_isRevealed == false, "Can no longer set the base URI after reveal");
        _baseTokenURI = baseURI;
    }

    // Set that we have revealed the final base token URI, and lock the reveal so that the token URI is permanent
    function setRevealed() public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Only an admin can finalize the reveal");
        require(_isRevealed != true, "Can no longer set the reveal once it has been revealed");
        _isRevealed = true;
    }

    function isRevealed() public view returns (bool) {
        return _isRevealed;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }
   
    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);

        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        }

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    // Always withdraw to the treasury address. Allow anyone to withdraw, such that there can be no issues with keys.
    function withdrawAll() public payable {
        require(payable(TREASURY_ADDRESS).send(address(this).balance));
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
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


}