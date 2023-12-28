// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
}

abstract contract VestingAccessControl {
    address public owner;
    mapping(address => bool) public beneficiaries;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the contract owner");
        _;
    }

    modifier onlyBeneficiary() {
        require(beneficiaries[msg.sender], "Not a beneficiary");
        _;
    }
}

/**
 * @title UpfrontReentrancyGuard
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting contracts must use the `nonReentrant` modifier on functions or
 * external calls that should be protected against reentrancy attacks.
 *
 * When the `nonReentrant` modifier is used, the function execution will be
 * halted if a reentrant call is detected, thereby guarding against such attacks.
 */
abstract contract UpfrontReentrancyGuard {
    // Internal status variable to keep track of the call state.
    // It's set to 1 during contract construction, representing the non-reentrant state.
    // When a function with the `nonReentrant` modifier is called, `_status` will be set to 2.
    uint8 private _status;

    constructor () {
        _status = 1; // Initialize the contract in the non-reentrant state.
    }

    /**
     * @dev Modifier to prevent reentrant calls.
     * It will revert the transaction if a reentrant call is detected.
     *
     * This modifier checks if the current call status is `1` (non-reentrant),
     * sets the status to `2` to represent an ongoing call, and then reverts it back to `1`
     * once the function call is completed.
     */
    modifier nonReentrant() {
        // If the status is 2, a reentrant call is detected, so we revert.
        require(_status != 2, "UpfrontReentrancyGuard: reentrant call");

        // Set the status to 2 to signal the start of a function execution.
        _status = 2;

        // Function execution is placed here by the `_;` placeholder.
        _;

        // Set the status back to 1 to indicate the end of a function execution.
        _status = 1;
    }
}

