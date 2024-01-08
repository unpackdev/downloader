//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC721.sol";
import "./ERC721Burnable.sol";
import "./ERC721Enumerable.sol";
import "./Strings.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./Counters.sol";

contract PenguinMugs is Ownable, ERC721Burnable, ERC721Enumerable {
    event RedeemMug(address indexed owner, uint256 indexed tokenId);

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdTracker;

    uint256 public constant MAX_MUGS = 8888;
    uint256 public constant MINT_FEE = .01 ether;
    string public constant IPFS_URL =
        "https://cryptomugs.mypinata.cloud/ipfs/QmTPS6B5GXWVLKLJqMVgUoXz4z8UtCswHHHZ9p37AKNpFu/";
    string private _baseTokenURI = IPFS_URL;
    address private constant PENGUINS_ADDRESS =
        0xBd3531dA5CF5857e7CfAA92426877b022e612cf8;
    ERC721 private _penguins = ERC721(PENGUINS_ADDRESS);

    constructor() ERC721("Penguin Mugs", "PMUGS") {}

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
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
    ) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function withdraw() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function mint() public payable {
        uint256 nextId = _tokenIdTracker.current();
        require(nextId < MAX_MUGS, "Mint is over");
        require(msg.value >= MINT_FEE, "price is too low");
        _safeMint(msg.sender, nextId);
        _tokenIdTracker.increment();
    }

    function redeem(uint256 tokenId) public {
        require(
            _penguins.ownerOf(tokenId) == msg.sender,
            "Must own penguin to redeem"
        );
        _burn(tokenId);
    }
}
