// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.10;

import "./IERC20.sol";
import "./ERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";
import "./Math.sol";
import "./ReentrancyGuard.sol";

struct CreateVestingInput {
    address user;
    uint128 amount;
}

/**
 * @param rate percentage vested from total amount during the phase in BPS
 * @param endAt Time when phase ends
 * @param minimumClaimablePeriod for linear vesting it would be "1 seconds", for weekly westing it would be "1 weeks", if not set(set to zero) user will be able to claim only after phase ends
 */
struct Phase {
    uint256 rate;
    uint256 endAt;
    uint256 minimumClaimablePeriod;
}

/**
 * @title VestingIDO
 * @dev no user can claim while contract is in locked state
 */
contract VestingIDO is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    error VestingIsNotUnlocked();
    error NoZeroAddress(string param);
    error CannotReinitializeAfterFirstClaim();
    error NothingToClaimCurrentlyPleaseTryAgainLater();
    error DepositedAmountIsInsufficientPleaseDepositMore();
    error WrongInputParameters();
    error AlreadyUnlocked();
    error OnlyOneVestingPerAddress();
    error MustNotBeZero(string param);
    error NoActiveVesting();
    error EmptyInputArray();

    /**
     * @param amount Total amount allocated for user
     * @param amountClaimed Total amount claimed by user so far
     * @param lastClaimAt Timestamp from user last claim
     */
    struct UserVesting {
        uint256 amount;
        uint256 amountClaimed;
        uint256 lastClaimAt;
    }

    bool public locked = false;
    uint256 public totalAmountAllocated; // Amount owner allocated for all users
    uint256 public totalAmountClaimed; // Amount claimed by all users

    uint256 public constant RATE_CONVERTER = 10000;

    IERC20 public vestedToken;

    string public name;
    uint256 public startDateAt;
    uint256 public vestingEndAt;
    uint256 public claimableAtStart; // in BPS
    bool public airdroptedAtStart;
    Phase[] public phases;

    mapping(address => UserVesting) public vestings;

    event NewVestingCreated(address indexed user, uint256 amount);

    event NewClaim(address indexed user, uint256 amountClaimed);

    constructor(
        IERC20 _vestedToken,
        string memory _name,
        uint256 _startDateAt,
        uint256 _claimableAtStart,
        bool _airdroptedAtStart,
        Phase[] memory _phases
    ) {
        _initialize(
            _vestedToken,
            _name,
            _startDateAt,
            _claimableAtStart,
            _airdroptedAtStart,
            _phases
        );
    }

    function reinitialize(
        IERC20 _vestedToken,
        string memory _name,
        uint256 _startDateAt,
        uint256 _claimableAtStart,
        Phase[] calldata _phases
    ) external onlyOwner {
        if (totalAmountClaimed != 0) {
            revert CannotReinitializeAfterFirstClaim();
        }

        _initialize(
            _vestedToken,
            _name,
            _startDateAt,
            _claimableAtStart,
            false,
            _phases
        );
    }

    function _initialize(
        IERC20 _vestedToken,
        string memory _name,
        uint256 _startDateAt,
        uint256 _claimableAtStart,
        bool _airdroptedAtStart,
        Phase[] memory _phases
    ) private {
        uint256 prevStartDate = _startDateAt;
        uint256 total = _claimableAtStart;
        for (uint256 i = 0; i < _phases.length; i++) {
            Phase memory phase = _phases[i];
            if (prevStartDate > phase.endAt) {
                // phases should be ordered ascending by end date and should not overlap
                revert WrongInputParameters();
            }

            total += phase.rate;

            prevStartDate = phase.endAt;
        }

        if (total / RATE_CONVERTER != 1) {
            revert WrongInputParameters();
        }

        if (address(_vestedToken) == address(0)) {
            revert NoZeroAddress("_vestedToken");
        }

        name = _name;
        vestedToken = _vestedToken;
        startDateAt = _startDateAt;
        // set vesting end date to last phase end date, if there is not phases then set end date to start date(e.g. for 100% claim at TGE)
        vestingEndAt = _phases.length > 0
            ? _phases[_phases.length - 1].endAt
            : _startDateAt;
        claimableAtStart = _claimableAtStart;
        airdroptedAtStart = _airdroptedAtStart;
        // clear the phases array in case of reinitialization
        delete phases;
        for (uint256 i = 0; i < _phases.length; i++) {
            phases.push(_phases[i]);
        }
    }

    /**
     * @notice allow users to claim their vested tokens
     */
    function setLock(bool _locked) external onlyOwner {
        locked = _locked;
    }

    /**
     * @notice Move vesting to another address in case user lose access to his original account
     */
    function moveVesting(address from, address to) external onlyOwner {
        UserVesting memory vesting = vestings[from];
        if (vesting.amount - vesting.amountClaimed == 0) {
            revert NoActiveVesting();
        }
        if (vestings[to].amount > 0) {
            revert OnlyOneVestingPerAddress();
        }
        if (to == address(0)) {
            revert NoZeroAddress("to");
        }

        vestings[to] = vesting;
        delete vestings[from];
    }

    /**
     * @notice create vesting for user, only one vesting per user address
     * @dev owner needs to first deploy enough tokens to vesting contract address
     */
    function createVestings(
        CreateVestingInput[] calldata vestingsInput,
        bool depositCheck
    ) external onlyOwner {
        if (vestingsInput.length == 0) {
            revert EmptyInputArray();
        }
        uint256 totalDepositedAmount = getDepositedAmount();
        uint256 amountAllocated;

        for (uint64 i = 0; i < vestingsInput.length; i++) {
            amountAllocated += vestingsInput[i].amount;
        }

        if (airdroptedAtStart) {
            totalAmountClaimed +=
                (amountAllocated * claimableAtStart) /
                RATE_CONVERTER;
        }

        if (depositCheck) {
            // check if depositor have enough credit
            if (
                (totalDepositedAmount +
                    totalAmountClaimed -
                    totalAmountAllocated) < amountAllocated
            ) {
                revert DepositedAmountIsInsufficientPleaseDepositMore();
            }
        }

        for (uint64 i = 0; i < vestingsInput.length; i++) {
            _createVesting(vestingsInput[i]);
        }
    }

    /**
     * @dev can be called any amount of time after vesting contract is unlocked, tokens are vested each block after cliffEnd
     */
    function claim() external nonReentrant {
        if (locked) {
            revert VestingIsNotUnlocked();
        }

        UserVesting storage vesting = vestings[msg.sender];
        if (vesting.amount - vesting.amountClaimed == 0) {
            revert NoActiveVesting();
        }

        uint256 claimableAmount = _claimable(vesting);

        if (claimableAmount == 0) {
            revert NothingToClaimCurrentlyPleaseTryAgainLater();
        }

        totalAmountClaimed += claimableAmount;
        vesting.amountClaimed += claimableAmount;
        vesting.lastClaimAt = block.timestamp;

        assert(vesting.amountClaimed <= vesting.amount);
        assert(totalAmountClaimed <= totalAmountAllocated);

        vestedToken.safeTransfer(msg.sender, claimableAmount);
        emit NewClaim(msg.sender, claimableAmount);
    }

    // return amount user can claim from locked tokens at the moment
    function claimable(address _user) external view returns (uint256 amount) {
        if (locked) {
            return 0;
        }
        return _claimable(vestings[_user]);
    }

    function getDepositedAmount() public view returns (uint256 amount) {
        return vestedToken.balanceOf(address(this));
    }

    // create a vesting for an user
    function _createVesting(CreateVestingInput memory v) private {
        if (v.user == address(0)) {
            revert NoZeroAddress("user");
        }
        if (v.amount == 0) {
            revert MustNotBeZero("amount");
        }
        if (vestings[v.user].amount > 0) {
            revert OnlyOneVestingPerAddress();
        }

        totalAmountAllocated += v.amount;

        vestings[v.user] = UserVesting({
            amount: v.amount,
            amountClaimed: airdroptedAtStart
                ? (v.amount * claimableAtStart) / RATE_CONVERTER
                : 0,
            lastClaimAt: airdroptedAtStart ? startDateAt : 0
        });

        emit NewVestingCreated(v.user, v.amount);
    }

    function _claimable(UserVesting memory v)
        private
        view
        returns (uint256 amount)
    {
        if (block.timestamp < startDateAt) {
            // vesting has not started
            return 0;
        }

        uint256 amountLeft = v.amount - v.amountClaimed;
        // user already claimed everything
        if (amountLeft == 0) return 0;

        if (block.timestamp >= vestingEndAt) {
            // if vesting ended return everything left
            amount = amountLeft;
        } else {
            if (v.lastClaimAt == 0) {
                // if this is first claim also calculate amount available at start
                amount += (claimableAtStart * v.amount) / RATE_CONVERTER;
            }
            uint256 prevEndDate = startDateAt;
            for (uint256 i = 0; i < phases.length; i++) {
                Phase memory phase = phases[i];
                uint256 phaseLength = phase.endAt - prevEndDate;

                // if last claim time is larger than the end of phase then skip it, already calculated in previous claim
                if (v.lastClaimAt < phase.endAt) {
                    if (
                        block.timestamp >= phase.endAt &&
                        phase.minimumClaimablePeriod == 0
                    ) {
                        // if phase completely passed then calculate amount with every second in phase
                        amount += (v.amount * phase.rate) / RATE_CONVERTER;
                    } else if (phase.minimumClaimablePeriod != 0) {
                        uint256 start = Math.max(v.lastClaimAt, prevEndDate);
                        uint256 end = Math.min(block.timestamp, phase.endAt);
                        // only take full increments of minimumClaimablePeriod in calculation of amount
                        uint256 timePassed = end -
                            start -
                            ((end - start) % phase.minimumClaimablePeriod);

                        amount +=
                            (v.amount * phase.rate * timePassed) /
                            (phaseLength * RATE_CONVERTER);
                    }

                    if (block.timestamp < phase.endAt) {
                        // if current time is less than end of this phase then there is no need to calculate remaining phases
                        break;
                    }
                }
                prevEndDate = phase.endAt;
            }
        }

        amount = Math.min(amount, amountLeft);

        return Math.min(amount, getDepositedAmount());
    }

    /**
     * @dev Returns time until next vesting batch will be unlocked for vesting contract provided in arguments
     */
    function nextBatchAt() external view returns (uint256) {
        if (block.timestamp >= vestingEndAt) {
            return vestingEndAt;
        }

        // we assume all vesting contracts release at least some funds on start date/TGE
        if (block.timestamp < startDateAt) {
            return startDateAt;
        }

        uint256 nextBatchIn;
        uint256 prevEndDate = startDateAt;
        // iterate over phases until we find current phase contract does not returns phases length
        for (uint256 i = 0; block.timestamp > prevEndDate; i++) {
            Phase memory phase = phases[i];
            if (block.timestamp < phase.endAt) {
                // vesting per sec/block
                if (phase.minimumClaimablePeriod == 1) {
                    nextBatchIn = 1;
                } else if (phase.minimumClaimablePeriod == 0) {
                    // vested at the end of the phase
                    nextBatchIn = phase.endAt;
                } else {
                    // if the funds are released in batches in current phase every `minimumClaimablePeriod` time,
                    nextBatchIn =
                        block.timestamp +
                        phase.minimumClaimablePeriod -
                        ((block.timestamp - prevEndDate) %
                            phase.minimumClaimablePeriod);
                }
                break;
            }
            prevEndDate = phase.endAt;
        }

        return nextBatchIn;
    }

    // @notice rescue any token accidentally sent to this contract
    function emergencyWithdrawToken(IERC20 token) external onlyOwner {
        token.safeTransfer(msg.sender, token.balanceOf(address(this)));
    }
}
