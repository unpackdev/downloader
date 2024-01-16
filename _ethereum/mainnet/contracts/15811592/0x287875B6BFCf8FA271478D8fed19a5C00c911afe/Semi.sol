// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";
import "./Counters.sol";

interface IRenderer {
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

contract Semi is ERC721, ERC721Enumerable, ERC721Burnable, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    uint8 public constant SIZE = 255;
    uint8 public constant SEMI_TYPES_NUM = 5;
    address[] public rendererAddresses;
    uint256 public rendererVersion = 1;
    mapping(uint256 => uint256) public desiredRendererVersions;
    mapping(uint256 => Individual) public semis;

    struct Individual {
        uint8 semiType;
        uint8 x;
        uint8 y;
    }

    constructor(address _rendererAddress) ERC721("Semi", "SEMI") {
        rendererAddresses.push(_rendererAddress);
    }

    function updateRenderer(address _rendererAddress) public onlyOwner {
        rendererAddresses.push(_rendererAddress);
        rendererVersion++;
    }

    function setRendererVersion(uint256 tokenId, uint256 version) public {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Semi: caller is not token owner nor approved");
        require(version <= rendererVersion, "Semi: invalid version");
        desiredRendererVersions[tokenId] = version;
    }

    function mint(address to) public {
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        semis[tokenId] = Individual(uint8(uint256(keccak256(abi.encodePacked(tokenId, blockhash(block.number)))) % SEMI_TYPES_NUM), 0, 0);
        _safeMint(to, tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
        semis[tokenId].x = uint8(uint256(keccak256(abi.encodePacked(tokenId, blockhash(block.number)))) % SIZE);
        semis[tokenId].y = uint8(uint256(keccak256(abi.encodePacked(tokenId + 1, blockhash(block.number)))) % SIZE);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
        if (desiredRendererVersions[tokenId] > 0) {
            return IRenderer(rendererAddresses[desiredRendererVersions[tokenId] - 1]).tokenURI(tokenId);
        }
        return IRenderer(rendererAddresses[rendererVersion - 1]).tokenURI(tokenId);
    }
}
