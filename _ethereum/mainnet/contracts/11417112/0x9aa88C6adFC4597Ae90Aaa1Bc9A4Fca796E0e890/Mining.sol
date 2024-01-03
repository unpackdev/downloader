// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./IUniswapV2Pair.sol";
import "./IRewardDistributionRecipient.sol";
import "./IMintable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";





contract Mining is Ownable {
    using SafeMath for uint256;

    IUniswapV2Pair public pair;
    IMintable public token;
    IRewardDistributionRecipient public pool;
    address dev;
    uint public constant BLOCK_TIME = 1 days;
    uint public lastBlocktime;
    uint public preR0;
    uint public preR1;
    bool public started;

    constructor(address _pair, address _token, address _pool, address _dev) public {
        require(_pair != address(0), "invalid pair");
        require(_token != address(0), "invalid token");
        require(_pool != address(0), "invalid pool");
        require(_dev != address(0), "invalid dev");
        pair = IUniswapV2Pair(_pair);
        token = IMintable(_token);
        pool = IRewardDistributionRecipient(_pool);
        dev = _dev;
    }

    modifier isStarted() {
        require(started, "not started");
        _;
    }

    modifier isInBlockWindow() {
        require(inBlockWindow(), "not in block window");
        _;
    }

    function mine() isInBlockWindow public {
        require(priceUp(), "CAN NOT MINE");
        uint amount = 90e18;
        token.mint(address(pool), amount);
        token.mint(address(dev), 10e18);
        pool.notifyRewardAmount(amount);
        (uint curR0, uint curR1, ) = pair.getReserves();
        if(curR0 > preR0.mul(2)){
            curR0 = preR0.mul(2);
        }
        if(curR1 > preR1.mul(2)){
            curR1 = preR1.mul(2);
        }
        preR0 = curR0;
        preR1 = curR1;
        lastBlocktime = block.timestamp;
    }

    function priceUp() public view isStarted returns (bool) {
        (uint curR0, uint curR1, ) = pair.getReserves();
        if(pair.token0() == address(token)){
            return curR0.mul(preR1) < curR1.mul(preR0);
        }else{
            return curR0.mul(preR1) > curR1.mul(preR0);
        }
    }


    function inBlockWindow() public view returns (bool){
        return block.timestamp > lastBlocktime.add(BLOCK_TIME);
    }

    function start() public onlyOwner {
        require(!started, "already started");
        (uint curR0, uint curR1, ) = pair.getReserves();
        require(curR0 > 0, "CAN NOT START");
        require(curR1 > 0, "CAN NOT START");
        preR0 = curR0;
        preR1 = curR1;
        lastBlocktime = block.timestamp;
        started = true;
    }

    function setDev(address _dev) public onlyOwner {
        require(_dev != address(0), "invalid dev");
        dev = _dev;
    }
}
