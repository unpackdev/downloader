pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";

contract AvatarNFT is ERC721A, Ownable {
    mapping(uint256 => string) public tokenUriHash;

    constructor() ERC721A("Avatar NFT", "AVATAR") {}

    function mint(address to, uint256 quantity) external onlyOwner {
        _safeMint(to, quantity);
    }

    string private _baseTokenURI;

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }
}
