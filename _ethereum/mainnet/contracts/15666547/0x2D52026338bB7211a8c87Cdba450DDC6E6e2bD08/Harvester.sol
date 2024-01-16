/// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "./IHarvester.sol";
import "./IUniswapV3Router.sol";
import "./ICurveV2Pool.sol";
import "./IVault.sol";
import "./IAggregatorV3.sol";

import "./IERC20Metadata.sol";
import "./SafeERC20.sol";

/// @title Harvester
/// @author PradeepSelva
/// @notice A contract to harvest rewards from Convex staking position into Want TOken
contract Harvester is IHarvester {
    using SafeERC20 for IERC20;
    using SafeERC20 for IERC20Metadata;

    /*///////////////////////////////////////////////////////////////
                        GLOBAL CONSTANTS
  //////////////////////////////////////////////////////////////*/
    /// @notice desired uniswap fee for WETH
    uint24 public constant WETH_SWAP_FEE = 500;
    /// @notice desired uniswap fee for snx
    uint24 public constant SNX_SWAP_FEE = 10000;
    /// @notice the max basis points used as normalizing factor
    uint256 public constant MAX_BPS = 1000;
    /// @notice normalization factor for decimals (USD)
    uint256 public constant USD_NORMALIZATION_FACTOR = 1e8;
    /// @notice normalization factor for decimals (ETH)
    uint256 public constant ETH_NORMALIZATION_FACTOR = 1e18;

    /// @notice address of crv token
    IERC20 public constant override crv =
        IERC20(0xD533a949740bb3306d119CC777fa900bA034cd52);
    /// @notice address of cvx token
    IERC20 public constant override cvx =
        IERC20(0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B);
    /// @notice address of snx token
    IERC20 public constant override snx =
        IERC20(0xC011a73ee8576Fb46F5E1c5751cA3B9Fe0af2a6F);
    /// @notice address of 3CRV LP token
    IERC20 public constant override _3crv =
        IERC20(0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490);
    /// @notice address of WETH token
    IERC20 private constant weth =
        IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    /// @notice address of Curve's CRV/ETH pool
    ICurveV2Pool private constant crveth =
        ICurveV2Pool(0x8301AE4fc9c624d1D396cbDAa1ed877821D7C511);
    /// @notice address of Curve's CVX/ETH pool
    ICurveV2Pool private constant cvxeth =
        ICurveV2Pool(0xB576491F1E6e5E62f1d8F26062Ee822B40B0E0d4);
    /// @notice address of Curve's 3CRV metapool
    ICurveV2Pool private constant _3crvPool =
        ICurveV2Pool(0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7);
    /// @notice address of uniswap router
    IUniswapV3Router private constant uniswapRouter =
        IUniswapV3Router(0xE592427A0AEce92De3Edee1F18E0157C05861564);

    /// @notice chainlink data feed for CRV/ETH
    IAggregatorV3 public constant crvEthPrice =
        IAggregatorV3(0x8a12Be339B0cD1829b91Adc01977caa5E9ac121e);
    /// @notice chainlink data feed for CVX/ETH
    IAggregatorV3 public constant cvxEthPrice =
        IAggregatorV3(0x231e764B44b2C1b7Ca171fa8021A24ed520Cde10);
    /// @notice chainlinkd ata feed for SNX/ETH
    IAggregatorV3 public constant snxUsdPrice =
        IAggregatorV3(0xDC3EA94CD0AC27d9A86C180091e7f78C683d3699);
    /// @notice chainlink data feed for ETH/USD
    IAggregatorV3 public constant ethUsdPrice =
        IAggregatorV3(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);

    /*///////////////////////////////////////////////////////////////
                        MUTABLE ACCESS MODFIERS
  //////////////////////////////////////////////////////////////*/
    /// @notice instance of vault
    IVault public override vault;
    /// @notice maximum acceptable slippage
    uint256 public maxSlippage = 1000;

    /// @notice creates a new Harvester
    /// @param _vault address of vault
    constructor(address _vault) {
        vault = IVault(_vault);

        // max approve CRV to CRV/ETH pool on curve
        crv.approve(address(crveth), type(uint256).max);
        // max approve CVX to CVX/ETH pool on curve
        cvx.approve(address(cvxeth), type(uint256).max);
        // max approve _3CRV to 3 CRV pool on curve
        _3crv.approve(address(_3crvPool), type(uint256).max);
        // max approve WETH to uniswap router
        weth.approve(address(uniswapRouter), type(uint256).max);
        // max approve SNX to uniswap router
        snx.approve(address(uniswapRouter), type(uint256).max);
    }

    /*///////////////////////////////////////////////////////////////
                         VIEW FUNCTONS
  //////////////////////////////////////////////////////////////*/

    /// @notice Function which returns address of reward tokens
    /// @return rewardTokens array of reward token addresses
    function rewardTokens() external pure override returns (address[] memory) {
        address[] memory rewards = new address[](4);
        rewards[0] = address(crv);
        rewards[1] = address(cvx);
        rewards[2] = address(_3crv);
        rewards[3] = address(snx);
        return rewards;
    }

    /*///////////////////////////////////////////////////////////////
                    KEEPER FUNCTONS
  //////////////////////////////////////////////////////////////*/
    /// @notice Keeper function to set maximum slippage
    /// @param _slippage new maximum slippage
    function setSlippage(uint256 _slippage) external override onlyKeeper {
        maxSlippage = _slippage;
    }

    /*///////////////////////////////////////////////////////////////
                      GOVERNANCE FUNCTIONS
  //////////////////////////////////////////////////////////////*/
    /// @notice Governance function to sweep a token's balance lying in Harvester
    /// @param _token address of token to sweep
    function sweep(address _token) external override onlyGovernance {
        IERC20(_token).safeTransfer(
            vault.governance(),
            IERC20Metadata(_token).balanceOf(address(this))
        );
    }

    /*///////////////////////////////////////////////////////////////
                    STATE MODIFICATION FUNCTONS
  //////////////////////////////////////////////////////////////*/

    /// @notice Harvest the entire swap tokens list, i.e convert them into wantToken
    /// @dev Pulls all swap token balances from the msg.sender, swaps them into wantToken, and sends back the wantToken balance
    function harvest() external override {
        uint256 crvBalance = crv.balanceOf(address(this));
        uint256 cvxBalance = cvx.balanceOf(address(this));
        uint256 _3crvBalance = _3crv.balanceOf(address(this));
        uint256 snxBalance = snx.balanceOf(address(this));

        // swap convex to eth
        if (cvxBalance > 0) {
            uint256 expectedOut = (_getPriceForAmount(crvEthPrice, cvxBalance));
            cvxeth.exchange(
                1,
                0,
                cvxBalance,
                _getMinReceived(expectedOut),
                false
            );
        }
        // swap crv to eth
        if (crvBalance > 0) {
            uint256 expectedOut = (_getPriceForAmount(crvEthPrice, crvBalance));
            crveth.exchange(
                1,
                0,
                crvBalance,
                _getMinReceived(expectedOut),
                false
            );
        }

        uint256 wethBalance = weth.balanceOf(address(this));

        // swap eth to USDC using 0.5% pool
        if (wethBalance > 0) {
            _swapToWantOnUniV3(
                address(weth),
                wethBalance,
                WETH_SWAP_FEE,
                ethUsdPrice
            );
        }

        // swap _crv to usdc
        if (_3crvBalance > 0) {
            _3crvPool.remove_liquidity_one_coin(_3crvBalance, 1, 0);
        }
        // swap SNX to usdc
        if (snxBalance > 0) {
            _swapToWantOnUniV3(
                address(snx),
                snxBalance,
                SNX_SWAP_FEE,
                snxUsdPrice
            );
        }

        // send token usdc back to vault
        IERC20(vault.wantToken()).safeTransfer(
            msg.sender,
            IERC20(vault.wantToken()).balanceOf(address(this))
        );
    }

    /// @notice helper to perform swap snx -> usdc on uniswap v3
    function _swapToWantOnUniV3(
        address tokenIn,
        uint256 amount,
        uint256 fee,
        IAggregatorV3 priceFeed
    ) internal {
        uint256 expectedOut = (_getPriceForAmount(priceFeed, amount) * 1e6) /
            ETH_NORMALIZATION_FACTOR;

        uniswapRouter.exactInput(
            IUniswapV3Router.ExactInputParams(
                abi.encodePacked(
                    tokenIn,
                    uint24(fee),
                    address(vault.wantToken())
                ),
                address(this),
                block.timestamp,
                amount,
                _getMinReceived(expectedOut)
            )
        );
    }

    /// @notice helper to get price of tokens in ETH, from chainlink
    /// @param priceFeed the price feed to fetch latest price from
    function _getPriceForAmount(IAggregatorV3 priceFeed, uint256 amount)
        internal
        view
        returns (uint256)
    {
        (, int256 latestPrice, , , ) = priceFeed.latestRoundData();
        return ((uint256(latestPrice) * amount) / 10**priceFeed.decimals());
    }

    /// @notice helper to get minimum amount to receive from swap
    function _getMinReceived(uint256 amount) internal view returns (uint256) {
        return (amount * (MAX_BPS - maxSlippage)) / MAX_BPS;
    }

    /*///////////////////////////////////////////////////////////////
                        ACCESS MODIFIERS
  //////////////////////////////////////////////////////////////*/

    /// @notice to check for valid address
    modifier validAddress(address _addr) {
        require(_addr != address(0), "_addr invalid");
        _;
    }

    /// @notice to check if caller is governance
    modifier onlyGovernance() {
        require(
            msg.sender == vault.governance(),
            "Harvester :: onlyGovernance"
        );
        _;
    }

    /// @notice to check if caller is keeper
    modifier onlyKeeper() {
        require(msg.sender == vault.keeper(), "auth: keeper");
        _;
    }
}
