// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";

contract BUNSLANDOlympus is ERC721, ERC721Enumerable, ERC721Burnable, Ownable {
    address private bank = 0xD888FE1bF64168be5fD94f329872B911E629f75c;
    bool public hasSaleStarted = false;
    uint256 public constant bunPrice = 2.4 ether;
    uint public constant MAX_SALE = 12;
    mapping(uint256 => bool) public minted;

    constructor() ERC721("BUNS.LAND Olympus", "BLO2") {}

    function safeMint(address to, uint256 tokenId) public payable {
        require(hasSaleStarted, "Sale has not started.");
        require(msg.value >= bunPrice, "Not enough ETH sent; check price!");
        require(isSoldOut(tokenId) == false, "SOLD OUT.");

        _safeMint(to, tokenId);
        minted[tokenId] = true;
    }

    function isSoldOut(uint256 tokenId) public view returns(bool) {
        return minted[tokenId] == true || tokenId > MAX_SALE || tokenId < 1;
    }

    function startSale() public onlyOwner {
        hasSaleStarted = true;
    }

    function stopSale() public onlyOwner {
        hasSaleStarted = false;
    }

    function _baseURI() internal pure override returns (string memory) {
        return "https://nfts.buns.land/blo2/";
    }

    function walletOfOwner(address _owner) public view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function withdraw() public onlyOwner {
        uint256 _balance = address(this).balance;

        require(payable(bank).send(_balance));
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
    internal
    override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721, ERC721Enumerable)
    returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
