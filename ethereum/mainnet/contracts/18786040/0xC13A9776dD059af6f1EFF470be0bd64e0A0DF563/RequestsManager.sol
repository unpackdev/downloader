pragma solidity ^0.8.22;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IRequestsManager.sol";
import "./AccessControlDefaultAdminRules.sol";
import "./IWagmeToken.sol";

contract RequestsManager is IRequestsManager, AccessControlDefaultAdminRules {

    bytes32 public constant SERVICE_ROLE = keccak256("SERVICE_ROLE");
    bytes32 public constant MAIN_MANAGER_ROLE = keccak256("MAIN_MANAGER_ROLE");

    IERC20 public immutable COLLATERAL_TOKEN;
    IERC20 public immutable RESOLV_TOKEN;

    address public treasuryAddress;

    uint256 public depositRequestsCounter;
    mapping(uint256 id => Request request) public depositRequests;
    uint256 public redeemRequestsCounter;
    mapping(uint256 id => Request request) public redeemRequests;

    mapping(address requester => bool isAllowed) public allowedRequesters;

    modifier depositRequestExists(uint256 _id) {
        if (!depositRequests[_id].exists) {
            revert DepositRequestNotExist(_id);
        }
        _;
    }

    modifier redeemRequestExists(uint256 _id) {
        if (!redeemRequests[_id].exists) {
            revert RedeemRequestNotExist(_id);
        }
        _;
    }

    modifier validAmount(uint256 _amount) {
        if (_amount <= 0) {
            revert InvalidAmount(_amount);
        }
        _;
    }

    modifier onlyAllowedRequester() {
        if (!allowedRequesters[msg.sender]) {
            revert UnknownRequester(msg.sender);
        }
        _;
    }

    constructor(
        address _collateralTokenAddress,
        address _resolvTokenAddress,
        address _treasuryAddress,
        address _serviceAddress
    ) AccessControlDefaultAdminRules(
    3 days,
    msg.sender
    ) {
        _assertNonZero(_collateralTokenAddress);
        _assertNonZero(_resolvTokenAddress);
        _assertNonZero(_treasuryAddress);
        _assertNonZero(_serviceAddress);

        _grantRole(MAIN_MANAGER_ROLE, _treasuryAddress);
        _grantRole(SERVICE_ROLE, _serviceAddress);

        COLLATERAL_TOKEN = IERC20(_collateralTokenAddress);
        RESOLV_TOKEN = IERC20(_resolvTokenAddress);
        treasuryAddress = _treasuryAddress;
    }

    function addRequester(address _requester) external onlyRole(DEFAULT_ADMIN_ROLE) {
        allowedRequesters[_requester] = true;
    }

    function removeRequester(address _requester) external onlyRole(DEFAULT_ADMIN_ROLE) {
        allowedRequesters[_requester] = false;
    }

    function setTreasury(address _treasuryAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _assertNonZero(_treasuryAddress);

        _revokeRole(MAIN_MANAGER_ROLE, treasuryAddress);
        treasuryAddress = _treasuryAddress;
        _grantRole(MAIN_MANAGER_ROLE, _treasuryAddress);
    }

    function deposit(uint256 _amount) external validAmount(_amount) onlyAllowedRequester {
        Request memory request = _addDepositRequest(_amount);

        SafeERC20.safeTransferFrom(COLLATERAL_TOKEN, msg.sender, address(this), _amount);

        emit DepositRequestCreated(request.id, request.requester, request.amount);
    }

    function completeDeposit(uint256 _id, uint256 _mintAmount) external
    onlyRole(SERVICE_ROLE) depositRequestExists(_id) validAmount(_mintAmount) {
        Request storage request = depositRequests[_id];
        _assertState(State.CREATED, request.state);

        request.state = State.COMPLETED;

        SafeERC20.safeIncreaseAllowance(COLLATERAL_TOKEN, address(this), request.amount);
        SafeERC20.safeTransferFrom(COLLATERAL_TOKEN, address(this), treasuryAddress, request.amount);

        IWagmeToken resolvToken = IWagmeToken(address(RESOLV_TOKEN));
        resolvToken.mint(request.requester, _mintAmount);

        emit DepositRequestCompleted(request.id, _mintAmount);
    }

    function redeem(uint256 _amount) external validAmount(_amount) onlyAllowedRequester {
        Request memory request = _addRedeemRequest(_amount);

        SafeERC20.safeTransferFrom(RESOLV_TOKEN, msg.sender, address(this), _amount);

        emit RedeemRequestCreated(request.id, request.requester, request.amount);
    }

    function completeRedeem(uint256 _id, uint256 _collateralAmount) external
    onlyRole(MAIN_MANAGER_ROLE) redeemRequestExists(_id) validAmount(_collateralAmount) {
        Request storage request = redeemRequests[_id];
        _assertState(State.CREATED, request.state);

        request.state = State.COMPLETED;

        IWagmeToken resolvToken = IWagmeToken(address(RESOLV_TOKEN));
        resolvToken.burn(address(this), request.amount);

        SafeERC20.safeTransferFrom(COLLATERAL_TOKEN, msg.sender, request.requester, _collateralAmount);

        emit RedeemRequestCompleted(request.id, _collateralAmount);
    }

    function _addDepositRequest(uint256 _amount) internal returns (Request memory depositRequest) {
        uint256 id = depositRequestsCounter;
        Request memory request = Request({
            id: id,
            requester: msg.sender,
            state: State.CREATED,
            amount: _amount,
            exists: true
        });
        depositRequests[id] = request;

        unchecked {depositRequestsCounter++;}

        return request;
    }

    function _addRedeemRequest(uint256 _amount) internal returns (Request memory redeemRequest) {
        uint256 id = redeemRequestsCounter;
        Request memory request = Request({
            id: id,
            requester: msg.sender,
            state: State.CREATED,
            amount: _amount,
            exists: true
        });
        redeemRequests[id] = request;

        unchecked {redeemRequestsCounter++;}

        return request;
    }

    function _assertNonZero(address _address) internal pure returns (address nonZeroAddress) {
        if (_address == address(0)) {
            revert ZeroAddress();
        }
        return _address;
    }

    function _assertState(State _expected, State _current) internal pure {
        if (_expected != _current) {
            revert IllegalState(_expected, _current);
        }
    }

}
