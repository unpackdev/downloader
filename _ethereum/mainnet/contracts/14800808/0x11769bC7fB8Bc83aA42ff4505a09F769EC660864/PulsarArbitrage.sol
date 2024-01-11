pragma solidity ^0.8.0;

import "./console.sol";
import "./IERC20.sol";
import "./FlashLoanReceiverBase.sol";
import "./ILendingPoolAddressesProvider.sol";
import "./ILendingPool.sol";
import "./SafeMath.sol";
import "./IPulsarArbitrage.sol";
import "./IUniswapV2Pair.sol";

interface DepositableERC20 is IERC20 {
    function deposit() external payable;
}

contract test is FlashLoanReceiverBaseV1, IPulsarArbitrage {

    using SafeMath for uint256;

    address public wethAddress = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    DepositableERC20 wethToken = DepositableERC20(wethAddress);

    constructor(address _addressProvider) FlashLoanReceiverBaseV1(_addressProvider) public{
    }

    function executeArbitrage(address fromToken, uint256 amountIn, address[] calldata pools) public override returns (uint256){
        console.log("Executing Arbitrage function of the smart contract");
        bytes memory params = abi.encode(pools);

        ILendingPoolV1 lendingPool = ILendingPoolV1(addressesProvider.getLendingPool());
        lendingPool.flashLoan(address(this), fromToken, amountIn, params);
        return 0;
    }

    function executeOperation(
        address _reserve,
        uint256 _amount,
        uint256 _fee,
        bytes calldata _params
    )
        external
        override
    {
        require(_amount <= getBalanceInternal(address(this), _reserve), "Invalid balance, was the flashLoan successful?");

        address[] memory pools = abi.decode(_params, (address[]));

        uint256 nbrOfSwaps = pools.length;

        address toSwap = _reserve;
        uint256 amountToSwap = _amount;

        for (uint8 i = 0; i < nbrOfSwaps; i++) {
            address token0 = IUniswapV2Pair(pools[i]).token0();
            address token1 = IUniswapV2Pair(pools[i]).token1();

            IUniswapV2Pair(pools[i]).swap(
                toSwap == token0 ? amountToSwap : 0,
                toSwap == token1 ? amountToSwap : 0,
                address(this),
                bytes("not empty")
            );
            toSwap = toSwap == token0 ? token1 : token0;
            amountToSwap = getBalanceInternal(address(this), toSwap);
        }

        uint totalDebt = _amount.add(_fee);
        transferFundsBackToPoolInternal(_reserve, totalDebt);
    }

    // function wrapETH() public {
    //     uint256 ethBalanc = address(this).balance;
    //     require(ethBalanc > 0, "No eth available to wrap");
    //     console.log("Trying to wrap some eth");
    //     wethToken.deposit{value: ethBalanc}();
    // }

}