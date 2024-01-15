// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

import "./SafeERC20.sol";
import "./Address.sol";
import "./IS7NSManagement.sol";
import "./IS7NSAvatar.sol";

contract SaleEvents {
    using SafeERC20 for IERC20;

    struct EventInfo {
        uint256 start;
        uint256 end;
        uint256 maxAllocation;      
        uint256 availableAmount;
        uint256 maxSaleAmount;
        bool isPublic;
        bool forcedTerminate;
    }
    
    bytes32 private constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    IS7NSManagement public management;
    uint256 public counter;
    
    mapping(uint256 => EventInfo) public events;
    mapping(uint256 => address) public nftTokens;
    mapping(uint256 => mapping(address => uint256)) public purchased;
    mapping(uint256 => mapping(address => uint256)) public prices;
    mapping(uint256 => mapping(address => bool)) public whitelist;

    event Purchased(
        uint256 indexed eventId,
        address indexed to,
        address indexed nftToken,
        address paymentToken,
        uint256 purchasedAmt,
        uint256 paymentAmt
    );

    event SetEvent(
        uint256 indexed eventId,
        uint256 indexed start,
        uint256 indexed end,
        uint256 maxSaleAmount,
        uint256 maxAllocation
    );

    event SetPrice(
        uint256 indexed eventId,
        address indexed token,
        uint256 indexed price
    );

    modifier onlyManager() {
        require(
            management.hasRole(MANAGER_ROLE, msg.sender), "OnlyManager"
        );
        _;
    }

    modifier checkEvent(uint256 eventId) {
        uint256 _current = block.timestamp;
        uint256 _endTime = events[eventId].end;
        require(
            _endTime != 0 && _current < _endTime && !events[eventId].forcedTerminate,
            "InvalidSetting"
        );
        _;
    }

    constructor(IS7NSManagement _management) {
        management = _management;
        counter = 1;
    }

    /**
        @notice Update a new address of S7NSManagement contract
        @dev  Caller must have MANAGER_ROLE
        @param _management          Address of new Governance contract

        Note: if `_management == 0x00`, this contract is deprecated
    */
    function setManagement(IS7NSManagement _management) external onlyManager {
        management = _management;
    }

    /**
        @notice Set a configuration of one `_eventId`
        @dev  Caller must have MANAGER_ROLE
        @param _eventId             The Event ID number
        @param _start               Starting time of `_eventId`
        @param _end                 Ending time of `_eventId`
        @param _maxAllocation       Max number of items can be purchased (per account) during the `_eventId`
        @param _maxSaleAmount       Max number of items can be purchased during the `_eventId`
        @param _nftToken            Address of NFT Token contract
        @param _isPublic            Public or Private Event
    */
    function setEvent(
        uint256 _eventId,
        uint256 _start,
        uint256 _end,
        uint256 _maxAllocation,
        uint256 _maxSaleAmount,
        address _nftToken,
        bool _isPublic
    ) external onlyManager {
        uint256 _current = block.timestamp;
        require(events[_eventId].end == 0, "EventExist");
        require(_start < _end && _current < _end, "InvalidSetting");

        events[_eventId].start = _start;
        events[_eventId].end = _end;
        events[_eventId].maxAllocation = _maxAllocation;
        events[_eventId].maxSaleAmount = _maxSaleAmount;
        events[_eventId].availableAmount = _maxSaleAmount;
        events[_eventId].isPublic = _isPublic;

        nftTokens[_eventId] = _nftToken;

        emit SetEvent(_eventId, _start, _end, _maxSaleAmount, _maxAllocation);
    }

    /**
        @notice Disable one `_eventId`
        @dev  Caller must have MANAGER_ROLE
        @param _eventId            Number id of an event

        Note: This method allows MANAGER_ROLE disable one event when it was set mistakenly
    */
    function terminate(uint256 _eventId) external onlyManager checkEvent(_eventId) {
        events[_eventId].forcedTerminate = true;
    }

    /**
        @notice Set fixed price (of one payment token) in the `_eventId`
        @dev  Caller must have MANAGER_ROLE
        @param _eventId            Number id of an event
        @param _token              Address of payment token (0x00 for native coin)
        @param _price              Amount to pay in the `_eventId`

        Note: Allow multiple payment tokens during the `_eventId`
    */
    function setPrice(uint256 _eventId, address _token, uint256 _price) external onlyManager checkEvent(_eventId) {
        require(management.paymentTokens(_token), "PaymentNotSupported");

        prices[_eventId][_token] = _price;

        emit SetPrice(_eventId, _token, _price);
    }

    /**
        @notice Add/Remove `_beneficiaries`
        @dev  Caller must have MANAGER_ROLE
        @param _eventId                     Number id of an event
        @param _beneficiaries               A list of `_beneficiaries`
        @param _opt                         Option choice (true = add, false = remove)

        Note: Allow to add/remove Beneficiaries during the Event
    */
    function setWhitelist(uint256 _eventId, address[] calldata _beneficiaries, bool _opt) external onlyManager checkEvent(_eventId) {
        uint256 _len = _beneficiaries.length;
        for(uint256 i; i < _len; i++) {
            if (_opt)
                whitelist[_eventId][_beneficiaries[i]] = true;
            else 
                delete whitelist[_eventId][_beneficiaries[i]];
        }
    }

    /**
        @notice Purchase NFT items during an `eventId`
        @dev  Caller must be in the whitelist of `eventId`
        @param _eventId                 ID number of an event
        @param _paymentToken            Address of payment token (0x00 - Native Coin)
        @param _purchaseAmt             Amount of items to purchase

        Note: 
        - When `halted = true` is set in the S7NSManagement contract, 
            the `S7NSAvatar` will be disable operations that relate to transferring (i.e., transfer, mint, burn)
            Thus, it's not neccessary to add a modifier `isMaintenance()` to this function
    */
    function purchase(
        uint256 _eventId,
        address _paymentToken,
        uint256 _purchaseAmt
    ) external payable {
        address _beneficiary = msg.sender;
        uint256 _paymentAmt = _precheck(_eventId, _paymentToken, _beneficiary, _purchaseAmt);

        //  if `purchasedAmt + _purchaseAmt` exceeds `maxAllocation` -> revert
        //  if `paymentToken` = 0x00 (native coin), check `msg.value = _paymentAmt`
        uint256 _purchasedAmt = purchased[_eventId][_beneficiary] + _purchaseAmt;
        require(_purchasedAmt <= events[_eventId].maxAllocation, "ExceedAllocation");
        if (_paymentToken == address(0))
            require(msg.value == _paymentAmt, "InvalidPaymentAmount");

        events[_eventId].availableAmount -= _purchaseAmt;         //  if `availableAmount` < `_purchaseAmt` -> underflow -> revert
        purchased[_eventId][_beneficiary] = _purchasedAmt;

        _makePayment(_paymentToken, _beneficiary, _paymentAmt);

        //  if `nftToken` not set for `_eventId` yet -> address(0) -> revert
        address _nftToken = nftTokens[_eventId];
        IS7NSAvatar(_nftToken).print(_beneficiary, counter, _purchaseAmt);
        counter += _purchasedAmt;

        emit Purchased(_eventId, _beneficiary, _nftToken, _paymentToken, _purchaseAmt, _paymentAmt);
    }

    function _precheck(
        uint256 _eventId,
        address _paymentToken,
        address _beneficiary,
        uint256 _purchaseAmt
    ) private view returns (uint256 _paymentAmt) {
        uint256 _currentTime = block.timestamp;
        require(!events[_eventId].forcedTerminate, "Terminated");
        require(
            _currentTime >= events[_eventId].start && _currentTime <= events[_eventId].end,
            "NotStartOrEnded"
        );
        if (!events[_eventId].isPublic)
            require(whitelist[_eventId][_beneficiary], "NotInWhitelist");
        
        uint256 _price = prices[_eventId][_paymentToken];
        require(_price != 0, "PaymentNotSupported");
        _paymentAmt = _price * _purchaseAmt;
    }

    function _makePayment(address _token, address _from, uint256 _amount) private {
        address _treasury = management.treasury();
        if (_token == address(0))
            Address.sendValue(payable(_treasury), _amount);
        else
            IERC20(_token).safeTransferFrom(_from, _treasury, _amount);
    }
}
