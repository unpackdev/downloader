// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721AQueryable.sol";

/**
 * @title MocGenesis
 * MocGenesis - ERC721 contract for MOC collection.
 */
contract WeverseGenesis is ERC721AQueryable, Ownable {
    string public baseTokenURI;
    uint256 public immutable maxTotalSupply = 100;
    
    constructor() ERC721A("Weverse Genesis", "WEVERSE") {}

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseTokenURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function adminMint(uint256 _amount, address _to) public onlyOwner {
        require(_amount>=1, "amount error");
        require(_amount<=maxTotalSupply, "amount exceed");
        require((totalSupply() + _amount) <= maxTotalSupply, "not enough tokens");

        _safeMint(_to, _amount);
    }
}
