// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Initializable.sol";
import "./Counters.sol";

contract NFT is Initializable, ERC721, ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    uint256 public cost;

    uint128 public maxPerTx;
    uint128 public maxMintAmount;
    uint256 public publicMintStartTime;

    string public baseURI;

    constructor(
        uint256 _cost,
        uint128 _maxPerTx,
        uint128 _maxMintAmount,
        uint256 _mintStart
    ) ERC721("Noodle Doods", "NOODLEDOODS") {
        publicMintStartTime = _mintStart;
        cost = _cost;
        maxMintAmount = _maxMintAmount;
        maxPerTx = _maxPerTx;
    }

    /////////////////////////////////////////////////////////////
    // MINTING
    /////////////////////////////////////////////////////////////
    function mint(uint256 _mintAmount) public payable {
        uint256 supply = _tokenIdCounter.current();
        require(_mintAmount > 0, "amount must be >0");
        require(_mintAmount <= maxPerTx, "amount must < max");
        require(supply + _mintAmount <= maxMintAmount, "sold out!");

        if (msg.sender != owner()) {
            require(block.timestamp > publicMintStartTime, "mint locked");
            require(msg.value >= cost * _mintAmount, "no funds");
        }


        for (uint256 i = 1; i <= _mintAmount; i++) {
            _tokenIdCounter.increment();
            uint256 tokenId = _tokenIdCounter.current();
            _mint(msg.sender, tokenId);
        }
    }

    function safeMint(address to) public onlyOwner {
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        _safeMint(to, tokenId);
    }

    /////////////////////////////////////////////////////////////
    // ADMIN
    /////////////////////////////////////////////////////////////
    function withdraw() public onlyOwner {
        require(
            payable(owner()).send(address(this).balance),
            "could not withdraw"
        );
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setPublicMintStartTime(uint88 _time) public onlyOwner {
        publicMintStartTime = _time;
    }

    function setBaseURI(string memory _uri) public onlyOwner {
        baseURI = _uri;
    }

    function setCost(uint256 _cost) public onlyOwner {
        cost = _cost;
    }

    function setMaxMintAmount(uint128 _amount) public onlyOwner {
        maxMintAmount = _amount;
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
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
