/// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "./IHarvester.sol";
import "./ICurveV2Pool.sol";
import "./IWETH9.sol";
import "./IUniswapSwapRouter.sol";
import "./IVault.sol";
import "./IAggregatorV3.sol";

import "./IERC20Metadata.sol";
import "./SafeERC20.sol";

contract Harvester is IHarvester {
    using SafeERC20 for IERC20;
    using SafeERC20 for IWETH9;
    using SafeERC20 for IERC20Metadata;

    /*///////////////////////////////////////////////////////////////
                          GLOBAL CONSTANTS
    //////////////////////////////////////////////////////////////*/
    /// @notice desired uniswap fee
    uint24 public constant UNISWAP_FEE = 10000;
    /// @notice the max basis points used as normalizing factor
    uint256 public constant MAX_BPS = 1000;
    /// @notice normalization factor for decimals
    uint256 public constant NORMALIZATION_FACTOR = 1e18;

    /// @notice address of crv
    IERC20 public constant override crv =
        IERC20(0xD533a949740bb3306d119CC777fa900bA034cd52);
    /// @notice address of cvx
    IERC20 public constant override cvx =
        IERC20(0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B);
    /// @notice address of ldo
    IERC20 public constant ldo =
        IERC20(0x5A98FcBEA516Cf06857215779Fd812CA3beF1B32);
    /// @notice address of weth
    IWETH9 private constant weth =
        IWETH9(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    /// @notice chainlink data feed for CRV/ETH
    IAggregatorV3 public constant crvEthPrice =
        IAggregatorV3(0x8a12Be339B0cD1829b91Adc01977caa5E9ac121e);
    /// @notice chainlink data feed for CVX/ETH
    IAggregatorV3 public constant cvxEthPrice =
        IAggregatorV3(0xC9CbF687f43176B302F03f5e58470b77D07c61c6);
    /// @notice chainlink data feed for LDO/ETH
    IAggregatorV3 public constant ldoEthPrice =
        IAggregatorV3(0x4e844125952D32AcdF339BE976c98E22F6F318dB);

    /// @notice address of CRV/ETH pool on curve
    ICurveV2Pool private constant crveth =
        ICurveV2Pool(0x8301AE4fc9c624d1D396cbDAa1ed877821D7C511);
    /// @notice address of CVX/ETH pool on curve
    ICurveV2Pool private constant cvxeth =
        ICurveV2Pool(0xB576491F1E6e5E62f1d8F26062Ee822B40B0E0d4);
    /// @notice uniswap router to swap tokens
    IUniswapSwapRouter private constant uniswapRouter =
        IUniswapSwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);

    /*///////////////////////////////////////////////////////////////
                        MUTABLE STATE
    //////////////////////////////////////////////////////////////*/
    /// @notice instance of vault
    IVault public override vault;
    /// @notice maximum acceptable slippage
    uint256 public maxSlippage = 500;

    /*///////////////////////////////////////////////////////////////
                            EXTERNAL CONTRACTS
    //////////////////////////////////////////////////////////////*/
    /// @notice address of position handler
    address public override positionHandler;

    /// @notice creates a new Harvester
    /// @param _vault address of vault
    constructor(address _vault) {
        vault = IVault(_vault);

        // max approve CRV to CRV/ETH pool on curve
        crv.safeApprove(address(crveth), type(uint256).max);
        // max approve CVX to CVX/ETH pool on curve
        cvx.safeApprove(address(cvxeth), type(uint256).max);
        // max approve LDO to uniswap swap router
        ldo.safeApprove(address(uniswapRouter), type(uint256).max);
    }

    /*///////////////////////////////////////////////////////////////
                         VIEW FUNCTONS
    //////////////////////////////////////////////////////////////*/
    /// @notice Function which returns address of reward tokens
    /// @return rewardTokens array of reward token addresses
    function rewardTokens() external pure override returns (address[] memory) {
        address[] memory rewards = new address[](3);
        rewards[0] = address(crv);
        rewards[1] = address(cvx);
        rewards[2] = address(ldo);
        return rewards;
    }

    /*///////////////////////////////////////////////////////////////
                    KEEPER FUNCTONS
    //////////////////////////////////////////////////////////////*/
    /// @notice Keeper function to set position handler to harvest for
    /// @param _addr address of the position handler
    function setPositionHandler(address _addr) external override onlyKeeper {
        positionHandler = _addr;
    }

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
    /// @notice Harvest the entire swap tokens list, i.e convert them into WETH
    /// @dev Pulls all swap token balances from the msg.sender, swaps them into WETH, and sends it back
    function harvest() external override onlyPositionHandler {
        uint256 crvBalance = crv.balanceOf(address(this));
        uint256 cvxBalance = cvx.balanceOf(address(this));
        uint256 ldoBalance = ldo.balanceOf(address(this));
        // swap CVX to WETH
        if (cvxBalance > 0) {
            cvxeth.exchange(
                1,
                0,
                cvxBalance,
                _getMinReceived(_getPriceInETH(cvxBalance, cvxEthPrice)),
                false
            );
        }
        // swap CRV to WETH
        if (crvBalance > 0) {
            crveth.exchange(
                1,
                0,
                crvBalance,
                _getMinReceived(_getPriceInETH(crvBalance, crvEthPrice)),
                false
            );
        }

        // swap LDO to WETH
        if (ldoBalance > 0) {
            _swapLidoForWETH(ldoBalance);
        }
        uint256 wethBalance = weth.balanceOf(address(this));

        // withdraw eth from weth
        if (wethBalance > 0) {
            weth.safeTransfer(msg.sender, wethBalance);
        }
    }

    /// @notice Helper function to swap LDO tokens for WETH
    /// @param amountToSwap the amount of LDO tokens to swap
    function _swapLidoForWETH(uint256 amountToSwap) internal {
        IUniswapSwapRouter.ExactInputSingleParams
            memory params = IUniswapSwapRouter.ExactInputSingleParams({
                tokenIn: address(ldo),
                tokenOut: address(weth),
                fee: UNISWAP_FEE,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: amountToSwap,
                amountOutMinimum: _getMinReceived(
                    _getPriceInETH(amountToSwap, ldoEthPrice)
                ),
                sqrtPriceLimitX96: 0
            });
        uniswapRouter.exactInputSingle(params);
    }

    /// @notice helper to get price of tokens in ETH, from chainlink
    /// @param amount the amount of tokens to get in terms of ETH
    /// @param priceFeed the price feed to fetch latest price from
    function _getPriceInETH(uint256 amount, IAggregatorV3 priceFeed)
        internal
        view
        returns (uint256)
    {
        (, int256 latestPrice, , , ) = priceFeed.latestRoundData();
        return (uint256(latestPrice) * amount) / NORMALIZATION_FACTOR;
    }

    /// @notice helper to get minimum amount to receive from swap
    /// @param amount the amount to be swapped
    function _getMinReceived(uint256 amount) internal view returns (uint256) {
        return (amount * (MAX_BPS - maxSlippage)) / MAX_BPS;
    }

    /*///////////////////////////////////////////////////////////////
                        ACCESS MODIFIERS
    //////////////////////////////////////////////////////////////*/
    modifier validAddress(address _addr) {
        require(_addr != address(0), "_addr invalid");
        _;
    }

    modifier onlyGovernance() {
        require(
            msg.sender == vault.governance(),
            "Harvester :: onlyGovernance"
        );
        _;
    }

    modifier onlyKeeper() {
        require(msg.sender == vault.keeper(), "auth: keeper");
        _;
    }

    modifier onlyPositionHandler() {
        require(msg.sender == positionHandler, "auth: positionHandler");
        _;
    }
}
