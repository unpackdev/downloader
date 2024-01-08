// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./ERC721Enumerable.sol";
import "./AccessControl.sol";

contract BigFanMinter is ERC721Enumerable, ERC721URIStorage, AccessControl {

    bytes32 public constant WITHDRAW_ROLE = keccak256("WITHDRAW_ROLE");

    constructor() ERC721("BIG FAN GENESIS COLLECTION", "BFT") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    bool public saleStarted = true;

    mapping(string => TokenUri) public approvedUris;

    mapping (string => Drop) public drops;

    struct TokenUri{
        bool approved;
        bool minted;
    }

    struct Drop {
        uint256 token_price;
        bool active;
    }

    modifier isApprovedTokenURI(string memory _tokenURI) {
        require(approvedUris[_tokenURI].approved == true, "The token is not approved");
        require(approvedUris[_tokenURI].minted == false, "The token has been minted");
        _;
    }

    function mint(address _buyer, string memory _tokenURI, string memory drop) public payable isApprovedTokenURI(_tokenURI) returns (uint256)
    {
        require(drops[drop].active == true, "The drop is not active or does not exist");
        require(drops[drop].token_price == msg.value, "The price is incorrect");
        require(saleStarted == true, "The sale is paused");

        uint256 newItemId = totalSupply() + 1;

        _safeMint(_buyer, newItemId);
        _setTokenURI(newItemId, _tokenURI);

        approvedUris[_tokenURI].minted = true;

        emit PermanentURI(_tokenURI, newItemId);

        emit TokenMinted(newItemId);

        return newItemId;
    }

    function burn(uint256 _tokenId) public onlyRole(DEFAULT_ADMIN_ROLE) returns (bool)
    {
        _burn(_tokenId);
        return true;
    }

    function approveTokenURI(string memory _tokenURI) public onlyRole(DEFAULT_ADMIN_ROLE)  returns(bool success) {
        approvedUris[_tokenURI].approved = true;
        approvedUris[_tokenURI].minted = false;
        return true;
    }

    function startDrop(string memory name, uint256 price) public onlyRole(DEFAULT_ADMIN_ROLE) returns(bool success) {
        drops[name].active = true;
        drops[name].token_price = price;
        return true;
    }

    function pauseDrop(string memory name) public onlyRole(DEFAULT_ADMIN_ROLE) returns(bool success) {
        drops[name].active = false;
        return true;
    }

    function startSale() public onlyRole(DEFAULT_ADMIN_ROLE) {
        saleStarted = true;
    }

    function pauseSale() public onlyRole(DEFAULT_ADMIN_ROLE) {
        saleStarted = false;
    }

    function withdraw() public payable onlyRole(WITHDRAW_ROLE) {
        require(payable(msg.sender).send(address(this).balance));
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, amount);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, AccessControl, ERC721Enumerable) returns (bool) {
       return super.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
       return super.tokenURI(tokenId);
    }

    event PermanentURI(string _value, uint256 indexed _id);

    event TokenMinted(uint256 tokenId);

}