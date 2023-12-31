// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "./Initializable.sol";
import "./IERC20.sol";
import "./bent3.sol";
import "./IBentLocker.sol";
import "./ReentrancyGuard.sol";
import "./Errors.sol";

contract bentFinanceCDP is Initializable, ReentrancyGuardUpgradeable {
    struct PoolData {
        address rewardToken;
        uint256 accRewardPerShare; // Accumulated Rewards per share, times 1e36. See below.
        uint256 rewardRate;
        uint256 reserves;
    }
    address public admin;
    address public bentAddress;
    address public webentAddress;
    address public bent3Address;
    uint256 public totalRewardClaimed;
    uint256 public totalSupply;

    uint256 public windowLength; // amount of blocks where we assume around 12 sec per block
    uint256 public minWindowLength; // minimum amount of blocks where 7200 = 1 day
    uint256 public endRewardBlock; // end block of rewards stream
    uint256 public lastRewardBlock; // last block of rewards streamed
    uint256 public harvesterFee; // percentage fee to onReward caller where 100 = 1%
    uint256 public rewardPoolsCount;

    mapping(address => uint256) public balanceOf;
    mapping(uint256 => PoolData) public rewardPools;
    mapping(address => bool) public isRewardToken;
    mapping(uint256 => mapping(address => uint256)) internal userRewardDebt;
    mapping(uint256 => mapping(address => uint256)) internal userPendingRewards;

    event Deposit(address indexed _from, uint _value);
    event Withdraw(address indexed _from, uint _value);
    event ClaimAll(address indexed _from, uint _value);
    event userClaim(address indexed _from, uint _amount);
    event userWithdraw(address indexed _from, uint _amount);
    event ownerWithdraw(address indexed _from, uint _amount);
    modifier onlyAdmin() {
        require(msg.sender == admin, "Invalid Owner");
        _;
    }

    function initialize(
        address _bentAddress,
        address _webentAddress,
        address _bent3Address,
        uint256 _windowLength
    ) external initializer {
        admin = msg.sender;
        bentAddress = _bentAddress;
        webentAddress = _webentAddress;
        bent3Address = _bent3Address;
        windowLength = _windowLength;
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
     * @param _windowLength The Window Length. Its Number of Blocks;
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

    /**
     * @notice set BENT Token Address.
     * @param _address Address For Bent Token;
     **/
    function setBentTokenAddress(address _address) external onlyAdmin {
        bentAddress = _address;
    }

    /**
     * @notice set weBENT Token Address.
     * @param _address Address For weBENT Token;
     **/
    function setWeBentAddress(address _address) external onlyAdmin {
        webentAddress = _address;
    }

    /**
     * @notice set 3vlBENT Token Address.
     * @param _address Address For 3vlBENT Token;
     **/
    function setbent3Address(address _address) external onlyAdmin {
        bent3Address = _address;
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
     * @notice Deposit BENT Tokens.
     * @param amount Amount of Bent Tokens to deposit
     * @dev Bent -> weBent
     **/
    function depositBent(uint256 amount) external nonReentrant {
        require(amount > 0, "Zero Amount is not acceptable");
        IERC20 bentContract = IERC20(bentAddress);
        require(
            bentContract.balanceOf(msg.sender) >= amount,
            "Not Enough Balance"
        );
        bent3 bent3Contract = bent3(bent3Address);
        IBentLocker weBentContract = IBentLocker(webentAddress);
        uint256 userAmount = balanceOf[msg.sender];

        _updateAccPerShare(true, msg.sender);
        bentContract.transferFrom(msg.sender, address(this), amount);
        bentContract.approve(webentAddress, amount);
        weBentContract.deposit(amount);
        bent3Contract.mintRequest(msg.sender, amount);
        totalSupply += amount;
        unchecked {
            balanceOf[msg.sender] = userAmount + amount;
        }
        _updateUserRewardDebt(msg.sender);
        emit Deposit(msg.sender, amount);
    }

    /**
     * @notice Withdraw BENT Token .
     * @param amount Amount of Bent Tokens to withdraw
     * @dev Contract's Bent Transfered to User
     **/
    function withdrawBent(uint256 amount) external nonReentrant {
        require(amount > 0, "Zero Amount is not acceptable");
        uint256 useBalance = balanceOf[msg.sender];
        IERC20 bentContract = IERC20(bentAddress);
        bent3 bent3Contract = bent3(bent3Address);
        require(useBalance >= amount, "Sender have no enough Deposit");
        _updateAccPerShare(true, msg.sender);
        bent3Contract.burnRequest(msg.sender, amount);
        bentContract.transfer(msg.sender, amount);
        totalSupply -= amount;
        unchecked {
            balanceOf[msg.sender] = useBalance - amount;
        }
        _updateUserRewardDebt(msg.sender);
        emit userWithdraw(msg.sender, amount);
    }

    /**
     * @dev Withdraw Bent From webent Contract, Pass the unlockable Amount As Input
     **/
    function masterWithdraw(uint256 amount) external onlyAdmin {
        require(amount > 0, "Zero Amount is not acceptable");
        IBentLocker weBentContract = IBentLocker(webentAddress);
        weBentContract.withdraw(
            weBentContract.unlockableBalances(address(this))
        );
        emit ownerWithdraw(msg.sender, amount);
    }

    /**
     * @dev Claim Bent From webent Contract
     **/
    function masterClaim() external {
        IBentLocker weBentContract = IBentLocker(webentAddress);
        weBentContract.claimAll();
    }

    /**
     * @notice Claim Reward for your deposit of BENT Token .
     * @param pid Reward Pool index
     **/
    function claim(uint256 pid) external nonReentrant {
        _updateAccPerShare(true, msg.sender);
        _claim(pid, msg.sender);
        _updateUserRewardDebt(msg.sender);
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
        require(msg.sender == bent3Address, "No Right To Call Transfer");
        uint256 userBalance = balanceOf[_user];
        require(userBalance >= _amount, "User Dont have enough deposit");

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
     * @notice Change Owner Of Contract
     * @param _address New Owner Address
     **/

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

    function updateReserve() external nonReentrant onlyAdmin {
        for (uint256 i = 0; i < rewardPoolsCount; ++i) {
            PoolData storage pool = rewardPools[i];
            if (pool.rewardToken == address(0)) {
                continue;
            }

            pool.reserves = IERC20(pool.rewardToken).balanceOf(address(this));
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
}
