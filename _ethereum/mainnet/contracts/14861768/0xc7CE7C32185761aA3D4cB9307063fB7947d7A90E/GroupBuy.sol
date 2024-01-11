//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./OwnableUpgradeable.sol";
import "./Context.sol";
import "./SafeMath.sol";
import "./IERC20.sol";

interface IOptiSwap {
    function buyToken(address token, uint amountOutMin, uint deadline) external payable;
}

contract GroupBuy is OwnableUpgradeable {
    IERC20 token;
    mapping(address => uint256) private _balances;
    uint threshold;
    uint deadline;
    uint tokensBought;
    using SafeMath for uint256;

    receive() external payable {}

    function initialize(address set_token, uint set_threshold, uint set_deadline) public initializer {
        token = IERC20(set_token);
        threshold = set_threshold;
        deadline = set_deadline;
        __Ownable_init();
    }

    function getToken() public view returns(address) {
        return address(token);
    }

    function getThreshold() public view returns(uint) {
        return threshold;
    }

    function getDeadline() public view returns(uint) {
        return deadline;
    }

    function contribute() public payable {
        //Add to buy pot
        require (tokensBought == 0, "GroupBuy is already complete.");
        require (address(this).balance <= threshold, "Contribution too large!");
        _balances[_msgSender()] += msg.value;
    }

    function getContributionOf(address account) public view returns (uint) {
        return _balances[account];
    }

    function recover() public {
        //Release funds back after deadline.
        require(block.timestamp > deadline, "GroupBuy is still active.");
        require(tokensBought == 0, "GroupBuy already happened! Claim your tokens.");
        address payable sender = payable(_msgSender());
        sender.transfer(_balances[sender]);
        _balances[sender] = 0;
    }

    function finalize(uint amountOutMin, uint buy_deadline) public onlyOwner() {
        //End GroupBuy with market purchase
        require (address(this).balance >= threshold, "Threshold not met!");
        IOptiSwap(0x293be20db3e4110670aFBcAE916393e40BC9B42b).buyToken
            {value: address(this).balance}
            (address(token), amountOutMin, buy_deadline);
        tokensBought = token.balanceOf(address(this));
    }    

    function getTokensBought() public view returns (uint) {
        return tokensBought;
    }

    function claim() public {
        //Release purchased tokens
        require(tokensBought > 0, "GroupBuy not finalized yet!");
        uint userTokenShare = _balances[_msgSender()].mul(tokensBought).div(threshold);
        token.transfer(_msgSender(), userTokenShare);
        _balances[_msgSender()] = 0;
    }

}
