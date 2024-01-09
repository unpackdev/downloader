// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
Updated Convex VestedEscrow
found at https://github.com/convex-eth/platform/blob/main/contracts/contracts/VestedEscrow.sol

Changes:
- update to solidity 0.8
- added back disable feature
- remove staking
- implement per address vesting start time
- implemented cliff
*/

import "./MathUtil.sol";
import "./IERC20.sol";
import "./Address.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";


contract CaskVestedEscrow is ReentrancyGuard{
    using SafeERC20 for IERC20;

    IERC20 public rewardToken;
    address public admin;
    address public fundAdmin;

    uint256 public startAfter;
    uint256 public duration;

    uint256 public initialLockedSupply;
    uint256 public unallocatedSupply;

    mapping(address => uint256) public startedAt;
    mapping(address => uint256) public cliffAt;
    mapping(address => uint256) public initialLocked;
    mapping(address => uint256) public totalClaimed;

    bool public canDisable;
    mapping(address => uint256) public disabledAt;

    address[] public members;

    event Fund(address indexed recipient, uint256 reward);
    event Claim(address indexed user, uint256 amount);
    event ToggleDisable(address recipient, bool disabled);

    constructor(
        address rewardToken_,
        uint256 startafter_,
        uint256 duration_,
        bool canDisable_,
        address fundAdmin_
    ) {
        require(startafter_ >= block.timestamp,"start must be future");
        require(duration_ > 0,"duration must be greater");

        rewardToken = IERC20(rewardToken_);
        startAfter = startafter_;
        duration = duration_;
        canDisable = canDisable_;
        admin = msg.sender;
        fundAdmin = fundAdmin_;
    }

    function setAdmin(address _admin) external {
        require(msg.sender == admin, "!auth");
        admin = _admin;
    }

    function setFundAdmin(address _fundadmin) external {
        require(msg.sender == admin, "!auth");
        fundAdmin = _fundadmin;
    }

    function addTokens(uint256 _amount) external returns(bool){
        require(msg.sender == admin, "!auth");

        rewardToken.safeTransferFrom(msg.sender, address(this), _amount);
        unallocatedSupply = unallocatedSupply + _amount;
        return true;
    }

    function fund(
        uint256 _startAt,
        uint256 _cliffDuration,
        address[] calldata _recipient,
        uint256[] calldata _amount
    ) external nonReentrant returns(bool){
        return _fund(_startAt, _cliffDuration, _recipient, _amount);
    }

    function fund(
        uint256 _startAt,
        address[] calldata _recipient,
        uint256[] calldata _amount
    ) external nonReentrant returns(bool){
        return _fund(_startAt, 0, _recipient, _amount);
    }

    function fund(
        address[] calldata _recipient,
        uint256[] calldata _amount
    ) external nonReentrant returns(bool){
        return _fund(startAfter, 0, _recipient, _amount);
    }

    function _fund(
        uint256 _startAt,
        uint256 _cliffDuration,
        address[] calldata _recipient,
        uint256[] calldata _amount
    ) internal returns(bool){
        require(msg.sender == fundAdmin || msg.sender == admin, "!auth");

        // startAt for this new batch is not allowed to start
        // before the global escrow startAfter date
        uint256 startAt = _startAt;
        if (startAt < startAfter) {
            startAt = startAfter;
        }

        uint256 totalAmount = 0;
        for(uint256 i = 0; i < _recipient.length; i++){
            uint256 amount = _amount[i];
            // can only set startedAt and cliffDuration on first funding
            if (startedAt[_recipient[i]] == 0){
                members.push(_recipient[i]);
                startedAt[_recipient[i]] = startAt;
                cliffAt[_recipient[i]] = startAt + _cliffDuration;
            }
            initialLocked[_recipient[i]] = initialLocked[_recipient[i]] + amount;
            totalAmount = totalAmount + amount;
            emit Fund(_recipient[i],amount);
        }

        require(totalAmount <= unallocatedSupply, "!balance");

        initialLockedSupply = initialLockedSupply + totalAmount;
        unallocatedSupply = unallocatedSupply - totalAmount;
        return true;
    }

    function toggle_disable(address _recipient) external {
        require(msg.sender == admin, "!auth");
        require(canDisable, "!canDisable");

        bool isEnabled = disabledAt[_recipient] == 0;
        if (isEnabled) {
            disabledAt[_recipient] = block.timestamp;
        } else {
            disabledAt[_recipient] = 0;
        }

        emit ToggleDisable(_recipient, isEnabled);
    }

    function disableCanDisable() external {
        require(msg.sender == admin, "!auth");
        canDisable = false;
    }

    function _totalVestedOf(address _recipient) internal view returns(uint256){
        uint256 startTime = startedAt[_recipient];
        uint256 endTime = disabledAt[_recipient];
        if (endTime == 0) {
            endTime = block.timestamp;
        }
        if(endTime < startTime){ // not started yet
            return 0;
        }
        if (cliffAt[_recipient] > endTime){ // cliff end not happened yet
            return 0;
        }
        uint256 locked = initialLocked[_recipient];
        uint256 elapsed = endTime - startTime;
        uint256 total = MathUtil.min(locked * elapsed / duration, locked );
        return total;
    }

    function _totalVested() internal view returns(uint256){
        if(block.timestamp < startAfter){
            return 0;
        }
        uint256 total = 0;
        for (uint256 i = 0; i < members.length; i++) {
            total = total + _totalVestedOf(members[i]);
        }
        return total;
    }

    function vestedSupply() external view returns(uint256){
        return _totalVested();
    }

    function lockedSupply() external view returns(uint256){
        return initialLockedSupply - _totalVested();
    }

    function vestedOf(address _recipient) external view returns(uint256){
        return _totalVestedOf(_recipient);
    }

    function balanceOf(address _recipient) external view returns(uint256){
        return _totalVestedOf(_recipient) - totalClaimed[_recipient];
    }

    function lockedOf(address _recipient) external view returns(uint256){
        return initialLocked[_recipient] - _totalVestedOf(_recipient);
    }

    function claim(address _recipient) public nonReentrant{
        uint256 vested = _totalVestedOf(_recipient);
        uint256 claimable = vested - totalClaimed[_recipient];

        totalClaimed[_recipient] = totalClaimed[_recipient] + claimable;
        rewardToken.safeTransfer(_recipient, claimable);

        emit Claim(msg.sender, claimable);
    }

    function claim() external{
        claim(msg.sender);
    }

}