// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./Initializable.sol";
import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";

interface IStaking {
    function updateRewardRecord(address _token, uint256 _index) external;
}

contract RewardManagerV2 is
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    IStaking public usdtStaking;
    // Address of the accessor
    uint256 public totalTokens;
    address[] public rewardToken;
    mapping(address => bool) public isRewardToken;
    mapping(address => bool) public isAuthorized;
    mapping(address => uint256) public totalRewardCount;
    mapping(address => uint256) public rewardAddTime;
    mapping(address => mapping(uint256 => uint256)) public totalAddedRewards;
    address public ETH_ADDRESS;

    // Event emitted when rewards are deposited
    event RewardDeposited(address user, uint256 amount, uint256 at);
    event RewardWithdrawn(
        address user,
        address token,
        uint256 amount,
        uint256 at
    );

    // Initialize the contract
    function initialize() external initializer {
        __Ownable_init();
        ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    }

    // Deposit rewards into the contract
    function depositRewards(address _token, uint256 _amount) external payable {
        require(isAuthorized[msg.sender], "Not Authorized!");
        require(_amount > 0, "Amount must be greater than 0");
        require(isRewardToken[_token], "Invalid Token!");

        if (_token != ETH_ADDRESS) {
            IERC20Upgradeable(_token).safeTransferFrom(
                msg.sender,
                address(this),
                _amount
            );
        } else {
            require(msg.value >= _amount, "Insufficient amount!");
        }
        totalRewardCount[_token] += 1;
        totalAddedRewards[_token][totalRewardCount[_token]] = _amount;
        rewardAddTime[_token] = block.timestamp;
        usdtStaking.updateRewardRecord(_token, totalRewardCount[_token]);

        emit RewardDeposited(msg.sender, _amount, block.timestamp);
    }

    function getRewardFrom(
        address _token,
        uint256 _index
    ) external view returns (uint256 totalReward) {
        require(isRewardToken[_token], "Invalid Token!");
        require(
            _index != 0 && _index <= totalRewardCount[_token],
            "Invalid Index!"
        );
        for (uint256 i = 1; i <= totalRewardCount[_token]; i++) {
            totalReward += totalAddedRewards[_token][i];
        }
    }

    // Withdraw all tokens from the contract (onlyOwner)
    function withdrawRewardTokens(
        address _token,
        address _recipient,
        uint256 _amount
    ) external {
        require(isAuthorized[msg.sender], "Not Authorized!");
        require(isRewardToken[_token], "Invalid Token!");

        uint256 balance = IERC20Upgradeable(_token).balanceOf(address(this));
        require(balance >= _amount, "Insufficient reward");

        if (_token == ETH_ADDRESS) {
            payable(_recipient).transfer(_amount);
        } else {
            IERC20Upgradeable(_token).safeTransfer(_recipient, _amount);
        }
        emit RewardWithdrawn(msg.sender, _token, _amount, block.timestamp);
    }

    function addAuthorized(address _address) external onlyOwner {
        isAuthorized[_address] = true;
    }

    function removeAuthorized(address _address) external onlyOwner {
        isAuthorized[_address] = false;
    }

    function addRewardToken(address _token) external onlyOwner {
        isRewardToken[_token] = true;
        rewardToken.push(_token);
        totalTokens++;
    }

    function removeRewardToken(address _token) external onlyOwner {
        isRewardToken[_token] = false;
    }

    function withdrawStuckTokens(
        address _tokenAddress,
        uint256 _amount
    ) external onlyOwner {
        require(_amount > 0, "Amount must be greater than 0");
        IERC20Upgradeable(_tokenAddress).safeTransfer(owner(), _amount);
    }

    function withdrawStuckFunds(uint256 _amount) external onlyOwner {
        require(_amount > 0, "Amount must be greater than 0");
        payable(owner()).transfer(_amount);
    }

    function setUsdtStaking(IStaking _staking) external onlyOwner {
        usdtStaking = _staking;
    }
}
