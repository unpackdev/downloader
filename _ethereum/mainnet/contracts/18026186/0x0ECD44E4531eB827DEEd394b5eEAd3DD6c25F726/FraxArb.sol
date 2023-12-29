// SPDX-License-Identifier: AGPLv3
pragma solidity 0.8.10;
import {ERC20} from "ERC20.sol";
import {Owned} from "Owned.sol";
import "ICurveMeta.sol";
import "ICurve3Pool.sol";
import "SafeTransferLib.sol";

/// Uniswap v3 router interface
interface IUniV3 {
    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    function exactInput(ExactInputParams calldata params)
        external
        payable
        returns (uint256 amountOut);
}

contract FraxArb is Owned {
    using SafeTransferLib for ERC20;
    /*//////////////////////////////////////////////////////////////
                                Events
    //////////////////////////////////////////////////////////////*/

    event ArbPerformed(
        uint256 _initialAmount,
        uint256 _finalAmount,
        uint256 _slippageAmount
    );
    /*//////////////////////////////////////////////////////////////
                        CONSTANTS & IMMUTABLES
    //////////////////////////////////////////////////////////////*/
    ERC20 internal constant CRV_3POOL_TOKEN =
        ERC20(address(0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490));
    ERC20 public constant DAI =
        ERC20(address(0x6B175474E89094C44Da98b954EedeAC495271d0F));
    ERC20 public constant USDC =
        ERC20(address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48));
    ERC20 public constant USDT =
        ERC20(address(0xdAC17F958D2ee523a2206206994597C13D831ec7));
    ERC20 public constant FRAX =
        ERC20(address(0x853d955aCEf822Db058eb8505911ED77F175b99e));

    ICurveMeta public constant FRAX_META =
        ICurveMeta(address(0xd632f22692FaC7611d2AA1C0D552930D43CAEd3B));
    ICurve3Pool public constant THREE_POOL =
        ICurve3Pool(address(0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7));

    int128 public constant THREE_CURVE_META_INDEX = 1;
    int128 public constant FRAX_META_INDEX = 0;
    uint256 public constant UNI_V3_FEE = 500;
    address public constant UNI_V3 =
        address(0xE592427A0AEce92De3Edee1F18E0157C05861564);

    constructor() Owned(msg.sender) {
        CRV_3POOL_TOKEN.approve(address(FRAX_META), type(uint256).max);
        // Approve all 3 tokens allowance to 3curve pool
        DAI.approve(address(THREE_POOL), type(uint256).max);
        USDC.approve(address(THREE_POOL), type(uint256).max);
        USDT.safeApprove(address(THREE_POOL), type(uint256).max);
        FRAX.approve(address(UNI_V3), type(uint256).max);
    }

    /// @notice This function is used to perform the arb
    /// @param _amount The amount of 3CRV to perform the arb with
    function performArbWithTransfer(uint256 _amount) external onlyOwner {
        // First, transfer the 3CRV token to this contract
        require(
            CRV_3POOL_TOKEN.allowance(msg.sender, address(this)) >= _amount,
            "!allowance"
        );
        CRV_3POOL_TOKEN.transferFrom(msg.sender, address(this), _amount);
        // Then, perform the arb
        performArb(50);
    }

    /// @notice run this function if you already have 3CRV token in this contract
    function performArb(uint256 _slippageAmount)
        public
        onlyOwner
        returns (uint256, uint256)
    {
        uint256 threeCurveBal = CRV_3POOL_TOKEN.balanceOf(address(this));
        // Require 3 curve token balance non-zero:
        require(threeCurveBal > 0, "!3CRV");
        // Swap the 3CRV for FRAX
        FRAX_META.exchange(
            THREE_CURVE_META_INDEX,
            FRAX_META_INDEX,
            threeCurveBal,
            0
        );

        // Make sure we have non-zero FRAX balance
        require(FRAX.balanceOf(address(this)) >= 0, "!FRAX");

        // Swap FRAX to USDC
        uint256 fraxAmount = FRAX.balanceOf(address(this));
        IUniV3(UNI_V3).exactInput(
            IUniV3.ExactInputParams(
                abi.encodePacked(FRAX, uint24(UNI_V3_FEE), USDC),
                address(this),
                block.timestamp,
                fraxAmount,
                0
            )
        );

        // Collect all balances of 3 tokens
        uint256 _daiBalance = DAI.balanceOf(address(this));
        uint256 _usdcBalance = USDC.balanceOf(address(this));
        uint256 _usdtBalance = USDT.balanceOf(address(this));
        // Make sure that we have non-zero balance
        require((_daiBalance + _usdcBalance + _usdtBalance) > 0, "!balance");

        uint256[3] memory _tokenAmounts = [
            _daiBalance,
            _usdcBalance,
            _usdtBalance
        ];

        // Deposit liquidity to 3 curve pool
        THREE_POOL.add_liquidity(_tokenAmounts, 0);

        // Check 3curve token amounts with slippage
        uint256 threeCurveAfter = CRV_3POOL_TOKEN.balanceOf(address(this));
        uint256 slippageAmount = (_slippageAmount * threeCurveBal) / 10000;
        require(threeCurveAfter > threeCurveBal - slippageAmount, "!slippage");
        emit ArbPerformed(threeCurveBal, threeCurveAfter, slippageAmount);

        return (threeCurveBal, threeCurveAfter);
    }

    /// @notice This function is used to sweep any tokens that are stuck in the contract
    function sweep(address asset) external onlyOwner {
        ERC20(asset).transfer(
            msg.sender,
            ERC20(asset).balanceOf(address(this))
        );
    }
}
