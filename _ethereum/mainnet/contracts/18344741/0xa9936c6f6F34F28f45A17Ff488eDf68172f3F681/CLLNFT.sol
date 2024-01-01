// SPDX-License-Identifier: GPL-3.0
import "./Ownable.sol";
import "./ERC721.sol";

pragma solidity >=0.7.0 <0.9.0;

contract CLLNFT is Ownable, ERC721{

    string private _baseTokenURI;
 
    constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) {
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata newBaseTokenURI) public onlyOwner{
        _baseTokenURI = newBaseTokenURI;
    }

    function baseURI() public view returns (string memory) {
        return _baseURI();
    }

    function safeMint(address to, uint256 tokenId) external{
      _safeMint(to, tokenId);
    }

    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    function burn(uint256 tokenId) external{
      require(_exists(tokenId), "Non existent token");
      require(_isApprovedOrOwner(msg.sender, tokenId), "Forbidden");
      _burn(tokenId);
    }

}
