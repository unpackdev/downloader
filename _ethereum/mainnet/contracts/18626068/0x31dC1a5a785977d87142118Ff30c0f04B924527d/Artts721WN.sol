// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./ERC721Drop.sol";
import "./Logion.sol";

contract Artts721WN is ERC721Drop, Logion {
    constructor(
        string memory _name,
        string memory _symbol,
        address _royaltyRecipient,
        uint128 _royaltyBps,
        address _primarySaleRecipient,
        //string memory _nonce,
        string memory _collectionLocId,
        string memory _certHost
    )
        ERC721Drop(
            _name,
            _symbol,
            _royaltyRecipient,
            _royaltyBps,
            _primarySaleRecipient
        )

        Logion(
            "",
            _collectionLocId, // The collection LOC ID
            _certHost // The domain for building a logion certificate URL
        )
    {

    }
}