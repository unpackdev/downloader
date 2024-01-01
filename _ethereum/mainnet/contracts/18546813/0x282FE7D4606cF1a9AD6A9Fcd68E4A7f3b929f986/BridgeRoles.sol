// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

// Import AccessControl from OpenZeppelin Contracts
import "./AccessControl.sol";

abstract contract BridgeRoles is AccessControl {
    bytes32 public constant SIGNER_ROLE = keccak256("SIGNER_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");
    bytes32 public constant REFUND_ROLE = keccak256("REFUND_ROLE");

    uint256 public signerCount = 0;

    /**
     * @dev Grant the admin role to the deployer and the signer role to the signers.
     * @param owner The address of the owner.
     * @param admin The address of the admin.
     * @param refundManager The address of the refund manager.
     * @param signers The addresses of the signers.
     */
    constructor(address owner, address admin, address refundManager, address[] memory signers) {
        _grantRole(OWNER_ROLE, owner);
        _grantRole(ADMIN_ROLE, admin);
        _grantRole(REFUND_ROLE, refundManager);

        for (uint256 i = 0; i < signers.length; i++) {
            _addSigner(signers[i]);
        }
    }

    modifier onlyOwner() {
        require(hasRole(OWNER_ROLE, msg.sender), "BridgeRoles: Caller is not the owner");
        _;
    }

    modifier onlyAdmin() {
        require(hasRole(ADMIN_ROLE, msg.sender), "BridgeRoles: Caller is not an admin");
        _;
    }

    modifier onlyRefundManager() {
        require(hasRole(REFUND_ROLE, msg.sender), "BridgeRoles: Caller is not a refund manager");
        _;
    }

    /**
     * @dev Add owner.
     * @param account The address of the owner.
     */
    function addOwner(address account) external onlyOwner {
        _grantRole(OWNER_ROLE, account);
    }

    /**
     * @dev Revoke owner.
     * @param account The address of the owner.
     */
    function revokeOwner(address account) external onlyOwner {
        require(account != msg.sender, "BridgeRoles: Cannot revoke self from owner");
        _revokeRole(OWNER_ROLE, account);
    }

    /**
     * @dev Add admin.
     * @param account The address of the admin.
     */
    function addAdmin(address account) external onlyOwner {
        _grantRole(ADMIN_ROLE, account);
    }

    /**
     * @dev Revoke admin.
     * @param account The address of the admin.
     */
    function revokeAdmin(address account) external onlyOwner {
        _revokeRole(ADMIN_ROLE, account);
    }

    /**
     * @dev Add refund manager.
     * @param account The address of the refund manager.
     */
    function addRefundManager(address account) external onlyOwner {
        _grantRole(REFUND_ROLE, account);
    }

    /**
     * @dev Revoke refund manager.
     * @param account The address of the refund manager.
     */
    function revokeRefundManager(address account) external onlyOwner {
        _revokeRole(REFUND_ROLE, account);
    }

    /**
     * @dev Add signers.
     * @param accounts The addresses of the signers.
     */
    function addSigners(address[] calldata accounts) external onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            _addSigner(accounts[i]);
        }
    }

    /**
     * @dev Revoke signers.
     * @param accounts The addresses of the signers.
     */
    function revokeSigners(address[] calldata accounts) external onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            _revokeSigner(accounts[i]);
        }
    }

    /**
     * @dev This function is overridden to prevent renouncing roles.
     * @inheritdoc AccessControl
     */
    function renounceRole(bytes32, address) public pure override {
        revert("BridgeRoles: Cannot renounce roles");
    }

    /**
     * @dev This function is overridden to prevent granting roles.
     * @inheritdoc AccessControl
     */
    function grantRole(bytes32, address) public pure override {
        revert("BridgeRoles: Cannot grant roles");
    }

    /**
     * @dev This function is overridden to prevent revoking roles.
     * @inheritdoc AccessControl
     */
    function revokeRole(bytes32, address) public pure override {
        revert("BridgeRoles: Cannot revoke roles");
    }

    /**
     * @dev Add signer and increment signer count.
     * @param account The address of the signer.
     */
    function _addSigner(address account) private {
        if (!hasSignerRole(account)) {
            _grantRole(SIGNER_ROLE, account);
            signerCount++;
        }
    }

    /**
     * @dev Revoke signer and decrement signer count.
     * @param account The address of the signer.
     */
    function _revokeSigner(address account) private {
        if (hasSignerRole(account)) {
            _revokeRole(SIGNER_ROLE, account);
            signerCount--;
        }
    }

    function hasSignerRole(address account) public view returns (bool) {
        return hasRole(SIGNER_ROLE, account);
    }
}
