// contracts/DyamineDynamicNft.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./DyamineStandardNft.sol";

//
//  DDDDDDD      EEEEEEEEEEEE
//  DD   DDD
//  DD     DD
//  DD       D   EEEEEEEEEEEE
//  DD     DD    EE
//  DD    DDD    EE
//  DDDDDDD      EEEEEEEEEEEE
//
// DYAMINE
// [https://dyamine.com]
//
// Dynamic ERC-721 Smart Contract with support for
// future items in the collection.
//

contract DyamineDynamicNft is DyamineStandardNft {
    constructor(
        string memory _name,
        string memory _symbol,
        uint256 totalSupply,
        string memory baseUri,
        address openSeaProxyAddress,
        address raribleProxyAddress
    )
        DyamineStandardNft(
            _name,
            _symbol,
            totalSupply,
            baseUri,
            openSeaProxyAddress,
            raribleProxyAddress
        )
    {}

    function addItems(string memory newBaseUrl, uint256 newTotalSupply)
        public
        onlyOwner
    {
        require(
            newTotalSupply > _totalSupply,
            "Dyamine ERC721: Must provide more items in collection"
        );

        setBaseUri(newBaseUrl);

        for (uint256 i = _totalSupply; i < newTotalSupply; i++) {
            emit Transfer(address(0), owner(), i);
        }

        _totalSupply = newTotalSupply;
    }
}
