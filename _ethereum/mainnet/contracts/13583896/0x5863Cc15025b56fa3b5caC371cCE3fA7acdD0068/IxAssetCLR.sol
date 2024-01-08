// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.6;
pragma abicoder v2;

import "./IERC20.sol";

/**
 * xAssetCLR Interface
 */
interface IxAssetCLR is IERC20 {
    function adminRebalance() external;

    function adminStake(uint256 amount0, uint256 amount1) external;

    function adminSwap(uint256 amount, bool _0for1) external;

    function adminSwapOneInch(
        uint256 minReturn,
        bool _0for1,
        bytes memory _oneInchData
    ) external;

    function adminUnstake(uint256 amount0, uint256 amount1) external;

    function burn(uint256 amount) external;

    function calculateAmountsMintedSingleToken(uint8 inputAsset, uint256 amount)
        external
        view
        returns (uint256 amount0Minted, uint256 amount1Minted);

    function calculateMintAmount(uint256 _amount, uint256 totalSupply)
        external
        view
        returns (uint256 mintAmount);

    function calculatePoolMintedAmounts(uint256 amount0, uint256 amount1)
        external
        view
        returns (uint256 amount0Minted, uint256 amount1Minted);

    function changePool(address _poolAddress, uint24 _poolFee) external;

    function collect()
        external
        returns (uint256 collected0, uint256 collected1);

    function collectAndRestake() external;

    function decimals() external view returns (uint8);

    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        returns (bool);

    function getAmountInAsset0Terms(uint256 amount)
        external
        view
        returns (uint256);

    function getAmountInAsset1Terms(uint256 amount)
        external
        view
        returns (uint256);

    function getAmountsForLiquidity(uint128 liquidity)
        external
        view
        returns (uint256 amount0, uint256 amount1);

    function getAsset0Price() external view returns (int128);

    function getAsset1Price() external view returns (int128);

    function getBufferBalance() external view returns (uint256);

    function getBufferToken0Balance() external view returns (uint256 amount0);

    function getBufferToken1Balance() external view returns (uint256 amount1);

    function getBufferTokenBalance()
        external
        view
        returns (uint256 amount0, uint256 amount1);

    function getLiquidityForAmounts(uint256 amount0, uint256 amount1)
        external
        view
        returns (uint128 liquidity);

    function getNav() external view returns (uint256);

    function getPositionLiquidity() external view returns (uint128 liquidity);

    function getStakedBalance() external view returns (uint256);

    function getStakedTokenBalance()
        external
        view
        returns (uint256 amount0, uint256 amount1);

    function getTicks() external view returns (int24 tick0, int24 tick1);

    function getTotalLiquidity() external view returns (uint256 amount);

    function increaseAllowance(address spender, uint256 addedValue)
        external
        returns (bool);

    function initialize(
        string memory _symbol,
        int24 _tickLower,
        int24 _tickUpper,
        address _token0,
        address _token1,
        UniswapContracts memory contracts,
        // Staking parameters
        address _rewardsToken,
        address _rewardEscrow,
        bool _rewardsAreEscrowed
    ) external;

    function lastLockedBlock(address) external view returns (uint256);

    function mint(uint8 inputAsset, uint256 amount) external;

    function mintInitial(uint256 amount0, uint256 amount1) external;

    function name() external view returns (string memory);

    function owner() external view returns (address);

    function pauseContract() external returns (bool);

    function paused() external view returns (bool);

    function poolFee() external view returns (uint24);

    function renounceOwnership() external;

    function resetTwap() external;

    function setMaxTwapDeviationDivisor(uint256 newDeviationDivisor) external;

    function setTwapPeriod(uint32 newPeriod) external;

    function symbol() external view returns (string memory);

    function token0DecimalMultiplier() external view returns (uint256);

    function token0Decimals() external view returns (uint8);

    function token1DecimalMultiplier() external view returns (uint256);

    function token1Decimals() external view returns (uint8);

    function tokenDiffDecimalMultiplier() external view returns (uint256);

    function tokenId() external view returns (uint256);

    function transferOwnership(address newOwner) external;

    function adminMint(uint256 amount, bool isToken0) external;

    function adminBurn(uint256 amount, bool isToken0) external;
    
    function adminApprove(bool isToken0) external;

    struct UniswapContracts {
        address pool;
        address router;
        address quoter;
        address positionManager;
    }

    function unpauseContract() external returns (bool);

    function withdrawToken(address token, address receiver) external;
}
