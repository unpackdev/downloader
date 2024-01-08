// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./Ownable.sol";
import "./ERC1155Supply.sol";

contract ChumverseMintpass is ERC1155Supply, Ownable   {

    bool public saleIsActive = false;
    bool public WLSaleIsActive = false;
    uint private _tokenId = 420;
    uint constant MAX_TOKENS = 4200;
    uint constant TOKEN_PRICE = 0.069 ether;
    mapping(address => uint8) private _allowList;

    constructor(string memory uri) ERC1155(uri) {
    }

    function setSaleState(bool newState) public onlyOwner {
        saleIsActive = newState;
    }

    function setWLSaleState(bool newState) public onlyOwner {
        WLSaleIsActive = newState;
    }

    function setAllowList(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            _allowList[addresses[i]] = 2;
        }
    }

    function numAvailableToMint(address addr) public view returns (uint8) {
        return _allowList[addr];
    }

    function mintAllowList(uint8 numberOfTokens) public payable {
        require(WLSaleIsActive, "Sale must be active to mint Tokens");
        require(totalSupply(_tokenId) + numberOfTokens <= MAX_TOKENS, "Purchase would exceed max supply of tokens");
        require(numberOfTokens > 0 && numberOfTokens <=2, "You can mint minimum 1, maximum 2 Tokens");
        require(msg.value >= TOKEN_PRICE * numberOfTokens, "Ether value sent is below the price");
        _allowList[msg.sender] -= numberOfTokens;
        _mint(msg.sender, _tokenId, numberOfTokens, "");
    }

    function mint(uint numberOfTokens) public payable {
        require(saleIsActive, "Sale must be active to mint Tokens");
        require(totalSupply(_tokenId) + numberOfTokens <= MAX_TOKENS, "Purchase would exceed max supply of tokens");
        require(numberOfTokens > 0 && numberOfTokens <= 2, "You can mint minimum 1, maximum 2 Tokens");
        require(msg.value >= TOKEN_PRICE * numberOfTokens, "Ether value sent is below the price");
        _mint(msg.sender, _tokenId, numberOfTokens, "");

    }

    function reserveAirdrop() public onlyOwner {
        require(totalSupply(_tokenId) + 30 <= MAX_TOKENS, "Purchase would exceed max supply of tokens");
        _mint(msg.sender, _tokenId, 30, "");
    }

    function withdrawAll() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

}
