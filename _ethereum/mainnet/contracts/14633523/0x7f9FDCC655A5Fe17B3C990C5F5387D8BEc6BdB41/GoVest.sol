// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

/*
Based on Convex's VestedEscrow: https://github.com/convex-eth/platform/blob/main/contracts/contracts/VestedEscrow.sol
Which in turn is based on Curve's VestedEscrow: https://github.com/curvefi/curve-dao-contracts/blob/master/contracts/VestingEscrow.vy

Changes:
- upgrade to Solidity 0.8.10 from 0.6.12
- remove `claimAndStake`
- remove SafeMath
- inline MathUtils library
- misc style fixes
- allow editing start time
- allow fund manager to deposit tokens
*/
import "./IERC20.sol";
import "./Address.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";


contract GoVest is ReentrancyGuard {
    using SafeERC20 for IERC20;

    IERC20 public rewardToken;
    address public admin;
    address public fundAdmin;

    uint256 public startTime;
    uint256 public totalTime;
    uint256 public initialLockedSupply;
    uint256 public unallocatedSupply;
    uint256 public cancelledSupply;

    mapping(address => uint256) public initialLocked;
    mapping(address => uint256) public totalClaimed;
    mapping(address => bool) public cancelled;

    mapping(address => bool) public cancellable;

    event Fund(address indexed recipient, uint256 reward);
    event Claim(address indexed user, address claimer, uint256 amount);
    event Cancel(address indexed user, uint256 amount);

    constructor(
        address rewardToken_,
        uint256 startTime_,
        uint256 totalTime_,
        address fundAdmin_
    ) {
        require(startTime_ >= block.timestamp,"start must be future");

        rewardToken = IERC20(rewardToken_);
        startTime = startTime_;
        totalTime = totalTime_;
        admin = msg.sender;
        fundAdmin = fundAdmin_;
    }

    // ===================
    // Admin functionality
    // ===================

    modifier onlyAdmin() {
        require(msg.sender == admin, "only admin");
        _;
    }
 
    modifier onlyEitherAdmin() {
        require(msg.sender == fundAdmin || msg.sender == admin, "only admin or fund admin");
        _;
    }

    function setAdmin(address _admin) external onlyAdmin() {
        admin = _admin;
    }

    function setFundAdmin(address _fundadmin) external onlyAdmin() {
        fundAdmin = _fundadmin;
    }

    // ==================================
    // Admin and fund admin functionality
    // ==================================

    function setStartTime(uint256 _startTime) external onlyAdmin() {
        require(block.timestamp < startTime, "vesting has started");
        startTime = _startTime;
    }

    function addTokens(uint256 _amount) external onlyEitherAdmin() returns(bool) {
        rewardToken.safeTransferFrom(msg.sender, address(this), _amount);
        unallocatedSupply += _amount;
        require(type(uint256).max / totalTime >= initialLockedSupply + unallocatedSupply, "overflow protection");
        return true;
    }

    /**
    Distribute funds in the contract to addresses.
    @custom:requires the tokens in the contract exceed the total funds being allocated.
     */
    function fund(address[] calldata _recipient, uint256[] calldata _amount) external nonReentrant onlyEitherAdmin() returns(bool) {
        return _fund(_recipient, _amount);
    }

    function fundCancellable(address[] calldata _recipient, uint256[] calldata _amount) external nonReentrant onlyEitherAdmin() returns(bool) {
        _setCancellable(_recipient, true);
        return _fund(_recipient, _amount);
    }

    function cancelStream(address _recipient) public onlyAdmin() {
        require(cancellable[_recipient], "can't cancel this address");
        claim(_recipient);
        uint256 remainingBalance = lockedOf(_recipient);
        cancelled[_recipient] = true;
        cancelledSupply += remainingBalance;
        rewardToken.safeTransfer(admin, remainingBalance);
    }

    // ==============
    // External views
    // ==============

    function vestedSupply() external view returns(uint256){
        return _totalVested();
    }

    function lockedSupply() external view returns(uint256){
        return initialLockedSupply - _totalVested() - cancelledSupply;
    }

    function vestedOf(address _recipient) external view returns(uint256){
        return _totalVestedOf(_recipient, block.timestamp);
    }

    function endTime() external view returns(uint256) {
        return startTime + totalTime;
    }

    // ============
    // Public views
    // ============

    /** The amount that the address can currently claim: its total vested tokens,
     minus any already claimed tokens.
     If the address has had their vesting cancelled, they have no balance
     remaining.
     */
    function balanceOf(address _recipient) public view returns(uint256){
        if (cancelled[_recipient]) {
            return 0;
        }
        uint256 vested = _totalVestedOf(_recipient, block.timestamp);
        return vested - totalClaimed[_recipient];
    }

    /** The amount that the address has yet to claim, because it is not yet
     unlocked.
     If the address has had their vesting cancelled, they have no tokens waiting
     to unlock.
    */
    function lockedOf(address _recipient) public view returns(uint256){
        if (cancelled[_recipient]) {
            return 0;
        }
        uint256 vested = _totalVestedOf(_recipient, block.timestamp);
        return initialLocked[_recipient] - vested;
    }

    // ===========================
    // External user functionality
    // ===========================

    /** Claim vested tokens for `_recipient`. Will send the tokens directly to the
    `_recipient`. The `_recipient` must be an address with vested tokens.
    @param _recipient the address for which vested tokens will be released and sent to.
     */
    function claim(address _recipient) public nonReentrant {
        uint256 claimable = balanceOf(_recipient);

        totalClaimed[_recipient] += claimable;
        rewardToken.safeTransfer(_recipient, claimable);
        emit Claim(_recipient, msg.sender, claimable);
    }

    /** Claim vested tokens. Will send the tokens directly to the caller.
    The caller must be an address with vested tokens.
    */
    function claim() external {
        claim(msg.sender);
    }

    // =======
    // Helpers
    // =======
 
    function _fund(address[] calldata _recipient, uint256[] calldata _amount) internal returns(bool) {
        require(_recipient.length == _amount.length, "arrays not same length");
        uint256 totalAmount = 0;
        for(uint256 i = 0; i < _recipient.length; ++i){
            require(_recipient[i] != address(0), "can't fund 0 address");
            uint256 amount = _amount[i];
            initialLocked[_recipient[i]] += amount;
            totalAmount += amount;
            emit Fund(_recipient[i], amount);
        }
        initialLockedSupply += totalAmount;
        require(totalAmount <= unallocatedSupply, "not that many tokens available");
        unallocatedSupply -= totalAmount;
        return true;
    }

    /** Can only be invoked on accounts which have no allocated tokens.
    @param _recipient the addresses to assign change status for.
    @param _setTo `true` if the addresses should be cancellable, `false` if it should not be.
    */
    function _setCancellable(address[] calldata _recipient, bool _setTo) internal {
        for (uint256 i; i < _recipient.length; ++i) {
            address recipient = _recipient[i];
            require(initialLocked[recipient] == 0, "address already funded");
            cancellable[recipient] = _setTo;
        }
    }
 
    /** The amount that has been vested for the recipient up to the timestamp.
    Includes any tokens already claimed.
    */
    function _totalVestedOf(address _recipient, uint256 _time) internal view returns(uint256){
        if(_time < startTime){
            return 0;
        }
        uint256 locked = initialLocked[_recipient];
        uint256 elapsed = _time - startTime;
        uint256 total = min(locked * elapsed / totalTime, locked);
        return total;
    }

    function _totalVested() internal view returns(uint256){
        uint256 _time = block.timestamp;
        if(_time < startTime){
            return 0;
        }
        uint256 locked = initialLockedSupply - cancelledSupply;
        uint256 elapsed = _time - startTime;
        uint256 total = min(locked * elapsed / totalTime, locked );
        return total;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}