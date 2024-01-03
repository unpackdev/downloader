// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import "./SafeMath.sol";
import "./ReentrancyGuard.sol";

import "./IHope.sol";
import "./IUniswapV2Router02.sol";

contract HopeLiquiditySeed is ReentrancyGuard {
    using SafeMath for uint256;

    IHope public hope;
    IUniswapV2Router02 uniswapV2Router;

    uint256 public startBlock;
    uint256 public endBlock;

    uint256 public halfHope; // Half for the sale, half to seed liquidity
    uint256 public ethTotal;

    mapping (address => uint256) public amountDeposited;
    mapping (address => bool) public hasCollected;

    bool public isLiquidityInitialized = false;

    constructor(IHope _hopeAddress, IUniswapV2Router02 _uniswapV2Router, uint256 _startBlock, uint256 _endBlock) public {
        require(_startBlock < _endBlock, "EndBlock must be greater than StartBlock");
        hope = _hopeAddress;
        uniswapV2Router = _uniswapV2Router;
        startBlock = _startBlock;
        endBlock = _endBlock;
    }

    function _getBlockNumber() internal view returns(uint256) {
        return block.number;
    }

    function fundSale(uint256 _amount) public nonReentrant {
        require(_getBlockNumber() < endBlock, "Sale has ended");

        hope.transferFrom(msg.sender, address(this), _amount);
        halfHope = halfHope.add(_amount.div(2));
    }

    function initializeLiquidity() public nonReentrant {
        require(isLiquidityInitialized == false, "Liquidity already initialized");

        hope.approve(address(uniswapV2Router), uint256(-1));
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(address(hope), halfHope, 0, 0, address(0), block.timestamp);
        isLiquidityInitialized = true;
        hope.setLiquidityInitialized();
    }

    function deposit() public payable nonReentrant {
        require(_getBlockNumber() >= startBlock, "Sale has not started");
        require(msg.value > 0, "No eth sent");
        require(_getBlockNumber() < endBlock, "Sale has ended");

        amountDeposited[msg.sender] = amountDeposited[msg.sender].add(msg.value);
        ethTotal = ethTotal.add(msg.value);
    }

    function collect() public nonReentrant {
        require(_getBlockNumber() > endBlock, "Sale has not ended");
        require(isLiquidityInitialized, "Liquidity is not initialized");
        require(hasCollected[msg.sender] == false, "Address already collected its reward");
        require(amountDeposited[msg.sender] > 0, "Address did not contribute");

        hasCollected[msg.sender] = true;
        uint256 contribution = amountDeposited[msg.sender].mul(1e12).div(ethTotal);
        uint256 hopeAmount = halfHope.mul(contribution).div(1e12);
        safeHopeTransfer(msg.sender, hopeAmount);
    }

    // Safe hope transfer function, just in case if rounding error causes pool to not have enough HOPEs.
    function safeHopeTransfer(address _to, uint256 _amount) internal {
        uint256 hopeBal = hope.balanceOf(address(this));
        if (_amount > hopeBal) {
            hope.transfer(_to, hopeBal);
        } else {
            hope.transfer(_to, _amount);
        }
    }
}