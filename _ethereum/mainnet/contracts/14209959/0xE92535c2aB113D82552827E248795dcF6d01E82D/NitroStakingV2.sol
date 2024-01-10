// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./ERC20.sol";
import "./Ownable.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./ReentrancyGuard.sol";
import "./Staking.sol";
import "./Libraries.sol";

contract NitroStakingV2 is Ownable, ReentrancyGuard {
    IERC20 public stakingToken;
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using StringLibrary for string;
    Staking public oldStaking;
    uint256 public totalStake;
    uint256 public startTime;
    uint256 public endTime;
    uint256 public APR;
    address public verifier;

    mapping(address => uint256) public userStake;
    mapping(address => uint256) public claimAmount;
    mapping(address => bool) public isClaimed;
    mapping(address => bool) public isMigrated;

    event Staked(address _who, uint256 _when, uint256 _howmuch);
    event UnStaked(address _who, uint256 _when, uint256 _howmuch);
    event RewardsClaimed(address _who, uint256 _when, uint256 _howmuch);
    event MigratedPool(address _who, uint256 _when, uint256 _howmuch);
    event UpdatedAPR(uint256 _oldAPR, uint256 _newAPR, uint256 _when);
    event UpdatedVerifier(
        address _oldVerifier,
        address _newVerifier,
        uint256 _when
    );
    event UpdatedPoolEndTime(uint256 _oldTime, uint256 _newTime, uint256 _when);

    constructor(
        address _stakingToken,
        uint256 _startTime,
        uint256 _endTime,
        Staking _oldStaking,
        address _verifier,
        uint256 _apr
    ) {
        require(
            _stakingToken != address(0),
            "Staking Token can not be Zero Address"
        );
        require(_verifier != address(0), "Verifier can not be Zero Address");
        require(_apr > 0, "UpdateAPR:: Invalid APR");
        oldStaking = _oldStaking;
        stakingToken = IERC20(_stakingToken);
        startTime = _startTime;
        endTime = _endTime;
        verifier = _verifier;
        APR = _apr;
    }

    // Allow New and/or Old Pool User to Stake
    function stake(uint256 _amount) external nonReentrant {
        uint256 _time = block.timestamp;
        require(_amount > 0, "Stake:: Amount can not be Zero");
        require(_time >= startTime, "Stake:: To early to Stake");
        require(_time <= endTime, "Stake:: To late to Stake");
        migratePool(msg.sender);
        totalStake = totalStake.add(_amount);
        userStake[msg.sender] = userStake[msg.sender].add(_amount);
        stakingToken.safeTransferFrom(msg.sender, address(this), _amount);
        emit Staked(msg.sender, _time, _amount);
    }

    // Allow New and/or Old Pool User to Unstake
    function unStake(uint256 _amount) external nonReentrant {
        require(_amount > 0, "Unstake:: Amount can not be Zero");
        migratePool(msg.sender);
        require(_amount <= userStake[msg.sender], "Unstake:: Invalid Amount");
        userStake[msg.sender] = userStake[msg.sender].sub(_amount);
        stakingToken.safeTransfer(msg.sender, _amount);
        emit UnStaked(msg.sender, block.timestamp, _amount);
    }

    // Migrate Pool-1 data to Pool-2 - This will run only once per user
    function migratePool(address _user) internal {
        if (!isMigrated[_user]) {
            uint256 oldPoolStake = oldStake(_user);
            userStake[_user] = oldPoolStake;
            isMigrated[_user] = true;
            totalStake = totalStake.add(oldPoolStake);
            emit MigratedPool(_user, block.timestamp, oldPoolStake);
        }
    }

    // Allow Pool-1 Staked users to Claim Rewards
    function calimRewards(
        uint256 _amount,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external nonReentrant {
        require(oldStake(msg.sender) > 0, "ClaimRewards:: Invalid Stake");
        require(
            !isClaimed[msg.sender],
            "ClaimRewards:: Already Claimed"
        );
        address signedBy = StringLibrary.recover(
            prepareMessage(msg.sender, _amount),
            v,
            r,
            s
        );
        require(signedBy == verifier, "CalimRewards:: Unauthorized");
        isClaimed[msg.sender] = true;
        claimAmount[msg.sender] = _amount;
        stakingToken.safeTransfer(msg.sender, _amount);
        emit RewardsClaimed(msg.sender, block.timestamp, _amount);
    }

    function prepareMessage(address _user, uint256 _amount)
        public
        view
        returns (string memory)
    {
        return
            toString(
                keccak256(abi.encodePacked(address(this), _user, _amount))
            );
    }

    function toString(bytes32 value) internal pure returns (string memory) {
        bytes memory alphabet = "0123456789abcdef";
        bytes memory str = new bytes(64);
        for (uint256 i = 0; i < 32; i++) {
            str[i * 2] = alphabet[uint8(value[i] >> 4)];
            str[1 + i * 2] = alphabet[uint8(value[i] & 0x0f)];
        }
        return string(str);
    }

    // Generate Signature for Verifier
    function generateSignerMessage(address _user, uint256 _amount)
        public
        view
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(address(this), _user, _amount));
    }

    // Get User staked amout from Pool-1
    function oldStake(address _user) public view returns (uint256) {
        return oldStaking.userStake(_user);
    }

    // Admin to withdraw excess tokens from Contract
    function withdraw(address _to) external onlyOwner {
        require(_to != address(0), "Withdraw:: _to Can not be Zero Address");
        uint256 _totalStake = IERC20(stakingToken).balanceOf(address(this));
        stakingToken.safeTransfer(_to, _totalStake);
        emit UnStaked(_to, block.timestamp, _totalStake);
    }

    // Update APR
    function updateAPR(uint256 _newAPR) external onlyOwner {
        require(_newAPR > 0, "UpdateAPR:: Invalid APR");
        uint256 _oldAPR = APR;
        APR = _newAPR;
        emit UpdatedAPR(_oldAPR, _newAPR, block.timestamp);
    }

    // Update Verifier
    function updateVerifier(address _newVerifier) external onlyOwner {
        require(
            _newVerifier != address(0),
            "UpdateVerifier:: Verifier can not be zero address"
        );
        address _oldVerifier = verifier;
        verifier = _newVerifier;
        emit UpdatedVerifier(_oldVerifier, _newVerifier, block.timestamp);
    }

    // Update EndTime
    function updatePoolEndTime(uint256 _newTime) external onlyOwner {
        require(
            _newTime > block.timestamp,
            "UpdatePoolEndTime:: Newtime can not be past time"
        );
        uint256 _oldTime = endTime;
        endTime = _newTime;
        emit UpdatedPoolEndTime(_oldTime, _newTime, block.timestamp);
    }
}
