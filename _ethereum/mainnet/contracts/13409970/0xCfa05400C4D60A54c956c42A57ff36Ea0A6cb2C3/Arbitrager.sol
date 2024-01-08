// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.4;

import "./IERC20.sol";
import "./IUniswapV2Router02.sol";

import "./IERC3156FlashBorrower.sol";
import "./IERC3156FlashLender.sol";

contract Arbitrager is IERC3156FlashBorrower {
    enum Direction {
        UNISWAP_SUSHISWAP,
        SUSHISWAP_UNISWAP
    }
    struct Data {
        address swapToken;
        Direction direction;
        uint256 deadline;
        uint256 amountRequired;
        address sender;
    }
    IERC3156FlashLender public immutable lender;
    IUniswapV2Router02 public immutable uniswapRouter;
    IUniswapV2Router02 public immutable sushiswapRouter;

    constructor(
        IERC3156FlashLender _lender,
        IUniswapV2Router02 _uniswapRouter,
        IUniswapV2Router02 _sushiswapRouter
    ) {
        lender = _lender;
        uniswapRouter = _uniswapRouter;
        sushiswapRouter = _sushiswapRouter;
    }

    function onFlashLoan(
        address initiator,
        address borrowedToken,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external override returns (bytes32) {
        require(msg.sender == address(lender), 'FLASH_BORROWER_UNTRUSTED_LENDER');
        require(initiator == address(this), 'FLASH_BORROWER_LOAN_INITIATOR');

        IERC20 borrowedTokenContract = IERC20(borrowedToken);
        Data memory decodedData = _decodeData(data);
        (IUniswapV2Router02 router1, IUniswapV2Router02 router2) = _getRouters(
            decodedData.direction
        );

        // Call protocol 1
        uint256 amountReceivedSwapToken = _protocolCall(
            router1,
            borrowedToken,
            decodedData.swapToken,
            amount,
            decodedData.deadline
        );

        // Call protocol 2
        uint256 amountReceivedBorrowedToken = _protocolCall(
            router2,
            decodedData.swapToken,
            borrowedToken,
            amountReceivedSwapToken,
            decodedData.deadline
        );

        // Check profitability
        uint256 repay = amount + fee;
        uint256 minAmountForProfitability = repay + decodedData.amountRequired;
        require(
            amountReceivedBorrowedToken > minAmountForProfitability,
            'ARBITRAGER_NO_PROFITABILITY'
        );

        // Transfer profit
        borrowedTokenContract.transfer(
            decodedData.sender,
            amountReceivedBorrowedToken - minAmountForProfitability
        );

        // Approve lender
        borrowedTokenContract.approve(address(lender), repay);

        return keccak256('ERC3156FlashBorrower.onFlashLoan');
    }

    function arbitrage(
        address borrowedToken,
        address swapToken,
        uint256 amount,
        Direction direction,
        uint256 deadline,
        uint256 amountRequired
    ) public {
        bytes memory _data = abi.encode(swapToken, direction, deadline, amountRequired, msg.sender);
        lender.flashLoan(this, borrowedToken, amount, _data);
    }

    function _decodeData(bytes calldata data) internal pure returns (Data memory) {
        (
            address swapToken,
            uint256 direction,
            uint256 deadline,
            uint256 amountRequired,
            address sender
        ) = abi.decode(data, (address, uint256, uint256, uint256, address));
        return Data(swapToken, Direction(direction), deadline, amountRequired, sender);
    }

    function _getRouters(Direction direction)
        internal
        view
        returns (IUniswapV2Router02, IUniswapV2Router02)
    {
        if (direction == Direction.SUSHISWAP_UNISWAP) {
            return (sushiswapRouter, uniswapRouter);
        }

        return (uniswapRouter, sushiswapRouter);
    }

    function _protocolCall(
        IUniswapV2Router02 router,
        address token1,
        address token2,
        uint256 amount,
        uint256 deadline
    ) internal returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = token1;
        path[1] = token2;
        IERC20(token1).approve(address(router), amount);

        return router.swapExactTokensForTokens(amount, 0, path, address(this), deadline)[1];
    }
}
