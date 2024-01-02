// SPDX-License-Identifier: BSD-3-Clause

pragma solidity 0.8.13;

import "./AccessControlledV8.sol";
import "./validators.sol";
import "./IXVSProxyOFT.sol";

/**
 * @title XVSBridgeAdmin
 * @author Venus
 * @notice The XVSBridgeAdmin contract extends a parent contract AccessControlledV8 for access control, and it manages an external contract called XVSProxyOFT.
 * It maintains a registry of function signatures and names,
 * allowing for dynamic function handling i.e checking of access control of interaction with only owner functions.
 */
contract XVSBridgeAdmin is AccessControlledV8 {
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    IXVSProxyOFT public immutable XVSBridge;
    /**
     * @notice A mapping keeps track of function signature associated with function name string.
     */
    mapping(bytes4 => string) public functionRegistry;

    /**
     * @notice emitted when function registry updated
     */
    event FunctionRegistryChanged(string signature, bool active);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address XVSBridge_) {
        ensureNonzeroAddress(XVSBridge_);
        XVSBridge = IXVSProxyOFT(XVSBridge_);
        _disableInitializers();
    }

    /**
     * @param accessControlManager_ Address of access control manager contract.
     */
    function initialize(address accessControlManager_) external initializer {
        __AccessControlled_init(accessControlManager_);
    }

    /**
     * @notice Invoked when called function does not exist in the contract.
     * @return Response of low level call.
     * @custom:access Controlled by AccessControlManager.
     */
    fallback(bytes calldata data) external returns (bytes memory) {
        string memory fun = _getFunctionName(msg.sig);
        require(bytes(fun).length != 0, "Function not found");
        _checkAccessAllowed(fun);
        (bool ok, bytes memory res) = address(XVSBridge).call(data);
        require(ok, "call failed");
        return res;
    }

    /**
     * @notice Sets trusted remote on particular chain.
     * @param remoteChainId_ Chain Id of the destination chain.
     * @param remoteAddress_ Address of the destination bridge.
     * @custom:access Controlled by AccessControlManager.
     * @custom:error ZeroAddressNotAllowed is thrown when remoteAddress_ contract address is zero.
     */
    function setTrustedRemoteAddress(uint16 remoteChainId_, bytes calldata remoteAddress_) external {
        _checkAccessAllowed("setTrustedRemoteAddress(uint16,bytes)");
        require(remoteChainId_ != 0, "ChainId must not be zero");
        ensureNonzeroAddress(bytesToAddress(remoteAddress_));
        XVSBridge.setTrustedRemoteAddress(remoteChainId_, remoteAddress_);
    }

    /**
     * @notice A setter for the registry of functions that are allowed to be executed from proposals.
     * @param signatures_  Function signature to be added or removed.
     * @param active_ bool value, should be true to add function.
     * @custom:access Only owner.
     * @custom:event Emits FunctionRegistryChanged if bool value of function changes.
     */
    function upsertSignature(string[] calldata signatures_, bool[] calldata active_) external onlyOwner {
        uint256 signatureLength = signatures_.length;
        require(signatureLength == active_.length, "Input arrays must have the same length");
        for (uint256 i; i < signatureLength; ) {
            bytes4 sigHash = bytes4(keccak256(bytes(signatures_[i])));
            bytes memory signature = bytes(functionRegistry[sigHash]);
            if (active_[i] && signature.length == 0) {
                functionRegistry[sigHash] = signatures_[i];
                emit FunctionRegistryChanged(signatures_[i], true);
            } else if (!active_[i] && signature.length != 0) {
                delete functionRegistry[sigHash];
                emit FunctionRegistryChanged(signatures_[i], false);
            }
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice This function transfers the ownership of the bridge from this contract to new owner.
     * @param newOwner_ New owner of the XVS Bridge.
     * @custom:access Controlled by AccessControlManager.
     */
    function transferBridgeOwnership(address newOwner_) external {
        _checkAccessAllowed("transferBridgeOwnership(address)");
        XVSBridge.transferOwnership(newOwner_);
    }

    /**
     * @notice Returns true if remote address is trustedRemote corresponds to chainId_.
     * @param remoteChainId_ Chain Id of the destination chain.
     * @param remoteAddress_ Address of the destination bridge.
     * @custom:error ZeroAddressNotAllowed is thrown when remoteAddress_ contract address is zero.
     * @return Bool indicating whether the remote chain is trusted or not.
     */
    function isTrustedRemote(uint16 remoteChainId_, bytes calldata remoteAddress_) external returns (bool) {
        require(remoteChainId_ != 0, "ChainId must not be zero");
        ensureNonzeroAddress(bytesToAddress(remoteAddress_));
        return XVSBridge.isTrustedRemote(remoteChainId_, remoteAddress_);
    }

    /**
     * @notice Empty implementation of renounce ownership to avoid any mishappening.
     */
    function renounceOwnership() public override {}

    /**
     * @dev Returns function name string associated with function signature.
     * @param signature_ Four bytes of function signature.
     * @return Function signature corresponding to its hash.
     */
    function _getFunctionName(bytes4 signature_) internal view returns (string memory) {
        return functionRegistry[signature_];
    }

    /**
     * @notice Converts given bytes into address.
     * @param b Bytes to be converted into address.
     * @return Converted address of given bytes.
     */
    function bytesToAddress(bytes calldata b) private pure returns (address) {
        return address(uint160(bytes20(b)));
    }
}
