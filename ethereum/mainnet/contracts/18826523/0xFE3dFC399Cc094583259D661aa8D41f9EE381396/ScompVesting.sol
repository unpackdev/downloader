/**
 * @title ScompVesting
 * @author MC
 * @notice Vesting of SCOMP tokens
 *  ____  _        _     _
 * / ___|| |_ __ _| |__ | | ___  ___ ___  _ __ ___  _ __
 * \___ \| __/ _` | '_ \| |/ _ \/ __/ _ \| '_ ` _ \| '_ \
 *  ___) | || (_| | |_) | |  __/ (_| (_) | | | | | | |_) |
 * |____/ \__\__,_|_.__/|_|\___|\___\___/|_| |_| |_| .__/
 *                                                 |_|
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "./ERC20.sol";
import "./Ownable.sol";
import "./SafeERC20.sol";
import "./MerkleProof.sol";

contract ScompVesting is Ownable {
    using SafeERC20 for ERC20;
    bytes32 public merkleRoot;
    uint256 public immutable vestingStart;
    ERC20 public immutable scomp;

    uint16 public constant PERCENTAGE_PRECISION = 10000;
    uint256 public constant INTERVAL = 30 days;

    struct VestingSchedule {
        uint256 totalTokens;
        uint16 initialUnlock;
        uint16 tokensPerInterval;
        uint8 startDelay;
        uint8 totalIntervals;
    }

    mapping(uint8 => VestingSchedule) public vestingSchedules;

    mapping(address => mapping(uint8 => uint256)) public claimed;

    event Claimed(
        address indexed user,
        uint256 amount,
        uint256 interval,
        uint8 vestingSchedule
    );

    constructor(address _scomp, bytes32 merkleRoot_, uint256 _vestingStart) {
        scomp = ERC20(_scomp);
        merkleRoot = merkleRoot_;
        vestingStart = _vestingStart;

        uint256 decimals = 10 ** uint256(scomp.decimals());
        vestingSchedules[0] = VestingSchedule(
            12000000 * decimals,
            1500,
            607,
            0,
            15
        );

        vestingSchedules[1] = VestingSchedule(
            12000000 * decimals,
            1500,
            772,
            0,
            12
        );

        vestingSchedules[2] = VestingSchedule(
            12000000 * decimals,
            1500,
            1062,
            0,
            9
        );

        vestingSchedules[3] = VestingSchedule(
            26690910 * decimals,
            0,
            1000,
            2,
            12
        );

        vestingSchedules[4] = VestingSchedule(
            19104000 * decimals,
            0,
            909,
            1,
            12
        );

        vestingSchedules[5] = VestingSchedule(
            100000 * decimals,
            400,
            872,
            0,
            12
        );

        vestingSchedules[6] = VestingSchedule(
            39166800 * decimals,
            0,
            212,
            1,
            48
        );

        vestingSchedules[7] = VestingSchedule(
            69000000 * decimals,
            0,
            500,
            4,
            24
        );
    }

    function updateMerkleRoot(bytes32 merkleRoot_) external onlyOwner {
        merkleRoot = merkleRoot_;
    }

    function claim(
        uint8 vestingSchedule,
        uint256 totalTokens,
        bytes32[] calldata merkleProof
    ) external {
        bytes32 leaf = keccak256(
            bytes.concat(
                keccak256(abi.encode(msg.sender, vestingSchedule, totalTokens))
            )
        );

        require(
            MerkleProof.verify(merkleProof, merkleRoot, leaf),
            "Invalid Merkle proof"
        );

        require(
            block.timestamp >=
                vestingStart +
                    vestingSchedules[vestingSchedule].startDelay *
                    INTERVAL,
            "Vesting not started"
        );

        uint256 currentInterval = (block.timestamp - vestingStart) / INTERVAL;
        uint256 claimAmount = getCurrentClaimableTokens(
            msg.sender,
            vestingSchedule,
            totalTokens
        );
        require(claimAmount > 0, "No tokens to claim");

        claimed[msg.sender][vestingSchedule] += claimAmount;

        emit Claimed(msg.sender, claimAmount, currentInterval, vestingSchedule);
        scomp.safeTransfer(msg.sender, claimAmount);
    }

    function getVestingDetails(
        uint8 vestingSchedule
    )
        external
        view
        returns (
            uint256 totalTokens,
            uint16 initialUnlock,
            uint16 tokensPerInterval,
            uint8 startDelay,
            uint8 totalIntervals
        )
    {
        VestingSchedule memory schedule = vestingSchedules[vestingSchedule];
        return (
            schedule.totalTokens,
            schedule.initialUnlock,
            schedule.tokensPerInterval,
            schedule.startDelay,
            schedule.totalIntervals
        );
    }

    function getClaimedTokens(
        address user,
        uint8 vestingSchedule
    ) external view returns (uint256) {
        return claimed[user][vestingSchedule];
    }

    function getInterval() external view returns (uint256) {
        return (block.timestamp - vestingStart) / INTERVAL;
    }

    function getCurrentClaimableTokens(
        address user,
        uint8 vestingSchedule,
        uint256 totalTokens
    ) public view returns (uint256) {
        uint256 interval = (block.timestamp - vestingStart) / INTERVAL;
        uint256 currentInterval = vestingSchedules[vestingSchedule].startDelay >
            0
            ? interval - (vestingSchedules[vestingSchedule].startDelay - 1)
            : interval;

        if (interval >= vestingSchedules[vestingSchedule].totalIntervals - 1) {
            uint256 claimable = totalTokens - claimed[user][vestingSchedule];
            return claimable;
        } else {
            uint256 totalClaimable = ((totalTokens *
                vestingSchedules[vestingSchedule].initialUnlock) +
                (totalTokens *
                    vestingSchedules[vestingSchedule].tokensPerInterval *
                    currentInterval)) / PERCENTAGE_PRECISION;
            uint256 finalAmount = totalClaimable -
                claimed[user][vestingSchedule];
            return finalAmount;
        }
    }

    function getContractTokenBalance() external view returns (uint256) {
        return scomp.balanceOf(address(this));
    }

    function withdrawTokens(address token, uint256 amount) external onlyOwner {
        ERC20(token).safeTransfer(msg.sender, amount);
    }
}
