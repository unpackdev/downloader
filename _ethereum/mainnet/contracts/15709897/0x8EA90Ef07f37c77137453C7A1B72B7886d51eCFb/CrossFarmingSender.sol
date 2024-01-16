// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./SafeERC20.sol";
import "./IERC20.sol";
import "./MessageReceiverApp.sol";
import "./IMessageBus.sol";
import "./AggregatorV3Interface.sol";
import "./DataTypes.sol";
import "./IVault.sol";

/// @title A cross chain sender contract for send message to receiver contract on BSC chain.
// It's for users from other EVM chain can participate Pancakeswap MCV2 farm pool CAKE reward in BSC chain.
contract CrossFarmingSender is MessageReceiverApp {
    using SafeERC20 for IERC20;

    // oracle data feeds
    enum Feeds {
        BNBUSD,
        ETHUSD
    }

    enum Chains {
        EVM,
        BSC
    }

    // cross farming vault contract on EVM chain.
    // Only Vault contract can send farming message to receiver contract.
    address public Vault;
    // cross farming receiver contract on BSC chain.
    address public CROSS_FARMING_RECEIVER;

    // create proxy contract on dest chain(BSC) gas limit.
    uint256 public createProxyGasLimit;
    // gas fee = gaslimit * gasprice, different EVM chain transaction have different average gas price
    // compensation rate in the range [0.1,10], for converting gas fee from dest chain to source chain.
    // for example, source chain gas price is 1/2 dest chain gas price, so the user paid for dest chain transaction
    // fee in sourcechain should base on 2x gas fee in source chain.
    uint256 public compensationRate;
    // Gas fee compensation rate precision.(100%)
    uint256 public constant COMPENSATION_PRECISION = 1e5;
    // Max compensation rate(1000%)
    uint256 public constant MAX_COMPENSATION_RATE = 10e5;
    // Minimize compensation rate(10%)
    uint256 public constant MIN_COMPENSATION_RATE = 1e4;
    // Small BNB change for the new user in BSC chain.
    uint256 public BNB_CHANGE = 0.005 ether;
    // ETH/BNB price exchange rate precison
    uint256 public constant EXCHANGE_RATE_PRECISION = 1e12;
    // BSC chain ID (Dest chainId)
    uint64 public immutable BSC_CHAIN_ID;

    // oracle data feeds
    mapping(Feeds => AggregatorV3Interface) public oracle;
    // oracle data feeds update time buffer
    mapping(Feeds => uint256) public oracleUpdateBuffer;
    // user pool nonce info(account => (pid => nonce))
    mapping(address => mapping(uint256 => uint64)) public nonces;
    // whether user send 1st cross-chain tx.
    mapping(address => bool) public is1st;
    // different message(operation) type have different estimate gas limit on EVM chain.
    mapping(Chains => mapping(DataTypes.MessageTypes => uint256)) public gaslimits;

    event NewOracle(address oracle);
    event VaultUpdated(address vault);
    event ReceiverUpdated(address receiver);
    event BnbChangeUpdated(uint256 amount);
    event CompensationRateUpdated(uint256 rate);
    event FeeClaimed(uint256 amount, bool success);
    event CreateProxyGasLimitUpdated(uint256 gaslimit);
    event OracleBufferUpdated(Feeds feed, uint256 oracleUpdateBuffer);
    event GasLimitUpdated(Chains chain, DataTypes.MessageTypes msgtype, uint256 gaslimit);
    event FarmingMessageReceived(
        address sender,
        uint64 srcChainId,
        uint64 nonce,
        DataTypes.MessageTypes msgType,
        address acount,
        uint256 pid,
        uint256 amount
    );

    constructor(
        address _messageBus,
        address _oracle_bnb,
        address _oracle_eth,
        uint256 _oracle_bnb_update_buffer,
        uint256 _oracle_eth_update_buffer,
        uint64 _chainId
    ) {
        // Dummy check oracle
        AggregatorV3Interface(_oracle_bnb).latestRoundData();
        AggregatorV3Interface(_oracle_eth).latestRoundData();

        messageBus = _messageBus;

        oracle[Feeds.BNBUSD] = AggregatorV3Interface(_oracle_bnb);
        oracle[Feeds.ETHUSD] = AggregatorV3Interface(_oracle_eth);

        oracleUpdateBuffer[Feeds.BNBUSD] = _oracle_bnb_update_buffer;
        oracleUpdateBuffer[Feeds.ETHUSD] = _oracle_eth_update_buffer;
        // initially, compensation rate is 100%
        compensationRate = COMPENSATION_PRECISION;
        BSC_CHAIN_ID = _chainId;
    }

    modifier onlyVault() {
        require(msg.sender == Vault, "Only vault contract");
        _;
    }

    /**
     * @notice Only called by Vault contract.
     * @param _message Encoded CrossFarmingRequest message bytes.
     */
    function sendFarmMessage(bytes calldata _message) external payable onlyVault {
        // decode the message
        DataTypes.CrossFarmRequest memory request = abi.decode((_message), (DataTypes.CrossFarmRequest));

        // ETH/USD price
        int256 ethPrice = _getPriceFromOracle(Feeds.ETHUSD);
        // BNB/USD price
        int256 bnbPrice = _getPriceFromOracle(Feeds.BNBUSD);

        require(bnbPrice > 0 && ethPrice > 0, "Abnormal prices");

        uint256 exchangeRate = (uint256(bnbPrice) * EXCHANGE_RATE_PRECISION) / uint256(ethPrice);
        // msgbus fee price by native token
        uint256 msgBusFee = IMessageBus(messageBus).calcFee(_message);

        uint256 totalFee = msgBusFee +
            // destTxFee
            (tx.gasprice *
                estimateGaslimit(Chains.BSC, request.account, request.msgType) *
                exchangeRate *
                compensationRate) /
            (EXCHANGE_RATE_PRECISION * COMPENSATION_PRECISION);

        // BNB change fee for new BNB user
        if (!is1st[request.account]) {
            totalFee += (BNB_CHANGE * exchangeRate) / EXCHANGE_RATE_PRECISION;
            is1st[request.account] = true;
        }

        if (request.msgType >= DataTypes.MessageTypes.Withdraw) {
            totalFee += (// executor call fee(Ack call on this contract 'executeMessage' interface)
            tx.gasprice *
                estimateGaslimit(Chains.EVM, request.account, request.msgType) +
                // withdraw ack msg messageBus fee on BSC chain
                ((msgBusFee * exchangeRate) / EXCHANGE_RATE_PRECISION));
        }

        require(msg.value >= totalFee, "Insufficient fee");

        IMessageBus(messageBus).sendMessage{value: msgBusFee}(request.receiver, request.dstChainId, _message);

        // increase nonce
        ++nonces[request.account][request.pid];

        if (msg.value > totalFee) {
            //send back to the user
            payable(request.account).transfer(msg.value - totalFee);
        }
    }

    /**
     * @notice Only called by MessageBus
     * @param _sender The address of the source app contract
     * @param _srcChainId The source chain ID where the transfer is originated from
     * @param _message Encoded CrossFarmingRequest message bytes.
     */
    function executeMessage(
        address _sender,
        uint64 _srcChainId,
        bytes calldata _message,
        address // executor who called the MessageBus execution function
    ) external payable override onlyMessageBus returns (ExecutionStatus) {
        require(_srcChainId == BSC_CHAIN_ID && _sender == CROSS_FARMING_RECEIVER, "Invalid receiver contract");
        // decode the message
        DataTypes.CrossFarmRequest memory request = abi.decode((_message), (DataTypes.CrossFarmRequest));

        if (request.msgType == DataTypes.MessageTypes.Withdraw) {
            IVault(Vault).ackWithdraw(request.account, request.pid, request.amount, request.nonce);
        } else if (request.msgType == DataTypes.MessageTypes.EmergencyWithdraw) {
            IVault(Vault).ackEmergencyWithdraw(request.account, request.pid, request.nonce);
        }

        emit FarmingMessageReceived(
            _sender,
            _srcChainId,
            request.nonce,
            request.msgType,
            request.account,
            request.pid,
            request.amount
        );

        return ExecutionStatus.Success;
    }

    /// set cross farming vault contract on source chain.
    /// @notice only be set once.
    function setVault(address _vault) external onlyOwner {
        require(_vault != address(0), "Vault contract can't be zero address");
        require(Vault == address(0), "Already set vault contract");
        Vault = _vault;

        emit VaultUpdated(Vault);
    }

    /// set cross farming receiver contract on dest chain(BSC chain).
    /// @notice only be set once.
    function setReceiver(address _receiver) external onlyOwner {
        require(_receiver != address(0), "Receiver contract can't be zero address");
        require(CROSS_FARMING_RECEIVER == address(0), "Already set receiver contract");
        CROSS_FARMING_RECEIVER = _receiver;

        emit ReceiverUpdated(_receiver);
    }

    /// set oracle data feeds.
    function setOracle(Feeds _feed, address _oracle) external onlyOwner {
        require(_oracle != address(0), "Oracle feed can't be zero address");
        oracle[_feed] = AggregatorV3Interface(_oracle);

        // Dummy check to make sure the interface implements this function properly
        oracle[_feed].latestRoundData();

        emit NewOracle(_oracle);
    }

    /// set oracle update buffer, different oracle feeds have different update frequency,
    /// so the buffer should also change accordingly
    function setOracleUpdateBuffer(Feeds _feed, uint256 _oracleUpdateBuffer) external onlyOwner {
        require(_oracleUpdateBuffer > 0, "oracle update time buffer should > 0");
        oracleUpdateBuffer[_feed] = _oracleUpdateBuffer;
        emit OracleBufferUpdated(_feed, _oracleUpdateBuffer);
    }

    /// set gas cost for specific operation in different chain.
    function setGaslimits(
        Chains _chain,
        DataTypes.MessageTypes _type,
        uint256 _gaslimit
    ) external onlyOwner {
        require(_gaslimit > 0, "Gaslimit should be > zero");
        gaslimits[_chain][_type] = _gaslimit;
        emit GasLimitUpdated(_chain, _type, _gaslimit);
    }

    /// @notice gas price and gas limit is different in differenct EVM chain, compensation rate
    /// is for hedging the risk of this difference caused the executor signer lose gas fee in execution
    function setCompensationRate(uint256 _rate) external onlyOwner {
        require(_rate >= MIN_COMPENSATION_RATE && _rate <= MAX_COMPENSATION_RATE, "Invalid compensation rate");
        compensationRate = _rate;
        emit CompensationRateUpdated(compensationRate);
    }

    /// set BNB change amount for new BSC chain user.
    function setBnbChange(uint256 _change) external onlyOwner {
        require(_change > 0, "BNB change for new user should greater than zero");
        BNB_CHANGE = _change;
        emit BnbChangeUpdated(_change);
    }

    /// create farming-proxy contract gas limit cost in BSC chain.
    function setCreateProxyGasLimit(uint256 _gaslimit) external onlyOwner {
        createProxyGasLimit = _gaslimit;
        emit CreateProxyGasLimitUpdated(_gaslimit);
    }

    /// estimate different operation consume gas limit in BSC chain.
    function estimateGaslimit(
        Chains _chain,
        address _account,
        DataTypes.MessageTypes _msgType
    ) public view returns (uint256 gaslimit) {
        gaslimit = gaslimits[_chain][_msgType];
        // 1st cross-chain tx should add create proxy gaslimit.
        if (!is1st[_account] && _chain == Chains.BSC) gaslimit += createProxyGasLimit;
    }

    /// transfer any ERC20 token of current contract to owner.
    function drainToken(address _token, uint256 _amount) external onlyOwner {
        IERC20(_token).safeTransfer(msg.sender, _amount);
    }

    /// send cross-chain sender contract all gas token to owner
    function claimFee(uint256 _gas) external onlyOwner {
        require(_gas >= 2300, "claimFee gaslimit should exceed 2300 ");

        uint256 amount = address(this).balance;
        (bool success, ) = msg.sender.call{value: amount, gas: _gas}("");

        emit FeeClaimed(amount, success);
    }

    /// @notice Get latest oracle price from chainlink.
    function _getPriceFromOracle(Feeds _feed) internal view returns (int256) {
        (, int256 price, , uint256 timestamp, ) = oracle[_feed].latestRoundData();
        require(timestamp + oracleUpdateBuffer[_feed] >= block.timestamp, "out of date oracle data");
        return price;
    }
}
