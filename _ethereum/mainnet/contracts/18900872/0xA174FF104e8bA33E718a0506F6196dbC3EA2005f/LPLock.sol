// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "./Ownable.sol";
import "./IERC20.sol";


contract LPLock is Ownable {

    uint256 public immutable ONE_WEEK = 604800; //this is the delay on retrieving the LPs
    uint256 public time;
    bool public coolStarted;
    address public lp;

    event coolDownStarted(uint256 _timestamp);
    event LPWithdrawn();

    constructor(address _lp) Ownable(msg.sender) {
        lp = _lp;
    }

    /// @notice this function is used by the LP owner to deposit the LP inside
    function depositLP(uint256 _amount) public onlyOwner {
        IERC20(lp).transferFrom(msg.sender, address(this), _amount);
    }
    /// @notice this function is used to check the balance of LP tokens in this contract
    function lpBalance() public view returns(uint _lpBal) {
        return IERC20(lp).balanceOf(address(this));
    }
    /// @notice this function starts the cooldown period (1 week) for owner to retrieve LPs
    function startTimer() public onlyOwner {
        time = block.timestamp;
        coolStarted = true;

        emit coolDownStarted(block.timestamp);
    }
    /// @notice after one week has passed, the owner can call this to retrieve the LP tokens. 
    function withdrawLP() public onlyOwner {
        require (block.timestamp > time + ONE_WEEK);
        require (coolStarted == true);
        uint256 lpSize = lpBalance();
        IERC20(lp).transfer(msg.sender, lpSize);
        coolStarted = false;

        emit LPWithdrawn();
    }


}