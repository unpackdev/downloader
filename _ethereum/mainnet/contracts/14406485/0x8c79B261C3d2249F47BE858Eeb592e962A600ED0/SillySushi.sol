//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ItemERC721.sol";

contract SillySushi is ItemERC721 {
   
    constructor(
        address _openSeaProxyRegistryAddress,
        uint256 _maxSupply,
        uint256 _maxPresaleSupply,
        string memory _name,
        string memory _symbol,
        string memory _uri,
        uint256 _publicSalePrice,
        uint256 _presalePrice,
        uint256 _maxItemsPerWallet,
        uint256 _maxItemsPerTxn
    ) ItemERC721(
         _openSeaProxyRegistryAddress,
         _maxSupply,
         _maxPresaleSupply,
         _name,
         _symbol,
         _uri,
         _publicSalePrice,
         _presalePrice,
         _maxItemsPerWallet,
         _maxItemsPerTxn
    ){}

}