// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "./Initializable.sol";

import "./IBentCVX.sol";
import "./IERC20.sol";
import "./IBentCVXStaking.sol";
import "./IBentCVXRewarderV2.sol";
import "./bentCVX3.sol";
import "./ReentrancyGuard.sol";
import "./Errors.sol";

contract bentConvexCDP is Initializable, ReentrancyGuardUpgradeable {
    struct PoolData {
        address rewardToken;
        uint256 accRewardPerShare; // Accumulated Rewards per share, times 1e36. See below.
        uint256 rewardRate;
        uint256 reserves;
    }
    address public admin;
    address public cvxAddress; // CVX Token Address
    address public bentCvxAddress; // bentCVX Token Address - Use this Address to Mint bentCVX Address
    address public bentCVX3Address; // vlBCVX Token Address
    address public bentCVXStaker; // BentCVXRewarder - To Stake Reward
    address public bentCVXRewarder; // BentCVXRewarder - To Collect the reward
    uint256 public totalSupply;
    uint256 public rewardPoolsCount;

    uint256 public windowLength; // amount of blocks where we assume around 12 sec per block
    uint256 public minWindowLength; // minimum amount of blocks where 7200 = 1 day
    uint256 public endRewardBlock; // end block of rewards stream
    uint256 public lastRewardBlock; // last block of rewards streamed
    uint256 public harvesterFee; // percentage fee to onReward caller where 100 = 1%

    mapping(address => uint256) public balanceOf;
    mapping(uint256 => PoolData) public rewardPools;
    mapping(address => bool) public isRewardToken;
    mapping(uint256 => mapping(address => uint256)) internal userRewardDebt;
    mapping(uint256 => mapping(address => uint256)) internal userPendingRewards;

    event DepositCVX(address indexed _from, uint _value);
    event WithdrawCVX(address indexed _from, uint _value);
    event ClaimAll(address indexed _from, uint _value);
    event userClaim(address indexed _from, uint _amount);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Invalid Admin");
        _;
    }

    function initialize(
        address _cvxAddress,
        address _bentCvxAddress,
        address _bentCVXStaker,
        address _bentCVXRewarder,
        address _bentCVX3Address,
        uint256 _widowLength
    ) external initializer {
        admin = msg.sender;
        cvxAddress = _cvxAddress;
        bentCvxAddress = _bentCvxAddress;
        bentCVXStaker = _bentCVXStaker;
        bentCVXRewarder = _bentCVXRewarder;
        bentCVX3Address = _bentCVX3Address;
        windowLength = _widowLength;
        minWindowLength = 300;
        totalSupply = 0;
        harvesterFee = 0;
    }

    /**
     * @notice set Reward Harvest Fee.
     * @param _fee The Fee to Charge 1 = 1%;
     **/
    function setHarvesterFee(uint256 _fee) public onlyAdmin {
        require(_fee <= 100, Errors.EXCEED_MAX_HARVESTER_FEE);
        harvesterFee = _fee;
    }

    /**
     * @notice set Window Length.
     * @param _windowLength Number of Blocks. 7200 =  1 day ;
     **/
    function setWindowLength(uint256 _windowLength) public onlyAdmin {
        require(_windowLength >= minWindowLength, Errors.INVALID_WINDOW_LENGTH);
        windowLength = _windowLength;
    }

    /**
     * @notice set Window Length.
     * @param _windowLength The Window Length. Its Number of Blocks;
     **/
    function setMinWindowLength(uint256 _windowLength) public onlyAdmin {
        require(_windowLength >= minWindowLength, Errors.INVALID_WINDOW_LENGTH);
        minWindowLength = _windowLength;
    }

    function addRewardTokens(address[] memory _rewardTokens) public onlyAdmin {
        uint256 length = _rewardTokens.length;
        for (uint256 i = 0; i < length; ++i) {
            require(!isRewardToken[_rewardTokens[i]], Errors.ALREADY_EXISTS);
            rewardPools[rewardPoolsCount + i].rewardToken = _rewardTokens[i];
            isRewardToken[_rewardTokens[i]] = true;
        }
        rewardPoolsCount += length;
    }

    function removeRewardToken(uint256 _index) external onlyAdmin {
        require(_index < rewardPoolsCount, Errors.INVALID_INDEX);

        isRewardToken[rewardPools[_index].rewardToken] = false;
        delete rewardPools[_index];
    }

    /**
     * @notice set CVX Address
     * @param _address CVX Address
     **/
    function setCVXTokenAddress(address _address) public onlyAdmin {
        cvxAddress = _address;
    }

    /**
     * @notice set Bent Address
     * @param _address Bent Address
     **/
    function setBentCvxAddress(address _address) public onlyAdmin {
        bentCvxAddress = _address;
    }

    /**
     * @notice set 3vlBCVX Address
     * @param _address 3vlBCVX Address
     **/
    function setvlBCVX3Address(address _address) public onlyAdmin {
        bentCVX3Address = _address;
    }

    /**
     * @notice set bentCVX Staker Address
     * @param _address bentCVXStaker Address
     **/

    function setbentCVXStaker(address _address) public onlyAdmin {
        bentCVXStaker = _address;
    }

    /**
     * @notice set bentCVX Rewarder Address
     * @param _address bentCVXRewarder Address
     **/

    function setbentCVXRewarder(address _address) public onlyAdmin {
        bentCVXRewarder = _address;
    }

    /**
     * @notice onTransfer transfer the ownership of deposits .
     * @param _user old owner of the deposit
     * @param _newOwner new Owner of the deposit
     * @param _amount Amount to Transfer
     **/
    function onTransfer(
        address _user,
        address _newOwner,
        uint256 _amount
    ) external nonReentrant {
        require(msg.sender == bentCVX3Address, "No Right To Call Transfer");
        require(balanceOf[_user] >= _amount, "User Dont have enough deposit");
        uint256 userBalance = balanceOf[_user];
        _updateAccPerShare(true, _user);
        _updateAccPerShare(true, _newOwner);
        unchecked {
            balanceOf[_user] = userBalance - _amount;
            balanceOf[_newOwner] = balanceOf[_newOwner] + _amount;
        }

        _updateUserRewardDebt(_user);
        _updateUserRewardDebt(_newOwner);
    }

    /**
     * @notice User Pending Reward
     * @param user User Address
     **/
    function pendingReward(
        address user
    ) external view returns (uint256[] memory pending) {
        uint256 _rewardPoolsCount = rewardPoolsCount;
        pending = new uint256[](_rewardPoolsCount);
        if (totalSupply != 0) {
            uint256[] memory addedRewards = _calcAddedRewards();
            for (uint256 i = 0; i < _rewardPoolsCount; ++i) {
                PoolData memory pool = rewardPools[i];
                if (pool.rewardToken == address(0)) {
                    continue;
                }
                uint256 newAccRewardPerShare = pool.accRewardPerShare +
                    ((addedRewards[i] * 1e36) / totalSupply);

                pending[i] =
                    userPendingRewards[i][user] +
                    ((balanceOf[user] * newAccRewardPerShare) / 1e36) -
                    userRewardDebt[i][user];
            }
        }
    }

    /**
     * @dev Deposit CVX to Get bentCVX3
     * @param _amount Amount to deposit. 1 CVX for 1 3vlCVX
     **/
    function depositCVX(uint256 _amount) external nonReentrant {
        require(_amount > 0, "Zero Amount is not acceptable");
        IERC20 cvxContract = IERC20(cvxAddress);
        IBentCVX BentCVXContract = IBentCVX(bentCvxAddress);
        bentCVX3 BentCVX3Contract = bentCVX3(bentCVX3Address);
        require(cvxContract.balanceOf(msg.sender) > 0, "Not Enough Balance");
        _updateAccPerShare(true, msg.sender);
        BentCVXContract.approve(bentCVXStaker, _amount);
        cvxContract.transferFrom(msg.sender, address(this), _amount);
        cvxContract.approve(bentCvxAddress, _amount);
        BentCVXContract.deposit(_amount);
        IBentCVXStaking(bentCVXStaker).deposit(_amount);

        BentCVX3Contract.mintRequest(msg.sender, _amount);
        uint256 userAmount = balanceOf[msg.sender];
        totalSupply += _amount;
        unchecked {
            balanceOf[msg.sender] = userAmount + (_amount);
        }
        _updateUserRewardDebt(msg.sender);
        emit DepositCVX(msg.sender, _amount);
    }

    /**
     * @dev Deposit BentCVX to Get bentCVX3
     * @param _amount Amount to deposit. 1 bentCVX for 1 3vlCVX
     **/

    function depositbentCVX(uint256 _amount) external nonReentrant {
        require(_amount > 0, "Zero Amount is not acceptable");
        IERC20 bentCvxContract = IERC20(bentCvxAddress);
        IBentCVX BentCVXContract = IBentCVX(bentCvxAddress);
        bentCVX3 BentCVX3Contract = bentCVX3(bentCVX3Address);
        require(
            bentCvxContract.balanceOf(msg.sender) >= _amount,
            "Not Enough Balance"
        );
        _updateAccPerShare(true, msg.sender);
        BentCVXContract.approve(bentCVXStaker, _amount);
        bentCvxContract.transferFrom(msg.sender, address(this), _amount);
        IBentCVXStaking(bentCVXStaker).deposit(_amount);
        BentCVX3Contract.mintRequest(msg.sender, _amount);
        uint256 userAmount = balanceOf[msg.sender];
        totalSupply += _amount;
        unchecked {
            balanceOf[msg.sender] = userAmount + (_amount);
        }
        _updateUserRewardDebt(msg.sender);
        emit DepositCVX(msg.sender, _amount);
    }

    /**
     * @notice withdraw CVX to Get bentCVX3
     * @param _amount Amount to Withdraw. 1 CVX for 1 3vlCVX
     **/
    function withdrawCVX(uint256 _amount) external nonReentrant {
        require(_amount > 0, "Zero Amount is not acceptable");
        uint256 userBalance = balanceOf[msg.sender];
        bentCVX3 BentCVX3Contract = bentCVX3(bentCVX3Address);
        IERC20 bentCvxContract = IERC20(bentCvxAddress);
        require(userBalance >= _amount, "Sender have no enough Deposit");
        _updateAccPerShare(true, msg.sender);
        BentCVX3Contract.burnRequest(msg.sender, _amount);
        IBentCVXStaking(bentCVXStaker).withdraw(_amount);
        bentCvxContract.transfer(msg.sender, _amount);
        totalSupply -= _amount;
        unchecked {
            balanceOf[msg.sender] = userBalance - (_amount);
        }
        _updateUserRewardDebt(msg.sender);
        emit WithdrawCVX(msg.sender, _amount);
    }

    /**
     * @notice Claim User Reward
     * @param pid Reward Pool Index
     **/
    function claim(uint256 pid) external nonReentrant {
        _updateAccPerShare(true, msg.sender);
        _claim(pid, msg.sender);
        _updateUserRewardDebt(msg.sender);
    }

    function updateReserve() external nonReentrant onlyAdmin {
        for (uint256 i = 0; i < rewardPoolsCount; ++i) {
            PoolData storage pool = rewardPools[i];
            if (pool.rewardToken == address(0)) {
                continue;
            }

            pool.reserves = IERC20(pool.rewardToken).balanceOf(address(this));
        }
    }

    function change_admin(address _address) external onlyAdmin {
        require(address(0) != _address, "Can not Set Zero Address");
        admin = _address;
    }

    /**
     * @notice withdraw Any Token By Owner of Contract
     * @param _token token Address to withdraw
     * @param _amount Amount of token to withdraw
     **/
    function withdraw_admin(
        address _token,
        uint256 _amount
    ) external nonReentrant onlyAdmin {
        IERC20(_token).transfer(admin, _amount);
    }

    function _updateAccPerShare(bool withdrawReward, address user) internal {
        uint256[] memory addedRewards = _calcAddedRewards();
        uint256 _rewardPoolsCount = rewardPoolsCount;
        for (uint256 i = 0; i < _rewardPoolsCount; ++i) {
            PoolData storage pool = rewardPools[i];
            if (pool.rewardToken == address(0)) {
                continue;
            }

            if (totalSupply == 0) {
                pool.accRewardPerShare = block.number;
            } else {
                pool.accRewardPerShare +=
                    (addedRewards[i] * (1e36)) /
                    totalSupply;
            }

            if (withdrawReward) {
                uint256 pending = ((balanceOf[user] * pool.accRewardPerShare) /
                    1e36) - userRewardDebt[i][user];
                if (pending > 0) {
                    userPendingRewards[i][user] += pending;
                }
            }
        }

        lastRewardBlock = block.number;
    }

    function _updateUserRewardDebt(address user) internal {
        uint256 _rewardPoolsCount = rewardPoolsCount;
        for (uint256 i = 0; i < _rewardPoolsCount; ++i) {
            if (rewardPools[i].rewardToken != address(0)) {
                userRewardDebt[i][user] =
                    (balanceOf[user] * rewardPools[i].accRewardPerShare) /
                    1e36;
            }
        }
    }

    // Should We Call Rewarder or Staker Contract For Getting Claim. Make Sure of it!!
    function masterClaim() external {
        IBentCVXRewarderV2 bentCvxRewarderContract = IBentCVXRewarderV2(
            bentCVXRewarder
        );
        bentCvxRewarderContract.claimAll(address(this));
    }

    function onReward() external nonReentrant {
        _updateAccPerShare(false, address(0));

        bool newRewardsAvailable = false;
        for (uint256 i = 0; i < rewardPoolsCount; ++i) {
            PoolData storage pool = rewardPools[i];
            if (pool.rewardToken == address(0)) {
                continue;
            }

            uint256 newRewards = IERC20(pool.rewardToken).balanceOf(
                address(this)
            ) - pool.reserves;
            uint256 newRewardsFees = (newRewards * harvesterFee) / 10000;
            uint256 newRewardsFinal = newRewards - newRewardsFees;

            if (newRewardsFinal > 0) {
                newRewardsAvailable = true;
            }

            if (endRewardBlock > lastRewardBlock) {
                pool.rewardRate =
                    (pool.rewardRate *
                        (endRewardBlock - lastRewardBlock) +
                        newRewardsFinal *
                        1e36) /
                    windowLength;
            } else {
                pool.rewardRate = (newRewardsFinal * 1e36) / windowLength;
            }
            pool.reserves += newRewardsFinal;

            if (newRewardsFees > 0) {
                IERC20(pool.rewardToken).transfer(msg.sender, newRewardsFees);
            }
        }

        require(newRewardsAvailable, Errors.ZERO_AMOUNT);
        endRewardBlock = lastRewardBlock + windowLength;
    }

    function _claim(
        uint256 pid,
        address user
    ) internal returns (uint256 claimAmount) {
        if (rewardPools[pid].rewardToken == address(0)) {
            return 0;
        }
        claimAmount = userPendingRewards[pid][user];
        if (claimAmount > 0) {
            IERC20(rewardPools[pid].rewardToken).transfer(user, claimAmount);
            rewardPools[pid].reserves -= claimAmount;
            userPendingRewards[pid][user] = 0;
        }
    }

    function _calcAddedRewards()
        internal
        view
        returns (uint256[] memory addedRewards)
    {
        uint256 startBlock = endRewardBlock > lastRewardBlock + windowLength
            ? endRewardBlock - windowLength
            : lastRewardBlock;
        uint256 endBlock = block.number > endRewardBlock
            ? endRewardBlock
            : block.number;
        uint256 duration = endBlock > startBlock ? endBlock - startBlock : 0;
        uint256 _rewardPoolsCount = rewardPoolsCount;
        addedRewards = new uint256[](_rewardPoolsCount);
        for (uint256 i = 0; i < _rewardPoolsCount; ++i) {
            addedRewards[i] = (rewardPools[i].rewardRate * duration) / 1e36;
        }
    }
}
