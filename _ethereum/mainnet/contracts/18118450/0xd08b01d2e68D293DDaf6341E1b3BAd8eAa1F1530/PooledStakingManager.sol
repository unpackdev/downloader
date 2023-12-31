// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./Deque.sol";
import "./IStakingWallet.sol";

contract PooledStakingManager is OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using DoubleDeque for DoubleDeque.Deque;
    using DoubleDeque for DoubleDeque.WithdrawalRequest;

    /*//////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/

    address public oracle;
    IStakingWallet public stakingWallet;

    bool public depositEnabled;
    bool public withdrawEnabled;

    /// @notice snapshot total ether
    uint256 public lastTotalETH;

    /// @notice snapshot total point
    uint256 public lastTotalPoint;

    /// @notice realtime point
    uint256 public currentPoint;

    /// @notice withdrawal request id
    uint256 public lastRequestID;

    /// @notice realtime deposit principal
    uint256 public currentDeposit;

    /// @notice max gas limit in returnETH
    uint256 public returnETHGasLimit;

    /// @notice realtime special withdrawal principal
    uint256 public currentSpecial;

    /// @notice double ended queue for withdrawal request
    DoubleDeque.Deque public registerWithdrawalQueue;

    mapping(uint256 => DoubleDeque.WithdrawalRequest) private _withdrawalRequestMap;
    mapping(address => UserStatus) private _userStatusMap;
    mapping(uint256 => bool) private _specialWithdrawalMap;

    struct UserStatus {
        uint256 point;
        uint256 principal;
    }

    /// @notice realtime special withdrawal profit
    uint256 public currentSpecialProfit;

    /// @notice withdraw pending block
    uint256 public pendingBlock;
    /// @notice block with user withdrawal permission
    mapping(address => uint256) private _canWithdrawBlock;
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event DepositEnable();
    event DepositPause();
    event WithdrawalPause();
    event WithdrawalEnable();
    event UpdateOracle(address _oracle);
    event DepositETH(address indexed _user, bytes32 tag, uint256 _amount, uint256 _point, uint256 canWithdrawBlock);
    event WithdrawalETH(
        address indexed _user,
        bool indexed _inQueue,
        uint256 _amount,
        uint256 _point,
        uint256 _requestID,
        uint256 _principal
    );
    event BalancesSubmitted(uint256 lastTotalETH, uint256 lastTotalEpETH);
    event Initialize(address _oracle, address _stakingWallet, uint256 _returnETHGasLimit);
    event UpdateReturnETHGasLimit(uint256 gasLimit);
    event AssetsDequeue(uint256 indexed _requestId, address indexed _user, uint256 _ethAmount, uint256 _profit);
    event SpecialDequeue(uint256 indexed _requestId, address indexed _user, uint256 _ethAmount, uint256 _profit);
    event SpecialReceive(uint256 indexed _requestId, address indexed _user, uint256 _ethAmount, uint256 _profit);
    event PoolDeposit(bytes pubkey, bytes signature, bytes32 deposit_data_root);
    event UpdatePendingBlock(uint256 _pendingBlock);
    /*//////////////////////////////////////////////////////////////
                            INITIALIZER
    //////////////////////////////////////////////////////////////*/

    function initialize(address _oracle, address _stakingWallet, uint256 _returnETHGasLimit) public initializer {
        require(address(_oracle) != address(0), "INVALID_ORACLE_ADDRESS");
        require(address(_stakingWallet) != address(0), "INVALID_STAKINGWALLET_ADDRESS");
        require(_returnETHGasLimit >= 26000, "GAS_LIMIT_TOO_LOW");
        oracle = _oracle;
        stakingWallet = IStakingWallet(_stakingWallet);
        __Ownable_init();
        __ReentrancyGuard_init();
        returnETHGasLimit = _returnETHGasLimit;
        emit Initialize(_oracle, _stakingWallet, _returnETHGasLimit);
    }

    /*//////////////////////////////////////////////////////////////
                                MODIFIER
    //////////////////////////////////////////////////////////////*/

    modifier onlyOracle() {
        require(msg.sender == oracle, "NOT_ORACLE");
        _;
    }

    modifier onlyWithdrawEnabled() {
        require(withdrawEnabled == true, "NOT_ENABLED");
        _;
    }

    modifier onlyDepositEnabled() {
        require(depositEnabled == true, "NOT_ENABLED");
        _;
    }

    /*//////////////////////////////////////////////////////////////
                            ADMIN METHOD
    //////////////////////////////////////////////////////////////*/

    function depositEnable() external onlyOwner {
        require(depositEnabled != true, "ALREADY_ENABLED");
        depositEnabled = true;
        emit DepositEnable();
    }

    function depositPause() external onlyOwner {
        require(depositEnabled != false, "ALREADY_PAUSED");
        depositEnabled = false;
        emit DepositPause();
    }

    function withdrawalEnable() external onlyOwner {
        require(withdrawEnabled != true, "ALREADY_ENABLED");
        withdrawEnabled = true;
        emit WithdrawalEnable();
    }

    function withdrawalPause() external onlyOwner {
        require(withdrawEnabled != false, "ALREADY_PAUSED");
        withdrawEnabled = false;
        emit WithdrawalPause();
    }

    function setReturnETHGasLimit(uint256 _returnETHGasLimit) external onlyOwner {
        require(_returnETHGasLimit >= 26000, "NEW VALUE TOO LOW");
        require(_returnETHGasLimit != returnETHGasLimit, "REPEAT_VALUE");
        returnETHGasLimit = _returnETHGasLimit;
        emit UpdateReturnETHGasLimit(_returnETHGasLimit);
    }

    function submitBalances(uint256 totalETH, uint256 totalPoint) external onlyOracle {
        lastTotalETH = totalETH;
        lastTotalPoint = totalPoint;
        emit BalancesSubmitted(lastTotalETH, lastTotalPoint);
    }

    function updateOracle(address _oracle) external onlyOwner {
        require(_oracle != address(0), "ZERO_ADDRESS");
        require(_oracle != oracle, "ORACLE_REPEAT");
        oracle = _oracle;
        emit UpdateOracle(_oracle);
    }

    function setPendingBlock(uint256 _pendingBlock) public onlyOwner {
        require(_pendingBlock != pendingBlock, "");
        pendingBlock = _pendingBlock;
        emit UpdatePendingBlock(_pendingBlock);
    }

    /*//////////////////////////////////////////////////////////////
                        ORACLE METHOD
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice deposit Ether to ETH2 deposit contract
     * @param pubkey A BLS12-381 public key.
     * @param signature A BLS12-381 signature.
     * @param deposit_data_root The SHA-256 hash of the SSZ-encoded DepositData object.
     * Used as a protection against malformed input.
     */
    function makeEth2Deposit(bytes[] calldata pubkey, bytes[] calldata signature, bytes32[] calldata deposit_data_root)
        external
        onlyOracle
    {
        require(pubkey.length == signature.length && pubkey.length == deposit_data_root.length, "INVALID INPUT");
        uint256 len = pubkey.length;
        require(address(stakingWallet).balance >= 32 ether * len, "INSUFFICIEN_WALLET_BALANCE");
        for (uint256 i = 0; i < len; i++) {
            stakingWallet.doEth2Deposit(pubkey[i], signature[i], deposit_data_root[i]);
            emit PoolDeposit(pubkey[i], signature[i], deposit_data_root[i]);
        }
    }

    function returnETH() public onlyOracle {
        for (uint256 i = 0; i < 10; i++) {
            if (hasSufficientFundsForWithdrawal()) {
                address receiver = registerWithdrawalQueue.front().user;
                uint256 ethAmount = registerWithdrawalQueue.front().amount;
                uint256 profit = registerWithdrawalQueue.front().profit;
                uint256 requestId = registerWithdrawalQueue.front().requestId;
                registerWithdrawalQueue.popFront();

                try stakingWallet.withdraw{gas: returnETHGasLimit}(receiver, ethAmount, profit) {
                    emit AssetsDequeue(requestId, receiver, ethAmount, profit);
                } catch {
                    _specialWithdrawalMap[requestId] = true;
                    currentSpecial += ethAmount;
                    currentSpecialProfit += profit;
                    emit SpecialDequeue(requestId, receiver, ethAmount, profit);
                }
            } else {
                return;
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                            USER METHOD
    //////////////////////////////////////////////////////////////*/

    /// @dev deposit ETH to ETH2.0 depositContract, and restore point to user
    function depositETH(bytes32 tag) public payable onlyDepositEnabled nonReentrant {
        uint256 ethAmount = msg.value;
        require(ethAmount >= 0.001 ether, "");
        uint256 point = calcPoint(ethAmount);
        _canWithdrawBlock[msg.sender] = block.number + pendingBlock;
        _userStatusMap[msg.sender].point += point;
        _userStatusMap[msg.sender].principal += ethAmount;
        currentPoint += point;
        currentDeposit += ethAmount;
        (bool sent,) = address(stakingWallet).call{value: ethAmount}("");
        require(sent, "FAILED TO SEND ETH");
        emit DepositETH(msg.sender, tag, ethAmount, point, block.number + pendingBlock);
    }

    function withdrawETH(uint256 point) public onlyWithdrawEnabled {
        require(_canWithdrawBlock[msg.sender] <= block.number, "PENDING_TIME");
        require(point != 0 && point <= _userStatusMap[msg.sender].point, "INSUFFICIENT_POINT");
        uint256 ethAmount = calcETH(point);
        uint256 principal =
            1e18 * _userStatusMap[msg.sender].principal * point / _userStatusMap[msg.sender].point / 1e18; // withdraw principal = (withdraw point / user total point) * user total principal
        lastRequestID += 1;
        uint256 profit = ethAmount >= principal ? ethAmount - principal : 0;
        DoubleDeque.WithdrawalRequest memory request = DoubleDeque.WithdrawalRequest({
            user: msg.sender,
            point: point,
            inQueue: false,
            amount: ethAmount,
            timestamp: block.timestamp,
            profit: profit,
            requestId: lastRequestID
        });
        currentPoint -= point;
        _userStatusMap[msg.sender].principal -= principal;
        _userStatusMap[msg.sender].point -= point;
        currentDeposit -= principal;
        if (getAvailableBalance() >= ethAmount && registerWithdrawalQueue.empty()) {
            stakingWallet.withdraw(msg.sender, ethAmount, profit);
            _withdrawalRequestMap[lastRequestID] = request;
            emit WithdrawalETH(msg.sender, false, ethAmount, point, lastRequestID, principal);
        } else {
            request.inQueue = true;
            _withdrawalRequestMap[lastRequestID] = request;
            registerWithdrawalQueue.pushBack(request);
            emit WithdrawalETH(msg.sender, true, ethAmount, point, lastRequestID, principal);
        }
    }

    function specialWithdrawalReceive(uint256 requestId) public {
        require(_specialWithdrawalMap[requestId], "");
        DoubleDeque.WithdrawalRequest memory request = _withdrawalRequestMap[requestId];
        require(msg.sender == request.user, "");
        currentSpecial -= request.amount;
        currentSpecialProfit -= request.profit;
        delete _specialWithdrawalMap[requestId];
        stakingWallet.withdraw(request.user, request.amount, request.profit);
        emit SpecialReceive(requestId, request.user, request.amount, request.profit);
    }

    receive() external payable {
        depositETH("");
    }

    /*//////////////////////////////////////////////////////////////
                            CALCULATE METHOD
    //////////////////////////////////////////////////////////////*/
    ///  lastTotalETH         ETH
    /// ——————————————   =  ——————
    /// lastTotalPoint       POINT

    /// @dev Calculate the amount of point backed by an amount of ETH
    function calcPoint(uint256 ethAmount) public view returns (uint256) {
        if (lastTotalETH == 0) return ethAmount;
        return 1e18 * lastTotalPoint * ethAmount / lastTotalETH / 1e18;
    }

    /// @dev Calculate the amount of ETH backed by an amount of point
    function calcETH(uint256 point) public view returns (uint256) {
        if (lastTotalPoint == 0) return point;
        return 1e18 * lastTotalETH * point / lastTotalPoint / 1e18;
    }

    function getExchangeRate() public view returns (uint256) {
        return calcETH(1e18);
    }

    /*//////////////////////////////////////////////////////////////
                            VIEW METHOD
    //////////////////////////////////////////////////////////////*/

    function hasSufficientFundsForWithdrawal() public view returns (bool) {
        return !registerWithdrawalQueue.empty() && getAvailableBalance() >= registerWithdrawalQueue.front().amount;
    }

    function getAvailableBalance() public view returns (uint256) {
        return address(stakingWallet).balance - currentSpecial;
    }

    function withdrawalRequestMap(uint256 requestID)
        public
        view
        returns (DoubleDeque.WithdrawalRequest memory request)
    {
        request = _withdrawalRequestMap[requestID];
    }

    function userStatusMap(address user) public view returns (UserStatus memory status) {
        status = _userStatusMap[user];
    }

    function getTotalInqueueETH() public view returns (uint256) {
        uint256 ethAmount;
        for (uint256 i = 0; i < registerWithdrawalQueue.length(); i++) {
            ethAmount += registerWithdrawalQueue.at(i).amount;
        }
        return ethAmount;
    }

    function getTotalInqueueProfit() public view returns (uint256) {
        uint256 profit;
        for (uint256 i = 0; i < registerWithdrawalQueue.length(); i++) {
            profit += registerWithdrawalQueue.at(i).profit;
        }
        return profit;
    }
}
