// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./ERC20.sol";
import "./Pausable.sol";
// import "./SafeMath.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract DiyPunks is ERC721, ERC721URIStorage, Pausable, Ownable {
    // using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    string public BASE_URI;
    uint256 public PRICE;

    constructor(string memory _baseUri, uint256 _price)
        ERC721("DiyPunks", "DIYP")
    {
        BASE_URI = _baseUri;
        PRICE = _price;
    }

    function _baseURI() internal view override returns (string memory) {
        return BASE_URI;
    }

    function updateBaseUri(string memory _baseUri) public onlyOwner {
        BASE_URI = _baseUri;
    }

    function updatePrice(uint256 _price) public onlyOwner {
        PRICE = _price;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function safeMint(address to, string memory uri) public payable {
        require(msg.value >= PRICE, "Not enough ether to purchase NFTs.");
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    function withdraw() external {
        uint256 balance = address(this).balance;
        require(balance > 0, "No ether left to withdraw");

        payable(owner()).transfer(balance);
    }

    function withdrawERC20(IERC20 _erc20Token) external {
        uint256 balance = _erc20Token.balanceOf(address(this));
        require(balance > 0, "No tokens left to withdraw");

        _erc20Token.transfer(owner(), balance);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
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
