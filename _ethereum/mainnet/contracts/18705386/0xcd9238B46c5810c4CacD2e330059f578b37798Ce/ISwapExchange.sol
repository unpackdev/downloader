// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.21;

import "./SwapUtils.sol";

interface ISwapExchange {

    event SwapCreated (uint256 indexed swapId, address indexed maker, address tokenA, address tokenB, uint256 amountA, uint256 amountB, uint8 feeType, uint32 start, uint32 expiration, bool partialSwap);
    event SwapClaimed (uint256 indexed swapId, address indexed claimant, uint256 amountA, uint256 amountB, uint256 fee, uint8 feeType);
    event SwapPartialClaimed (uint256 indexed swapId, address indexed claimant, uint256 amountA, uint256 amountB, uint256 fee, uint8 feeType);
    event SwapMultiClaimed (address indexed taker, address tokenA, address tokenB, uint256 amountA, uint256 amountB, uint256 fee, uint8 feeType);
    event SwapCancelled (uint256 indexed swapId);

    function getSwap(uint256 swapId) external view returns (SwapUtils.Swap memory);

    function getMaxHops() external view returns (uint256);

    function getMaxSwaps() external view returns (uint256);

    function getFixedFee() external view returns (uint256);

    function getFeeValues() external view returns (uint256[2] memory feeValues);

    function getFeeTokens() external view returns (address[] memory);

    function createSwap(
        address tokenA,
        address tokenB,
        uint256 amountA,
        uint256 amountB,
        uint32 duration,
        bool partialSwap) external payable returns (bool);

    function calculateFeeType(address tokenA, address tokenB) external view returns (uint8 feeType, address feeToken);

    function calculateSwapA(uint256 swapId, uint256 netAmountA) external view returns (SwapUtils.SwapCalculation memory);

    function calculateSwapNetB(uint256 swapId, uint256 netAmountB) external view returns (SwapUtils.SwapCalculation memory);

    function calculateSwapGrossB(uint256 swapId, uint256 grossAmountB) external view returns (SwapUtils.SwapCalculation memory);

    function calculateCompleteSwap(uint256 swapId) external view returns (SwapUtils.SwapCalculation memory);

    function calculateSwaps(SwapUtils.ClaimInput[] calldata claimInputs) external view returns (SwapUtils.SwapCalculation[] memory, uint256);

    function calculateMultiSwap(SwapUtils.MultiClaimInput calldata multiClaimInput) external view returns (SwapUtils.SwapCalculation memory);

    function claimSwap(uint256 swapId, uint256 amountA, uint256 amountB) external payable returns (bool);

    function claimSwaps(SwapUtils.Claim[] calldata claims) external payable returns (bool);

    function claimMultiSwap(SwapUtils.MultiClaim calldata multiClaim) external payable returns (bool);

    function cancelSwap(uint256 swapId) external payable returns (bool);

    function expireSwap(uint256 swapId) external;

    function recoverSwaps(address token, uint256[] calldata swapIds, address recoveryAddress) external payable;

}

