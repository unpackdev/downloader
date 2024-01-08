// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./Ownable.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721.sol";
import "./ERC721Burnable.sol";
import "./ERC721Enumerable.sol";
import "./SafeMath.sol";
import "./Counters.sol";
import "./Strings.sol";

contract Ethereality is
    ERC721,
    ERC721Enumerable,
    Pausable,
    Ownable,
    ERC721Burnable,
    ReentrancyGuard
{
    using SafeMath for uint256;
    using Strings for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    uint256 public tokenPrice;
    uint256 public maxPerMint;
    uint256 public maxSupply;
    string public baseURI;

    event MaxSupplyChanged(uint256 newMaxSupply);
    event MaxPerMintChanged(uint256 newMaxPerMint);
    event TokenMinted(uint256 indexed tokenId);

    constructor(
        uint256 _tokenPrice,
        uint256 _maxPerMint,
        uint256 _maxSupply,
        string memory _baseURI
    ) ERC721('Ethereality', 'ERL') {
        tokenPrice = _tokenPrice;
        maxPerMint = _maxPerMint;
        maxSupply = _maxSupply;
        baseURI = _baseURI;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function safeMint(address to, uint256 count) public payable nonReentrant {
        uint256 _totalMinted = _tokenIdCounter.current();
        require(_totalMinted < maxSupply, 'All tokens have been minted');
        require(_totalMinted + count <= maxSupply, 'Mint count would surpass max supply');
        require(count > 0, 'Must mint at least 1');
        require(count <= maxPerMint, 'Trying to mint too many tokens at once');
        require(msg.value >= tokenPrice.mul(count), 'Insufficient payment for requested token(s)');

        for (uint256 i = 0; i < count; i++) {
            _safeMintOne(to);
        }
    }

    function _safeMintOne(address _to) private {
        uint256 tokenId = _tokenIdCounter.current();
        _safeMint(_to, tokenId);
        _tokenIdCounter.increment();
        emit TokenMinted(tokenId);
    }

    function setMaxSupply(uint256 _maxSupply) public onlyOwner {
        maxSupply = _maxSupply;

        emit MaxSupplyChanged(maxSupply);
    }

    function setMaxPerMint(uint256 _maxPerMint) public onlyOwner {
        maxPerMint = _maxPerMint;
        emit MaxPerMintChanged(maxPerMint);
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    function getTotalMinted() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), 'URI query for nonexistent token');
        return string(abi.encodePacked(baseURI, tokenId.toString(), '.json'));
    }

    function walletOfOwner(address _owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokensId;
    }

    function withdrawAll() public payable onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);
        _widthdraw(owner(), address(this).balance);
    }

    function _widthdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}('');
        require(success, 'Withdraw transfer failed.');
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
