// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./SafeMath.sol";

contract Octoplush is
    ERC721,
    ERC721URIStorage,
    ERC721Enumerable,
    Pausable,
    Ownable
{
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    string private _baseURIPrefix;

    bool public hasPresaleStarted = false;
    uint256 public constant MAX_PRESALE = 500;

    uint256 private constant maxTokensPerTransaction = 28;
    uint256 private tokenPrice = 60000000000000000; //0.06 ETH
    uint256 public constant nftsNumber = 8008;
    uint256 private constant nftsPublicNumber = 7958; // 50 for giveaways and promotions

    Counters.Counter private _tokenIdCounter;

    event Giveaway(address to, uint256 tokensNumber);

    constructor() ERC721("Octoplush", "OCTO") {
        _tokenIdCounter.increment();
    }

    function setPrice(uint256 newPrice) public onlyOwner {
        tokenPrice = newPrice;
    }

    function getTokenPrice() public view returns (uint256) {
        return tokenPrice;
    }

    function _totalSupply() internal view returns (uint256) {
        return _tokenIdCounter.current();
    }

    function totalMint() public view returns (uint256) {
        return _totalSupply();
    }

    function setBaseURI(string memory baseURIPrefix) public onlyOwner {
        _baseURIPrefix = baseURIPrefix;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseURIPrefix;
    }

    function getAssetsByOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }

    function getMyAssets() external view returns (uint256[] memory) {
        return getAssetsByOwner(tx.origin);
    }

    function safeMint(address to) public onlyOwner {
        _safeMint(to, _tokenIdCounter.current());
        _tokenIdCounter.increment();
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function startPresale() public onlyOwner {
        hasPresaleStarted = true;
    }

    function pausePresale() public onlyOwner {
        hasPresaleStarted = false;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);
    }

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

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function directMint(address to, uint256 tokenId) public onlyOwner {
        require(
            tokenId > nftsNumber,
            "Tokens number to mint must exceed number of total tokens"
        );
        _safeMint(to, tokenId);
    }

    function giveaway(address to, uint256 tokensNumber) external onlyOwner {
        require(
            _tokenIdCounter.current().add(tokensNumber) <= nftsNumber,
            "Tokens number to mint exceeds number of total tokens"
        );
        for (uint256 i = 0; i < tokensNumber; i++) {
            _safeMint(to, _tokenIdCounter.current());
            _tokenIdCounter.increment();
        }
        emit Giveaway(to, tokensNumber);
    }

    function buyOctos(uint256 tokensNumber) public payable whenNotPaused {
        require(tokensNumber > 0, "Wrong amount");
        require(
            tokensNumber <= maxTokensPerTransaction,
            "Max tokens per transaction number exceeded"
        );
        require(
            _tokenIdCounter.current().add(tokensNumber) <= nftsPublicNumber,
            "Tokens number to mint exceeds number of public tokens"
        );
        require(
            tokenPrice.mul(tokensNumber) <= msg.value,
            "Ether value sent is too low"
        );

        for (uint256 i = 0; i < tokensNumber; i++) {
            _safeMint(msg.sender, _tokenIdCounter.current());
            _tokenIdCounter.increment();
        }
    }

    function mintPresaleOctos(uint256 tokensNumber) public payable {
        require(hasPresaleStarted, "Presale has not started");
        require(tokensNumber > 0, "Wrong amount");
        require(totalSupply() <= MAX_PRESALE, "Presale has already ended");
        require(
            tokensNumber <= maxTokensPerTransaction,
            "Max tokens per transaction number exceeded"
        );
        require(
            _tokenIdCounter.current().add(tokensNumber) <= MAX_PRESALE,
            "Exceeds MAX_PRESALE"
        );
        require(
            tokenPrice.mul(tokensNumber) <= msg.value,
            "Ether value sent is too low"
        );
        for (uint256 i = 0; i < tokensNumber; i++) {
            _safeMint(msg.sender, _tokenIdCounter.current());
            _tokenIdCounter.increment();
        }
    }
}
