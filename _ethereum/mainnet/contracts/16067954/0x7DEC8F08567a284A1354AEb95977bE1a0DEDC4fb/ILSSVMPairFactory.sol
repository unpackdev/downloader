// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./ICurve.sol";
import "./ILSSVMPair.sol";

interface ILSSVMPairFactory {
    function createPairETH(
        IERC721 _nft,
        ICurve _bondingCurve,
        address payable _assetRecipient,
        ILSSVMPair.PoolType _poolType,
        uint128 _delta,
        uint96 _fee,
        uint128 _spotPrice,
        uint256[] calldata _initialNFTIDs
    ) external payable returns (ILSSVMPairETH pair);
}
