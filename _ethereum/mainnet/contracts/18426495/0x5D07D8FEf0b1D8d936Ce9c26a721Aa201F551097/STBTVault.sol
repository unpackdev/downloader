// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "IERC20.sol";
import "SafeERC20.sol";

import "ContractGuard.sol";
import "ReentrancyGuard.sol";

import "Operator.sol";
import "Blacklistable.sol";
import "Pausable.sol";

import "ICurve.sol";
import "ICvxDeposit.sol";
import "ICvxReward.sol";
import "ISTBTMinter.sol";
import "ISTBTRouter.sol";

import "Abs.sol";
import "SafeCast.sol";

contract ShareWrapper {

    using SafeERC20 for IERC20;
    using Abs for int256;

    address public share;

    uint256 public fee;
    address public feeTo;

    struct TotalSupply {
        uint256 wait;
        uint256 staked;
        uint256 withdrawable;
        int256 reward;
    }

    struct Balances {
        uint256 wait;
        uint256 staked;
        uint256 withdrawable;
        int256 reward;
    }

    mapping(address => Balances) internal _balances;
    TotalSupply internal _totalSupply;

    function total_supply_wait() public view returns (uint256) {
        return _totalSupply.wait;
    }

    function total_supply_staked() public view returns (uint256) {
        return _totalSupply.staked;
    }

    function total_supply_withdraw() public view returns (uint256) {
        return _totalSupply.withdrawable;
    }

    function total_supply_reward() public view returns (int256) {
        return _totalSupply.reward;
    }

    function balance_wait(address account) public view returns (uint256) {
        return _balances[account].wait;
    }

    function balance_staked(address account) public view returns (uint256) {
        return _balances[account].staked;
    }

    function balance_withdraw(address account) public view returns (uint256) {
        return _balances[account].withdrawable;
    }

    function balance_reward(address account) public view returns (int256) {
        return _balances[account].reward;
    }

    function stake(uint256 amount) public payable virtual {
        _totalSupply.wait += amount;
        _balances[msg.sender].wait += amount;
        IERC20(share).safeTransferFrom(msg.sender, address(this), amount);
    }

    function withdraw(uint256 amount) public virtual {
        require(_balances[msg.sender].withdrawable >= amount, "withdraw request greater than withdrawable amount");
        _totalSupply.withdrawable -= amount;
        _balances[msg.sender].withdrawable -= amount;
        int _reward = balance_reward(msg.sender);
        if (_reward > 0) {
            _balances[msg.sender].reward = 0;
            _totalSupply.reward -= _reward;
            IERC20(share).safeTransfer(msg.sender, amount + _reward.abs());
        } else if (_reward < 0) {
            _balances[msg.sender].reward = 0;
            _totalSupply.reward -= _reward;
            IERC20(share).safeTransfer(msg.sender, amount - _reward.abs());            
        } else {
            IERC20(share).safeTransfer(msg.sender, amount);
        }
    }
}

