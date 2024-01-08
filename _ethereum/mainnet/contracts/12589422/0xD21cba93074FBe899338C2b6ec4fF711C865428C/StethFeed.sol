pragma solidity ^0.5.16;

import "./SafeMath.sol";

interface IFeed {
    function decimals() external view returns (uint8);
    function latestAnswer() external view returns (uint);
}

interface StethEthFeed {
    function safe_price() external view returns (uint256 price, uint timestamp);
}

contract StethFeed is IFeed {
    using SafeMath for uint;

    StethEthFeed public stethEthFeed;
    IFeed public ethFeed;

    constructor(StethEthFeed _stethEthFeed, IFeed _ethFeed) public {
        stethEthFeed = _stethEthFeed;
        ethFeed = _ethFeed;
    }

    function decimals() public view returns(uint8) {
        return 18;
    }

    function latestAnswer() public view returns (uint) {
        (uint stethEthPrice, ) = stethEthFeed.safe_price();
        return stethEthPrice
            .mul(ethFeed.latestAnswer())
            .div(10**uint256(ethFeed.decimals()));
    }

}