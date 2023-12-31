// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Initializable.sol";
import "./Errors.sol";

import "./IERC20.sol";
import "./bentCVX3.sol";
import "./IBentLocker.sol";
import "./ReentrancyGuard.sol";
import "./BentFinanceCDP.sol";
import "./bentConvexCDP.sol";
import "./console.sol";

contract bent3Fi is Initializable, ReentrancyGuardUpgradeable {
    struct PoolData {
        address rewardToken;
        uint256 accRewardPerShare; // Accumulated Rewards per share, times 1e36. See below.
        uint256 rewardRate;
        uint256 reserves;
    }
    // 3 Finance Tokens
    address public bentCVX3Address;
    address public bent3Address;
    // 3 Finance CDP Contracts
    address public bentCDPAddress;
    address public convexCDPAddress;
    // Bent Finance Tokens
    address public bentAddress;
    address public cvxAddress;
    address public bentCVXAddress;

    address public admin;
    uint256 public rewardPoolsCount;
    uint256 public totalSupply;

    string private _name;
    string private _symbol;

    uint256 public windowLength; // amount of blocks where we assume around 12 sec per block
    uint256 public minWindowLength; // minimum amount of blocks where 7200 = 1 day
    uint256 public endRewardBlock; // end block of rewards stream
    uint256 public lastRewardBlock; // last block of rewardsF streamed
    uint256 public harvesterFee; // percentage fee to onReward caller where 100 = 1%
    address public fi3NFT; // 3 Fi NFT Address

    mapping(address => uint256) public balance;
    mapping(address => mapping(address => uint256)) private allowances;
    mapping(uint256 => PoolData) public rewardPools;
    mapping(address => bool) public isRewardToken;
    mapping(uint256 => mapping(address => uint256)) internal userRewardDebt;
    mapping(uint256 => mapping(address => uint256)) internal userPendingRewards;

    event Deposit(address indexed _from, uint _value);
    event Withdraw(address indexed _from, uint _value);
    event userWithdraw(address indexed user, uint256 amount);
    event ClaimAll(address indexed user);
    event Claim(address indexed user, uint256[] pids);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Invalid Admin");
        _;
    }

    function initialize(
        string memory name_,
        string memory symbol_,
        address _bentCVX3Address,
        address _bent3Address,
        address _bentCDPAddress,
        address _convexCDPAddress,
        address _bentAddress,
        address _cvxAddress,
        address _bentCVXAddress,
        uint256 _windowLength
    ) external initializer {
        admin = payable(msg.sender);
        _name = name_;
        _symbol = symbol_;
        bentCVX3Address = _bentCVX3Address;
        bent3Address = _bent3Address;
        bentCDPAddress = _bentCDPAddress;
        convexCDPAddress = _convexCDPAddress;
        bentAddress = _bentAddress;
        cvxAddress = _cvxAddress;
        bentCVXAddress = _bentCVXAddress;
        windowLength = _windowLength;
        minWindowLength = 300;
        totalSupply = 0;
        harvesterFee = 0;
    }

    /**
     * @notice set 3Fi NFT Address.
     * @param _address The 3Fi NFT smart contract Address
     **/
    function set3fiNFTAddress(address _address) external onlyAdmin {
        fi3NFT = _address;
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
    function setbentCVX3Address(address _address) external onlyAdmin {
        bentCVX3Address = _address;
    }

    function setbentCVXAddress(address _address) external onlyAdmin {
        bentCVXAddress = _address;
    }

    function setbent3Address(address _address) external onlyAdmin {
        bent3Address = _address;
    }

    function setbentCDPAddress(address _address) external onlyAdmin {
        bentCDPAddress = _address;
    }

    function setconvexCDPAddress(address _address) external onlyAdmin {
        convexCDPAddress = _address;
    }

    function setbentAddress(address _address) external onlyAdmin {
        bentAddress = _address;
    }

    function setcvxAddress(address _address) external onlyAdmin {
        cvxAddress = _address;
    }

    /**
     * @notice Add New Token For Rewards.
     * @param _rewardTokens The Address of new Reward Token;
     **/

    function addRewardTokens(address[] memory _rewardTokens) public onlyAdmin {
        uint256 length = _rewardTokens.length;
        for (uint256 i = 0; i < length; ++i) {
            require(!isRewardToken[_rewardTokens[i]], Errors.ALREADY_EXISTS);
            rewardPools[rewardPoolsCount + i].rewardToken = _rewardTokens[i];
            isRewardToken[_rewardTokens[i]] = true;
        }
        rewardPoolsCount += length;
    }

    /**
     * @notice Name
     **/
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @notice Symbol
     **/
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @notice Decimals
     **/
    function decimals() public view returns (uint8) {
        return 18;
    }

    /**
     * @notice Claim and Get 3 Fi Tokens
     * @param _amount Amount of bent3 and bentCVX3 Tokens to deposit.
     
     **/
    function mint3FiToken(uint256 _amount) external nonReentrant {
        IERC20 BentCVX3Contract = IERC20(bentCVX3Address);
        IERC20 bent3Contract = IERC20(bent3Address);
        require(
            BentCVX3Contract.balanceOf(msg.sender) >= _amount,
            "Not Enough Balance bentCVX3 Tokens"
        );
        require(
            bent3Contract.balanceOf(msg.sender) >= _amount,
            "Not Enough Balance Bent3 Tokens"
        );

        _updateAccPerShare(true, msg.sender);
        BentCVX3Contract.transferFrom(msg.sender, address(this), _amount);
        bent3Contract.transferFrom(msg.sender, address(this), _amount);
        mint(msg.sender, _amount);
        _updateUserRewardDebt(msg.sender);
        emit Deposit(msg.sender, _amount);
    }

    function balanceOf(address account) public view virtual returns (uint256) {
        return balance[account];
    }

    function allowance(address _owner) public view returns (uint256) {
        return allowances[_owner][fi3NFT];
    }

    function approve(uint256 amount) external returns (bool) {
        allowances[msg.sender][fi3NFT] = amount;
        return true;
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

    function transferFrom(
        address from,
        uint256 amount
    ) external nonReentrant returns (bool) {
        address _nftAddress = fi3NFT;
        address spender = msg.sender;
        require(spender == _nftAddress, "Transfer Not Allowed");
        _spendAllowance(from, _nftAddress, amount);
        _transfer(from, _nftAddress, amount);
        return true;
    }

    /**
     * @notice Withdraw Tokens and Get  bentCVX3 and bent3 Tokens
     * @param _amount Amount of 3Fi Tokens you deposit Back.1 3Fi Token gets you  1 bentCVX & 1 bent
     **/
    function withdraw3Fi(uint256 _amount) external nonReentrant {
        require(_amount > 0, "Zero Amount is not acceptable");
        require(balance[msg.sender] >= _amount, "Not Enought Deposit");
        _updateAccPerShare(true, msg.sender);
        burn(msg.sender, _amount);
        // Transfer Tokens to User
        IERC20 bentCvxContract = IERC20(bentCVXAddress);
        IERC20 bentToken = IERC20(bentAddress);
        bentConvexCDP(convexCDPAddress).withdrawCVX(_amount);
        bentFinanceCDP(bentCDPAddress).withdrawBent(_amount);
        // Transfer Tokens
        bentCvxContract.transfer(msg.sender, _amount);
        bentToken.transfer(msg.sender, _amount);
        _updateUserRewardDebt(msg.sender);
        emit userWithdraw(msg.sender, _amount);
    }

    // Internal Functions

    function updateReserve() external nonReentrant onlyAdmin {
        for (uint256 i = 0; i < rewardPoolsCount; ++i) {
            PoolData storage pool = rewardPools[i];
            if (pool.rewardToken == address(0)) {
                continue;
            }
            pool.reserves = IERC20(pool.rewardToken).balanceOf(address(this));
        }
    }

    /**
     * @notice User Pending Reward
     * @param user address of the user wallet
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
                    ((balance[user] * newAccRewardPerShare) / 1e36) -
                    userRewardDebt[i][user];
            }
        }
    }

    /**
     * @notice Claim All your rewards
     **/
    function claimAll() external nonReentrant returns (bool claimed) {
        _updateAccPerShare(true, msg.sender);
        uint256 _rewardPoolsCount = rewardPoolsCount;
        for (uint256 i = 0; i < _rewardPoolsCount; ++i) {
            uint256 claimAmount = _claim(i, msg.sender);
            if (claimAmount > 0) {
                claimed = true;
            }
        }

        _updateUserRewardDebt(msg.sender);

        emit ClaimAll(msg.sender);
    }

    /**
     * @notice Claim reward for specific reward token
     * @param pids index of the reward token
     **/
    function claim(
        uint256[] memory pids
    ) external nonReentrant returns (bool claimed) {
        _updateAccPerShare(true, msg.sender);

        for (uint256 i = 0; i < pids.length; ++i) {
            uint256 claimAmount = _claim(pids[i], msg.sender);
            if (claimAmount > 0) {
                claimed = true;
            }
        }

        _updateUserRewardDebt(msg.sender);

        emit Claim(msg.sender, pids);
    }

    /**
     * @notice Claim Reward for the Contract from CDP Contracts
     * @param  pidConvex  Rewarding Pool index
     * @param  pidBent Rewarding Pool index
     **/
    function masterClaim(
        uint256 pidConvex,
        uint256 pidBent
    ) external nonReentrant {
        bentFinanceCDP bentCDPContract = bentFinanceCDP(bentCDPAddress);
        bentConvexCDP convexCDPContract = bentConvexCDP(convexCDPAddress);
        bentCDPContract.claim(pidBent);
        convexCDPContract.claim(pidConvex);
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

    function mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            balance[account] += amount;
        }
    }

    function burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");
        uint256 accountBalance = balance[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        totalSupply -= amount;
        unchecked {
            balance[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
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
                uint256 pending = ((balance[user] * pool.accRewardPerShare) /
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
                    (balance[user] * rewardPools[i].accRewardPerShare) /
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

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        allowances[owner][spender] = amount;
        // emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) internal {
        require(from != address(0), "NFT: transfer from the zero address");
        uint256 fromBalance = balance[from];
        require(
            fromBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        unchecked {
            balance[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            balance[to] += amount;
        }
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowances[owner][spender];
        if (currentAllowance != type(uint256).max) {
            require(
                currentAllowance >= amount,
                "ERC20: insufficient allowance"
            );
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }
}
