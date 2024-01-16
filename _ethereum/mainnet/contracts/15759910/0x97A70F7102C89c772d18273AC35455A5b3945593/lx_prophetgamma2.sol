// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./ReentrancyGuard.sol";

interface Prophetgamma {
    function balanceOf(address) external view returns (uint256);
}

contract PGGameCard is ERC721, ERC721Enumerable, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private currentTokenId;

    string public baseTokenURI;
    uint256 public maxSupply;
    bool public paused = false;
    Prophetgamma pg;

    constructor(
        uint256 _maxSupply,
        string memory _baseTokenURI,
        address pgAddress,
        address[] memory addresses
    ) ERC721('PGGameCard', 'PGGameCard') {
        maxSupply = _maxSupply;
        baseTokenURI = _baseTokenURI;
        pg = Prophetgamma(pgAddress);
        airDrop(addresses);
    }

    modifier pausedMintCompliance() {
        require(!paused, 'contract is paused');
        _;
    }

    function mint(address to) public payable pausedMintCompliance {
        require(balanceOf(to) < 5, 'address can not mint more than 5 times');
        require(totalSupply() < maxSupply, 'max supply exceeded');
        if (pg.balanceOf(to) > 0 && balanceOf(to) >= 1) {
            require(0.006 ether == msg.value, 'ether value you sent not correct, own Prophetgamma');
        }
        if (pg.balanceOf(to) == 0) {
            require(0.006 ether == msg.value, 'ether value you sent not correct, not own Prophetgamma');
        }
        currentTokenId.increment();
        uint256 itemId = currentTokenId.current();
        _safeMint(to, itemId);
    }

    function airDrop(address[] memory addresses) public onlyOwner {
        require(totalSupply() < maxSupply, 'max supply exceeded');
        for (uint256 i = 0; i < addresses.length; i++) {
           currentTokenId.increment();
           uint256 itemId = currentTokenId.current();
           _safeMint(addresses[i], itemId);
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, Strings.toString(tokenId), '.json')) : '';
    }

    function setBaseTokenURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function setPaused(bool _paused) public onlyOwner {
        paused = _paused;
    }

    function withdraw() public onlyOwner nonReentrant {
        (bool os, ) = payable(owner()).call{value: address(this).balance}('');
        require(os);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
