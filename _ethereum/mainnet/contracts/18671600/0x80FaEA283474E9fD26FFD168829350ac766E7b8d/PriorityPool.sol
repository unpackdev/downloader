// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

import "./UUPSUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./MerkleProofUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./MathUpgradeable.sol";

import "./IStakingPool.sol";
import "./ISDLPool.sol";

/**
 * @title Priority Pool
 * @notice Allows users to queue asset tokens which are eventually deposited into a staking pool when space becomes available -
 * liquid staking derivative tokens minted by the staking pool are then distributed using a merkle tree
 */
contract PriorityPool is UUPSUpgradeable, OwnableUpgradeable, PausableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    enum PoolStatus {
        OPEN,
        DRAINING,
        CLOSED
    }

    IERC20Upgradeable public token;
    IStakingPool public stakingPool;
    ISDLPool public sdlPool;
    address public distributionOracle;

    uint128 public queueDepositMin;
    uint128 public queueDepositMax;
    PoolStatus public poolStatus;

    bytes32 public merkleRoot;
    bytes32 public ipfsHash;
    uint256 public merkleTreeSize;

    uint256 public totalQueued;
    uint256 public depositsSinceLastUpdate;
    uint256 private sharesSinceLastUpdate;

    address[] private accounts;
    mapping(address => uint256) private accountIndexes;
    mapping(address => uint256) private accountQueuedTokens;
    mapping(address => uint256) private accountClaimed;
    mapping(address => uint256) private accountSharesClaimed;

    event UnqueueTokens(address indexed account, uint256 amount);
    event ClaimLSDTokens(address indexed account, uint256 amount, uint256 amountWithYield);
    event Deposit(address indexed account, uint256 poolAmount, uint256 queueAmount);
    event Withdraw(address indexed account, uint256 amount);
    event UpdateDistribution(
        bytes32 merkleRoot,
        bytes32 ipfsHash,
        uint256 incrementalAmount,
        uint256 incrementalSharesAmount
    );
    event SetPoolStatus(PoolStatus status);
    event SetQueueDepositParams(uint128 queueDepositMin, uint128 queueDepositMax);
    event DepositQueuedTokens(uint256 amount);

    error InvalidValue();
    error UnauthorizedToken();
    error InsufficientQueuedTokens();
    error InvalidProof();
    error InsufficientBalance();
    error NothingToClaim();
    error DepositsDisabled();
    error WithdrawalsDisabled();
    error InsufficientDepositRoom();
    error CannotSetClosedStatus();
    error SenderNotAuthorized();
    error InvalidAmount();
    error StatusAlreadySet();

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice initializes contract
     * @param _token address of asset token
     * @param _stakingPool address of staking pool
     * @param _sdlPool address of SDL pool
     * @param _queueDepositMin min amount of tokens needed to execute deposit
     * @param _queueDepositMax max amount of tokens in a single deposit
     **/
    function initialize(
        address _token,
        address _stakingPool,
        address _sdlPool,
        uint128 _queueDepositMin,
        uint128 _queueDepositMax
    ) public initializer {
        __UUPSUpgradeable_init();
        __Ownable_init();
        __Pausable_init();
        token = IERC20Upgradeable(_token);
        stakingPool = IStakingPool(_stakingPool);
        sdlPool = ISDLPool(_sdlPool);
        queueDepositMin = _queueDepositMin;
        queueDepositMax = _queueDepositMax;
        accounts.push(address(0));
        token.safeIncreaseAllowance(_stakingPool, type(uint256).max);
    }

    /**
     * @notice reverts if sender is not distribution oracle
     **/
    modifier onlyDistributionOracle() {
        if (msg.sender != distributionOracle) revert SenderNotAuthorized();
        _;
    }

    /**
     * @notice returns a list of all accounts in the order that they appear in the merkle tree
     * @return list of accounts
     */
    function getAccounts() external view returns (address[] memory) {
        return accounts;
    }

    /**
     * @notice returns the index of an account
     * @dev this index represents an account's position in the merkle tree
     * @param _account account address
     * @return account index
     */
    function getAccountIndex(address _account) external view returns (uint256) {
        return accountIndexes[_account];
    }

    /**
     * @notice returns an account's current amount of queued tokens
     * @dev _distributionAmount is stored on IPFS
     * @param _account account address
     * @param _distributionAmount account's distribution amount from the latest distribution
     * @return amount of queued tokens for an account
     */
    function getQueuedTokens(address _account, uint256 _distributionAmount) public view returns (uint256) {
        return accountQueuedTokens[_account] - _distributionAmount;
    }

    /**
     * @notice returns an account's current amount of withdrawable LSD tokens
     * @dev _distributionShareAmount is stored on IPFS
     * @param _account account address
     * @param _distributionShareAmount account's distribution share amounts from the latest distribution
     * @return withdrawable LSD tokens for account
     */
    function getLSDTokens(address _account, uint256 _distributionShareAmount) external view returns (uint256) {
        uint256 sharesToClaim = _distributionShareAmount - accountSharesClaimed[_account];
        return stakingPool.getStakeByShares(sharesToClaim);
    }

    /**
     * @notice returns the total amount of asset tokens that an account can withdraw
     * @dev includes account's queued tokens and stLINK balance and checks both priority pool
     * and staking pool liquidity
     * @param _account account address
     * @param _distributionAmount account's distribution amount from the latest distribution
     * @return amount of withrawable tokens
     */
    function canWithdraw(address _account, uint256 _distributionAmount) external view returns (uint256) {
        uint256 canUnqueue = paused() ? 0 : MathUpgradeable.min(getQueuedTokens(_account, _distributionAmount), totalQueued);
        uint256 stLINKCanWithdraw = MathUpgradeable.min(
            stakingPool.balanceOf(_account),
            stakingPool.canWithdraw() + totalQueued - canUnqueue
        );
        return canUnqueue + stLINKCanWithdraw;
    }

    /**
     * @notice ERC677 implementation to receive a token deposit or withdrawal
     * @dev can receive both asset tokens (deposit) and LSD tokens (withdrawal)
     * @param _sender of the token transfer
     * @param _value of the token transfer
     * @param _calldata encoded shouldQueue (bool)
     **/
    function onTokenTransfer(
        address _sender,
        uint256 _value,
        bytes calldata _calldata
    ) external {
        if (_value == 0) revert InvalidValue();

        if (msg.sender == address(token)) {
            bool shouldQueue = abi.decode(_calldata, (bool));
            _deposit(_sender, _value, shouldQueue);
        } else if (msg.sender == address(stakingPool)) {
            _withdraw(_value);
            token.safeTransfer(_sender, _value);
            emit Withdraw(_sender, _value);
        } else {
            revert UnauthorizedToken();
        }
    }

    /**
     * @notice deposits asset tokens into the staking pool and/or queue
     * @param _amount amount to deposit
     * @param _shouldQueue whether tokens should be queued if there's no room in the staking pool
     */
    function deposit(uint256 _amount, bool _shouldQueue) external {
        if (_amount == 0) revert InvalidAmount();
        token.safeTransferFrom(msg.sender, address(this), _amount);
        _deposit(msg.sender, _amount, _shouldQueue);
    }

    /**
     * @notice withdraws asset tokens
     * @dev will unqueue sender's tokens before taking LSD tokens if possible and
     * if _shouldUnqueue is set to true
     * @param _amountToWithdraw amount of tokens to withdraw
     * @param _amount amount as recorded in sender's merkle tree entry
     * @param _sharesAmount shares amount as recorded in sender's merkle tree entry
     * @param _merkleProof merkle proof for sender's merkle tree entry
     * @param _shouldUnqueue whether tokens should be unqueued before taking LSD tokens
     */
    function withdraw(
        uint256 _amountToWithdraw,
        uint256 _amount,
        uint256 _sharesAmount,
        bytes32[] calldata _merkleProof,
        bool _shouldUnqueue
    ) external {
        if (_amountToWithdraw == 0) revert InvalidAmount();

        uint256 toWithdraw = _amountToWithdraw;
        address account = msg.sender;

        if (_shouldUnqueue == true) {
            _requireNotPaused();

            if (_merkleProof.length != 0) {
                bytes32 node = keccak256(bytes.concat(keccak256(abi.encode(account, _amount, _sharesAmount))));
                if (!MerkleProofUpgradeable.verify(_merkleProof, merkleRoot, node)) revert InvalidProof();
            } else if (accountIndexes[account] < merkleTreeSize) {
                revert InvalidProof();
            }

            uint256 queuedTokens = getQueuedTokens(account, _amount);
            uint256 canUnqueue = queuedTokens <= totalQueued ? queuedTokens : totalQueued;
            uint256 amountToUnqueue = toWithdraw <= canUnqueue ? toWithdraw : canUnqueue;

            if (amountToUnqueue != 0) {
                accountQueuedTokens[account] -= amountToUnqueue;
                totalQueued -= amountToUnqueue;
                toWithdraw -= amountToUnqueue;
                emit UnqueueTokens(account, amountToUnqueue);
            }
        }

        if (toWithdraw != 0) {
            IERC20Upgradeable(address(stakingPool)).safeTransferFrom(account, address(this), toWithdraw);
            _withdraw(toWithdraw);
            emit Withdraw(account, toWithdraw);
        }

        token.safeTransfer(account, _amountToWithdraw);
    }

    /**
     * @notice Unqueues queued tokens
     * @param _amountToUnqueue amount of tokens to unqueue
     * @param _amount amount as recorded in sender's merkle tree entry
     * @param _sharesAmount shares amount as recorded in sender's merkle tree entry
     * @param _merkleProof merkle proof for sender's merkle tree entry
     */
    function unqueueTokens(
        uint256 _amountToUnqueue,
        uint256 _amount,
        uint256 _sharesAmount,
        bytes32[] calldata _merkleProof
    ) external whenNotPaused {
        if (_amountToUnqueue == 0) revert InvalidAmount();
        if (_amountToUnqueue > totalQueued) revert InsufficientQueuedTokens();

        address account = msg.sender;
        if (accountIndexes[account] < merkleTreeSize) {
            bytes32 node = keccak256(bytes.concat(keccak256(abi.encode(account, _amount, _sharesAmount))));
            if (!MerkleProofUpgradeable.verify(_merkleProof, merkleRoot, node)) revert InvalidProof();
        }

        if (_amountToUnqueue > getQueuedTokens(account, _amount)) revert InsufficientBalance();

        accountQueuedTokens[account] -= _amountToUnqueue;
        totalQueued -= _amountToUnqueue;
        token.safeTransfer(account, _amountToUnqueue);

        emit UnqueueTokens(account, _amountToUnqueue);
    }

    /**
     * @notice claims withdrawable LSD tokens
     * @param _amount amount as recorded in sender's merkle tree entry
     * @param _sharesAmount shares amount as recorded in sender's merkle tree entry
     * @param _merkleProof merkle proof for sender's merkle tree entry
     */
    function claimLSDTokens(
        uint256 _amount,
        uint256 _sharesAmount,
        bytes32[] calldata _merkleProof
    ) external {
        address account = msg.sender;

        bytes32 node = keccak256(bytes.concat(keccak256(abi.encode(account, _amount, _sharesAmount))));
        if (!MerkleProofUpgradeable.verify(_merkleProof, merkleRoot, node)) revert InvalidProof();

        uint256 amountToClaim = _amount - accountClaimed[account];
        uint256 sharesAmountToClaim = _sharesAmount - accountSharesClaimed[account];
        uint256 amountToClaimWithYield = stakingPool.getStakeByShares(sharesAmountToClaim);

        if (amountToClaimWithYield == 0) revert NothingToClaim();

        accountClaimed[account] = _amount;
        accountSharesClaimed[account] = _sharesAmount;
        IERC20Upgradeable(address(stakingPool)).safeTransfer(account, amountToClaimWithYield);

        emit ClaimLSDTokens(account, amountToClaim, amountToClaimWithYield);
    }

    /**
     * @notice deposits queued and/or unused tokens
     * @dev allows bypassing of the stored deposit limits
     * @param _queueDepositMin min amount of tokens required for deposit
     * @param _queueDepositMax max amount of tokens that can be deposited at once
     */
    function depositQueuedTokens(uint256 _queueDepositMin, uint256 _queueDepositMax) external {
        _depositQueuedTokens(_queueDepositMin, _queueDepositMax);
    }

    /**
     * @notice returns whether a call should be made to performUpkeep to deposit queued/unused tokens
     * into the staking pool
     * @dev used by chainlink keepers
     */
    function checkUpkeep(bytes calldata) external view returns (bool, bytes memory) {
        uint256 strategyDepositRoom = stakingPool.getStrategyDepositRoom();
        uint256 unusedDeposits = stakingPool.getUnusedDeposits();
        return (
            poolStatus == PoolStatus.OPEN &&
                strategyDepositRoom >= queueDepositMin &&
                (totalQueued + unusedDeposits) >= queueDepositMin,
            bytes("")
        );
    }

    /**
     * @notice deposits queued and/or unused tokens
     * @dev will revert if less than queueDepositMin tokens can be deposited
     * @dev used by chainlink keepers
     */
    function performUpkeep(bytes calldata) external {
        _depositQueuedTokens(queueDepositMin, queueDepositMax);
    }

    /**
     * @notice returns the amount of deposits since the last call to updateDistribution and the amount of shares
     * received for those deposits
     * @return amount of deposits
     * @return amount of shares
     */
    function getDepositsSinceLastUpdate() external view returns (uint256, uint256) {
        return (depositsSinceLastUpdate, sharesSinceLastUpdate);
    }

    /**
     * @notice returns account data used for calculating a new merkle tree
     * @dev merkle tree is calculated based on users' reSDL balance and the number of tokens they have queued,
     * the index of an account in this contract is equal to their index in the tree
     * @return accounts list of all accounts that have ever queued tokens
     * @return sdlBalances list of SDL balances for each account
     * @return queuedBalances list of queued token amounts for each account (ignores distributed LSD tokens)
     */
    function getAccountData()
        external
        view
        returns (
            address[] memory,
            uint256[] memory,
            uint256[] memory
        )
    {
        uint256[] memory reSDLBalances = new uint256[](accounts.length);
        uint256[] memory queuedBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < reSDLBalances.length; ++i) {
            address account = accounts[i];
            reSDLBalances[i] = sdlPool.effectiveBalanceOf(account);
            queuedBalances[i] = accountQueuedTokens[account];
        }

        return (accounts, reSDLBalances, queuedBalances);
    }

    /**
     * @notice distributes a new batch of LSD tokens to users that have queued tokens
     * @param _merkleRoot new merkle root for the distribution tree
     * @param _ipfsHash new ipfs hash for the distribution tree (CIDv0, no prefix - only hash)
     * @param _amountDistributed amount of LSD tokens distributed in this distribution
     * @param _sharesAmountDistributed amount of LSD shares distributed in this distribution
     */
    function updateDistribution(
        bytes32 _merkleRoot,
        bytes32 _ipfsHash,
        uint256 _amountDistributed,
        uint256 _sharesAmountDistributed
    ) external onlyDistributionOracle {
        _unpause();

        depositsSinceLastUpdate -= _amountDistributed;
        sharesSinceLastUpdate -= _sharesAmountDistributed;
        merkleRoot = _merkleRoot;
        ipfsHash = _ipfsHash;
        merkleTreeSize = accounts.length;

        emit UpdateDistribution(_merkleRoot, _ipfsHash, _amountDistributed, _sharesAmountDistributed);
    }

    /**
     * @notice pauses queueing and unqueueing so a new merkle tree can be generated
     */
    function pauseForUpdate() external onlyDistributionOracle {
        _pause();
    }

    /**
     * @notice sets the pool's status
     * @param _status pool status
     */
    function setPoolStatus(PoolStatus _status) external onlyOwner {
        if (_status == PoolStatus.CLOSED) revert CannotSetClosedStatus();
        if (_status == poolStatus) revert StatusAlreadySet();
        poolStatus = _status;
        emit SetPoolStatus(_status);
    }

    /**
     * @notice sets the pool's status to CLOSED
     */
    function setPoolStatusClosed() external onlyOwner {
        if (poolStatus == PoolStatus.CLOSED) revert StatusAlreadySet();
        poolStatus = PoolStatus.CLOSED;
        emit SetPoolStatus(PoolStatus.CLOSED);
    }

    /**
     * @notice sets the minimum and maximum amount that can be deposited
     * @param _queueDepositMin min amount of tokens required for deposit
     * @param _queueDepositMax max amount of tokens that can be deposited at once
     */
    function setQueueDepositParams(uint128 _queueDepositMin, uint128 _queueDepositMax) external onlyOwner {
        queueDepositMin = _queueDepositMin;
        queueDepositMax = _queueDepositMax;
        emit SetQueueDepositParams(_queueDepositMin, _queueDepositMax);
    }

    /**
     * @notice sets the distribution oracle
     * @param _distributionOracle address of oracle
     */
    function setDistributionOracle(address _distributionOracle) external onlyOwner {
        distributionOracle = _distributionOracle;
    }

    /**
     * @notice deposits asset tokens into the staking pool and/or queue
     * @dev tokens will be deposited into staking pool if there is room and the queue is empty, otherwise
     * they will be queued if `_shouldQueue` is true; remaining tokens will be returned to sender
     * @param _account account to deposit for
     * @param _amount amount to deposit
     * @param _shouldQueue whether tokens should be queued
     **/
    function _deposit(
        address _account,
        uint256 _amount,
        bool _shouldQueue
    ) internal {
        if (poolStatus != PoolStatus.OPEN) revert DepositsDisabled();

        uint256 toDeposit = _amount;

        if (totalQueued == 0) {
            uint256 canDeposit = stakingPool.canDeposit();
            if (canDeposit != 0) {
                uint256 toDepositIntoPool = toDeposit <= canDeposit ? toDeposit : canDeposit;
                stakingPool.deposit(_account, toDepositIntoPool);
                toDeposit -= toDepositIntoPool;
            }
        }

        if (toDeposit != 0 && _shouldQueue) {
            _requireNotPaused();
            if (accountIndexes[_account] == 0) {
                accounts.push(_account);
                accountIndexes[_account] = accounts.length - 1;
            }
            accountQueuedTokens[_account] += toDeposit;
            totalQueued += toDeposit;
        } else if (toDeposit != 0) {
            token.safeTransfer(_account, toDeposit);
        }

        emit Deposit(_account, _amount - toDeposit, _shouldQueue ? toDeposit : 0);
    }

    /**
     * @notice withdraws asset tokens
     * @dev will swap LSD tokens for queued tokens if possible followed by withdrawing
     * from the staking pool if necessary (assumes staking pool will revert if there is insufficient withdrawal room)
     * @param _amount amount to withdraw
     **/
    function _withdraw(uint256 _amount) internal {
        if (poolStatus == PoolStatus.CLOSED) revert WithdrawalsDisabled();

        uint256 toWithdrawFromQueue = _amount <= totalQueued ? _amount : totalQueued;
        uint256 toWithdrawFromPool = _amount - toWithdrawFromQueue;

        if (toWithdrawFromQueue != 0) {
            totalQueued -= toWithdrawFromQueue;
            depositsSinceLastUpdate += toWithdrawFromQueue;
            sharesSinceLastUpdate += stakingPool.getSharesByStake(toWithdrawFromQueue);
        }

        if (toWithdrawFromPool != 0) {
            stakingPool.withdraw(address(this), address(this), toWithdrawFromPool);
        }
    }

    /**
     * @notice deposits queued and/or unused tokens
     * @dev will prioritize unused deposits sitting in staking pool before queued deposits in this pool
     * @param _depositMin min amount of tokens required to deposit
     **/
    function _depositQueuedTokens(uint256 _depositMin, uint256 _depositMax) internal {
        if (poolStatus != PoolStatus.OPEN) revert DepositsDisabled();

        uint256 strategyDepositRoom = stakingPool.getStrategyDepositRoom();
        if (strategyDepositRoom == 0 || strategyDepositRoom < _depositMin) revert InsufficientDepositRoom();

        uint256 _totalQueued = totalQueued;
        uint256 unusedDeposits = stakingPool.getUnusedDeposits();
        uint256 canDeposit = _totalQueued + unusedDeposits;
        if (canDeposit == 0 || canDeposit < _depositMin) revert InsufficientQueuedTokens();

        uint256 toDepositFromStakingPool = MathUpgradeable.min(
            MathUpgradeable.min(unusedDeposits, strategyDepositRoom),
            _depositMax
        );
        uint256 toDepositFromQueue = MathUpgradeable.min(
            MathUpgradeable.min(_totalQueued, strategyDepositRoom - toDepositFromStakingPool),
            _depositMax - toDepositFromStakingPool
        );

        totalQueued = _totalQueued - toDepositFromQueue;
        depositsSinceLastUpdate += toDepositFromQueue;
        sharesSinceLastUpdate += stakingPool.getSharesByStake(toDepositFromQueue);
        stakingPool.deposit(address(this), toDepositFromQueue);

        emit DepositQueuedTokens(toDepositFromQueue);
    }

    /**
     * @dev Checks authorization for contract upgrades
     */
    function _authorizeUpgrade(address) internal override onlyOwner {}
}
