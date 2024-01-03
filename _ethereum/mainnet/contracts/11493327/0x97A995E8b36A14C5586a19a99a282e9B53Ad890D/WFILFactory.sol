/// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.6.12;

/// Copyright (C) 2020 WFIL Labs, Inc.
/// @title WFILFactory
/// @author Nazzareno Massari @naszam
/// @notice Wrapped Filecoin (WFIL) Factory
/// @dev All function calls are currently implemented without side effects through TDD approach
/// @dev OpenZeppelin Library is used for secure contract development

/*
╦ ╦╔═╗╦╦    ╔═╗┌─┐┌─┐┌┬┐┌─┐┬─┐┬ ┬
║║║╠╣ ║║    ╠╣ ├─┤│   │ │ │├┬┘└┬┘
╚╩╝╚  ╩╩═╝  ╚  ┴ ┴└─┘ ┴ └─┘┴└─ ┴
*/

import "./SafeERC20.sol";
import "./AccessControl.sol";
import "./Pausable.sol";
import "./Counters.sol";

interface WFILToken {
  function wrap(address to, uint256 amount) external returns (bool);
  function unwrapFrom(address account, uint256 amount) external returns (bool);
}

contract WFILFactory is AccessControl, Pausable {

    /// @dev Libraries
    using SafeERC20 for IERC20;
    using Counters for Counters.Counter;

    enum RequestStatus {PENDING, CANCELED, APPROVED, REJECTED}

    struct Request {
      address requester; // sender of the request.
      address custodian; // custodian associated to sender
      uint256 amount; // amount of fil to mint/burn.
      string deposit; // custodian's fil address in mint, merchant's fil address in burn.
      string txId; // filcoin txId for sending/redeeming fil in the mint/burn process.
      uint256 nonce; // serial number allocated for each request.
      uint256 timestamp; // time of the request creation.
      RequestStatus status; // status of the request.
    }

    WFILToken internal immutable wfil;

    /// @dev Counters
    Counters.Counter private _mintsIdTracker;
    Counters.Counter private _burnsIdTracker;

    /// @dev Storage
    mapping(address => string) public custodianDeposit;
    mapping(address => string) public merchantDeposit;
    mapping(bytes32 => uint256) public mintNonce;
    mapping(bytes32 => uint256) public burnNonce;
    mapping(uint256 => Request) public mints;
    mapping(uint256 => Request) public burns;

    /// @dev Roles
    bytes32 public constant CUSTODIAN_ROLE = keccak256("CUSTODIAN_ROLE");
    bytes32 public constant MERCHANT_ROLE = keccak256("MERCHANT_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    /// @dev Events
    event CustodianDepositSet(address indexed merchant, address indexed custodian, string deposit);
    event MerchantDepositSet(address indexed merchant, string deposit);
    event MintRequestAdd(
        uint256 indexed nonce,
        address indexed requester,
        address indexed custodian,
        uint256 amount,
        string deposit,
        string txId,
        uint256 timestamp,
        bytes32 requestHash
    );
    event MintRequestCancel(uint256 indexed nonce, address indexed requester, bytes32 requestHash);
    event MintConfirmed(
        uint256 indexed nonce,
        address indexed requester,
        address indexed custodian,
        uint256 amount,
        string deposit,
        string txId,
        uint256 timestamp,
        bytes32 requestHash
    );
    event MintRejected(
        uint256 indexed nonce,
        address indexed requester,
        address indexed custodian,
        uint256 amount,
        string deposit,
        string txId,
        uint256 timestamp,
        bytes32 requestHash
    );
    event Burned(
        uint256 indexed nonce,
        address indexed requester,
        address indexed custodian,
        uint256 amount,
        string deposit,
        uint256 timestamp,
        bytes32 requestHash
    );
    event BurnConfirmed(
        uint256 indexed nonce,
        address indexed requester,
        address indexed custodian,
        uint256 amount,
        string deposit,
        string txId,
        uint256 timestamp,
        bytes32 inputRequestHash
    );
    event BurnRejected(
        uint256 indexed nonce,
        address indexed requester,
        address indexed custodian,
        uint256 amount,
        string deposit,
        string txId,
        uint256 timestamp,
        bytes32 inputRequestHash
    );
    event TokenClaimed(IERC20 indexed token, address indexed recipient, uint256 amount);

    constructor(address wfil_, address dao_)
        public
    {
        require(wfil_ != address(0), "WFILFactory: wfil token set to zero address");
        require(dao_ != address(0), "WFILFactory: dao set to zero address");

        _setupRole(DEFAULT_ADMIN_ROLE, dao_);
        _setupRole(PAUSER_ROLE, dao_);

        wfil = WFILToken(wfil_);

    }

    /// @notice Fallback function
    /// @dev Added not payable to revert transactions not matching any other function which send value
    fallback() external {
        revert("WFILFactory: function not matching any other");
    }

    /// @notice Set Custodian Deposit Address
    /// @dev Access restricted only for Custodian
    /// @param merchant Merchant Address
    /// @param deposit Custodian deposit address
    function setCustodianDeposit(address merchant, string calldata deposit)
      external
      whenNotPaused
    {
        require(hasRole(CUSTODIAN_ROLE, msg.sender), "WFILFactory: caller is not a custodian");
        require(merchant != address(0), "WFILFactory: invalid merchant address");
        require(hasRole(MERCHANT_ROLE, merchant), "WFILFactory: merchant address does not have merchant role");
        require(!_isEmpty(deposit), "WFILFactory: invalid asset deposit address");
        require(!_compareStrings(deposit, custodianDeposit[merchant]), "WFILFactory: custodian deposit address already set");

        custodianDeposit[merchant] = deposit;
        emit CustodianDepositSet(merchant, msg.sender, deposit);
    }

    /// @notice Set Merchant Deposit Address
    /// @dev Access restricted only for Merchant
    /// @param deposit Merchant deposit address
    function setMerchantDeposit(string calldata deposit)
        external
        whenNotPaused
    {
        require(hasRole(MERCHANT_ROLE, msg.sender), "WFILFactory: caller is not a merchant");
        require(!_isEmpty(deposit), "WFILFactory: invalid asset deposit address");
        require(!_compareStrings(deposit, merchantDeposit[msg.sender]), "WFILFactory: merchant deposit address already set");

        merchantDeposit[msg.sender] = deposit;
        emit MerchantDepositSet(msg.sender, deposit);
    }

    /// @notice Add Merchant WFIL Mint Request
    /// @dev Access restricted only for Merchant
    /// @param amount Ammount of WFIL to mint
    /// @param txId Transaction Id of the FIL transaction
    /// @param custodian Custodian address
    function addMintRequest(uint256 amount, string calldata txId, address custodian)
        external
        whenNotPaused
    {
        require(hasRole(MERCHANT_ROLE, msg.sender), "WFILFactory: caller is not a merchant");
        require(amount > 0, "WFILFactory: amount is zero");
        require(!_isEmpty(txId), "WFILFactory: invalid filecoin txId");
        require(hasRole(CUSTODIAN_ROLE, custodian), "WFILFactory: custodian has not the custodian role");

        string memory deposit = custodianDeposit[msg.sender];
        require(!_isEmpty(deposit), "WFILFactory: custodian filecoin deposit address was not set");

        uint256 nonce = _mintsIdTracker.current();
        uint256 timestamp = _timestamp();

        mints[nonce].requester = msg.sender;
        mints[nonce].custodian = custodian;
        mints[nonce].amount = amount;
        mints[nonce].deposit = deposit;
        mints[nonce].txId = txId;
        mints[nonce].nonce = nonce;
        mints[nonce].timestamp = timestamp;
        mints[nonce].status = RequestStatus.PENDING;

        bytes32 requestHash = _hash(mints[nonce]);
        mintNonce[requestHash] = nonce;
        _mintsIdTracker.increment();

        emit MintRequestAdd(nonce, msg.sender, custodian, amount, deposit, txId, timestamp, requestHash);
    }

    /// @notice Cancel Merchant WFIL Mint Request
    /// @dev Access restricted only for Merchant
    /// @param requestHash Hash of the merchant mint request metadata
    function cancelMintRequest(bytes32 requestHash) external whenNotPaused {
        require(hasRole(MERCHANT_ROLE, msg.sender), "WFILFactory: caller is not a merchant");

        (uint256 nonce, Request memory request) = _getPendingMintRequest(requestHash);

        require(msg.sender == request.requester, "WFILFactory: cancel caller is different than pending request initiator");
        mints[nonce].status = RequestStatus.CANCELED;

        emit MintRequestCancel(nonce, msg.sender, requestHash);
    }

    /// @notice Confirm Merchant WFIL Mint Request
    /// @dev Access restricted only for Custodian
    /// @param requestHash Hash of the merchant mint request metadata
    function confirmMintRequest(bytes32 requestHash) external whenNotPaused {
        require(hasRole(CUSTODIAN_ROLE, msg.sender), "WFILFactory: caller is not a custodian");

        (uint256 nonce, Request memory request) = _getPendingMintRequest(requestHash);

        require(msg.sender == request.custodian, "WFILFactory: confirm caller is different than pending request custodian");

        mints[nonce].status = RequestStatus.APPROVED;

        emit MintConfirmed(
            request.nonce,
            request.requester,
            request.custodian,
            request.amount,
            request.deposit,
            request.txId,
            request.timestamp,
            requestHash
        );

        require(wfil.wrap(request.requester, request.amount), "WFILFactory: mint failed");
    }

    /// @notice Reject Merchant WFIL Mint Request
    /// @dev Access restricted only for Custodian
    /// @param requestHash Hash of the merchant mint request metadata
    function rejectMintRequest(bytes32 requestHash) external whenNotPaused {
        require(hasRole(CUSTODIAN_ROLE, msg.sender), "WFILFactory: caller is not a custodian");

        (uint256 nonce, Request memory request) = _getPendingMintRequest(requestHash);

        require(msg.sender == request.custodian, "WFILFactory: reject caller is different than pending request custodian");

        mints[nonce].status = RequestStatus.REJECTED;

        emit MintRejected(
            request.nonce,
            request.requester,
            request.custodian,
            request.amount,
            request.deposit,
            request.txId,
            request.timestamp,
            requestHash
        );
    }

    /// @notice Add Merchant WFIL Burn Request
    /// @dev Access restricted only for Merchant
    /// @dev Set txId as empty since it is not known yet.
    /// @param amount Amount of WFIL to burn
    /// @param custodian Custodian Address
    function addBurnRequest(uint256 amount, address custodian) external whenNotPaused {
        require(hasRole(MERCHANT_ROLE, msg.sender), "WFILFactory: caller is not a merchant");
        require(amount > 0, "WFILFactory: amount is zero");
        require(hasRole(CUSTODIAN_ROLE, custodian), "WFILFactory: custodian has not the custodian role");

        string memory deposit = merchantDeposit[msg.sender];
        require(!_isEmpty(deposit), "WFILFactory: merchant filecoin deposit address was not set");

        uint256 nonce = _burnsIdTracker.current();
        uint256 timestamp = _timestamp();

        string memory txId = "";

        burns[nonce].requester = msg.sender;
        burns[nonce].custodian = custodian;
        burns[nonce].amount = amount;
        burns[nonce].deposit = deposit;
        burns[nonce].txId = txId;
        burns[nonce].nonce = nonce;
        burns[nonce].timestamp = timestamp;
        burns[nonce].status = RequestStatus.PENDING;

        bytes32 requestHash = _hash(burns[nonce]);
        burnNonce[requestHash] = nonce;
        _burnsIdTracker.increment();

        emit Burned(nonce, msg.sender, custodian, amount, deposit, timestamp, requestHash);

        require(wfil.unwrapFrom(msg.sender, amount), "WFILFactory: burn failed");
    }

    /// @notice Confirm Merchant Burn Request
    /// @dev Access restricted only for Custodian
    /// @param requestHash Hash of the merchant burn request metadata
    /// @param txId Transaction Id of the FIL transaction
    function confirmBurnRequest(bytes32 requestHash, string calldata txId) external whenNotPaused {
        require(hasRole(CUSTODIAN_ROLE, msg.sender), "WFILFactory: caller is not a custodian");
        require(!_isEmpty(txId), "WFILFactory: invalid filecoin txId");

        (uint256 nonce, Request memory request) = _getPendingBurnRequest(requestHash);

        require(msg.sender == request.custodian, "WFILFactory: confirm caller is different than pending request custodian");

        burns[nonce].txId = txId;
        burns[nonce].status = RequestStatus.APPROVED;
        burnNonce[_hash(burns[nonce])] = nonce;

        emit BurnConfirmed(
            request.nonce,
            request.requester,
            request.custodian,
            request.amount,
            request.deposit,
            txId,
            request.timestamp,
            requestHash
        );
    }

    /// @notice Reject Merchant WFIL Burn Request
    /// @dev Access restricted only for Custodian
    /// @param requestHash Hash of the merchant burn request metadata
    function rejectBurnRequest(bytes32 requestHash) external whenNotPaused {
        require(hasRole(CUSTODIAN_ROLE, msg.sender), "WFILFactory: caller is not a custodian");

        (uint256 nonce, Request memory request) = _getPendingBurnRequest(requestHash);

        require(msg.sender == request.custodian, "WFILFactory: reject caller is different than pending request custodian");

        burns[nonce].status = RequestStatus.REJECTED;

        emit BurnRejected(
            request.nonce,
            request.requester,
            request.custodian,
            request.amount,
            request.deposit,
            request.txId,
            request.timestamp,
            requestHash
        );

        require(wfil.wrap(request.requester, request.amount), "WFILFactory: mint failed");
    }

    /// @notice Mint Request Getter
    /// @param nonce Mint Request Nonce
    /// @return requestNonce requester amount deposit txId timestamp status requestHash
    function getMintRequest(uint256 nonce)
        external
        view
        returns (
            uint256 requestNonce,
            address requester,
            address custodian,
            uint256 amount,
            string memory deposit,
            string memory txId,
            uint256 timestamp,
            string memory status,
            bytes32 requestHash
        )
    {
        require(_mintsIdTracker.current() > nonce, "WFILFactory: invalid mint request nonce");
        Request memory request = mints[nonce];
        string memory statusString = _getStatusString(request.status);

        requestNonce = request.nonce;
        requester = request.requester;
        custodian = request.custodian;
        amount = request.amount;
        deposit = request.deposit;
        txId = request.txId;
        timestamp = request.timestamp;
        status = statusString;
        requestHash = _hash(request);
    }

    /// @notice Mint Request Count Getter
    /// @return count Current number of mint requests
    function getMintRequestsCount() external view returns (uint256 count) {
        return _mintsIdTracker.current();
    }

    /// @notice Burn Request Getter
    /// @param nonce Burn Request Nonce
    /// @return requestNonce requester amount deposit txId timestamp status requestHash
    function getBurnRequest(uint256 nonce)
        external
        view
        returns (
            uint256 requestNonce,
            address requester,
            address custodian,
            uint256 amount,
            string memory deposit,
            string memory txId,
            uint256 timestamp,
            string memory status,
            bytes32 requestHash
        )
    {
        require(_burnsIdTracker.current() > nonce, "WFILFactory: invalid burn request nonce");
        Request memory request = burns[nonce];
        string memory statusString = _getStatusString(request.status);

        requestNonce = request.nonce;
        requester = request.requester;
        custodian = request.custodian;
        amount = request.amount;
        deposit = request.deposit;
        txId = request.txId;
        timestamp = request.timestamp;
        status = statusString;
        requestHash = _hash(request);
    }

    /// @notice Burn Request Count Getter
    /// @return count Current number of burn requests
    function getBurnRequestsCount() external view returns (uint256 count) {
        return _burnsIdTracker.current();
    }


    /// @notice Reclaim all ERC20 compatible tokens
    /// @dev Access restricted only for Default Admin
    /// @dev `recipient` cannot be the zero address
    /// @param token IERC20 address of the token contract
    /// @param recipient Recipient address
    function reclaimToken(IERC20 token, address recipient) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "WFILFactory: caller is not the default admin");
        require(recipient != address(0), "WFILFactory: recipient is the zero address");
        uint256 balance = token.balanceOf(address(this));
        token.safeTransfer(recipient, balance);
        emit TokenClaimed(token, recipient, balance);
    }


    /// @notice Add a new Custodian
    /// @dev Access restricted only for Default Admin
    /// @param account Address of the new Custodian
    /// @return True if account is added as Custodian
    function addCustodian(address account) external returns (bool) {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "WFILFactory: caller is not the default admin");
        require(account != address(0), "WFILFactory: account is the zero address");
        require(!hasRole(CUSTODIAN_ROLE, account), "WFILFactory: account is already a custodian");
        grantRole(CUSTODIAN_ROLE, account);
        return true;
    }

    /// @notice Remove a Custodian
    /// @dev Access restricted only for Default Admin
    /// @param account Address of the Custodian
    /// @return True if account is removed as Custodian
    function removeCustodian(address account) external returns (bool) {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "WFILFactory: caller is not the default admin");
        require(hasRole(CUSTODIAN_ROLE, account), "WFILFactory: account is not a custodian");
        revokeRole(CUSTODIAN_ROLE, account);
        return true;
    }

    /// @notice Add a new Merchant
    /// @dev Access restricted only for Default Admin
    /// @param account Address of the new Merchant
    /// @return True if account is added as Merchant
    function addMerchant(address account) external returns (bool) {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "WFILFactory: caller is not the default admin");
        require(account != address(0), "WFILFactory: account is the zero address");
        require(!hasRole(MERCHANT_ROLE, account), "WFILFactory: account is already a merchant");
        grantRole(MERCHANT_ROLE, account);
        return true;
    }

    /// @notice Remove a Merchant
    /// @dev Access restricted only for Default Admin
    /// @param account Address of the Merchant
    /// @return True if account is removed as Merchant
    function removeMerchant(address account) external returns (bool) {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "WFILFactory: caller is not the default admin");
        require(hasRole(MERCHANT_ROLE, account), "WFILFactory: account is not a merchant");
        revokeRole(MERCHANT_ROLE, account);
        return true;
    }

    /// @notice Pause all the functions
    /// @dev the caller must have the 'PAUSER_ROLE'
    function pause() external {
        require(hasRole(PAUSER_ROLE, msg.sender), "WFILFactory: must have pauser role to pause");
        _pause();
    }

    /// @notice Unpause all the functions
    /// @dev the caller must have the 'PAUSER_ROLE'
    function unpause() external {
        require(hasRole(PAUSER_ROLE, msg.sender), "WFILFactory: must have pauser role to unpause");
        _unpause();
    }

    /// @notice Compare Strings
    /// @dev compare the hash of two strings
    /// @param a String A
    /// @param b String B
    /// @return True if the strings matches
    function _compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }

    /// @notice Check for Empty String
    /// @dev compare a string with ""
    /// @param a String A
    /// @return True if the string is empty
    function _isEmpty(string memory a) internal pure returns (bool) {
       return bytes(a).length == 0;
    }

    /// @notice Return Current Block Timestamp
    /// @dev block.timestamp is only used for data maintaining purpose, it is not relied on for critical logic
    function _timestamp() internal view returns (uint256) {
      return block.timestamp;
    }

    /// @notice Hash the Request Metadata
    /// @param request Request
    /// @return hash Hash of the request metadata
    function _hash(Request memory request) internal pure returns (bytes32 hash) {
        return keccak256(abi.encode(
            request.requester,
            request.custodian,
            request.amount,
            request.deposit,
            request.txId,
            request.nonce,
            request.timestamp
        ));
    }

    /// @notice Get Pending Mint Requests
    /// @param requestHash Hash of the merchant mint request metadata
    /// @return nonce request
    function _getPendingMintRequest(bytes32 requestHash) internal view returns (uint256 nonce, Request memory request) {
        require(requestHash != 0, "WFILFactory: request hash is 0");
        nonce = mintNonce[requestHash];
        request = mints[nonce];
        _check(request, requestHash);
    }

    /// @notice Get Pending Burn Requests
    /// @param requestHash Hash of the merchant burn request metadata
    /// @return nonce request
    function _getPendingBurnRequest(bytes32 requestHash) internal view returns (uint256 nonce, Request memory request) {
        require(requestHash != 0, "WFILFactory: request hash is 0");
            nonce = burnNonce[requestHash];
            request = burns[nonce];
            _check(request, requestHash);
    }

    /// @notice Validate Pending Mint/Burn Requests
    /// @dev Revert on not valid requests
    /// @dev Hook used in _getPendingMintRequest and _getPendingBurnRequest
    /// @param request Request
    /// @param requestHash Hash of the merchant mint/burn request metadata
    function _check(Request memory request, bytes32 requestHash) internal pure {
        require(request.status == RequestStatus.PENDING, "WFILFactory: request is not pending");
        require(requestHash == _hash(request), "WFILFactory: given request hash does not match a pending request");
    }

    /// @notice Return Request Status String
    /// @dev decode enum into string
    /// @param status Request Status
    /// @return request status string
    function _getStatusString(RequestStatus status) internal pure returns (string memory) {
        if (status == RequestStatus.PENDING) return "pending";
        else if (status == RequestStatus.CANCELED) return "canceled";
        else if (status == RequestStatus.APPROVED) return "approved";
        else if (status == RequestStatus.REJECTED) return "rejected";
        else revert("WFILFactory: unknown status");
    }
}
