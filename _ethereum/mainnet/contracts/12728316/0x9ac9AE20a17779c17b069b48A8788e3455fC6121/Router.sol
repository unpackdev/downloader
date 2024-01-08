// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./ECDSA.sol";
import "./ReentrancyGuard.sol";

import "./IConsumerBase.sol";
import "./RequestIdBase.sol";


/**
 * @title Router smart contract
 *
 * @dev Routes requests for data from Consumers to data providers.
 * Data providers listen for requests and process data, sending it back to the
 * Consumer's smart contract.
 *
 * An ERC-20 Token fee is charged by the provider, and paid for by the consumer
 *
 */
contract Router is RequestIdBase, ReentrancyGuard {
    using SafeMath for uint256;
    using Address for address;

    /*
     * CONSTANTS
     */

    uint8 public constant REQUEST_STATUS_NOT_SET = 0;
    uint8 public constant REQUEST_STATUS_REQUESTED = 1;

    /*
     * STRUCTURES
     */

    struct DataRequest {
        address consumer;
        address provider;
        uint256 fee;
        uint8 status;
    }

    struct DataProvider {
        uint256 minFee;
        mapping(address => uint256) granularFees; // Per consumer fees if required
    }

    /*
     * STATE VARS
     */

    // Contract address of ERC-20 Token being used to pay for data
    IERC20 private immutable token;

    // Mapping to hold registered providers
    mapping(address => DataProvider) private dataProviders;

    // Mapping to hold open data requests
    mapping(bytes32 => DataRequest) public dataRequests;

    // nonces for generating requestIds. Must be in sync with the consumer's 
    // nonces defined in ConsumerBase.sol.
    mapping(address => mapping(address => uint256)) private nonces;

    // Mapping to track accumulated provider earnings upon request fulfillment.
    mapping(address => uint256) private withdrawableTokens;

    /*
     * EVENTS
     */

    /**
     * @dev DataRequested. Emitted when a data request is sent by a Consumer.
     * @param consumer address of the Consumer's contract
     * @param provider address of the data provider
     * @param fee amount of xFUND paid for data request
     * @param data data being requested
     * @param requestId the request ID
     */
    event DataRequested(
        address indexed consumer,
        address indexed provider,
        uint256 fee,
        bytes32 data,
        bytes32 indexed requestId
    );

    /**
     * @dev RequestFulfilled. Emitted when a provider fulfils a data request
     * @param consumer address of the Consumer's contract
     * @param provider address of the data provider
     * @param requestId the request ID being fulfilled
     * @param requestedData the data sent to the Consumer's contract
     */
    event RequestFulfilled(
        address indexed consumer,
        address indexed provider,
        bytes32 indexed requestId,
        uint256 requestedData
    );

    /**
     * @dev TokenSet. Emitted once during contract construction
     * @param tokenAddress contract address of token being used to pay fees
     */
    event TokenSet(address tokenAddress);

    /**
     * @dev ProviderRegistered. Emitted when a provider registers
     * @param provider address of the provider
     * @param minFee new fee value
     */
    event ProviderRegistered(address indexed provider, uint256 minFee);

    /**
     * @dev SetProviderMinFee. Emitted when a provider changes their minimum token fee for providing data
     * @param provider address of the provider
     * @param oldMinFee old fee value
     * @param newMinFee new fee value
     */
    event SetProviderMinFee(address indexed provider, uint256 oldMinFee, uint256 newMinFee);

    /**
     * @dev SetProviderGranularFee. Emitted when a provider changes their token fee for providing data
     * to a selected consumer contract
     * @param provider address of the provider
     * @param consumer address of the consumer
     * @param oldFee old fee value
     * @param newFee new fee value
     */
    event SetProviderGranularFee(address indexed provider, address indexed consumer, uint256 oldFee, uint256 newFee);

    /**
    * @dev WithdrawFees. Emitted when a provider withdraws their accumulated fees
    * @param provider address of the provider withdrawing
    * @param recipient address of the recipient
    * @param amount uint256 amount being withdrawn
    */
    event WithdrawFees(address indexed provider, address indexed recipient, uint256 amount);

    /*
     * FUNCTIONS
     */

    /**
     * @dev Contract constructor. Accepts the address for a Token smart contract.
     * @param _token address must be for an ERC-20 token (e.g. xFUND)
     */
    constructor(address _token) {
        require(_token != address(0), "token cannot be zero address");
        require(_token.isContract(), "token address must be a contract");
        token = IERC20(_token);
        emit TokenSet(_token);
    }

    /**
     * @dev registerAsProvider - register as a provider
     * @param _minFee uint256 - minimum fee provider will accept to fulfill request
     * @return success
     */
    function registerAsProvider(uint256 _minFee) external returns (bool success) {
        require(_minFee > 0, "fee must be > 0");
        require(dataProviders[msg.sender].minFee == 0, "already registered");
        dataProviders[msg.sender].minFee = _minFee;
        emit ProviderRegistered(msg.sender, _minFee);
        return true;
    }

    /**
     * @dev setProviderMinFee - provider calls for setting its minimum fee
     * @param _newMinFee uint256 - minimum fee provider will accept to fulfill request
     * @return success
     */
    function setProviderMinFee(uint256 _newMinFee) external returns (bool success) {
        require(_newMinFee > 0, "fee must be > 0");
        require(dataProviders[msg.sender].minFee > 0, "not registered yet");
        uint256 oldMinFee = dataProviders[msg.sender].minFee;
        dataProviders[msg.sender].minFee = _newMinFee;
        emit SetProviderMinFee(msg.sender, oldMinFee, _newMinFee);
        return true;
    }

    /**
     * @dev setProviderGranularFee - provider calls for setting its fee for the selected consumer
     * @param _consumer address of consumer contract
     * @param _newFee uint256 - minimum fee provider will accept to fulfill request
     * @return success
     */
    function setProviderGranularFee(address _consumer, uint256 _newFee) external returns (bool success) {
        require(_newFee > 0, "fee must be > 0");
        require(dataProviders[msg.sender].minFee > 0, "not registered yet");
        uint256 oldFee = dataProviders[msg.sender].granularFees[_consumer];
        dataProviders[msg.sender].granularFees[_consumer] = _newFee;
        emit SetProviderGranularFee(msg.sender, _consumer, oldFee, _newFee);
        return true;
    }

    /**
     * @dev Allows the provider to withdraw their xFUND
     * @param _recipient is the address the funds will be sent to
     * @param _amount is the amount of xFUND transferred from the Coordinator contract
     */
    function withdraw(address _recipient, uint256 _amount) external hasAvailableTokens(_amount) {
        withdrawableTokens[msg.sender] = withdrawableTokens[msg.sender].sub(_amount);
        emit WithdrawFees(msg.sender, _recipient, _amount);
        assert(token.transfer(_recipient, _amount));
    }

    /**
     * @dev initialiseRequest - called by Consumer contract to initialise a data request. Can only be called by
     * a contract. Daata providers can watch for the DataRequested being emitted, and act on any requests
     * for the provider. Only the provider specified in the request may fulfil the request.
     * @param _provider address of the data provider.
     * @param _fee amount of Tokens to pay for data
     * @param _data type of data being requested. E.g. PRICE.BTC.USD.AVG requests average price for BTC/USD pair
     * @return success if the execution was successful. Status is checked in the Consumer contract
     */
    function initialiseRequest(
        address _provider,
        uint256 _fee,
        bytes32 _data
    ) external paidSufficientFee(_fee, _provider) nonReentrant returns (bool success) {
        address consumer = msg.sender; // msg.sender is the address of the Consumer's smart contract
        require(address(consumer).isContract(), "only a contract can initialise");
        require(dataProviders[_provider].minFee > 0, "provider not registered");

        token.transferFrom(consumer, address(this), _fee);

        uint256 nonce = nonces[_provider][consumer];
        // recreate request ID from params sent
        bytes32 requestId = makeRequestId(consumer, _provider, address(this), nonce, _data);

        dataRequests[requestId].consumer = consumer;
        dataRequests[requestId].provider = _provider;
        dataRequests[requestId].fee = _fee;
        dataRequests[requestId].status = REQUEST_STATUS_REQUESTED;

        // Transfer successful - emit the DataRequested event
        emit DataRequested(
            consumer,
            _provider,
            _fee,
            _data,
            requestId
        );

        nonces[_provider][consumer] = nonces[_provider][consumer].add(1);

        return true;
    }

    /**
     * @dev fulfillRequest - called by data provider to forward data to the Consumer. Only the specified provider
     * may fulfil the data request.
     * @param _requestId the request the provider is sending data for
     * @param _requestedData the data to send
     * @param _signature data provider's signature of the _requestId, _requestedData and Consumer's address
     * this will used to validate the data's origin in the Consumer's contract
     * @return success if the execution was successful.
     */
    function fulfillRequest(bytes32 _requestId, uint256 _requestedData, bytes memory _signature)
    external
    nonReentrant
    returns (bool){
        require(dataProviders[msg.sender].minFee > 0, "provider not registered");
        require(dataRequests[_requestId].status == REQUEST_STATUS_REQUESTED, "request does not exist");

        address consumer = dataRequests[_requestId].consumer;
        address provider = dataRequests[_requestId].provider;
        uint256 fee = dataRequests[_requestId].fee;

        // signature must be valid. msg.sender must match
        // 1. the provider in the request
        // 2. the address recovered from the signature
        bytes32 message = ECDSA.toEthSignedMessageHash(keccak256(abi.encodePacked(_requestId, _requestedData, consumer)));
        address recoveredProvider = ECDSA.recover(message, _signature);

        // msg.sender is the address of the data provider
        require(msg.sender == provider &&
            msg.sender == recoveredProvider &&
            recoveredProvider == provider,
            "ECDSA.recover mismatch - correct provider and data?"
        );

        emit RequestFulfilled(
            consumer,
            msg.sender,
            _requestId,
            _requestedData
        );

        delete dataRequests[_requestId];

        withdrawableTokens[provider] = withdrawableTokens[provider].add(fee);

        // All checks have passed - send the data to the consumer contract
        // consumer will see msg.sender as the Router's contract address
        // using functionCall from OZ's Address library
        IConsumerBase cb; // just used to get the rawReceiveData function's selector
        require(gasleft() >= 400000, "not enough gas");
        consumer.functionCall(abi.encodeWithSelector(cb.rawReceiveData.selector, _requestedData, _requestId));

        return true;
    }

    /**
     * @dev getTokenAddress - get the contract address of the Token being used for paying fees
     * @return address of the token smart contract
     */
    function getTokenAddress() external view returns (address) {
        return address(token);
    }

    /**
     * @dev getDataRequestConsumer - get the consumer for a request
     * @param _requestId bytes32 request id
     * @return address data consumer contract address
     */
    function getDataRequestConsumer(bytes32 _requestId) external view returns (address) {
        return dataRequests[_requestId].consumer;
    }

    /**
     * @dev getDataRequestProvider - get the consumer for a request
     * @param _requestId bytes32 request id
     * @return address data provider address
     */
    function getDataRequestProvider(bytes32 _requestId) external view returns (address) {
        return dataRequests[_requestId].provider;
    }
    /**
     * @dev requestExists - check a request ID exists
     * @param _requestId bytes32 request id
     * @return bool
     */
    function requestExists(bytes32 _requestId) external view returns (bool) {
        return dataRequests[_requestId].status != REQUEST_STATUS_NOT_SET;
    }

    /**
     * @dev getRequestStatus - check a request status
     * 0 = does not exist/not yet initialised
     * 1 = Request initialised
     * @param _requestId bytes32 request id
     * @return bool
     */
    function getRequestStatus(bytes32 _requestId) external view returns (uint8) {
        return dataRequests[_requestId].status;
    }

    /**
     * @dev getProviderMinFee - returns minimum fee provider will accept to fulfill data request
     * @param _provider address of data provider
     * @return uint256
     */
    function getProviderMinFee(address _provider) external view returns (uint256) {
        return dataProviders[_provider].minFee;
    }

    /**
     * @dev getProviderGranularFee - returns fee provider will accept to fulfill data request
     * for the given consumer
     * @param _provider address of data provider
     * @param _consumer address of consumer contract
     * @return uint256
     */
    function getProviderGranularFee(address _provider, address _consumer) external view returns (uint256) {
        if(dataProviders[_provider].granularFees[_consumer] > 0) {
            return dataProviders[_provider].granularFees[_consumer];
        } else {
            return dataProviders[_provider].minFee;
        }
    }

    /**
     * @dev getWithdrawableTokens - returns withdrawable tokens for the given provider
     * @param _provider address of data provider
     * @return uint256
     */
    function getWithdrawableTokens(address _provider) external view returns (uint256) {
        return withdrawableTokens[_provider];
    }

    /**
     * @dev Reverts if amount is not at least what the provider has set as their min fee
     * @param _feePaid The payment for the request
     * @param _provider address of the provider
     */
    modifier paidSufficientFee(uint256 _feePaid, address _provider) {
        require(_feePaid > 0, "fee cannot be zero");
        if(dataProviders[_provider].granularFees[msg.sender] > 0) {
            require(_feePaid >= dataProviders[_provider].granularFees[msg.sender], "below agreed granular fee");
        } else {
            require(_feePaid >= dataProviders[_provider].minFee, "below agreed min fee");
        }
        _;
    }

    /**
     * @dev Reverts if amount requested is greater than withdrawable balance
     * @param _amount The given amount to compare to `withdrawableTokens`
     */
    modifier hasAvailableTokens(uint256 _amount) {
        require(withdrawableTokens[msg.sender] >= _amount, "can't withdraw more than balance");
        _;
    }
}
