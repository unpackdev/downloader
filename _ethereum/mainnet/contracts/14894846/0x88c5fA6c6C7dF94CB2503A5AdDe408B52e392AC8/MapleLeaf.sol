// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./Ownable.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";

contract MapleLeaf is Ownable, Pausable, ReentrancyGuard, ERC721A {
    using Strings for uint256;

    address constant public TEAM = 0x37CDAce99029F61cAcC44Edbb9Bac786cAFdEb9f;
    uint256 constant public MAX_SUPPLY = 7534;
    uint256 constant public TEAM_RESERVE = 750;
    uint256 constant public PRICE = 5_000_000_000_000_000;
    string private _baseTokenURI;
    bool private _revealed;
    

    constructor() ERC721A("MapleLeaf", "ML") {
        _baseTokenURI = "ipfs://QmTgSBCDYFN3Bp4KFWTXp4ShEys1BqLWj6ssQgWi2jjCW3";
        _team_mint();
        _pause();
    }

    function _team_mint() private {
        _safeMint(TEAM, TEAM_RESERVE);
    }

    function mint_as_prize(address to, uint256 quantity) external onlyOwner {
        require(_totalMinted() + quantity <= MAX_SUPPLY);
        _safeMint(to, quantity);
    }

    function mint(uint256 quantity) external payable whenNotPaused nonReentrant {
        require(quantity > 0 && quantity <= 200);
        require(_totalMinted() + quantity <= MAX_SUPPLY);
        if (_numberMinted(msg.sender) == 0) {
            require((quantity - 1) * PRICE == msg.value);
        } else {
            require(quantity * PRICE == msg.value);
        }
        _safeMint(msg.sender, quantity);
    }

    // metadata URI
    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        if (!_revealed) return _baseTokenURI;
        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : '';
    }

    function reveal() external onlyOwner {
        require(!_revealed);
        _revealed = true;
    }

    function pause() external onlyOwner {
        _pause();
    }
    
    function unpause() external onlyOwner {
        _unpause();
    }

    function withdrawAssets() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{ value: address(this).balance, gas: 30_000 }(new bytes(0));
        require(success);
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function numberBurned(address owner) public view returns (uint256) {
        return _numberBurned(owner);
    }

    function getOwnershipData(uint256 tokenId) public view returns (TokenOwnership memory) {
        return _ownershipOf(tokenId);
    }

}