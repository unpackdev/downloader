//Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721](https://docs.openzeppelin.com/contracts/3.x/erc721)
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";

contract LibraryOfBabelNFT is ERC721 {

    constructor() public ERC721("BabelNFT", "babeloon") {}

    function mintNFT(address recipient, bytes32 b32hash)
        public // anyone can mint
        returns (uint256)
    {
        uint256 uint256hash = uint256(b32hash);
        _mint(recipient, uint256hash);
        return uint256hash;
    }

}
