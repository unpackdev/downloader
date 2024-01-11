// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./Strings.sol";

contract Dots is ERC721, ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    uint256 public constant MAX_DOTS = 5000;
    string public constant DESCRIPTION =
        "Modern dots from modern palettes. Inspired by modern art and design.";

    uint256 public price = 0.01 ether;

    Counters.Counter private _tokenIdCounter;
    string private _base;
    mapping(uint256 => bytes32) public tokenIdToHash;
    mapping(bytes32 => uint256) public hashToTokenId;

    constructor(string memory initUrl) ERC721("Mod Dots", "DOTS") {
        _tokenIdCounter.increment();
        _base = initUrl;
    }

    function _mint(address destination) private {
        uint256 tokenId = _tokenIdCounter.current();
        require(tokenId <= MAX_DOTS, "SOLD_OUT");
        bytes32 _hash = keccak256(
            abi.encodePacked(
                tokenId,
                block.number,
                blockhash(block.number - 1),
                msg.sender
            )
        );
        _safeMint(destination, tokenId);
        tokenIdToHash[tokenId] = _hash;
        hashToTokenId[_hash] = tokenId;
        _tokenIdCounter.increment();
    }

    function setBaseURI(string memory base) public onlyOwner {
        _base = base;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _base;
    }

    function ownerMint(address destination) public payable virtual onlyOwner {
        _mint(destination);
    }

    function mint() public payable virtual {
        require(msg.value >= price, "PRICE_NOT_MET");
        _mint(msg.sender);
    }

    function mintForFriend(address walletAddress) public payable virtual {
        require(msg.value >= price, "PRICE_NOT_MET");
        _mint(walletAddress);
    }

    function withdrawAll() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
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
