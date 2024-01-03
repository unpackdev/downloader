// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./IRewardDistributionRecipient.sol";
import "./IMintable.sol";
import "./Oracle.sol";
import "./Ownable.sol";
import "./SafeMath.sol";





contract MiningV3 is Ownable {
    using SafeMath for uint256;

    IUniswapV2Pair public pair;
    IMintable public token;
    IRewardDistributionRecipient public pool;

    Oracle public oracle;

    uint public constant DEV_REWARD = 10e18;
    uint public constant MINING_REWARD = 100e18;
    uint public constant BLOCK_TIME = 10 minutes;
    address public dev;
    uint public priceHighest;
    uint public blockTimestampLast;

    uint Xe18 = 1e18;

    constructor(address _pair, address _token, address _pool, address _oracle, address _dev) public {
        require(_pair != address(0), "invalid pair");
        require(_token != address(0), "invalid token");
        require(_pool != address(0), "invalid pool");
        require(_dev != address(0), "invalid dev");
        pair = IUniswapV2Pair(_pair);
        token = IMintable(_token);
        pool = IRewardDistributionRecipient(_pool);
        oracle = Oracle(_oracle);
        dev = _dev;
        uint price = oracle.consult(address(token), Xe18);
        blockTimestampLast = oracle.blockTimestampLast();
        priceHighest = price;
    }


    modifier isInBlockWindow() {
        require(inBlockWindow(), "not in block window");
        _;
    }

    function mine() isInBlockWindow public {
        try oracle.update() {} catch {}
        uint priceLast = oracle.consult(address(token), Xe18);
        if(priceLast > priceHighest){
            uint amount = MINING_REWARD;
            token.mint(address(pool), amount);
            token.mint(address(dev), DEV_REWARD);
            pool.notifyRewardAmount(amount);
            if(priceLast > priceHighest.mul(2) && priceHighest > 0){
                priceHighest = priceHighest.mul(2);
            }else{
                priceHighest = priceLast;
            }
            
        }
        blockTimestampLast = oracle.blockTimestampLast();
    }

    function newHighest() public view returns (bool) {
        return priceLast() > priceHighest;
    }


    function inBlockWindow() public view returns (bool){
        uint timeElapsed = block.timestamp - blockTimestampLast;
        return timeElapsed >= oracle.PERIOD();
    }

    function priceLast() public view returns (uint) {
        return oracle.consultNow(address(token), Xe18);
    }

    function setDev(address _dev) public onlyOwner {
        require(_dev != address(0), "invalid dev");
        dev = _dev;
    }
}