contract TokenVesting is VestingAccessControl, UpfrontReentrancyGuard {
    enum VestingType { LINEAR, GRADED, CLIFF, BASIC_LOCK }

    struct VestingInfo {
        uint256 vestingId; // Unique ID for each vesting schedule
        address user; // Address of the user who locked tokens
        address token; // Address of the token
        uint256 amount; // Amount of tokens locked
        uint256 start; // Start time of the vesting
        uint256 cliff; // Cliff duration (0 if not applicable)
         uint256 duration; // Duration of the vesting schedule
        uint256 claimed; // Amount claimed so far
        bool finished; // True if the entire amount is claimed
        VestingType vestingType; // Type of vesting (Basic Lock, Linear, etc.)
        uint256[] gradedPercentages; // Percentages for graded vesting
    }

    mapping(address => VestingInfo[]) private userVestings; // Maps user address to their vesting schedules
    mapping(uint256 => VestingInfo) private vestingById; // Maps vesting ID to the vesting schedule

    uint256 private nextVestingId;
    address payable public feeWallet;
    uint256 public feePercentage = 25; // 0.25% in basis points

    

    event DepositMade(address indexed user, address indexed token, uint256 amount, uint256 duration, VestingType vestingType, uint256 vestingId);
    event TokensClaimed(address indexed user, address indexed token, uint256 amount, uint256 vestingId);

    constructor(address payable _feeWallet) {
        feeWallet = _feeWallet;
    }

    function _generateVestingId() private returns (uint256) {
        return nextVestingId++;
    }

    function changeFeeWallet(address payable newFeeWallet) external onlyOwner {
        require(newFeeWallet != address(0), "Invalid address");
        feeWallet = newFeeWallet;
    }

    function depositBasicLock(address token, uint256 amount, uint256 durationInMinutes) external payable nonReentrant {
        require(msg.value == 0.03 ether, "Fee of 0.03 ETH not sent");
        require(durationInMinutes > 0, "Lock duration must be more than 0");
        require(amount > 0, "Amount must be greater than 0");

        uint256 durationInSeconds = durationInMinutes * 1 minutes; // Convert duration to seconds
        _deposit(token, amount, 0, durationInSeconds, VestingType.BASIC_LOCK, new uint256[](0));
    }

    function depositLinear(address token, uint256 amount, uint256 durationInMinutes) external payable nonReentrant {
        require(msg.value == 0.03 ether, "Fee of 0.03 ETH not sent");
        require(durationInMinutes > 0, "Lock duration must be more than 0");
        require(amount > 0, "Amount must be greater than 0");

        uint256 durationInSeconds = durationInMinutes * 1 minutes; // Convert duration to seconds
        _deposit(token, amount, 0, durationInSeconds, VestingType.LINEAR, new uint256[](0));
    }

    function depositGraded(
        address token, 
        uint256 amount, 
        uint256 durationInMinutes, 
        uint256[] memory gradedPercentages
    ) external payable nonReentrant {
        require(msg.value == 0.03 ether, "Fee of 0.03 ETH not sent");
        require(durationInMinutes > 0, "Lock duration must be more than 0");
        require(amount > 0, "Amount must be greater than 0");
        require(_isValidGradedPercentages(gradedPercentages), "Invalid graded percentages");

        uint256 durationInSeconds = durationInMinutes * 1 minutes; // Convert duration to seconds
        _deposit(token, amount, 0, durationInSeconds, VestingType.GRADED, gradedPercentages);
    }

    function _isValidGradedPercentages(uint256[] memory percentages) private pure returns (bool) {
        uint256 totalPercent = 0;
        for (uint i = 0; i < percentages.length; i++) {
            totalPercent += percentages[i];
        }
        return totalPercent == 100;
    }

    function depositCliff(
        address token, 
        uint256 amount, 
        uint256 cliffDurationInMinutes, 
        uint256 durationInMinutes, 
        uint256[] memory gradedPercentages
    ) external payable nonReentrant {
        require(msg.value == 0.03 ether, "Fee of 0.03 ETH not sent");
        require(cliffDurationInMinutes > 0, "Cliff duration must be more than 0");
        require(durationInMinutes > cliffDurationInMinutes, "Total duration must be greater than cliff duration");
        require(amount > 0, "Amount must be greater than 0");
        require(_isValidGradedPercentages(gradedPercentages), "Invalid graded percentages");

        uint256 cliffDurationInSeconds = cliffDurationInMinutes * 1 minutes;
        uint256 durationInSeconds = durationInMinutes * 1 minutes;

        _deposit(token, amount, cliffDurationInSeconds, durationInSeconds, VestingType.CLIFF, gradedPercentages);
    }

    function _deposit(address token, uint256 amount, uint256 cliffDuration, uint256 duration, VestingType vestingType, uint256[] memory gradedPercentages) internal {
        uint256 vestingId = _generateVestingId();
        uint256 fee = (amount * feePercentage) / 10000;
        uint256 depositAmount = amount - fee;
        uint256 cliffStart = (vestingType == VestingType.CLIFF) ? block.timestamp + cliffDuration : block.timestamp;

        IERC20(token).transferFrom(msg.sender, address(this), depositAmount);
        IERC20(token).transferFrom(msg.sender, feeWallet, fee);

        VestingInfo memory newVesting = VestingInfo({
            vestingId: vestingId,
            user: msg.sender,
            token: token,
            amount: depositAmount,
            start: block.timestamp,
            cliff: cliffStart, // Correctly set the cliff start time
            duration: duration, // Duration of the vesting
            claimed: 0,
            finished: false,
            vestingType: vestingType,
            gradedPercentages: gradedPercentages
        });

        userVestings[msg.sender].push(newVesting);
        vestingById[vestingId] = newVesting;
        // Add user to beneficiaries mapping
        beneficiaries[msg.sender] = true;

        emit DepositMade(msg.sender, token, depositAmount, duration, vestingType, vestingId);
    }

    function claim(uint256 vestingId) external onlyBeneficiary nonReentrant {
        require(vestingId < nextVestingId, "Invalid vesting ID");

        VestingInfo storage vesting = vestingById[vestingId];
        require(vesting.user == msg.sender, "Caller is not the beneficiary");
        require(!vesting.finished, "Vesting is already completed");
        require(vesting.start <= block.timestamp, "Vesting has not started yet");

        uint256 releasable = _calculateReleasableAmount(vesting);

        require(releasable > 0, "No tokens to release yet");

        vesting.claimed += releasable;
        if (vesting.claimed >= vesting.amount) {
            vesting.finished = true;
        }

        IERC20(vesting.token).transfer(msg.sender, releasable);

        emit TokensClaimed(msg.sender, vesting.token, releasable, vestingId);
    }

    function _calculateReleasableAmount(VestingInfo storage vesting) internal view returns (uint256) {
        uint256 elapsed = block.timestamp - vesting.start;
        uint256 totalAmount = vesting.amount;
        uint256 vestedAmount;

        if (vesting.vestingType == VestingType.LINEAR) {
            uint256 vestingEnd = vesting.start + vesting.duration;
            if (block.timestamp > vestingEnd) {
                vestedAmount = totalAmount; // Vesting period is over
            } else {
                vestedAmount = (totalAmount * elapsed) / vesting.duration;
            }
        }

        if (vesting.vestingType == VestingType.BASIC_LOCK) {
            if (block.timestamp >= vesting.start + vesting.duration) {
                vestedAmount = totalAmount; // Entire amount is available after lock duration
            } else {
                vestedAmount = 0; // Nothing is vested until the end of the duration
            }
        }

        if (vesting.vestingType == VestingType.CLIFF) {
            if (elapsed < vesting.cliff - vesting.start) {
                return 0; // No tokens are released during the cliff
            }

            // Calculate vested amount for graded release after the cliff
            uint256 postCliffElapsed = elapsed - (vesting.cliff - vesting.start);
            uint256 postCliffDuration = vesting.duration - (vesting.cliff - vesting.start);
            uint256 intervalDuration = postCliffDuration / vesting.gradedPercentages.length;
            uint256 totalPercentVested = 0;

        for (uint256 i = 0; i < vesting.gradedPercentages.length; i++) {
            if (postCliffElapsed >= intervalDuration * (i + 1)) {
                totalPercentVested += vesting.gradedPercentages[i];
            }
        }

        vestedAmount = (totalAmount * totalPercentVested) / 100;
    }
        // ... [logic for future updates] ...

        return vestedAmount > vesting.claimed ? vestedAmount - vesting.claimed : 0;
    }

    function withdrawEther(uint256 amount) external onlyOwner {
        require(amount <= address(this).balance, "Insufficient balance");
        payable(owner).transfer(amount);
    }

    function getVestingDetailsById(uint256 vestingId) external view returns (VestingInfo memory vestingDetails) {
        require(vestingId < nextVestingId, "Invalid vesting ID");
        vestingDetails = vestingById[vestingId];
    }

    receive() external payable {}
}