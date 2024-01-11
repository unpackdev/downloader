// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "ERC721.sol";
import "ERC721Enumerable.sol";
import "ERC721URIStorage.sol";
import "Pausable.sol";
import "Ownable.sol";
import "Counters.sol";
import "SafeMath.sol";

contract FuckTheIRS is
    ERC721,
    ERC721Enumerable,
    Pausable,
    Ownable,
    ERC721URIStorage
{
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    address public constant multiSigAddress = 0xA34A7f45B33cb6D4f001db81E1219062ec8d3300;
    address public constant nullAddress = 0x0000000000000000000000000000000000000000;
    address public winnerAddress = 0x0000000000000000000000000000000000000000;
    bool public isPaused = false;
    uint256 public winnerID = 42069;
    uint256 public constant maxSupply = 3700;

    Counters.Counter private _tokenIdCounter;

    constructor() ERC721("FuckTheIRS", "FuckYou") {}

    function announceWinner() public onlyOwner {
        require(winnerID == 42069, "Winner already selected. FuckTheIRS!");
        winnerID = uint256(
            keccak256(
                abi.encodePacked(
                block.coinbase,
                block.difficulty,
                block.gaslimit,
                block.timestamp
                )
            )
        ) % totalSupply();
        winnerAddress = ownerOf(winnerID);
        pause();
        withdrawAll();
    }

    function pause() private {
        isPaused = true;
        _pause();
    }

    function safeMint(address to, string memory uri)
        public
        payable
        returns (string memory)
    {
        require(isPaused == false, "Minting permanently disabled. FuckTheIRS!");
        require(totalSupply() < maxSupply, "We've minted out. FuckTheIRS!");
        require(msg.value >= 0.0418 ether, "Not enough ETH sent: check price. FuckTheIRS!");
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
        return uri;
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
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

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function setTokenURI(uint256 _tokenId, string memory _tokenURI)
        public
        onlyOwner
    {
        _setTokenURI(_tokenId, _tokenURI);
    }

    function withdrawAll() private {
        uint256 balance = address(this).balance;
        require(balance > 0);
        require(winnerAddress != nullAddress, "Winner address cannot be null address. FuckTheIRS!");
        _widthdraw(winnerAddress, balance.mul(50).div(100));
        _widthdraw(multiSigAddress, address(this).balance.mul(98).div(100));
    }

    function _widthdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed. FuckTheIRS!");
    }
}
