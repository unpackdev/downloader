//SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./SafeMath.sol";
import "./IERC20.sol";
import "./FlashLoanReceiverBase.sol";
import "./ILendingPool.sol";
import "./IMinter.sol";
import "./IUniswapV2Router.sol";

contract Arb is FlashLoanReceiverBase {
    using SafeMath for uint256;

    address public xvix;
    address public weth;
    address public minter;
    address public floor;
    address public router; // uniswap router
    address public receiver;
    address[] public path;
    address public gov;

    modifier onlyGov() {
        require(msg.sender == gov, "Arb: forbidden");
        _;
    }

    constructor(
        address _xvix,
        address _weth,
        address _minter,
        address _floor,
        address _router,
        address _receiver,
        address _lendingPoolAddressesProvider
    ) FlashLoanReceiverBase(_lendingPoolAddressesProvider) public {
        xvix = _xvix;
        weth = _weth;
        minter = _minter;
        floor = _floor;
        router = _router;
        receiver = _receiver;

        path.push(xvix);
        path.push(weth);

        gov = msg.sender;
    }

    function setGov(address _gov) external onlyGov {
        gov = _gov;
    }

    function setReceiver(address _receiver) external onlyGov {
        receiver = _receiver;
    }

    function rebalanceMinter(uint256 _ethAmount) external onlyGov {
        address asset = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
        bytes memory data = "";
        ILendingPool lendingPool = ILendingPool(addressesProvider.getLendingPool());
        lendingPool.flashLoan(address(this), asset, _ethAmount, data);
    }

    function executeOperation(
        address _asset,
        uint256 _amount,
        uint256 _fee,
        bytes calldata /* _params */
    )
        external
        override
    {
        require(_asset == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE, "Arb: loaned asset is not ETH");
        require(_amount <= getBalanceInternal(address(this), _asset), "Arb: flashLoan failed");

        IMinter(minter).mint{value: _amount}(address(this));

        uint256 amountXVIX = IERC20(xvix).balanceOf(address(this));
        IERC20(xvix).approve(router, amountXVIX);
        IUniswapV2Router(router).swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountXVIX,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 totalDebt = _amount.add(_fee);
        transferFundsBackToPoolInternal(_asset, totalDebt);

        uint256 profit = address(this).balance;

        (bool success,) = receiver.call{value: profit}("");
        require(success, "Arb: transfer to reciever failed");
    }
}
