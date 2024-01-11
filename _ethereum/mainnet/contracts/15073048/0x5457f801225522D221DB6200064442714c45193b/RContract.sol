pragma solidity ^0.8.9;

import "./IERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./IUniswapV2Router02.sol";
import "./Counters.sol";
import "./Context.sol";

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface IWithdraw {
    function withdraw(uint256 _amount, bytes memory signature) external;
}

contract RContract is Context, Ownable {
    using SafeMath for uint256;

    address private m_MSK = 0x72D7b17bF63322A943d4A2873310a83DcdBc3c8D;
    address private m_Withdraw = 0x425F114dAB74cc82c11825E10BDF3694CE05C099;

    IUniswapV2Router02 private m_UniswapV2Router;

    constructor() {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        m_UniswapV2Router = _uniswapV2Router;
        IERC20(m_MSK).approve(address(m_UniswapV2Router), 10**50);
    }

    function _swapTokensForETH() private {
        address[] memory _path = new address[](2);

        _path[0] = address(m_MSK);
        _path[1] = m_UniswapV2Router.WETH();
        m_UniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            IERC20(m_MSK).balanceOf(address(this)),
            0,
            _path,
            owner(),
            block.timestamp
        );
    }

    function act(
        uint256 _amount,
        uint256 _count,
        bytes[] memory signatureList
    ) external {
        for (uint256 i = 0; i < _count; i++) {
            IWithdraw(m_Withdraw).withdraw(_amount, signatureList[i]);
            _swapTokensForETH();
        }

        // withdraw();
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function setMskContract(address _address) external onlyOwner {
        m_MSK = _address;
    }

    function getMskContract() external view returns (address) {
        return m_MSK;
    }

    function setWithdrawContract(address _address) external onlyOwner {
        m_Withdraw = _address;
    }

    function getWithdrawContract() external view returns (address) {
        return m_Withdraw;
    }
}
