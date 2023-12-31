// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.18;
pragma abicoder v2;

import "./DefinitiveAssets.sol";

// https://polygonscan.com/address/0x45A01E4e04F14f7A4a6702c74187c5F6222033cd#code
interface IStargateRouter {
    // solhint-disable-next-line contract-name-camelcase
    struct lzTxObj {
        uint256 dstGasForCall;
        uint256 dstNativeAmount;
        bytes dstNativeAddr;
    }

    function addLiquidity(uint256 _poolId, uint256 _amountLD, address _to) external;

    function swap(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLD,
        uint256 _minAmountLD,
        lzTxObj memory _lzTxParams,
        bytes calldata _to,
        bytes calldata _payload
    ) external payable;

    function redeemRemote(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLP,
        uint256 _minAmountLD,
        bytes calldata _to,
        lzTxObj memory _lzTxParams
    ) external payable;

    function instantRedeemLocal(uint16 _srcPoolId, uint256 _amountLP, address _to) external returns (uint256);

    function redeemLocal(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLP,
        bytes calldata _to,
        lzTxObj memory _lzTxParams
    ) external payable;

    function sendCredits(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress
    ) external payable;

    function quoteLayerZeroFee(
        uint16 _dstChainId,
        uint8 _functionType,
        bytes calldata _toAddress,
        bytes calldata _transferAndCallPayload,
        lzTxObj memory _lzTxParams
    ) external view returns (uint256, uint256);
}

//https://optimistic.etherscan.io/address/0xB49c4e680174E331CB0A7fF3Ab58afC9738d5F8b#code
interface IRouterETH {
    // solhint-disable-next-line contract-name-camelcase
    function addLiquidityETH() external payable;
}

interface ILPStaking {
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
    }

    function userInfo(uint256 _pid, address _user) external view returns (UserInfo memory);

    function deposit(uint256 _pid, uint256 _amount) external;

    function withdraw(uint256 _pid, uint256 _amount) external;
}

// https://polygonscan.com/address/0x8731d54E9D02c286767d56ac03e8037C07e01e98#code
interface ILPStakingSTG {
    function stargate() external view returns (IERC20);

    function pendingStargate(uint256 _pid, address _user) external view returns (uint256);
}

// https://optimistic.etherscan.io/address/0x4DeA9e918c6289a52cd469cAC652727B7b412Cd2#code
interface ILPStakingEmissionToken {
    function eToken() external view returns (IERC20);

    function pendingEmissionToken(uint256 _pid, address _user) external view returns (uint256);
}

interface IStargateLPToken {
    function deltaCredit() external view returns (uint256);
}
