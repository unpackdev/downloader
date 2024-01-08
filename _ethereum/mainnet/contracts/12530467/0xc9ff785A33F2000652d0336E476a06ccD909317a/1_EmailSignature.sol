// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";

contract EmailSignature is ERC721
 {

    string private ipfsLocation = "ipfs://Qmd51uzME5WnQF1ZLBnsBjdh72hGBwG9EDFCapXQyv2igR";

    event Mint(address indexed owner, uint indexed _tokenId);

    constructor() payable ERC721("EmailSignature", "ES") {
      _mint(0x10B16eEDe03cF73CbF44e4BFFFa3e6BFf36F1Fad, 1337);
      emit Mint(0x10B16eEDe03cF73CbF44e4BFFFa3e6BFf36F1Fad, 1337);
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
      require(_tokenId == 1337);
      return ipfsLocation;
    }

}