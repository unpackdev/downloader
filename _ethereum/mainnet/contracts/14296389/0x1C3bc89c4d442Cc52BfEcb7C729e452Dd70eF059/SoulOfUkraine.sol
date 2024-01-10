// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./IERC721Enumerable.sol";
import "./ERC721Enumerable.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract SoulOfUkraine is ERC721Enumerable, Ownable {
    using Strings for uint256;
    using SafeMath for uint256;

    string private _rootURI;

    uint256 public cost = 0.03 ether;
    uint256 public maxSupply = 5000;
    bool public isSaleActive = true;
    

    constructor() ERC721("Soul of Ukraine", "SUA") {}

    function mint(uint256 _mintAmount) public payable {
        require(!isSaleActive, "Sale is not active");
        uint256 supply = totalSupply();
        require(_mintAmount > 0, "You must mint at least 1 NFT");
        require(supply + _mintAmount <= maxSupply, "max NFT limit exceeded");
        require(msg.value >= cost * _mintAmount, "insufficient funds");

        for (uint256 i = 1; i <= _mintAmount; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    function flipSaleStatus() public onlyOwner {
        isSaleActive = !isSaleActive;
    }

    function setBaseURI(string memory uri) external onlyOwner {
        _rootURI = uri;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _rootURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "Token ID not valid");
        require(bytes(_rootURI).length > 0, "Base URI not yet set");
        return string(abi.encodePacked(_baseURI(), tokenId.toString()));
    }

    function withdraw() public payable onlyOwner {
    (bool success, ) = payable(0x165CD37b4C644C2921454429E7F9358d18A45e14).call{value: address(this).balance}("");
    require(success, "Withdrawal of funds failed");
  }
}
