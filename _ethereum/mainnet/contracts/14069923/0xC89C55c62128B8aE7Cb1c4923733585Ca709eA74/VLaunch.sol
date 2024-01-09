// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

import "./IERC20.sol";
import "./ReentrancyGuard.sol";
import "./SafeMath.sol";

contract VLaunch is ReentrancyGuard {
    using SafeMath for uint256;

    IERC20 myNFT;
    uint256 private _initTime;
    uint256 private _vestingEnd;

    mapping(address => bool) _approved;
    mapping(address => uint256) _totalBalance;
    mapping(address => uint256) _claimed;

    event Withdraw(address account, uint256 amount);

    constructor(address _myNFT) {
        myNFT = IERC20(_myNFT);
        _initTime = block.timestamp;
        _vestingEnd = _initTime + 365 days;
        _approved[msg.sender] = true;
    }

    /// @notice Approval modifier. It's a replacement for the typical Owner.isOwner() since this contract may be called from the token contract.
    /// It is possible to add addresses to the approval list with addEmeregencyApproval
    /// @dev See: emeregencyWithdraw();
    modifier onlyApproved() {
        require(_approved[msg.sender], "Not approved for emergency withdrawal");
        _;
    }

    /// @notice The total supply of myNFT tokens which this contract is currently holding.
    function totalSupply() public view returns (uint256) {
        return myNFT.balanceOf(address(this));
    }

    /// @notice The current claimable amount the user has available.
    /// @dev View function for front-end display.
    function claimable(address account) public view returns (uint256) {
        return _getAmount(account);
    }

    /// @notice The total remaining amount the user has stored within this contract.
    /// This includes amounts which are currently unclaimable and is meant for viewing on the frontend.
    function balanceOf(address account) external view returns (uint256) {
        uint256 totalUnclaimed = _totalBalance[account].sub(_claimed[account]);
        return totalUnclaimed;
    }

    /// @notice Updates the amount stored for the user. 
    /// This is to be executed from the base token contract, it notifies this locker contract of the amount which is allocated to each individual address.
    /// @param account the account to add amounts to
    /// @param amount the amount to assign to the user. 
    function updateUserAmount(address account, uint256 amount)
        external
        onlyApproved
        nonReentrant
    {
        _totalBalance[account] = _totalBalance[account].add(amount);
    }

    /// @notice Withdraws the users total earned vested amount.
    /// @dev Since the pathway of the withdraw function explicitly calls only one internal withdraw function, _withdrawInitial() is included here for users who have not claimed their initial 10%
    function withdraw(address account) external {
        //uint256 amount = _getAmount(account);
        uint256 amount = claimable(account);
        _claimed[account] = _claimed[account].add(amount);
        myNFT.transfer(account, amount);
        emit Withdraw(account, amount);
    }

    /// @notice Contingency, only add to this if necessary, since approval allows the wallet to withdraw the entire amount from this contract.
    function addEmergencyApproval(address account) external onlyApproved {
        _approved[account] = true;
    }

    /// @notice ONLY FOR EMERGENCY. Emergency withdrawal to the approved callers address.
    /// @dev This is for if somebody is unable to claim or something unusual happens which leaves a remaining balance inside of this contract.
    function emergencyWithdraw() external onlyApproved returns (bool) {
        uint256 supply = totalSupply();
        return myNFT.transfer(msg.sender, supply);
    }

    /// @notice Gets the reward rate at which tokens should be rewarded over the 12 month period.
    /// @return The total reward rate based on the entire vesting period.
    function _getRate(address account) internal view returns (uint256) {
        uint256 totalTime = _vestingEnd.sub(_initTime);
        uint256 rate = _totalBalance[account].div(totalTime);
        return rate;
    }

    /// @notice Gets the total amount a user should receive during a claim occurring during the vesting period.
    /// @dev  We multiply the rewardReward by the total time passed after the vesting period begins. With this total, we subtract the amount already claimed to the current reward for the user.
    /// @return The total amount receivable when claiming after vesting begins.
    function _getAmount(address account) internal view returns (uint256) {
        uint256 rewardRate = _getRate(account);
        uint256 totalTime = block.timestamp.sub(_initTime);
        uint256 adjustedAmount = rewardRate.mul(totalTime).sub(
            _claimed[account]
        );
        uint256 totalUnclaimed = _totalBalance[account].sub(_claimed[account]);
        /// This ensures that the maximum amount distributed is never above the users unclaimed amount.
        if (adjustedAmount > totalUnclaimed) return totalUnclaimed;
        return adjustedAmount;
    }
}
