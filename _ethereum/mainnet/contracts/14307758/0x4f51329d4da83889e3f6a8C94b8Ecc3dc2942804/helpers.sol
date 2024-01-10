//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./interface.sol";

contract InstaFlashReceiver {
    using SafeERC20 for IERC20;
    address chainToken = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address oneInchRouter_;
    address uniswapV3Router_;
    address nftManagerAddress_;

    IFlashLoan internal immutable flashloan;
    NonfungiblePositionManager internal nftManager;

    MintParams internal param;

    error flashloanRevert(bool zeroForOne, uint256 amount);

    struct nftParam {
        uint256 loan0;
        uint256 loan1;
        uint256 fee0;
        uint256 fee1;
        uint256 tokenId;
        bytes _callData;
    }

    constructor(
        address _flashloan,
        address _oneInchRouter,
        address _uniswapV3Router,
        address _nftManagerAddress
    ) {
        oneInchRouter_ = _oneInchRouter;
        uniswapV3Router_ = _uniswapV3Router;
        nftManagerAddress_ = _nftManagerAddress;
        flashloan = IFlashLoan(_flashloan);
        nftManager = NonfungiblePositionManager(nftManagerAddress_);
    }

    function flashBorrow(
        address[] memory _tokens,
        uint256[] memory _amts,
        uint256 _route,
        bytes memory _data
    ) public {
        bytes memory instaData;
        flashloan.flashLoan(_tokens, _amts, _route, _data, instaData);
    }

    function executeOperation(
        address[] calldata tokens,
        uint256[] calldata amounts,
        uint256[] calldata premiums,
        address initiator,
        bytes calldata params
    ) external returns (bool) {
        nftParam memory args;
        bool simulate;
        address owner;
        (args.loan0, args.loan1) = (amounts[0], amounts[1]);
        (args.fee0, args.fee1) = (premiums[0], premiums[1]);

        (simulate, args.tokenId, owner, args._callData, param) = abi.decode(
            params,
            (bool, uint256, address, bytes, MintParams)
        );

        _approve(param.token0, param.amount0Desired, nftManagerAddress_);
        _approve(param.token1, param.amount1Desired, nftManagerAddress_);

        uint256 oldTokenId = args.tokenId;
        (uint256 newTokenId, uint128 liquidityX, , ) = nftManager.mint(param);

        (, , , , uint24 fee, , , uint128 liquidity, , , , ) = nftManager
            .positions(oldTokenId);

        _decreaseLiquidity(oldTokenId, liquidity);
        _collect(oldTokenId);

        uint256 totalFee0 = args.loan0 + args.fee0;
        uint256 totalFee1 = args.loan1 + args.fee1;

        if (simulate) {
            _simulateSwapWithOneInch(
                args._callData,
                totalFee0,
                totalFee1,
                param.token0,
                param.token1
            );
        }
        bool success = _swapWithOneInch(
            args._callData,
            totalFee0,
            totalFee1,
            param.token0,
            param.token1
        );

        if (!success) {
            //To swap using uniswap v3 pool:
            _swapWithUniswap(
                totalFee0,
                totalFee1,
                param.token0,
                param.token1,
                fee
            );
        }

        _repay(param.token0, _balance(param.token0), owner);
        _repay(param.token1, _balance(param.token1), owner);
    }

    function _swapWithOneInch(
        bytes memory _callData,
        uint256 totalFee0,
        uint256 totalFee1,
        address token0,
        address token1
    ) internal returns (bool success) {
        (uint256 amount0, uint256 amount1) = (
            _balance(token0),
            _balance(token1)
        );
        if (amount0 > totalFee0) {
            _approve(token0, amount0 - totalFee0, oneInchRouter_);
        } else if (amount1 > totalFee1) {
            _approve(token1, amount1 - totalFee1, oneInchRouter_);
        }
        (success, ) = address(oneInchRouter_).call(_callData);

        if (success) {
            _repay(token0, totalFee0, address(flashloan));
            _repay(token1, totalFee1, address(flashloan));
        }
    }

    function _simulateSwapWithOneInch(
        bytes memory _callData,
        uint256 totalFee0,
        uint256 totalFee1,
        address token0,
        address token1
    ) internal view returns (bool success) {
        bool zeroForOne;
        uint256 amount;
        (uint256 amount0, uint256 amount1) = (
            _balance(token0),
            _balance(token1)
        );

        if (amount0 > totalFee0) {
            zeroForOne = true;
            amount = amount0 - totalFee0;
        } else {
            zeroForOne = false;
            amount = amount1 - totalFee1;
        }
        revert flashloanRevert({zeroForOne: zeroForOne, amount: amount});
    }

    function _swapWithUniswap(
        uint256 totalFee0,
        uint256 totalFee1,
        address token0,
        address token1,
        uint24 fee
    ) internal {
        uint256 amt;
        IUniswapV2Router routerv2 = IUniswapV2Router(uniswapV3Router_);
        (uint256 amount0, uint256 amount1) = (
            _balance(token0),
            _balance(token1)
        );

        if (amount0 > totalFee0) {
            amt = amount0 - totalFee0;
            _approve(token0, amt, uniswapV3Router_);

            ExactInputSingleParams memory singleParam = ExactInputSingleParams(
                token0,
                token1,
                fee,
                address(this),
                amt,
                0,
                0
            );
            routerv2.exactInputSingle(singleParam);
        } else {
            amt = amount1 - totalFee1;
            _approve(token1, amt, uniswapV3Router_);

            ExactInputSingleParams memory singleParam = ExactInputSingleParams(
                token1,
                token0,
                fee,
                address(this),
                amt,
                0,
                0
            );

            routerv2.exactInputSingle(singleParam);
        }
        _repay(token1, totalFee1, address(flashloan));
        _repay(token0, totalFee0, address(flashloan));
    }

    function _approve(
        address token,
        uint256 amount,
        address recipient
    ) internal {
        IERC20(token).approve(recipient, amount);
    }

    function _repay(
        address token,
        uint256 amount,
        address recepient
    ) internal {
        require(_balance(token) >= amount, "Repay failed!");
        IERC20(token).safeTransfer(recepient, amount);
    }

    function _collect(uint256 oldTokenId)
        public
        payable
        returns (uint256 amount0, uint256 amount1)
    {
        CollectParams memory collectParam = CollectParams(
            oldTokenId,
            address(this),
            type(uint128).max,
            type(uint128).max
        );

        (amount0, amount1) = nftManager.collect(collectParam);
    }

    function _decreaseLiquidity(uint256 oldTokenId, uint128 liquidity)
        public
        payable
    {
        DecreaseLiquidityParams memory decreaseParam = DecreaseLiquidityParams(
            oldTokenId,
            liquidity,
            0,
            0,
            block.timestamp + 1
        );

        nftManager.decreaseLiquidity(decreaseParam);
    }

    function _balance(address token) internal view returns (uint256 balance) {
        balance = IERC20(token).balanceOf(address(this));
    }
}
