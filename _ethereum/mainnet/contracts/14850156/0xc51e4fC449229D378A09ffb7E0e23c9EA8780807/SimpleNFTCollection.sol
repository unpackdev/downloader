// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./NFTCollectionPausableMint.sol";
import "./NFTCollectionMutableParams.sol";

contract SimpleNFTCollection is
    NFTCollectionPausableMint,
    NFTCollectionMutableParams
{
    constructor(
        string memory _name,
        string memory _symbol,
        string memory _notRevealedUri,
        uint256 _cost,
        uint256 _maxSupply,
        uint256 _maxMintAmount,
        address _owner
    )
        NFTCollection(
            _name,
            _symbol,
            _notRevealedUri,
            _cost,
            _maxSupply,
            _maxMintAmount,
            _owner
        )
    {}

    function _mintAmount(uint256 _amount)
        internal
        override(NFTCollection, NFTCollectionPausableMint)
    {
        NFTCollectionPausableMint._mintAmount(_amount);
    }
}
