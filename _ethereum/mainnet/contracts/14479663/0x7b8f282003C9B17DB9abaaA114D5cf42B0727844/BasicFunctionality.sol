// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./Counters.sol";
import "./ReentrancyGuard.sol";
import "./TimerController.sol";
import "./OwnerController.sol";
import "./AdminController.sol";
import "./BasicWithdraw.sol";

struct Props {
    address owner;
    uint256 costInWei;
}

/**
 * @dev SafeListBase is a base contract to create safe list and admin controlled NFT contracts,
 */
contract BasicFunctionality is
    OwnerController,
    AdminController,
    TimerController,
    ReentrancyGuard,
    BasicWithdraw
{
    /// @dev the cost of purchasing a token, in weic
    uint256 public costInWei;

    /// @dev is the contract enabled
    bool public isEnabled = false;

    /// @dev keeps track of the purchased tokens
    using Counters for Counters.Counter;
    Counters.Counter internal counter;

    constructor(Props memory props)
        ReentrancyGuard()
        OwnerController(props.owner)
    {
        costInWei = props.costInWei;
    }

    /// @dev makes sure the contract is enabled
    modifier onlyEnabled() {
        require(isEnabled, "not enabled");
        _;
    }

    /// @dev starts the contract by enabling it and starting the timer
    function start(uint256 drawLengthHours) external onlyAdmin {
        _startTimer(drawLengthHours);
        isEnabled = true;
    }

    /// @dev allows to withdraw all funds from the contract
    function withdraw(address payable to) external onlyOwner {
        _withdrawAllFunds(to);
    }

    /// @dev set a new cost
    function setCostInWei(uint256 newCostInWei) external onlyAdmin {
        costInWei = newCostInWei;
    }

    /// @dev set a new isEnabled
    function setIsEnabled(bool newIsEnabled) external onlyAdmin {
        isEnabled = newIsEnabled;
    }

    /// @dev set a new draw length in hours
    function setDrawLengthHours(uint256 timeInHours) external onlyAdmin {
        _setTimerEndsInHours(timeInHours);
    }

    function _incrementCount() internal {
        counter.increment();
    }

    /// @dev is the sender an admin
    function _isAdmin()
        internal
        view
        virtual
        override(AdminController)
        returns (bool)
    {
        return isOwner();
    }
}
