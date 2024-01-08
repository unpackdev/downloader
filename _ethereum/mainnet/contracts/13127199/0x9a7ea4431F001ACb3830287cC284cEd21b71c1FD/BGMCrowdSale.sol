// contracts/SimpleCrowdsale.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.5.5;

import "./Crowdsale.sol";
import "./TimedCrowdsale.sol";

/**
 * @title SimpleCrowdsale
 * @dev This is an example of a fully fledged crowdsale.
 */
contract BGMCrowdSale is TimedCrowdsale {
    modifier onlyOwner() {
        require(msg.sender == _owner);
        _;
    }
    address payable public _owner;
    IERC20 private _token;

    constructor(
        uint256 rate,
        uint256 openingTime,
        uint256 closingTime,
        address payable wallet,
        IERC20 token
    )
        public
        Crowdsale(rate, wallet, token)
        TimedCrowdsale(openingTime, closingTime)
    {
        _token = token;
        _owner = wallet;
    }

    /**
     * @dev Extra token may remain after ICO time, so the owner
     * can withdraw extra token
     */
    function withdrawExtraTokens() public onlyOwner {
        // require(block.timestamp > this.closingTime(),"CrowdSale does not finished yet!");
        require(
            hasClosed(),
            "TimedCrowdsale: CrowdSale does not finished yet!"
        );

        uint256 remainBalance = _token.balanceOf(address(this));
        _token.transfer(_owner, remainBalance);
    }



    function  forwardFunds() public onlyOwner{
        _forwardFunds();
    }
}