contract STBTVault is ShareWrapper, ContractGuard, ReentrancyGuard, Operator, Blacklistable, Pausable {

    using SafeERC20 for IERC20;
    using Address for address;
    using Abs for int256;
    using SafeCast for uint256;

    /* ========== DATA STRUCTURES ========== */

    // @dev Record the deposit information of each user in the system.
    // @param rewardEarned: The total earnings of the user.
    // @param lastSnapshotIndex: The starting time for calculating the user's earnings.
    // @param epochTimerStart: Record the epoch when the user's request is handled.
    struct Memberseat {
        int256 rewardEarned;
        uint256 lastSnapshotIndex;
        uint256 epochTimerStart;
    }

    // @dev Record the information of rewards distributed for each epoch in the system.
    // @param rewardReceived: The total reward of the epoch.
    // @param rewardPerShare: The reward for each share.
    // @param time: block.number
    struct BoardroomSnapshot {
        int256 rewardReceived;
        int256 rewardPerShare;
        uint256 time;
    }

    struct StakeInfo {
        uint256 amount;
        uint256 requestTimestamp;
        uint256 requestEpoch;
    }

    struct WithdrawInfo {
        uint256 amount;
        uint256 requestTimestamp;
        uint256 requestEpoch;
    }

    /* ========== STATE VARIABLES ========== */

    // The total amount of withdrawals per epoch.
    uint256 public totalWithdrawRequest;

    // @dev Users will be charged a certain amount of gas fees when making deposits and withdrawals, 
    // which will be used to handle the deposit and withdrawal requests.
    uint256 public gasthreshold;

    // The minimum required amount for deposits and withdrawals.
    uint256 public minimumRequest;

    address public governance;

    mapping(address => Memberseat) public members;
    BoardroomSnapshot[] public boardroomHistory;

    mapping(address => StakeInfo) public stakeRequest;
    mapping(address => WithdrawInfo) public withdrawRequest;

    mapping(address => bool) public governanceWithdrawWhiteList;

    uint256 public withdrawLockupEpochs;

    // flags
    bool public initialized;

    uint256 public epoch;
    uint256 public startTime;
    uint256 public period = 7 days;
    uint256 public lastEpochPoint;

    // stbt related addresses
    address public STBT = 0x530824DA86689C9C17CdC2871Ff29B058345b44a;
    address public DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address public STBTPool = 0x892D701d94a43bDBCB5eA28891DaCA2Fa22A690b;
    address public STBTMinter = 0xca241823d4Bfe8b29610709Db617407FbC9AE02b;
    address public STBTDepositZap = 0xA79828DF1850E8a3A3064576f380D90aECDD3359;
    address public cvxBoost = 0xF403C135812408BFbE8713b5A23a04b3D48AAE31;
    address public cvxReward = 0xf8Fa0b3899DE5B4b3cb0cfF65b528AcDD2d163F3;
    address public cvxSTBTToken = 0x355f07d5E24c5fd7D129AC7833aF17eC5F672eAa;
    /* ========== EVENTS ========== */

    event Initialized(address indexed executor, uint256 at);
    event Staked(address indexed user, uint256 amount);
    event WithdrawRequest(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event MintedSTBTByGov(uint256 indexed atEpoch, uint256 amount);
    event RedeemedSTBTByGov(uint256 indexed atEpoch, uint256 amount);
    event RewardPaid(address indexed user, int256 reward);
    event RewardAdded(uint256 indexed atEpoch, uint256 period, uint256 totalStakedAmount, int256 reward);
    event StakeRequestIgnored(address indexed ignored, uint256 atEpoch);
    event WithdrawRequestIgnored(address indexed ignored, uint256 atEpoch);
    event HandledStakeRequest(uint256 indexed atEpoch, address[] _address);
    event HandledWithdrawRequest(uint256 indexed atEpoch, address[] _address);
    event HandledReward(uint256 indexed atEpoch, uint256 time);
    event WithdrawLockupEpochsUpdated(uint256 indexed atEpoch, uint256 _withdrawLockupEpochs);
    event FeeUpdated(uint256 indexed atEpoch, uint256 _fee);
    event FeeToUpdated(uint256 indexed atEpoch, address _feeTo);
    event PeriodUpdated(uint256 indexed atEpoch, uint256 _period);
    event GasthresholdUpdated(uint256 indexed atEpoch, uint256 _gasthreshold);
    event MinimumRequestUpdated(uint256 indexed atEpoch, uint256 _minimumRequest);
    event EpochUpdated(uint256 indexed atEpoch, uint256 timestamp);
    event GovernanceWithdrawWhiteListUpdated(uint256 indexed atEpoch, address _whitelistAddress, bool _status);
    event GovernanceUpdated(uint256 indexed atEpoch, address _governance);

    /* ========== Modifiers =============== */

    modifier onlyGovernance() {
        require(governance == msg.sender, "caller is not the governance");
        _;
    }

    modifier memberExists() {
        require(balance_staked(msg.sender) > 0, "The member does not exist");
        _;
    }

    modifier notInitialized() {
        require(!initialized, "already initialized");
        _;
    }

    receive() payable external {}
    
    /* ========== GOVERNANCE ========== */

    function initialize (
        address _governance,
        address _share,
        uint256 _fee,
        address _feeTo,
        uint256 _gasthreshold,
        uint256 _minimumRequset,
        uint256 _startTime
    ) public notInitialized {
        require(_share != address(0), "share address can not be zero address");
        require(_feeTo != address(0), "feeTo address can not be zero address");

        governance = _governance;
        share = _share;
        fee = _fee;
        feeTo = _feeTo;
        gasthreshold = _gasthreshold;
        minimumRequest = _minimumRequset;

        BoardroomSnapshot memory genesisSnapshot = BoardroomSnapshot({time: block.number, rewardReceived: 0, rewardPerShare: 0});
        boardroomHistory.push(genesisSnapshot);

        withdrawLockupEpochs = 2; // Lock for 2 epochs (14days) before release withdraw
        startTime = _startTime;
        lastEpochPoint = _startTime;
        initialized = true;

        emit Initialized(msg.sender, block.number);
    }

    /* ========== CONFIG ========== */

    // @dev In case of an emergency, the administrator has the authority to temporarily pause the system. 
    // This pause may impact certain functionalities such as user deposits, withdrawals, redemptions.
    function pause() external onlyOperator {
        super._pause();
    }

    function unpause() external onlyOperator {
        super._unpause();
    }

    function setLockUp(uint256 _withdrawLockupEpochs) external onlyOperator {
        withdrawLockupEpochs = _withdrawLockupEpochs;
        emit WithdrawLockupEpochsUpdated(epoch, _withdrawLockupEpochs);
    }

    function setFee(uint256 _fee) external onlyOperator {
        require(_fee <= 500, "fee: out of range");
        fee = _fee;
        emit FeeUpdated(epoch, _fee);
    }

    function setFeeTo(address _feeTo) external onlyOperator {
        require(_feeTo != address(0), "feeTo can not be zero address");
        feeTo = _feeTo;
        emit FeeToUpdated(epoch, _feeTo);
    }

    function setPeriod(uint256 _period) external onlyOperator {
        period = _period;
        emit PeriodUpdated(epoch, _period);
    }

    function setGasThreshold(uint256 _gasthreshold) external onlyOperator {
        gasthreshold = _gasthreshold;
        emit GasthresholdUpdated(epoch, _gasthreshold);
    }    

    function setMinimumRequest(uint256 _minimumRequest) external onlyOperator {
        minimumRequest = _minimumRequest;
        emit MinimumRequestUpdated(epoch, _minimumRequest);
    }   

    function setGovernanceWithdrawWhiteList(address _whitelistAddress, bool _status) external onlyOperator {
        require(_whitelistAddress != address(0), "whitelist address cannot be zero address");
        governanceWithdrawWhiteList[_whitelistAddress] = _status;
        emit GovernanceWithdrawWhiteListUpdated(epoch, _whitelistAddress, _status);
    }

    function setGovernance(address _governance) external onlyOperator {
        require(_governance != address(0), "governance address cannot be zero address");
        governance = _governance;
        emit GovernanceUpdated(epoch, _governance);
    }

    /* ========== VIEW FUNCTIONS ========== */

    function latestSnapshotIndex() public view returns (uint256) {
        return boardroomHistory.length - 1;
    }

    function getLatestSnapshot() internal view returns (BoardroomSnapshot memory) {
        return boardroomHistory[latestSnapshotIndex()];
    }

    function getLastSnapshotIndexOf(address member) public view returns (uint256) {
        return members[member].lastSnapshotIndex;
    }

    function getLastSnapshotOf(address member) internal view returns (BoardroomSnapshot memory) {
        return boardroomHistory[getLastSnapshotIndexOf(member)];
    }

    function canWithdraw(address member) external view returns (bool) {
        return members[member].epochTimerStart + withdrawLockupEpochs <= epoch;
    }

    // epoch
    function nextEpochPoint() public view returns (uint256) {
        return lastEpochPoint + period;
    }

    function rewardPerShare() public view returns (int256) {
        return getLatestSnapshot().rewardPerShare;
    }

    // calculate earned reward of specified user
    function earned(address member) public view returns (int256) {
        int256 latestRPS = getLatestSnapshot().rewardPerShare;
        int256 storedRPS = getLastSnapshotOf(member).rewardPerShare;

        return balance_staked(member).toInt256() * (latestRPS - storedRPS) / 1e18 + members[member].rewardEarned;
    }

    // STBT virtual price
    function getSTBTPrice() public view returns (uint256) {
        return ICurve(STBTPool).get_virtual_price();
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    // @dev user stake function.
    // Protocol fees will be charged.
    // Additional gas fees will also be charged.
    // The number of multiple stake requests will be accumulated.
    // @param _amount: The amount of deposited tokens.
    function stake(uint256 _amount) public payable override onlyOneBlock notBlacklisted(msg.sender) whenNotPaused {
        require(_amount >= minimumRequest, "stake amount too low");
        require(msg.value >= gasthreshold, "need more gas to handle request");
        if (fee > 0) {
            uint tax = _amount * fee / 10000;
            _amount = _amount - tax;
            IERC20(share).safeTransferFrom(msg.sender, feeTo, tax);
        }
        super.stake(_amount);
        stakeRequest[msg.sender].amount += _amount;
        stakeRequest[msg.sender].requestTimestamp = block.timestamp;
        stakeRequest[msg.sender].requestEpoch = epoch;
        emit Staked(msg.sender, _amount);
    }

    // @dev user withdraw request function.
    // The number of multiple withdrawal requests will be accumulated.
    // @param _amount: The amount of withdraw tokens.
    function withdraw_request(uint256 _amount) public payable memberExists notBlacklisted(msg.sender) whenNotPaused {
        require(_amount != 0, "withdraw request cannot be equal to 0");
        require(_amount + withdrawRequest[msg.sender].amount <= _balances[msg.sender].staked, "withdraw amount exceeds the staked balance");
        require(members[msg.sender].epochTimerStart + withdrawLockupEpochs <= epoch, "still in withdraw lockup");
        require(msg.value >= gasthreshold, "need more gas to handle request");
        withdrawRequest[msg.sender].amount += _amount;
        withdrawRequest[msg.sender].requestTimestamp = block.timestamp;
        withdrawRequest[msg.sender].requestEpoch = epoch;
        totalWithdrawRequest += _amount;
        emit WithdrawRequest(msg.sender, _amount);
    }

    // @dev user withdraw functions.
    // After a user's withdrawal request has been handled, 
    // the user can invoke this function to retrieve their tokens.
    // @param amount: withdraw token amount.
    function withdraw(uint256 amount) public override onlyOneBlock notBlacklisted(msg.sender) whenNotPaused {
        require(amount != 0, "cannot withdraw 0");
        super.withdraw(amount);
        emit Withdrawn(msg.sender, amount);
    }

    function handleStakeRequest(address[] memory _address) external onlyGovernance {
        for (uint i = 0; i < _address.length; i++) {
            address user = _address[i];
            uint amount = stakeRequest[user].amount;
            if (stakeRequest[user].requestEpoch == epoch) { // check latest epoch
                emit StakeRequestIgnored(user, epoch);
                continue;  
            }
            if (stakeRequest[user].requestTimestamp == 0) {
                continue;
            }
            updateReward(user);
            _balances[user].wait -= amount;
            _balances[user].staked += amount;
            _totalSupply.wait -= amount;
            _totalSupply.staked += amount;    
            members[user].epochTimerStart = epoch - 1;  // reset timer   
            delete stakeRequest[user];
        }
        emit HandledStakeRequest(epoch, _address);
    }

    function handleWithdrawRequest(address[] memory _address) external onlyGovernance {
        for (uint i = 0; i < _address.length; i++) {
            address user = _address[i];
            uint amount = withdrawRequest[user].amount;
            uint amountReceived = amount; // user real received amount
            if (withdrawRequest[user].requestEpoch == epoch) { // check latest epoch
                emit WithdrawRequestIgnored(user, epoch);
                continue;  
            }
            if (withdrawRequest[user].requestTimestamp == 0) {
                continue;
            }
            claimReward(user);
            _balances[user].staked -= amount;
            _balances[user].withdrawable += amountReceived;
            _totalSupply.staked -= amount;
            _totalSupply.withdrawable += amountReceived;
            totalWithdrawRequest -= amount;
            members[user].epochTimerStart = epoch - 1; // reset timer
            delete withdrawRequest[user];
        }
        emit HandledWithdrawRequest(epoch, _address);
    }

    function removeWithdrawRequest(address[] memory _address) external onlyGovernance {
        for (uint i = 0; i < _address.length; i++) {
            address user = _address[i];
            uint amount = withdrawRequest[user].amount;
            totalWithdrawRequest -= amount;
            delete withdrawRequest[user];
        }      
    }

    function updateReward(address member) internal {
        if (member != address(0)) {
            Memberseat memory seat = members[member];
            seat.rewardEarned = earned(member);
            seat.lastSnapshotIndex = latestSnapshotIndex();
            members[member] = seat;
        }
    }

    function claimReward(address member) internal returns (int) {
        updateReward(member);
        int256 reward = members[member].rewardEarned;
        members[member].rewardEarned = 0;
        _balances[member].reward += reward;
        emit RewardPaid(member, reward);
        return reward;
    }

    // @dev governance mint STBT.
    // @param token: which token to deposit?
	// @param depositAmount: how much to deposit?
	// @param minProposedAmount: the sender uses this value to protect against sudden rise of feeRate
	// @param salt: a random number that can affect TimelockController's input salt
	// @param extraData: will be used to call STBT's issue function
    function mintSTBTByGov(
        address token, 
        uint256 depositAmount, 
        uint256 minProposedAmount, 
        bytes32 salt,
        bytes calldata extraData
    ) external onlyGovernance {
        IERC20(token).safeApprove(STBTMinter, 0);
        IERC20(token).safeApprove(STBTMinter, depositAmount);
        ISTBTMinter(STBTMinter).mint(token, depositAmount, minProposedAmount, salt, extraData);
        emit MintedSTBTByGov(epoch, depositAmount);
    }
    
    // @dev governance redeem STBT
	// @param token: which token to receive after redeem?
	// @param amount: how much STBT to deposit?
	// @param salt: a random number that can affect TimelockController's input salt
	// @param extraData: will be used to call STBT's redeemFrom function
	function redeemSTBTByGov(
        address token, 
        uint256 amount, 
        bytes32 salt, 
        bytes calldata extraData
    ) external onlyGovernance {
        IERC20(STBT).safeApprove(STBTMinter, 0);
        IERC20(STBT).safeApprove(STBTMinter, amount);
        ISTBTMinter(STBTMinter).redeem(amount, token, salt, extraData);
        emit RedeemedSTBTByGov(epoch, amount);
    }

    // swap exact tokens for tokens
    // @param i == 0, j = 1, means swap STBT for DAI.
    // @param i == 1, j = 0, means swap DAI for STBT.
    // @param i == 2, j = 0, means swap USDC for STBT.
    // @param i == 3, j = 0, means swap USDT for STBT.
    // @param _dx: input amount
    // @param _min_dy: minimum output amount
    function swap(
        int128 i, 
        int128 j, 
        uint256 _dx, 
        uint256 _min_dy
    ) public onlyGovernance returns(uint256) {
        if (i == 0) {
            IERC20(STBT).safeApprove(STBTPool, 0);
            IERC20(STBT).safeApprove(STBTPool, _dx);
        } else if (i == 1 && j == 0) {
            IERC20(DAI).safeApprove(STBTPool, 0);
            IERC20(DAI).safeApprove(STBTPool, _dx);
        } else if (i == 2 && j == 0) {
            IERC20(USDC).safeApprove(STBTPool, 0);
            IERC20(USDC).safeApprove(STBTPool, _dx);
        } else if (i == 3 && j == 0) {
            IERC20(USDT).safeApprove(STBTPool, 0);
            IERC20(USDT).safeApprove(STBTPool, _dx);
        } else {
            revert('input error');
        }
        bytes memory data = abi.encodeWithSelector(0xa6417ed6, i, j, _dx, _min_dy);
        (bool success, bytes memory returnData) = STBTPool.call(data);
        require(success == true, "call failure");
        uint256 _amount = abi.decode(returnData, (uint256));
        return _amount;
    }

    // @dev acquire lp tokens
    // @param _pool: Address of the pool to deposit into
    // @param _deposit_amounts: List of amounts of underlying coins to deposit
    // _deposit_amounts[0]: STBT amount
    // _deposit_amounts[1]: DAI amount
    // _deposit_amounts[2]: USDC amount
    // _deposit_amounts[3]: USDT amount
    // @param _min_mint_amount: Minimum amount of LP tokens to mint from the deposit
    function add_liquidity(
        address _pool, 
        uint256[4] memory _deposit_amounts, 
        uint256 _min_mint_amount
    ) public onlyGovernance returns(uint256 mint_amount) {
        if (_deposit_amounts[0] != 0) {
            IERC20(STBT).safeApprove(STBTDepositZap, 0);
            IERC20(STBT).safeApprove(STBTDepositZap, _deposit_amounts[0]);
        }
        if (_deposit_amounts[1] != 0) {
            IERC20(DAI).safeApprove(STBTDepositZap, 0);
            IERC20(DAI).safeApprove(STBTDepositZap, _deposit_amounts[1]);
        }
        if (_deposit_amounts[2] != 0) {
            IERC20(USDC).safeApprove(STBTDepositZap, 0);
            IERC20(USDC).safeApprove(STBTDepositZap, _deposit_amounts[2]);
        }
        if (_deposit_amounts[3] != 0) {
            IERC20(USDT).safeApprove(STBTDepositZap, 0);
            IERC20(USDT).safeApprove(STBTDepositZap, _deposit_amounts[3]);
        }
        bytes memory data = abi.encodeWithSelector(0x384e03db, _pool, _deposit_amounts, _min_mint_amount);
        (bool success, bytes memory returnData) = STBTDepositZap.call(data);
        require(success == true, "call failure");
        mint_amount = abi.decode(returnData, (uint256));
    }

    // @dev Withdraw and unwrap a single coin from the pool
    // @param _pool Address of the pool to deposit into
    // @param _burn_amount Amount of LP tokens to burn in the withdrawal
    // @param i Index value of the coin to withdraw
    // @param _min_amount Minimum amount of underlying coin to receive
    // i = 0, receive STBT
    // i = 1, receive DAI
    // i = 2, receive USDC
    // i = 3, receive USDT
    // @return Amount of underlying coin received
    function remove_liquidity_one_coin(
        address _pool, 
        uint256 _burn_amount, 
        int128 i, 
        uint256 _min_amount
    ) public onlyGovernance returns (uint256 token_amount) {
        IERC20(STBTPool).safeApprove(STBTDepositZap, 0);
        IERC20(STBTPool).safeApprove(STBTDepositZap, _burn_amount);
        bytes memory data = abi.encodeWithSelector(0x29ed2862, _pool, _burn_amount, i, _min_amount);
        (bool success, bytes memory returnData) = STBTDepositZap.call(data);
        require(success == true, "call failure");
        token_amount = abi.decode(returnData, (uint256));
    }

    // @dev deposit lp tokens and stake
    // @param _pid: pool id
    // @param _amount: lp tokens amount
    // @param _stake: true by default
    function depositLP(uint256 _pid, uint256 _amount, bool _stake) public onlyGovernance returns(bool) {
        IERC20(STBTPool).safeApprove(cvxBoost, 0);
        IERC20(STBTPool).safeApprove(cvxBoost, _amount);
        ICvxDeposit(cvxBoost).deposit(_pid, _amount, _stake);
        return true;
    }

    // depracated, do not use this function
    // withdraw lp tokens
    // @param _pid: pool id
    // @param _amount: lp tokens amount
    function withdrawLP(uint256 _pid, uint256 _amount) public onlyGovernance returns(bool) {
        IERC20(cvxSTBTToken).safeApprove(cvxBoost, 0);
        IERC20(cvxSTBTToken).safeApprove(cvxBoost, _amount);
        ICvxDeposit(cvxBoost).withdraw(_pid, _amount);
        return true;
    }

    // withdraw lp tokens
    // @param amount: lp tokens amount
    // @param claim: true by default
    function withdrawAndUnwrapLP(uint256 amount, bool claim) public onlyGovernance returns(bool) {
        IERC20(cvxSTBTToken).safeApprove(cvxReward, 0);
        IERC20(cvxSTBTToken).safeApprove(cvxReward, amount);
        ICvxReward(cvxReward).withdrawAndUnwrap(amount, claim);
        return true;
    }

    // @dev claim rewards
    function handleRewards() public onlyGovernance returns(bool) {
        ICvxReward(cvxReward).getReward();
        return true;
    }

    function allocateReward(int256 amount) external onlyOneBlock onlyGovernance {
        require(total_supply_staked() > 0, "rewards cannot be allocated when totalSupply is 0");

        // Create & add new snapshot
        int256 prevRPS = getLatestSnapshot().rewardPerShare;
        int256 nextRPS = prevRPS + amount * 1e18 / total_supply_staked().toInt256();

        BoardroomSnapshot memory newSnapshot = BoardroomSnapshot({time: block.number, rewardReceived: amount, rewardPerShare: nextRPS});
        boardroomHistory.push(newSnapshot);

        _totalSupply.reward += amount;
        emit RewardAdded(epoch, period, total_supply_staked(), amount);
    }

    // trigger by the governance wallet at the end of each epoch
    function updateEpoch() external onlyGovernance {
        require(block.timestamp >= nextEpochPoint(), "not opened yet");
        epoch += 1;
        lastEpochPoint += period;
        emit EpochUpdated(epoch, block.timestamp);
    }

    function governanceWithdrawFunds(address _token, uint256 amount, address to) external onlyGovernance {
        require(governanceWithdrawWhiteList[to] == true, "to address is not in the whitelist");
        IERC20(_token).safeTransfer(to, amount);
    }

    function governanceWithdrawFundsETH(uint256 amount, address to) external nonReentrant onlyGovernance {
        require(governanceWithdrawWhiteList[to] == true, "to address is not in the whitelist");
        Address.sendValue(payable(to), amount);
    }

    function executeAction(
        address internalRouter,
        address externalRouter,
        address fromTokenAddress,
        address toTokenAddress,
        uint256 amount,
        bytes memory data
    ) public onlyOperator {
        IERC20(fromTokenAddress).safeApprove(internalRouter, 0);
        IERC20(fromTokenAddress).safeApprove(internalRouter, amount);
        ISTBTRouter(internalRouter).executeWithData(externalRouter, fromTokenAddress, toTokenAddress, amount, address(this), data, true);
    }
}