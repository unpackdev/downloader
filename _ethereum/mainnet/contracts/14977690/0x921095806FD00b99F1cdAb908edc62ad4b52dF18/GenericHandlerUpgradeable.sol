// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;
pragma experimental ABIEncoderV2;

import "./Initializable.sol";
import "./AddressUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./IGenericHandler.sol";
import "./iRouterCrossTalk.sol";
import "./iGBridge.sol";
import "./IFeeManagerGeneric.sol";

/**
    @title Handles generic deposits and deposit executions.
    @author Router Protocol
    @notice This contract is intended to be used with the Bridge contract.
**/
contract GenericHandlerUpgradeable is Initializable, AccessControlUpgradeable {
    using AddressUpgradeable for address;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    // ----------------------------------------------------------------- //
    //                        DS Section Starts                          //
    // ----------------------------------------------------------------- //

    bytes32 public constant BRIDGE_ROLE = keccak256("BRIDGE_ROLE");

    bytes32 public constant FEE_SETTER_ROLE = keccak256("FEE_SETTER_ROLE");

    iGBridge public bridge;

    iFeeManagerGeneric private feeManager;

    bytes32 private resourceID;

    mapping(uint8 => mapping(uint64 => DepositRecord)) private _depositRecords;

    mapping(uint8 => mapping(uint64 => ExecuteRecord)) private _executeRecords;

    struct ExecuteRecord {
        bool isExecuted;
        bool _status;
        bytes _callback;
    }

    struct DepositRecord {
        bytes32 _resourceID;
        uint8 _srcChainID;
        uint8 _destChainID;
        uint64 _nonce;
        address _srcAddress;
        address _destAddress;
        bytes4 _selector;
        bytes data;
        bytes32 hash;
        uint256 _gas;
        address _feeToken;
    }

    struct RouterLinker {
        address _rSyncContract;
        uint8 _chainID;
        address _linkedContract;
    }

    mapping(uint8 => uint256) private defaultGas;

    // ----------------------------------------------------------------- //
    //                        DS Section Ends                            //
    // ----------------------------------------------------------------- //

    // ----------------------------------------------------------------- //
    //                        Init Section Starts                        //
    // ----------------------------------------------------------------- //

    function __GenericHandlerUpgradeable_init(address _bridge, bytes32 _resourceID) internal initializer {
        __AccessControl_init();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(BRIDGE_ROLE, _bridge);
        _setupRole(FEE_SETTER_ROLE, msg.sender);

        bridge = iGBridge(_bridge);
        resourceID = _resourceID;
    }

    function __GenericHandlerUpgradeable_init_unchained() internal initializer {}

    function initialize(address _bridge, bytes32 _resourceID) external initializer {
        __GenericHandlerUpgradeable_init(_bridge, _resourceID);
    }

    // ----------------------------------------------------------------- //
    //                        Init Section Ends                          //
    // ----------------------------------------------------------------- //

    // ----------------------------------------------------------------- //
    //                        Mapping Section Starts                     //
    // ----------------------------------------------------------------- //

    /**
        @notice Function Maps the two contracts on cross chain enviroment
        @param linker Linker object to be verified
    **/
    function MapContract(RouterLinker calldata linker) external {
        iRouterCrossTalk crossTalk = iRouterCrossTalk(linker._rSyncContract);
        require(
            msg.sender == crossTalk.fetchLinkSetter(),
            "Router Generichandler : Only Link Setter can map contracts"
        );
        crossTalk.Link{ gas: 57786 }(linker._chainID, linker._linkedContract);
    }

    /**
        @notice Function UnMaps the two contracts on cross chain enviroment
        @param linker Linker object to be verified
    **/
    function UnMapContract(RouterLinker calldata linker) external {
        iRouterCrossTalk crossTalk = iRouterCrossTalk(linker._rSyncContract);
        require(
            msg.sender == crossTalk.fetchLinkSetter(),
            "Router Generichandler : Only Link Setter can unmap contracts"
        );
        crossTalk.Unlink{ gas: 35035 }(linker._chainID);
    }

    // ----------------------------------------------------------------- //
    //                        Mapping Section Ends                       //
    // ----------------------------------------------------------------- //

    // ----------------------------------------------------------------- //
    //                        Deposit Section Starts                     //
    // ----------------------------------------------------------------- //

    /**
        @notice Function fired to fetch chain ID from bridge.
    **/
    function fetch_chainID() external view returns (uint8) {
        return bridge.fetch_chainID();
    }

    /**
        @notice Function fired to trigger Cross Chain Communication.
        @param  _destChainID Destination ChainID
        @param  _selector Selector for the cross chain function.
        @param  _data Data for the cross chain function.
        @param  hash Hash of the cross chain data packet.
        @param  _gas Gas allowed for the transaction.
        @param  _feeToken Fee Token for the transaction.
    **/
    function genericDeposit(
        uint8 _destChainID,
        bytes4 _selector,
        bytes calldata _data,
        bytes32 hash,
        uint256 _gas,
        address _feeToken
    ) external {
        uint64 _nonce = bridge.genericDeposit(_destChainID, resourceID);
        iRouterCrossTalk crossTalk = iRouterCrossTalk(msg.sender);
        uint8 chainid = bridge.fetch_chainID();
        address destAddress = crossTalk.fetchLink(_destChainID);

        require(defaultGas[_destChainID] != 0, "Router Generichandler : Destination Gas Not Set");
        uint256 gas = _gas < defaultGas[_destChainID] ? defaultGas[_destChainID] : _gas;
        deductFee(_destChainID, _feeToken, gas);
        DepositRecord memory record = DepositRecord(
            resourceID,
            chainid,
            _destChainID,
            _nonce,
            msg.sender,
            destAddress,
            _selector,
            _data,
            hash,
            gas,
            _feeToken
        );
        _depositRecords[_destChainID][_nonce] = record;
    }

    /**
        @notice Function fetches deposit record.
        @param  _ChainID CHainID of the deposit
        @param  _nonce Nonce of the deposit
    **/
    function fetchDepositRecord(uint8 _ChainID, uint64 _nonce) external view returns (DepositRecord memory) {
        return _depositRecords[_ChainID][_nonce];
    }

    /**
        @notice Function fetches execute record.
        @param  _ChainID CHainID of the deposit
        @param  _nonce Nonce of the deposit
    **/
    function fetchExecuteRecord(uint8 _ChainID, uint64 _nonce) external view returns (ExecuteRecord memory) {
        return _executeRecords[_ChainID][_nonce];
    }

    // ----------------------------------------------------------------- //
    //                        Deposit Section Ends                       //
    // ----------------------------------------------------------------- //

    // ----------------------------------------------------------------- //
    //                        Execute Section Starts                     //
    // ----------------------------------------------------------------- //

    /**
        @notice Function Executes a cross Chain Request on destination chain and can only be triggered by bridge.
        @param  _data Cross chain Data recived from relayer
    **/
    function executeProposal(bytes calldata _data) external onlyRole(BRIDGE_ROLE) returns (bool) {
        DepositRecord memory depositData = decodeData(_data);
        require(
            _executeRecords[depositData._srcChainID][depositData._nonce].isExecuted == false,
            "Router Generichandler : Deposit record already handled"
        );
        if (!depositData._destAddress.isContract()) {
            _executeRecords[depositData._srcChainID][depositData._nonce]._callback = "";
            _executeRecords[depositData._srcChainID][depositData._nonce]._status = false;
            _executeRecords[depositData._srcChainID][depositData._nonce].isExecuted = true;
            return true;
        }
        (bool success, bytes memory callback) = depositData._destAddress.call(
            abi.encodeWithSelector(
                0xaa15f41d, // routerSync(uint8,address,bytes4,bytes,bytes32)
                depositData._srcChainID,
                depositData._srcAddress,
                depositData._selector,
                depositData.data,
                depositData.hash
            )
        );
        _executeRecords[depositData._srcChainID][depositData._nonce]._callback = callback;
        _executeRecords[depositData._srcChainID][depositData._nonce]._status = success;
        _executeRecords[depositData._srcChainID][depositData._nonce].isExecuted = true;
        return true;
    }

    /**
        @notice Function Decodes the data element recived from bridge.
        @param  _data Cross chain Data recived from relayer
    **/
    function decodeData(bytes calldata _data) internal pure returns (DepositRecord memory) {
        DepositRecord memory depositData;
        (
            depositData._srcChainID,
            depositData._nonce,
            depositData._srcAddress,
            depositData._destAddress,
            depositData._selector,
            depositData.data,
            depositData.hash,
            depositData._gas
        ) = abi.decode(_data, (uint8, uint64, address, address, bytes4, bytes, bytes32, uint256));
        return depositData;
    }

    // ----------------------------------------------------------------- //
    //                        Execute Section Ends                       //
    // ----------------------------------------------------------------- //

    // ----------------------------------------------------------------- //
    //                    Fee Manager Section Starts                     //
    // ----------------------------------------------------------------- //

    /**
        @notice Function Fetches the fee manager address.
    **/
    function fetchFeeManager() external view returns (address) {
        return address(feeManager);
    }

    /**
        @notice Function Sets the fee manager address.
        @param _feeManager Address of the fee manager.
    **/
    function setFeeManager(address _feeManager) public onlyRole(DEFAULT_ADMIN_ROLE) {
        feeManager = iFeeManagerGeneric(_feeManager);
    }

    /**
        @notice Function Fetches the default Gas for a chain ID .
    **/
    function fetchDefaultGas(uint8 _chainID) external view returns (uint256) {
        return defaultGas[_chainID];
    }

    /**
        @notice Function Sets default gas fees for chain.
        @param _chainID ChainID of the .
        @param _defaultGas Default gas for a chainid.
    **/
    function setDefaultGas(uint8 _chainID, uint256 _defaultGas) public onlyRole(DEFAULT_ADMIN_ROLE) {
        defaultGas[_chainID] = _defaultGas;
    }

    /**
        @notice Function Sets the fee for a fee token on to feemanager.
        @param destinationChainID ID of the destination chain.
        @param feeTokenAddress Address of fee token.
        @param feeFactor FeeFactor for the cross chain call.
        @param bridgeFee Base Fee for bridge.
        @param accepted Bool value for enabling and disabling feetoken.
    **/
    function setFees(
        uint8 destinationChainID,
        address feeTokenAddress,
        uint256 feeFactor,
        uint256 bridgeFee,
        bool accepted
    ) external onlyRole(FEE_SETTER_ROLE) {
        feeManager.setFee(destinationChainID, feeTokenAddress, feeFactor, bridgeFee, accepted);
    }

    /**
        @notice Calculates fees for a cross chain Call.
        @param destinationChainID id of the destination chain.
        @param feeTokenAddress Address fee token.
        @param gas Gas required for cross chain call.
    **/
    function calculateFees(
        uint8 destinationChainID,
        address feeTokenAddress,
        uint256 gas
    ) external view returns (uint256) {
        uint256 _defaultGas = defaultGas[destinationChainID];
        require(_defaultGas != 0, "Router Generichandler : Destination Gas Not Set");
        (uint256 feeFactor, uint256 bridgeFees) = feeManager.getFee(destinationChainID, feeTokenAddress);
        uint256 _gas = gas < _defaultGas ? _defaultGas : gas;
        return (feeFactor * _gas) + bridgeFees;
    }

    /**
        @notice Function deducts fees for a cross chain Call.
        @param destinationChainID id of the destination chain.
        @param feeTokenAddress Address fee token.
        @param gas Gas required for cross chain call.
    **/
    function deductFee(
        uint8 destinationChainID,
        address feeTokenAddress,
        uint256 gas
    ) internal {
        (uint256 feeFactor, uint256 bridgeFees) = feeManager.getFee(destinationChainID, feeTokenAddress);
        IERC20Upgradeable token = IERC20Upgradeable(feeTokenAddress);
        uint256 fee = ((feeFactor * gas) + bridgeFees);
        token.safeTransferFrom(msg.sender, address(feeManager), fee);
    }

    /**
        @notice Used to manually release ERC20 tokens from FeeManager.
        @param tokenAddress Address of token contract to release.
        @param recipient Address to release tokens to.
        @param amount The amount of ERC20 tokens to release.
    **/
    function withdrawFees(
        address tokenAddress,
        address recipient,
        uint256 amount
    ) external virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        feeManager.withdrawFee(tokenAddress, recipient, amount);
    }

    function setBridge(address _bridge) external onlyRole(DEFAULT_ADMIN_ROLE) {
        bridge = iGBridge(_bridge);
    }

    // ----------------------------------------------------------------- //
    //                    Fee Manager Section Ends                       //
    // ----------------------------------------------------------------- //
}
