// SPDX-License-Identifier: UNLICENSED
// DELTA-BUG-BOUNTY
pragma solidity ^0.7.6;

import "./SafeMath.sol";
import "./UniswapV2Library.sol";
import "./IDeltaToken.sol";
import "./IRebasingLiquidityToken.sol";
import "./IDeepFarmingVault.sol";
import "./IWETH.sol";
import "./Math.sol";

/**
 * @dev This contract be be whitelisted as noVesting since it can receive delta token
 * when swapping half of the eth when providing liquidity with eth only.
 */
contract DeltaRouter {
    using SafeMath for uint256;
    bool public disabled;

    address public immutable DELTA_WETH_UNISWAP_PAIR;
    IWETH constant public WETH = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IDeltaToken public immutable DELTA_TOKEN;
    IDeepFarmingVault public immutable DEEP_FARMING_VAULT;
    IRebasingLiquidityToken public immutable REBASING_TOKEN;

    constructor(address _deltaToken, address _DELTA_WETH_UNISWAP_PAIR, address _DEEP_FARMING_VAULT, address _REBASING_TOKEN) {
        require(_deltaToken != address(0), "Invalid DELTA_TOKEN Address");
        require(_DELTA_WETH_UNISWAP_PAIR != address(0), "Invalid DeltaWethPair Address");
        require(_DEEP_FARMING_VAULT != address(0), "Invalid DeepFarmingVault Address");
        require(_REBASING_TOKEN != address(0), "Invalid RebasingToken Address");

        DELTA_TOKEN = IDeltaToken(_deltaToken);
        DELTA_WETH_UNISWAP_PAIR = _DELTA_WETH_UNISWAP_PAIR;
        DEEP_FARMING_VAULT = IDeepFarmingVault(_DEEP_FARMING_VAULT);
        REBASING_TOKEN = IRebasingLiquidityToken(_REBASING_TOKEN);

        IRebasingLiquidityToken(_REBASING_TOKEN).approve(address(_DEEP_FARMING_VAULT), uint(-1));
        IUniswapV2Pair(_DELTA_WETH_UNISWAP_PAIR).approve(address(_REBASING_TOKEN), uint(-1));
    }
    
    function deltaGovernance() public view returns (address) {
        return DELTA_TOKEN.governance();
    }

    function onlyMultisig() private view {
        require(msg.sender == deltaGovernance(), "!governance");
    }

    function refreshApproval() public {
        IUniswapV2Pair(DELTA_WETH_UNISWAP_PAIR).approve(address(REBASING_TOKEN), uint(-1));
        REBASING_TOKEN.approve(address(DEEP_FARMING_VAULT), uint(-1));
    }

    function disable() public {
        onlyMultisig();
        disabled = true;
    }

    function rescueTokens(address token) public {
        onlyMultisig();
        IERC20(token).transfer(msg.sender, IERC20(token).balanceOf(address(this)));
    }
    
    function rescueEth() public {
        onlyMultisig();
        (bool success,) = msg.sender.call{value : address(this).balance}("");
        require(success);
    }

    receive() external payable {
       revert("DeltaRouter: INVALID_OPERATION");
    }

    /// @notice Add liquidity using ETH only with a minimum lp amount to receive
    /// getRLPTokenPerEthUnit() can be used to estimate the number of
    /// lp take can be minted from an ETH amount
    function addLiquidityETHOnly(uint256 _minLpOut, bool _autoStake) public payable {
        require(!disabled, 'DeltaRouter: DISABLED');

        uint256 buyAmount = msg.value.div(2);
        require(buyAmount >= 5, "DeltaRouter: MINIMUM_LIQUIDITY_THRESHOLD_UNMET");
        WETH.deposit{value: msg.value}();

        (uint256 deltaReserve, uint256 wethReserve, ) = IUniswapV2Pair(DELTA_WETH_UNISWAP_PAIR).getReserves();
        uint256 outDelta = UniswapV2Library.getAmountOut(buyAmount, wethReserve, deltaReserve);
        // We swap for half the amount of delta
        WETH.transfer(DELTA_WETH_UNISWAP_PAIR, buyAmount);
        IUniswapV2Pair(DELTA_WETH_UNISWAP_PAIR).swap(outDelta, 0, address(this), "");
        
        // Now we will have too much delta because of slippage always so we quote for number of ETH instead
        // uint256 optimalDelta = UniswapV2Library.quote(buyAmount, wethReserve.add(buyAmount), deltaReserve.sub(outDelta)); //amountin reservein reserveother

        // Well, no. You bought DELTA above which means you will have slippage in the direction of having less DELTA relative to the
        // remaining ETH. So actually you need to get the number of ETH to match the (slightly smaller amount) DELTA
        // that you actually have now.
        uint256 optimalWETH = UniswapV2Library.quote(outDelta, deltaReserve.sub(outDelta), wethReserve.add(buyAmount));
        uint256 optimalDelta = outDelta;
        if(optimalWETH > buyAmount) {
            // Matching uses more ETH than we have.
            // This happens because DELTA price has increased enough that it's more than what was sacrificed to slippage
            optimalWETH = buyAmount;
            optimalDelta = UniswapV2Library.quote(buyAmount, wethReserve.add(buyAmount), deltaReserve.sub(outDelta));
        }

        // Feed the pair and refund the guy
        DELTA_TOKEN.transfer(DELTA_WETH_UNISWAP_PAIR, optimalDelta);
        WETH.transfer(DELTA_WETH_UNISWAP_PAIR, optimalWETH);
        {
            WETH.transfer(msg.sender, buyAmount - optimalWETH);
        }

        mintWrapAndStakeOrNot(_autoStake, _minLpOut);
    }

    function stakeRLP(uint256 amount) private {
        DEEP_FARMING_VAULT.depositFor(msg.sender, amount, 0);
    }

    function mintWrapAndStakeOrNot(bool _autoStake, uint256 minOut) private {
        uint256 mintedLP = IUniswapV2Pair(DELTA_WETH_UNISWAP_PAIR).mint(address(this));
        require(mintedLP >= minOut, "DeltaRouter: MINTED_LP_LOWER_THAN_EXPECTED");
        uint256 mintedRLP = REBASING_TOKEN.wrapWithReturn();
        if(_autoStake){
            stakeRLP(mintedRLP);
        } else {
            IERC20(address(REBASING_TOKEN)).transfer(msg.sender, mintedRLP);
        }
    }

    function addLiquidityBothSides(uint256 _maxDeltaAmount, uint256 _minLpOut, bool _autoStake) public payable {
        require(!disabled, 'DeltaRouter: DISABLED');
        
        WETH.deposit{value: msg.value}();
        (uint256 deltaReserve, uint256 wethReserve, ) = IUniswapV2Pair(DELTA_WETH_UNISWAP_PAIR).getReserves();
        uint256 optimalDelta = UniswapV2Library.quote(msg.value, wethReserve, deltaReserve); //amountin reservein reserveother
        require(_maxDeltaAmount >= optimalDelta, "DeltaRouter: OPTIMAL_QUOTE_EXCEEDS_MAX_DELTA_AMOUNT");
        // We have to transfer to here first because the pair cannot be a immature recieverS
        bool success = DELTA_TOKEN.transferFrom(msg.sender, address(this), optimalDelta);
        DELTA_TOKEN.transfer(DELTA_WETH_UNISWAP_PAIR, optimalDelta);
        require(success, "DeltaRouter: TRANSFER_FAILED");
        WETH.transfer(DELTA_WETH_UNISWAP_PAIR, msg.value);
        
        mintWrapAndStakeOrNot(_autoStake, _minLpOut);
    }

    function getOptimalDeltaAmountForEthAmount(uint256 _ethAmount) public view returns (uint256 optimalDeltaAmount) {
        (uint256 deltaReserve, uint256 wethReserve, ) = IUniswapV2Pair(DELTA_WETH_UNISWAP_PAIR).getReserves();
        optimalDeltaAmount = UniswapV2Library.quote(_ethAmount, wethReserve, deltaReserve);
    }

    function getOptimalEthAmountForDeltaAmount(uint256 _deltaAmount) public view returns (uint256 optimalEthAmount) {
        (uint256 deltaReserve, uint256 wethReserve, ) = IUniswapV2Pair(DELTA_WETH_UNISWAP_PAIR).getReserves();
        optimalEthAmount = UniswapV2Library.quote(_deltaAmount, deltaReserve, wethReserve);
    }

    function getRLPTokenPerEthUnit(uint256 _ethAmount) public view returns (uint256 liquidity) {
        (uint256 deltaReserve, uint256 reserveWeth, ) = IUniswapV2Pair(DELTA_WETH_UNISWAP_PAIR).getReserves();
        uint256 halfEthAmount = _ethAmount.div(2);
        uint256 outDelta = UniswapV2Library.getAmountOut(halfEthAmount, reserveWeth, deltaReserve);
        uint256 totalSupply = IUniswapV2Pair(DELTA_WETH_UNISWAP_PAIR).totalSupply();
    

        uint256 optimalDeltaAmount = UniswapV2Library.quote(halfEthAmount, reserveWeth, deltaReserve);
        uint256 optimalWETHAmount = halfEthAmount;

        if (optimalDeltaAmount > outDelta) {
            optimalWETHAmount = UniswapV2Library.quote(outDelta, deltaReserve, reserveWeth);
            optimalDeltaAmount = outDelta;
        }
        
        deltaReserve -= optimalDeltaAmount;
        reserveWeth += optimalWETHAmount;

        uint256 rlpPerLP = IRebasingLiquidityToken(REBASING_TOKEN).rlpPerLP();
        liquidity = Math.min(optimalDeltaAmount.mul(totalSupply) / deltaReserve, optimalWETHAmount.mul(totalSupply) / reserveWeth).mul(rlpPerLP).div(1e18);
    }

    function getRLPTokenPerBothSideUnits(uint256 _deltaAmount, uint256 _ethAmount) public view returns (uint256 liquidity) {
        (uint256 deltaReserve, uint256 reserveWeth, ) = IUniswapV2Pair(DELTA_WETH_UNISWAP_PAIR).getReserves();
        uint256 totalSupply = IUniswapV2Pair(DELTA_WETH_UNISWAP_PAIR).totalSupply();

        uint256 optimalDeltaAmount = UniswapV2Library.quote(_ethAmount, reserveWeth, deltaReserve);
        uint256 optimalWETHAmount = _ethAmount;

        if (optimalDeltaAmount > _deltaAmount) {
            optimalWETHAmount = UniswapV2Library.quote(_deltaAmount, deltaReserve, reserveWeth);
            optimalDeltaAmount = _deltaAmount;
        }

        uint256 rlpPerLP = IRebasingLiquidityToken(REBASING_TOKEN).rlpPerLP();
        liquidity = Math.min(optimalDeltaAmount.mul(totalSupply) / deltaReserve, optimalWETHAmount.mul(totalSupply) / reserveWeth).mul(rlpPerLP).div(1e18);
    }
}