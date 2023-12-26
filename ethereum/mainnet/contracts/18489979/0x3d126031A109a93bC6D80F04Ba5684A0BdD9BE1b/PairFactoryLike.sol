// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./ICurve.sol";
import "./LSSVMPair.sol";
import "./ERC20.sol";

interface PairFactoryLike {
    function isValidPair(address pairAddress) external view returns (bool);

    function createPairERC721ETH(
        IERC721 _nft,
        ICurve _bondingCurve,
        address payable _assetRecipient,
        LSSVMPair.PoolType _poolType,
        uint128 _delta,
        uint96 _fee,
        uint128 _spotPrice,
        address _propertyChecker,
        uint256[] calldata _initialNFTIDs
    ) external payable returns (LSSVMPair pair);

    struct CreateERC721ERC20PairParams {
        ERC20 token;
        IERC721 nft;
        ICurve bondingCurve;
        address payable assetRecipient;
        LSSVMPair.PoolType poolType;
        uint128 delta;
        uint96 fee;
        uint128 spotPrice;
        address propertyChecker;
        uint256[] initialNFTIDs;
        uint256 initialTokenBalance;
    }

    function createPairERC721ERC20(CreateERC721ERC20PairParams calldata params) external returns (LSSVMPair pair);
}
