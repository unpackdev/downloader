// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./AccessControl.sol";

contract AccessController is AccessControl {
    enum AccessMethods {
        UPDATE_PREMIUM_ADDRESS,
        UPDATE_ORACLE_ADDRESS,
        UPDATE_HANDLER,
        UPDATE_FEE_RECEIVER,
        UPDATE_FEE
    }

    uint256 public constant MAX_PROTOCL_FEE = 2e17; // 20%
    bytes32 public constant CONTRACT_CONTROLLER = keccak256("CONTRACT_CONTROLLER");

    uint256 public fee;
    address public feeReceiver;

    address public aquaPremiumContract;
    address public oracleContract;

    mapping(AccessMethods => bool) public isAccessControlDisabled;
    mapping(address => mapping(address => bool)) public handlerToContract;

    event OracleAddressUpdated(address oldAddress, address newAddress);
    event PremiumContractUpdated(address oldAddress, address newAddress);
    event HandlerUpdated(address handler, address contractAddress, bool status);
    event ControllerContractUpdated(address oldAddress, address newAddress);
    event FeeReceiverUpdated(address oldFeeReceiver, address newFeeReceiver);
    event FeeUpdated(uint256 oldFee, uint256 newFee);
    event AccessControlRevoked(AccessMethods methodId);

    constructor(
        address _timelock,
        address _feeReceiver,
        address _aquaPremiumContract,
        address _oracleContract,
        uint256 _fee
    ) {
        _setupRole(CONTRACT_CONTROLLER, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, _timelock);

        updateAquaPremiumAddress(_aquaPremiumContract);
        updateOracleAddress(_oracleContract);
        updateFeeReceiver(_feeReceiver);
        updateFee(_fee);
    }

    modifier accessControlEnabled(AccessMethods methodId) {
        require(isAccessControlDisabled[methodId] == false, "ACCESS_CONTROL_DISABLED");
        _;
    }

    function updateAquaPremiumAddress(address _aquaPremiumContract)
        public
        onlyRole(CONTRACT_CONTROLLER)
        accessControlEnabled(AccessMethods.UPDATE_PREMIUM_ADDRESS)
    {
        emit PremiumContractUpdated(aquaPremiumContract, _aquaPremiumContract);
        aquaPremiumContract = _aquaPremiumContract;
    }

    function updateOracleAddress(address _oracleContract)
        public
        onlyRole(CONTRACT_CONTROLLER)
        accessControlEnabled(AccessMethods.UPDATE_ORACLE_ADDRESS)
    {
        emit OracleAddressUpdated(oracleContract, _oracleContract);
        oracleContract = _oracleContract;
    }

    function updateHandler(address[] calldata handler, address[] calldata contractAddress)
        public
        onlyRole(CONTRACT_CONTROLLER)
        accessControlEnabled(AccessMethods.UPDATE_HANDLER)
    {
        require(handler.length == contractAddress.length, "Access controller :: Invalid Args.");
        for (uint8 i = 0; i < handler.length; i++) {
            handlerToContract[handler[i]][contractAddress[i]] = !handlerToContract[handler[i]][contractAddress[i]];
            emit HandlerUpdated(handler[i], contractAddress[i], handlerToContract[handler[i]][contractAddress[i]]);
        }
    }

    function updateFeeReceiver(address _feeReceiver)
        public
        onlyRole(CONTRACT_CONTROLLER)
        accessControlEnabled(AccessMethods.UPDATE_FEE_RECEIVER)
    {
        emit FeeReceiverUpdated(feeReceiver, _feeReceiver);
        feeReceiver = _feeReceiver;
    }

    function updateFee(uint256 _fee)
        public
        onlyRole(CONTRACT_CONTROLLER)
        accessControlEnabled(AccessMethods.UPDATE_FEE)
    {
        require(_fee <= MAX_PROTOCL_FEE, "FEE_EXCEEDS_MAX");
        emit FeeUpdated(fee, _fee);
        fee = _fee;
    }

    function disableAccessControlForever(AccessMethods methodId) external onlyRole(CONTRACT_CONTROLLER) {
        isAccessControlDisabled[methodId] = true;
        emit AccessControlRevoked(methodId);
    }
}
