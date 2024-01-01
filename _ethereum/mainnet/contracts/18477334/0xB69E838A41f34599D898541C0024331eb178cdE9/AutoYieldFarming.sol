// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./DistributionManager.sol";
import "./ERC20.sol";
import "./IERC20.sol";

contract AutoYieldFarming is DistributionManager, ERC20 {
    /*
    ╔══════════════════════════════╗
    
    ║           VARIABLES          ║
    
    ╚══════════════════════════════╝
    */
    address public owner;
    IERC20 public rewardToken;
    IERC20 public farmToken;

    uint256 constant EPOCH_DURATION = 30 days;
    uint256 constant WITHDRAW_DURATION = 1 days;

    uint256 public startTime;
    uint256 mockTime;
    uint256 paddingTime;
    uint128 emissionPerSecond;

    mapping(address => uint256) public farmerRewardsToClaim;
    mapping(address => uint256) public userClaimed;

    /*
    ╔══════════════════════════════╗
    
    ║           MODIFIER           ║
    
    ╚══════════════════════════════╝
    */

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    /*
    ╔══════════════════════════════╗
    
    ║            EVENTS            ║
    
    ╚══════════════════════════════╝
    */

    event Farm(address indexed user, uint256 amount);

    event Withdraw(address indexed user, uint256 amount);

    event RewardsAccrued(address indexed user, uint256 amount);

    event RewardsClaimed(address indexed user, uint256 amount);

    /*
    ╔══════════════════════════════╗
    
    ║          INITIALIZE          ║
    
    ╚══════════════════════════════╝
    */

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _distributionDuration,
        uint128 _emissionPerSecond,
        address _farmToken,
        address _rewardToken,
        address _owner
    ) ERC20(_name, _symbol) {
        require(address(_farmToken) != address(0), "INVALID ADDRESS");
        require(address(_rewardToken) != address(0), "INVALID ADDRESS");
        owner = _owner;
        rewardToken = IERC20(_rewardToken);
        farmToken = IERC20(_farmToken);
        distributionEnd = block.timestamp + _distributionDuration;
        emissionPerSecond = _emissionPerSecond;
    }

    /*
    ╔══════════════════════════════╗
    
    ║       ADMIN FUNCTIONS        ║
    
    ╚══════════════════════════════╝
    */

    function setOwner(address _owner) external onlyOwner {
        require(_owner != address(0), "INVALID ADDRESS");
        owner = _owner;
    }

    function setRewardToken(IERC20 _rewardToken) external onlyOwner {
        require(address(_rewardToken) != address(0), "INVALID ADDRESS");
        rewardToken = _rewardToken;
    }

    function setFarmToken(IERC20 _farmToken) external onlyOwner {
        require(address(_farmToken) != address(0), "INVALID ADDRESS");
        farmToken = _farmToken;
    }

    function increaseDistribution(
        uint256 distributionDuration
    ) external onlyOwner {
        distributionEnd = distributionEnd + distributionDuration;
    }

    function configureAsset(
        uint128 _InputEmissionPerSecond
    ) external onlyOwner {
        AssetConfigInput memory assetConfigInput = AssetConfigInput({
            emissionPerSecond: _InputEmissionPerSecond,
            totalStaked: totalSupply()
        });
        _configureAsset(assetConfigInput);
    }

    function transferAllRewardToken(
        address _tokenAddress,
        address _receiver
    ) external onlyOwner {
        rewardToken.transfer(
            _receiver,
            IERC20(_tokenAddress).balanceOf(address(this))
        );
    }

    function rescueERC20Tokens(address tokenAddress) external onlyOwner {
        IERC20(tokenAddress).transfer(
            msg.sender,
            IERC20(tokenAddress).balanceOf(address(this))
        );
    }

    function startEpoch() external {
        require(msg.sender == address(rewardToken), "Only reward token");
        startTime = block.timestamp - WITHDRAW_DURATION;
        paddingTime = EPOCH_DURATION - (startTime % EPOCH_DURATION);
        mockTime = (startTime + paddingTime) / EPOCH_DURATION;

        AssetConfigInput memory assetConfigInput = AssetConfigInput({
            emissionPerSecond: emissionPerSecond,
            totalStaked: totalSupply()
        });
        _configureAsset(assetConfigInput);
    }

    /*
    ╔══════════════════════════════╗
    
    ║       EXTERNAL FUNCTIONS     ║
    
    ╚══════════════════════════════╝
  */

    /**
     * @dev Withdraws farmed tokens, and stop earning rewards
     * @param _amount Amount to withdraw
     **/
    function farm(uint256 _amount, address _receiver) external {
        require(_amount != 0, "INVALID_ZERO_AMOUNT");

        uint256 balanceOfUser = balanceOf(_receiver);

        uint256 accruedRewards = _updateUserAssetInternal(
            _receiver,
            balanceOfUser,
            totalSupply()
        );
        if (accruedRewards != 0) {
            emit RewardsAccrued(_receiver, accruedRewards);
            farmerRewardsToClaim[_receiver] =
                farmerRewardsToClaim[_receiver] +
                accruedRewards;
        }

        _mint(_receiver, _amount);

        farmToken.transferFrom(msg.sender, address(this), _amount);

        emit Farm(_receiver, _amount);
    }

    /**
     * @dev Withdraws farmed tokens, and stop earning rewards
     * @param _amount Amount to withdraw
     **/
    function withdraw(uint256 _amount) external {
        require(_amount != 0, "INVALID_ZERO_AMOUNT");
        require(isWithdrawable(block.timestamp), "NOT TIME YET");
        address withdrawer = _msgSender();

        uint256 balanceOfWithdrawer = balanceOf(withdrawer);

        uint256 amountToWithdraw = (_amount > balanceOfWithdrawer)
            ? balanceOfWithdrawer
            : _amount;

        _updateCurrentUnclaimedRewards(withdrawer, balanceOfWithdrawer, true);

        _burn(withdrawer, amountToWithdraw);

        farmToken.transfer(withdrawer, amountToWithdraw);

        emit Withdraw(msg.sender, amountToWithdraw);
    }

    /**
     * @dev Claims an `amount` of `REWARD_TOKEN` to the msg.sender
     **/
    function claimRewards() external {
        address claimer = _msgSender();
        uint256 amountToClaim = _updateCurrentUnclaimedRewards(
            claimer,
            balanceOf(claimer),
            false
        );

        farmerRewardsToClaim[claimer] = 0;

        rewardToken.transfer(claimer, amountToClaim);

        userClaimed[msg.sender] += amountToClaim;

        emit RewardsClaimed(claimer, amountToClaim);
    }

    /**
     * @dev Return the total rewards pending to claim by an farmer
     * @param _farmer The farmer address
     * @return The rewards
     */
    function getTotalRewardsBalance(
        address _farmer
    ) external view returns (uint256) {
        UserStakeInput memory userFarmInput = UserStakeInput({
            stakedByUser: balanceOf(_farmer),
            totalStaked: totalSupply()
        });

        return
            farmerRewardsToClaim[_farmer] +
            _getUnclaimedRewards(_farmer, userFarmInput);
    }

    function isWithdrawable(uint256 _timestamp) public view returns (bool) {
        if (
            ((_timestamp + paddingTime) /
                WITHDRAW_DURATION -
                (mockTime * EPOCH_DURATION) /
                WITHDRAW_DURATION) %
                (EPOCH_DURATION / WITHDRAW_DURATION) <
            1
        ) return (true);
        else return (false);
    }

    function timeLeftUntilWithdrawable() external view returns (uint256) {
        uint256 time = startTime;
        while (time < block.timestamp) {
            time = time + EPOCH_DURATION;
        }
        return time;
    }

    /*
    ╔══════════════════════════════╗
    
    ║       INTERNAL FUNCTIONS     ║
    
    ╚══════════════════════════════╝
  */

    /**
     * @dev Updates the user state related with his accrued rewards
     * @param _user Address of the user
     * @param _userBalance The current balance of the user
     * @param _updateStorage Boolean flag used to update or not the farmerRewardsToClaim of the user
     * @return The unclaimed rewards that were added to the total accrued
     **/
    function _updateCurrentUnclaimedRewards(
        address _user,
        uint256 _userBalance,
        bool _updateStorage
    ) internal returns (uint256) {
        uint256 accruedRewards = _updateUserAssetInternal(
            _user,
            _userBalance,
            totalSupply()
        );
        uint256 unclaimedRewards = farmerRewardsToClaim[_user] + accruedRewards;

        if (accruedRewards != 0) {
            if (_updateStorage) {
                farmerRewardsToClaim[_user] = unclaimedRewards;
            }
            emit RewardsAccrued(_user, accruedRewards);
        }

        return unclaimedRewards;
    }

    /**
     * @dev Internal ERC20 _transfer of the tokenized farmed tokens
     * @param from Address to transfer from
     * @param to Address to transfer to
     * @param amount Amount to transfer
     **/
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        uint256 balanceOfFrom = balanceOf(from);
        // Sender
        _updateCurrentUnclaimedRewards(from, balanceOfFrom, true);

        // Recipient
        if (from != to) {
            uint256 balanceOfTo = balanceOf(to);
            _updateCurrentUnclaimedRewards(to, balanceOfTo, true);
        }

        super._transfer(from, to, amount);
    }
}
