// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./Ownable.sol";
import "./Pausable.sol";
import "./ERC721A.sol";

contract MapleLeaf is Ownable, Pausable, ERC721A {
    using Strings for uint256;

    address constant public TEAM = 0x37CDAce99029F61cAcC44Edbb9Bac786cAFdEb9f;
    uint256 constant public MAX_SUPPLY = 7534;
    uint256 constant public TEAM_RESERVE = 750;
    string private _baseTokenURI;
    bool private _revealed;

    constructor() ERC721A("MapleLeaf", "ML") {
        _baseTokenURI = "ipfs://QmWq3MDure6AstCXAZJwJhGAUbvMstidFC4bGJrzEoReeC";
        _team_mint();
        _pause();
    }

    function _team_mint() private {
        _safeMint(TEAM, TEAM_RESERVE);
    }

    function mint_as_prize(address to, uint256 quantity) public onlyOwner {
        require(_totalMinted() + quantity <= MAX_SUPPLY);
        _safeMint(to, quantity);
    }

    function mint() public whenNotPaused {
        require(_totalMinted() < MAX_SUPPLY);
        require(_numberMinted(msg.sender) == 0);
        _safeMint(msg.sender, 1);
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

    function reveal() public onlyOwner {
        require(!_revealed);
        _revealed = true;
    }

    function pause() public onlyOwner {
        _pause();
    }
    
    function unpause() public onlyOwner {
        _unpause();
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