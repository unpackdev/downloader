// SPDX-License-Identifier: BUSL-1.1
// @author cSigma Finance Inc., a Delaware company, for its Real World Credit tokenization protocol
pragma solidity ^0.8.0;

import "./LibDiamond.sol";
import "./LenderFacet.sol";
import "./CreditPoolFacet.sol";
import "./PoolManagerFacet.sol";
import "./PaymentFacet.sol";
import "./AccessControlFacet.sol";
import "./IERC20.sol";

error NotVaultCall();
error PaymentTokenIsInitialized(address token);
error InvalidAmount(uint256 amount);
error InvalidPaymentType(PaymentLib.PaymentType paymentType);
error CuringPeriodIsNotOver(string roleId);
error PendingRequestExist(string roleId);
error InvalidRequestIndex(uint256 index);
error EnforcedPause();
error ExpectedPause();

library VaultLib {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("csigma.vault.storage");

    struct VaultState {
        mapping(string => uint256) vaultBalance;
        mapping(string => uint256) borrowedAmount;
        mapping(string => RequestStatus) pendingRequest;
        Request[] requests;
        uint256 minDepositLimit;
        address paymentToken;
        bool isVaultCall;
        bool paused;
    }

    struct Request {
        string roleId;
        string poolId;
        address wallet;
        RequestType requestType;
        uint256 amount;
    }

    struct RequestStatus {
        bool isPending;
        uint256 requestIndex;
    }

    struct PaymentInfo {
        uint256 amount;
        PaymentLib.PaymentType paymentType;
    }

    enum RequestType {INVESTMENT, WITHDRAW, RECEIVE}

    enum AccountType {LENDER, POOL}

    modifier whenNotPaused() {
        requireNotPaused();
        _;
    }

    modifier whenPaused() {
        requirePaused();
        _;
    }

    function diamondStorage() internal pure returns (VaultState storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function getVaultBalance(string calldata _roleId) internal view returns (uint256) {
        VaultState storage vaultState = diamondStorage();
        return vaultState.vaultBalance[_roleId];
    }

    function getBorrowedAmount(string memory _poolId) internal view returns (uint256) {
        VaultState storage vaultState = diamondStorage();
        return vaultState.borrowedAmount[_poolId];
    }

    function getMinDepositLimit() internal view returns (uint256) {
        VaultState storage vaultState = diamondStorage();
        return vaultState.minDepositLimit;
    }

    function getPaymentToken() internal view returns (address) {
        VaultState storage vaultState = diamondStorage();
        return vaultState.paymentToken;
    }

    function getRequestStatus(string calldata _roleId) internal view returns (RequestStatus memory) {
        VaultState storage vaultState = diamondStorage();
        return vaultState.pendingRequest[_roleId];
    }

    function getRequests() internal view returns (Request[] memory) {
        VaultState storage vaultState = diamondStorage();
        return vaultState.requests;
    }

    function getRequestByIndex(uint256 _reqIndex) internal view returns (Request memory) {
        VaultState storage vaultState = diamondStorage();
        return vaultState.requests[_reqIndex];
    }

    function getRequestsLength() internal view returns (uint256) {
        VaultState storage vaultState = diamondStorage();
        return vaultState.requests.length;
    }

    function paused() internal view returns (bool) {
        VaultState storage vaultState = diamondStorage();
        return vaultState.paused;
    }

    function initializePaymentToken(address _token) internal {
        LibDiamond.enforceIsContractOwner();
        VaultState storage vaultState = diamondStorage();
        if(vaultState.paymentToken != address(0)) {
            revert PaymentTokenIsInitialized(vaultState.paymentToken);
        }
        vaultState.paymentToken = _token;
    }

    function setMinDepositLimit(uint256 _limit) internal {
        AccessControlLib.enforceIsConfigManager();
        VaultState storage vaultState = diamondStorage();
        vaultState.minDepositLimit = _limit;
    }

    function pause() internal whenNotPaused {
        LibDiamond.enforceIsContractOwner();
        VaultState storage vaultState = diamondStorage();
        vaultState.paused = true;
    }

    function unpause() internal whenPaused {
        LibDiamond.enforceIsContractOwner();
        VaultState storage vaultState = diamondStorage();
        vaultState.paused = false;
    }

    function deposit(string calldata _roleId, uint256 _amount) internal whenNotPaused returns (string memory) {
        LenderLib.enforceIsLender(_roleId);
        LenderLib.enforceIsLenderKYBVerified(_roleId);
        VaultState storage vaultState = diamondStorage();
        if(_amount == 0 || _amount < vaultState.minDepositLimit) {
            revert InvalidAmount(_amount);
        }
        IERC20(vaultState.paymentToken).transferFrom(msg.sender, address(this), _amount);
        vaultState.isVaultCall = true;
        string memory _paymentId = PaymentLib.addPayment(_roleId, new string(0), PaymentLib.PaymentType.DEPOSIT, msg.sender, address(this), _amount);
        LenderLib.addPaymentId(_roleId, _paymentId);
        vaultState.isVaultCall = false;
        vaultState.vaultBalance[_roleId] += _amount;
        return _paymentId;
    }

    function investRequest(string calldata _roleId, string calldata _poolId, uint256 _amount) internal whenNotPaused {
        LenderLib.enforceIsLender(_roleId);
        LenderLib.enforceIsLenderKYBVerified(_roleId);
        CreditPoolLib.enforceIsActivePool(_poolId);
        CreditPoolLib.enforcePoolIsNotExpired(_poolId);
        VaultState storage vaultState = diamondStorage();
        if(
            _amount == 0 ||
            _amount > vaultState.vaultBalance[_roleId] ||
            _amount + vaultState.borrowedAmount[_poolId] > CreditPoolLib.getCreditPoolBorrowingAmount(_poolId)
        ) {
            revert InvalidAmount(_amount);
        }
        if(vaultState.pendingRequest[_roleId].isPending) {
            revert PendingRequestExist(_roleId);
        }
        uint256 _reqIndex = vaultState.requests.length;
        vaultState.requests.push(Request(_roleId, _poolId, msg.sender, RequestType.INVESTMENT, _amount));
        vaultState.pendingRequest[_roleId] = RequestStatus(true, _reqIndex);
    }

    function processInvestRequest(uint256 _reqIndex, bool _isApproved) internal {
        AccessControlLib.enforceIsInvestManager();
        VaultState storage vaultState = diamondStorage();
        if(vaultState.requests[_reqIndex].requestType != RequestType.INVESTMENT) {
            revert InvalidRequestIndex(_reqIndex);
        }
        Request memory _request = vaultState.requests[_reqIndex];
        if(_isApproved) {
            LenderLib.enforceIsLenderKYBVerified(_request.roleId);
            CreditPoolLib.enforceIsActivePool(_request.poolId);
            CreditPoolLib.enforcePoolIsNotExpired(_request.poolId);
            if(_request.amount + vaultState.borrowedAmount[_request.poolId] > CreditPoolLib.getCreditPoolBorrowingAmount(_request.poolId)) {
                _request.amount = CreditPoolLib.getCreditPoolBorrowingAmount(_request.poolId) - vaultState.borrowedAmount[_request.poolId];
            }
            if(_request.amount == 0) revert InvalidAmount(_request.amount);
            vaultState.isVaultCall = true;
            string memory _paymentId = PaymentLib.addPayment(
                _request.roleId,
                _request.poolId,
                PaymentLib.PaymentType.INVESTMENT,
                _request.wallet,
                address(this),
                _request.amount
            );
            LenderLib.addPaymentId(_request.roleId, _paymentId);
            CreditPoolLib.addPaymentId(_request.poolId, _paymentId);
            CreditPoolLib.addLenderId(_request.poolId, _request.roleId);
            vaultState.isVaultCall = false;
            vaultState.vaultBalance[_request.roleId] -= _request.amount;
            vaultState.vaultBalance[_request.poolId] += _request.amount;
            vaultState.borrowedAmount[_request.poolId] += _request.amount;
        }
        uint256 _lastReqIndex = vaultState.requests.length - 1;
        if(_reqIndex != _lastReqIndex) {
            vaultState.requests[_reqIndex] = vaultState.requests[_lastReqIndex];
            vaultState.pendingRequest[vaultState.requests[_lastReqIndex].roleId].requestIndex = _reqIndex;
        }
        vaultState.requests.pop();
        delete vaultState.pendingRequest[_request.roleId];
    }

    function distribute(
        string calldata _roleId,
        string calldata _poolId,
        PaymentInfo[] calldata _paymentInfo
    ) internal {
        AccessControlLib.enforceIsDistributeManager();
        VaultState storage vaultState = diamondStorage();
        LenderLib.enforceIsLenderKYBVerified(_roleId);
        CreditPoolLib.enforceIsLenderBoundWithPool(_roleId, _poolId);
        uint256 _amount;
        vaultState.isVaultCall = true;
        for(uint i = 0; i < _paymentInfo.length; i++) {
            if(_paymentInfo[i].amount == 0) revert InvalidAmount(_paymentInfo[i].amount);
            if(
                _paymentInfo[i].paymentType == PaymentLib.PaymentType.INVESTMENT ||
                _paymentInfo[i].paymentType == PaymentLib.PaymentType.DEPOSIT ||
                _paymentInfo[i].paymentType == PaymentLib.PaymentType.WITHDRAW ||
                _paymentInfo[i].paymentType == PaymentLib.PaymentType.FEE ||
                _paymentInfo[i].paymentType == PaymentLib.PaymentType.EXIT
            ) {
                revert InvalidPaymentType(_paymentInfo[i].paymentType);
            }
            string memory _paymentId = PaymentLib.addPayment(
                _roleId,
                _poolId,
                _paymentInfo[i].paymentType,
                address(this),
                LenderLib.getLenderWallet(_roleId),
                _paymentInfo[i].amount
            );
            LenderLib.addPaymentId(_roleId, _paymentId);
            CreditPoolLib.addPaymentId(_poolId, _paymentId);
            _amount += _paymentInfo[i].amount;
        }
        vaultState.isVaultCall = false;
        if(_amount > vaultState.vaultBalance[_poolId]) revert InvalidAmount(_amount);
        vaultState.vaultBalance[_poolId] -= _amount;
        vaultState.vaultBalance[_roleId] += _amount;
    }

    function processExit(string calldata _roleId, string calldata _poolId, uint256 _amount) internal {
        AccessControlLib.enforceIsDistributeManager();
        VaultState storage vaultState = diamondStorage();
        if(_amount == 0 || _amount > vaultState.vaultBalance[_poolId]) {
            revert InvalidAmount(_amount);
        }
        LenderLib.enforceIsLenderKYBVerified(_roleId);
        CreditPoolLib.enforceIsLenderBoundWithPool(_roleId, _poolId);
        vaultState.isVaultCall = true;
        string memory _paymentId = PaymentLib.addPayment(
            _roleId,
            _poolId,
            PaymentLib.PaymentType.EXIT,
            address(this),
            LenderLib.getLenderWallet(_roleId),
            _amount
        );
        LenderLib.addPaymentId(_roleId, _paymentId);
        CreditPoolLib.addPaymentId(_poolId, _paymentId);
        CreditPoolLib.removeLenderId(_poolId, _roleId);
        vaultState.isVaultCall = false;
        vaultState.vaultBalance[_poolId] -= _amount;
        vaultState.vaultBalance[_roleId] += _amount;
    }

    function withdrawRequest(string calldata _roleId, uint256 _amount) internal whenNotPaused {
        LenderLib.enforceIsLender(_roleId);
        LenderLib.enforceIsLenderKYBVerified(_roleId);
        VaultState storage vaultState = diamondStorage();
        if(_amount == 0 || _amount > vaultState.vaultBalance[_roleId]) {
            revert InvalidAmount(_amount);
        }
        if(vaultState.pendingRequest[_roleId].isPending) {
            revert PendingRequestExist(_roleId);
        }
        uint256 _reqIndex = vaultState.requests.length;
        vaultState.requests.push(Request(_roleId, new string(0), msg.sender, RequestType.WITHDRAW, _amount));
        vaultState.pendingRequest[_roleId] = RequestStatus(true, _reqIndex);
    }

    function processWithdrawRequest(uint256 _reqIndex, bool _isApproved) internal {
        AccessControlLib.enforceIsWithdrawManager();
        VaultState storage vaultState = diamondStorage();
        if(vaultState.requests[_reqIndex].requestType != RequestType.WITHDRAW) {
            revert InvalidRequestIndex(_reqIndex);
        }
        Request memory _request = vaultState.requests[_reqIndex];
        if(_isApproved) {
            LenderLib.enforceIsLenderKYBVerified(_request.roleId);
            vaultState.isVaultCall = true;
            string memory _paymentId = PaymentLib.addPayment(
                _request.roleId,
                _request.poolId,
                PaymentLib.PaymentType.WITHDRAW,
                address(this),
                _request.wallet,
                _request.amount
            );
            LenderLib.addPaymentId(_request.roleId, _paymentId);
            vaultState.isVaultCall = false;
            vaultState.vaultBalance[_request.roleId] -= _request.amount;
            IERC20(vaultState.paymentToken).transfer(_request.wallet, _request.amount);
        }
        uint256 _lastReqIndex = vaultState.requests.length - 1;
        if(_reqIndex != _lastReqIndex) {
            vaultState.requests[_reqIndex] = vaultState.requests[_lastReqIndex];
            vaultState.pendingRequest[vaultState.requests[_lastReqIndex].roleId].requestIndex = _reqIndex;
        }
        vaultState.requests.pop();
        delete vaultState.pendingRequest[_request.roleId];
    }

    function receiveInvestmentRequest(string calldata _roleId, string calldata _poolId, uint256 _amount) internal whenNotPaused {
        CreditPoolLib.enforceIsPoolManagerBoundWithPool(_roleId, _poolId);
        PoolManagerLib.enforceIsPoolManager(_roleId);
        PoolManagerLib.enforceIsPoolManagerKYBVerified(_roleId);
        CreditPoolLib.enforceIsActivePool(_poolId);
        VaultState storage vaultState = diamondStorage();
        if(_amount == 0 || _amount > vaultState.vaultBalance[_poolId]) {
            revert InvalidAmount(_amount);
        }
        if(vaultState.pendingRequest[_roleId].isPending) {
            revert PendingRequestExist(_roleId);
        }
        uint256 _reqIndex = vaultState.requests.length;
        vaultState.requests.push(Request(_roleId, _poolId, msg.sender, RequestType.RECEIVE, _amount));
        vaultState.pendingRequest[_roleId] = RequestStatus(true, _reqIndex);
    }

    function processReceiveInvestmentRequest(uint256 _reqIndex, bool _isApproved) internal {
        AccessControlLib.enforceIsWithdrawManager();
        VaultState storage vaultState = diamondStorage();
        if(vaultState.requests[_reqIndex].requestType != RequestType.RECEIVE) {
            revert InvalidRequestIndex(_reqIndex);
        }
        Request memory _request = vaultState.requests[_reqIndex];
        if(_isApproved) {
            PoolManagerLib.enforceIsPoolManagerKYBVerified(_request.roleId);
            CreditPoolLib.enforceIsActivePool(_request.poolId);
            vaultState.isVaultCall = true;
            string memory _paymentId = PaymentLib.addPayment(
                _request.roleId,
                _request.poolId,
                PaymentLib.PaymentType.WITHDRAW,
                address(this),
                _request.wallet,
                _request.amount
            );
            PoolManagerLib.addPaymentId(_request.roleId, _paymentId);
            CreditPoolLib.addPaymentId(_request.poolId, _paymentId);
            vaultState.isVaultCall = false;
            vaultState.vaultBalance[_request.poolId] -= _request.amount;
            IERC20(vaultState.paymentToken).transfer(_request.wallet, _request.amount);
        }
        uint256 _lastReqIndex = vaultState.requests.length - 1;
        if(_reqIndex != _lastReqIndex) {
            vaultState.requests[_reqIndex] = vaultState.requests[_lastReqIndex];
            vaultState.pendingRequest[vaultState.requests[_lastReqIndex].roleId].requestIndex = _reqIndex;
        }
        vaultState.requests.pop();
        delete vaultState.pendingRequest[_request.roleId];
    }

    function pay(
        string calldata _roleId,
        string calldata _poolId,
        PaymentInfo[] calldata _paymentInfo
    ) internal whenNotPaused {
        CreditPoolLib.enforceIsPoolManagerBoundWithPool(_roleId, _poolId);
        PoolManagerLib.enforceIsPoolManager(_roleId);
        PoolManagerLib.enforceIsPoolManagerKYBVerified(_roleId);
        CreditPoolLib.enforceIsActivePool(_poolId);
        VaultState storage vaultState = diamondStorage();
        uint256 _amount;
        vaultState.isVaultCall = true;
        for(uint i = 0; i < _paymentInfo.length; i++) {
            if(_paymentInfo[i].amount == 0) revert InvalidAmount(_paymentInfo[i].amount);
            if(
                _paymentInfo[i].paymentType == PaymentLib.PaymentType.INVESTMENT ||
                _paymentInfo[i].paymentType == PaymentLib.PaymentType.DEPOSIT ||
                _paymentInfo[i].paymentType == PaymentLib.PaymentType.WITHDRAW
            ) {
                revert InvalidPaymentType(_paymentInfo[i].paymentType);
            }
            string memory _paymentId = PaymentLib.addPayment(_roleId, _poolId, _paymentInfo[i].paymentType, msg.sender, address(this), _paymentInfo[i].amount);
            PoolManagerLib.addPaymentId(_roleId, _paymentId);
            CreditPoolLib.addPaymentId(_poolId, _paymentId);
            _amount += _paymentInfo[i].amount;
        }
        vaultState.isVaultCall = false;
        IERC20(vaultState.paymentToken).transferFrom(msg.sender, address(this), _amount);
        vaultState.vaultBalance[_poolId] += _amount;
    }

    function collectFee(string calldata _poolId, uint256 _amount) internal {
        AccessControlLib.enforceIsFeeManager();
        VaultState storage vaultState = diamondStorage();
        if(_amount == 0 || _amount > vaultState.vaultBalance[_poolId]) {
            revert InvalidAmount(_amount);
        }
        vaultState.isVaultCall = true;
        string memory _paymentId = PaymentLib.addPayment(
            new string(0),
            _poolId,
            PaymentLib.PaymentType.FEE,
            address(this),
            LibDiamond.contractOwner(),
            _amount
        );
        CreditPoolLib.addPaymentId(_poolId, _paymentId);
        vaultState.isVaultCall = false;
        vaultState.vaultBalance[_poolId] -= _amount;
        IERC20(vaultState.paymentToken).transfer(LibDiamond.contractOwner(), _amount);
    }

    function adjustVaultBalance(
        string calldata _id,
        uint256 _amount,
        AccountType _account,
        PaymentLib.PaymentType _type
    ) internal {
        LibDiamond.enforceIsContractOwner();
        VaultState storage vaultState = diamondStorage();
        if(_amount == 0) revert InvalidAmount(_amount);
        string memory _roleId = _account == AccountType.LENDER ? _id : new string(0);
        string memory _poolId = _account == AccountType.POOL ? _id : new string(0);
        if(_type == PaymentLib.PaymentType.DEPOSIT) {
            vaultState.isVaultCall = true;
            string memory _paymentId = PaymentLib.addPayment(
                _roleId,
                _poolId,
                _type,
                msg.sender,
                address(this),
                _amount
            );
            _account == AccountType.LENDER ? LenderLib.addPaymentId(_id, _paymentId) : CreditPoolLib.addPaymentId(_id, _paymentId);
            vaultState.isVaultCall = false;
            vaultState.vaultBalance[_id] += _amount;
        }
        if(_type == PaymentLib.PaymentType.WITHDRAW) {
            vaultState.isVaultCall = true;
            string memory _paymentId = PaymentLib.addPayment(
                _roleId,
                _poolId,
                _type,
                address(this),
                msg.sender,
                _amount
            );
            _account == AccountType.LENDER ? LenderLib.addPaymentId(_id, _paymentId) : CreditPoolLib.addPaymentId(_id, _paymentId);
            vaultState.isVaultCall = false;
            vaultState.vaultBalance[_id] -= _amount;
        }
    }

    function emergencyWithdraw(address _token, address _to, uint256 _amount) internal {
        LibDiamond.enforceIsContractOwner();
        if(_amount == 0) revert InvalidAmount(_amount);
        IERC20(_token).transfer(_to, _amount);
    }

    function enforceIsVault() internal view {
        VaultState storage vaultState = diamondStorage();
        if(!vaultState.isVaultCall) {
            revert NotVaultCall();
        }
    }

    function requireNotPaused() internal view {
        if (paused()) {
            revert EnforcedPause();
        }
    }

    function requirePaused() internal view {
        if (!paused()) {
            revert ExpectedPause();
        }
    }    
}

contract VaultFacet {
    event Deposit(string indexed roleId, uint256 amount);
    event Invest(string indexed roleId, string poolId, uint256 amount);
    event Distribute(string indexed roleId, string poolId, VaultLib.PaymentInfo[] paymentInfo);
    event Exit(string indexed roleId, string poolId, uint256 amount);
    event Withdraw(string indexed roleId, uint256 amount);
    event Receive(string indexed roleId, string poolId, uint256 amount);
    event Pay(string indexed roleId, string poolId, VaultLib.PaymentInfo[] paymentInfo);
    event Fee(string indexed poolId, uint256 amount);
    event Adjust(string indexed id, uint256 amount, VaultLib.AccountType account, PaymentLib.PaymentType paymentType);
    event Paused(address account);
    event Unpaused(address account);
    event EmergencyWithdraw(address indexed executor, address token, address receiver, uint256 amount);

    struct DistributeBatchArgs {
        string roleId;
        string poolId;
        VaultLib.PaymentInfo[] paymentInfo;
    }

    struct ExitBatchArgs {
        string roleId;
        string poolId;
        uint256 amount;
    }

    function getVaultBalance(string calldata _roleId) external view returns (uint256) {
        return VaultLib.getVaultBalance(_roleId);
    }

    function getBorrowedAmount(string calldata _poolId) external view returns (uint256) {
        return VaultLib.getBorrowedAmount(_poolId);
    }

    function getMinDepositLimit() external view returns (uint256) {
        return VaultLib.getMinDepositLimit();
    }

    function getPaymentToken() external view returns (address) {
        return VaultLib.getPaymentToken();
    }

    function getRequestStatus(string calldata _roleId) external view returns (VaultLib.RequestStatus memory) {
        return VaultLib.getRequestStatus(_roleId);
    }

    function getRequests() external view returns (VaultLib.Request[] memory) {
        return VaultLib.getRequests();
    }

    function getRequestByIndex(uint256 _reqIndex) external view returns (VaultLib.Request memory) {
        return VaultLib.getRequestByIndex(_reqIndex);
    }

    function getRequestsLength() external view returns (uint256) {
        return VaultLib.getRequestsLength();
    }

    function paused() external view returns (bool) {
        return VaultLib.paused();
    }

    function initializePaymentToken(address _token) external {
        return VaultLib.initializePaymentToken(_token);
    }

    function setMinDepositLimit(uint256 _limit) external {
        return VaultLib.setMinDepositLimit(_limit);
    }

    function deposit(string calldata _roleId, uint256 _amount) external returns (string memory) {
        emit Deposit(_roleId, _amount);
        return VaultLib.deposit(_roleId, _amount);
    }

    function investRequest(string calldata _roleId, string calldata _poolId, uint256 _amount) external {
        VaultLib.investRequest(_roleId, _poolId, _amount);
    }

    function processInvestRequest(uint256 _reqIndex, bool _isApproved) external {
        if(_isApproved) {
            VaultLib.Request memory _request = VaultLib.getRequestByIndex(_reqIndex);
            if(_request.amount + VaultLib.getBorrowedAmount(_request.poolId) > CreditPoolLib.getCreditPoolBorrowingAmount(_request.poolId)) {
                _request.amount = CreditPoolLib.getCreditPoolBorrowingAmount(_request.poolId) - VaultLib.getBorrowedAmount(_request.poolId);
            }
            emit Invest(_request.roleId, _request.poolId, _request.amount);
        }
        VaultLib.processInvestRequest(_reqIndex, _isApproved);
    }

    function distribute(
        string calldata _roleId,
        string calldata _poolId,
        VaultLib.PaymentInfo[] calldata _paymentInfo
    ) external {
        VaultLib.distribute(_roleId, _poolId, _paymentInfo);
        emit Distribute(_roleId, _poolId, _paymentInfo);
    }

    function distributeBatch(DistributeBatchArgs[] calldata _distribute) external {
        for(uint i; i < _distribute.length; i++) {
            VaultLib.distribute(_distribute[i].roleId, _distribute[i].poolId, _distribute[i].paymentInfo);
            emit Distribute(_distribute[i].roleId, _distribute[i].poolId, _distribute[i].paymentInfo);
        }
    }

    function processExit(string calldata _roleId, string calldata _poolId, uint256 _amount) external {
        VaultLib.processExit(_roleId, _poolId, _amount);
        emit Exit(_roleId, _poolId, _amount);
    }

    function processExitBatch(ExitBatchArgs[] calldata _exit) external {
        for(uint i; i < _exit.length; i++) {
            VaultLib.processExit(_exit[i].roleId, _exit[i].poolId, _exit[i].amount);
            emit Exit(_exit[i].roleId, _exit[i].poolId, _exit[i].amount);
        }
    }

    function withdrawRequest(string calldata _roleId, uint256 _amount) external {
        VaultLib.withdrawRequest(_roleId, _amount);
    }

    function processWithdrawRequest(uint256 _reqIndex, bool _isApproved) external {
        if(_isApproved) {
            VaultLib.Request memory _request = VaultLib.getRequestByIndex(_reqIndex);
            emit Withdraw(_request.roleId, _request.amount);
        }
        VaultLib.processWithdrawRequest(_reqIndex, _isApproved);
    }

    function receiveInvestmentRequest(string calldata _roleId, string calldata _poolId, uint256 _amount) external {
        VaultLib.receiveInvestmentRequest(_roleId, _poolId, _amount);
    }

    function processReceiveInvestmentRequest(uint256 _reqIndex, bool _isApproved) external {
        if(_isApproved) {
            VaultLib.Request memory _request = VaultLib.getRequestByIndex(_reqIndex);
            emit Receive(_request.roleId, _request.poolId, _request.amount);
        }
        VaultLib.processReceiveInvestmentRequest(_reqIndex, _isApproved);
    }

    function pay(
        string calldata _roleId,
        string calldata _poolId,
        VaultLib.PaymentInfo[] calldata _paymentInfo
    ) external {
        VaultLib.pay(_roleId, _poolId, _paymentInfo);
        emit Pay(_roleId, _poolId, _paymentInfo);
    }

    function collectFee(string calldata _poolId, uint256 _amount) external {
        VaultLib.collectFee(_poolId, _amount);
        emit Fee(_poolId, _amount);
    }

    function adjustVaultBalance(
        string calldata _id,
        uint256 _amount,
        VaultLib.AccountType _account,
        PaymentLib.PaymentType _type
    ) external {
        VaultLib.adjustVaultBalance(_id, _amount, _account, _type);
        emit Adjust(_id, _amount, _account, _type);
    }

    function emergencyWithdraw(address _token, address _to, uint256 _amount) external {
        VaultLib.emergencyWithdraw(_token, _to, _amount);
        emit EmergencyWithdraw(msg.sender, _token, _to, _amount);
    }

    function pause() external {
        VaultLib.pause();
        emit Paused(msg.sender);
    }

    function unpause() external {
        VaultLib.unpause();
        emit Unpaused(msg.sender);
    }
}