// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

import "./IFeeReceiving.sol";
import "./IVeToken.sol";
import "./IAutoStakeFor.sol";

contract ReferralProgram is ReentrancyGuard, Ownable, IFeeReceiving {
    using SafeERC20 for IERC20;

    struct User {
        bool exists;
        address referrer;
    }

    mapping(address => User) public users;
    // user_address -> token_address -> token_amount
    mapping(address => mapping(address => uint256)) public rewards;

    uint256[] public distribution = [70, 20, 10];
    address[] public tokens;
    address[] public distributors;

    address public rootAddress;

    uint256 public percentageToBeLocked;
    IVeToken public veToken;
    IAutoStakeFor public votingStakingRewards;

    event RegisterUser(address user, address referrer);
    event RewardReceived(
        address user,
        address referrer,
        address token,
        uint256 amount
    );
    event RewardsClaimed(address user, address[] tokens, uint256[] amounts);
    event NewDistribution(uint256[] distribution);
    event NewToken(address token);

    modifier onlyFeeDistributors {
        for (uint256 i = 0; i < distributors.length; i++) {
            if (msg.sender == distributors[i]) {
                _;
                return;
            }
        }
        revert("RP!feeDistributor");
    }

    /**
    * @dev configures the contract
    * @param _rootAddress Treasure address
    * @param _percentageToBeLocked Percentage to be locked
    * @param _veToken VeToken address
    * @param _votingStakingRewards VSR address
    */
    constructor(
        address _rootAddress,
        uint256 _percentageToBeLocked,
        IVeToken _veToken,
        IAutoStakeFor _votingStakingRewards
    ) {
        require(_rootAddress != address(0), "RProotIsZero");
        rootAddress = _rootAddress;
        users[_rootAddress] = User({exists: true, referrer: _rootAddress});
        percentageToBeLocked = _percentageToBeLocked;
        veToken = _veToken;
        votingStakingRewards = _votingStakingRewards;
    }

    function setPercentageToBeLocked(uint256 _percentageToBeLocked) external onlyOwner {
        require(_percentageToBeLocked <= 100, "invalid percentage");
        percentageToBeLocked = _percentageToBeLocked;
    }

    function setVeToken(IVeToken _veToken) external onlyOwner {
        address token = tokens[0];
        IERC20(token).approve(address(veToken), 0);
        IERC20(token).approve(address(_veToken), type(uint256).max);
        veToken = _veToken;
    }

    function setVotingStakingRewards(IAutoStakeFor _votingStakingRewards) external onlyOwner {
        votingStakingRewards = _votingStakingRewards;
    }

    function setFeeDistributors(address[] memory _distributors) external onlyOwner {
        distributors = _distributors;
    }

    function setRewardTokens(address[] memory _rewardTokens) external onlyOwner {
        tokens = _rewardTokens;
        IERC20(_rewardTokens[0]).approve(address(veToken), type(uint256).max);
    }

    function registerUser(address referrer, address referral)
        external
        onlyFeeDistributors
    {
        _registerUser(referrer, referral);
    }

    function registerUser(address referrer) external {
        _registerUser(referrer, msg.sender);
    }

    function _registerUser(address referrer, address referral) internal {
        require(referral != address(0), "RPuserIsZero");
        require(!users[referral].exists, "RPuserExists");
        require(users[referrer].exists, "RP!referrerExists");
        users[referral] = User({exists: true, referrer: referrer});
        emit RegisterUser(referral, referrer);
    }

    function feeReceiving(
        address _for,
        address _token,
        uint256 _amount
    ) external override onlyFeeDistributors {
        // If notify reward for unregistered _for -> register with root referrer
        if (!users[_for].exists) {
            _registerUser(rootAddress, _for);
        }

        address upline = users[_for].referrer;
        for (uint256 i = 0; i < distribution.length; i++) {
            uint256 amount = rewards[upline][_token] + _amount * distribution[i] / 100;
            rewards[upline][_token] = amount;

            emit RewardReceived(_for, upline, _token, amount);
            upline = users[upline].referrer;
        }
    }

    function claimRewardsFor(address userAddr) public nonReentrant {
        require(users[userAddr].exists, "RP!userExists");
        uint256[] memory amounts = new uint256[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            address token = tokens[i];
            uint256 reward = rewards[userAddr][token];
            if (reward > 0) {
                amounts[i] = reward;
                _transferOrLock(token, reward, userAddr);
                rewards[userAddr][token] = 0;
            }
        }
        emit RewardsClaimed(userAddr, tokens, amounts);
    }

    function claimRewards() external {
        claimRewardsFor(msg.sender);
    }

    function claimRewardsForRoot() external {
        claimRewardsFor(rootAddress);
    }

    function getTokensList() external view returns (address[] memory) {
        return tokens;
    }

    function getDistributionList() external view returns (uint256[] memory) {
        return distribution;
    }

    function changeDistribution(uint256[] calldata newDistribution)
        external
        onlyOwner
    {
        uint256 sum;
        for (uint256 i = 0; i < newDistribution.length; i++) {
            sum += newDistribution[i];
        }
        require(sum == 100, "RP!fullDistribution");
        distribution = newDistribution;
        emit NewDistribution(distribution);
    }

    function addNewToken(address tokenAddress) external onlyOwner {
        require(tokenAddress != address(0), "RPtokenIsZero");
        for (uint256 i = 0; i < tokens.length; i++) {
            require(tokenAddress != tokens[i], "RPtokenAlreadyExists");
        }
        tokens.push(tokenAddress);
        emit NewToken(tokenAddress);
    }

    function _transferOrLock(
        address _token,
        uint256 _amount,
        address _receiver
    ) internal {
        if (_token != tokens[0]) {
            IERC20(_token).safeTransfer(_receiver, _amount);
        } else {
            uint256 toLock = percentageToBeLocked * _amount / 100;
            uint256 toTransfer = _amount - toLock;
            IVeToken veToken_ = IVeToken(veToken);
            uint256 unlockTime = veToken_.lockedEnd(_receiver);
            if (unlockTime == 0) {
                IVeToken.Point memory initialPoint = veToken_.pointHistory(0);
                uint256 rewardsDuration = votingStakingRewards.rewardsDuration();
                uint256 lockTime = veToken_.MAXTIME();
                uint256 week = veToken_.WEEK();
                if (initialPoint.ts + lockTime + rewardsDuration < block.timestamp) { // reward program is surely over
                    IERC20(_token).safeTransfer(_receiver, _amount);
                } else {
                    IERC20(_token).safeTransfer(_receiver, toTransfer);
                    uint256 unlockDate = 
                        (initialPoint.ts + lockTime) / week * week <= block.timestamp ? // if we are between 100 and 101 week
                        block.timestamp + 2 * rewardsDuration : 
                        initialPoint.ts + lockTime;
                    veToken_.createLockFor(_receiver, toLock, unlockDate);
                }
            } else {
                require(unlockTime > block.timestamp, "withdraw the lock first");
                IERC20(_token).safeTransfer(_receiver, toTransfer);
                veToken_.increaseAmountFor(_receiver, toLock);
            }
        }
    }
}
