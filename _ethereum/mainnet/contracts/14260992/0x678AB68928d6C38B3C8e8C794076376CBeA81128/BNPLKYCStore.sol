// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Initializable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./ECDSAUpgradeable.sol";

/// @title BNPL KYC store contract.
///
/// @notice
/// - Features:
///   **Create and store KYC status**
///   **Create a KYC bank node**
///   **Change the KYC mode**
///   **Check the KYC status**
///   **Approve or reject the applicant**
///
/// @author BNPL
contract BNPLKYCStore is Initializable, ReentrancyGuardUpgradeable {
    using ECDSAUpgradeable for bytes32;

    /// @dev [Domain id] => [KYC public key]
    mapping(uint32 => address) public publicKeys;

    /// @dev [encode(Domain, User)] => [Permissions]
    mapping(uint256 => uint32) public domainPermissions;

    /// @dev [encode(Domain, User)] => [KYC status]
    mapping(uint256 => uint32) public userKycStatuses;

    /// @dev [Proof hash] => [Use status]
    mapping(bytes32 => uint8) public proofUsed;

    /// @dev [Domain id] => [KYC mode]
    mapping(uint32 => uint256) public domainKycMode;

    uint32 public constant PROOF_MAGIC = 0xfc203827;
    uint32 public constant DOMAIN_ADMIN_PERM = 0xffff;

    /// @notice The current number of domains in the KYC store
    uint32 public domainCount;

    /// @dev Encode KYC domain and user address into a uint256
    ///
    /// @param domain The domain id
    /// @param user The address of user
    /// @return KYCUserDomainKey Encoded user domain key
    function encodeKYCUserDomainKey(uint32 domain, address user) internal pure returns (uint256) {
        return (uint256(uint160(user)) << 32) | uint256(domain);
    }

    /// @dev Can only be operated by domain admin
    modifier onlyDomainAdmin(uint32 domain) {
        require(
            domainPermissions[encodeKYCUserDomainKey(domain, msg.sender)] == DOMAIN_ADMIN_PERM,
            "User must be an admin for this domain to perform this action"
        );
        _;
    }

    /// @notice Get domain permissions with domain id and user address
    ///
    /// @param domain The domain id
    /// @param user The address of user
    /// @return DomainPermissions User's domain permissions
    function getDomainPermissions(uint32 domain, address user) external view returns (uint32) {
        return domainPermissions[encodeKYCUserDomainKey(domain, user)];
    }

    /// @dev Set domain permissions with domain id and user address
    function _setDomainPermissions(
        uint32 domain,
        address user,
        uint32 permissions
    ) internal {
        domainPermissions[encodeKYCUserDomainKey(domain, user)] = permissions;
    }

    /// @notice Get user's kyc status under domain
    ///
    /// @param domain The domain id
    /// @param user The address of user
    /// @return KYCStatusUser User's KYC status
    function getKYCStatusUser(uint32 domain, address user) public view returns (uint32) {
        return userKycStatuses[encodeKYCUserDomainKey(domain, user)];
    }

    /// @dev Verify that the operation and signature are valid
    function _verifyProof(
        uint32 domain,
        address user,
        uint32 status,
        uint256 nonce,
        bytes calldata signature
    ) internal {
        require(domain != 0 && domain <= domainCount, "invalid domain");
        require(publicKeys[domain] != address(0), "this domain is disabled");
        bytes32 proofHash = getKYCSignatureHash(domain, user, status, nonce);
        require(proofHash.toEthSignedMessageHash().recover(signature) == publicKeys[domain], "invalid signature");
        require(proofUsed[proofHash] == 0, "proof already used");
        proofUsed[proofHash] = 1;
    }

    /// @dev Set KYC status for user
    function _setKYCStatusUser(
        uint32 domain,
        address user,
        uint32 status
    ) internal {
        userKycStatuses[encodeKYCUserDomainKey(domain, user)] = status;
    }

    /// @dev Bitwise OR the user's KYC status
    function _orKYCStatusUser(
        uint32 domain,
        address user,
        uint32 status
    ) internal {
        userKycStatuses[encodeKYCUserDomainKey(domain, user)] |= status;
    }

    /// @notice Create a new KYC store domain
    ///
    /// @param admin The address of domain admin
    /// @param publicKey The KYC domain publicKey
    /// @param kycMode The KYC mode
    /// @return DomainId The new KYC domain id
    function createNewKYCDomain(
        address admin,
        address publicKey,
        uint256 kycMode
    ) external returns (uint32) {
        require(admin != address(0), "cannot create a kyc domain with an empty user");
        uint32 id = domainCount + 1;
        domainCount = id;
        _setDomainPermissions(id, admin, DOMAIN_ADMIN_PERM);
        publicKeys[id] = publicKey;
        domainKycMode[id] = kycMode;
        return id;
    }

    /// @notice Set KYC domain public key for domain
    ///
    /// - PRIVILEGES REQUIRED:
    ///     Domain admin
    ///
    /// @param domain The KYC domain id
    /// @param newPublicKey New KYC domain publickey
    function setKYCDomainPublicKey(uint32 domain, address newPublicKey) external onlyDomainAdmin(domain) {
        publicKeys[domain] = newPublicKey;
    }

    /// @notice Set KYC mode for domain
    ///
    /// - PRIVILEGES REQUIRED:
    ///     Domain admin
    ///
    /// @param domain The KYC domain id
    /// @param mode The KYC mode
    function setKYCDomainMode(uint32 domain, uint256 mode) external onlyDomainAdmin(domain) {
        domainKycMode[domain] = mode;
    }

    /// @notice Check the KYC mode of the user under the specified domain
    ///
    /// @param domain The KYC domain id
    /// @param user The address of user
    /// @param mode The KYC mode
    /// @return result Return `1` if valid
    function checkUserBasicBitwiseMode(
        uint32 domain,
        address user,
        uint256 mode
    ) external view returns (uint256) {
        require(domain != 0 && domain <= domainCount, "invalid domain");
        require(
            user != address(0) && ((domainKycMode[domain] & mode) == 0 || (mode & getKYCStatusUser(domain, user) != 0)),
            "invalid user permissions"
        );
        return 1;
    }

    /// @notice Allow domain admin to set KYC status for user
    ///
    /// - PRIVILEGES REQUIRED:
    ///     Domain admin
    ///
    /// @param domain The KYC domain id
    /// @param user The address of user
    /// @param status The status number
    function setKYCStatusUser(
        uint32 domain,
        address user,
        uint32 status
    ) external onlyDomainAdmin(domain) {
        _setKYCStatusUser(domain, user, status);
    }

    /// @notice Returns KYC signature (encoded data)
    ///
    /// @param domain The KYC domain id
    /// @param user The address of user
    /// @param status The status number
    /// @param nonce The nonce
    /// @return KYCSignaturePayload The KYC signature (encoded data)
    function getKYCSignaturePayload(
        uint32 domain,
        address user,
        uint32 status,
        uint256 nonce
    ) public pure returns (bytes memory) {
        return (
            abi.encode(
                ((uint256(PROOF_MAGIC) << 224) |
                    (uint256(uint160(user)) << 64) |
                    (uint256(domain) << 32) |
                    uint256(status)),
                nonce
            )
        );
    }

    /// @notice Returns KYC signature (keccak256 hash)
    ///
    /// @param domain The KYC domain id
    /// @param user The address of user
    /// @param status The status number
    /// @param nonce The nonce
    /// @return KYCSignatureHash The KYC signature (keccak256 hash)
    function getKYCSignatureHash(
        uint32 domain,
        address user,
        uint32 status,
        uint256 nonce
    ) public pure returns (bytes32) {
        return keccak256(getKYCSignaturePayload(domain, user, status, nonce));
    }

    /// @notice Bitwise OR the user's KYC status
    ///
    /// - SIGNATURE REQUIRED:
    ///     Domain admin
    ///
    /// @param domain The KYC domain id
    /// @param user The address of user
    /// @param status The status number to bitwise OR
    /// @param nonce The nonce
    /// @param signature The domain admin signature (proof)
    function orKYCStatusWithProof(
        uint32 domain,
        address user,
        uint32 status,
        uint256 nonce,
        bytes calldata signature
    ) external {
        _verifyProof(domain, user, status, nonce, signature);
        _orKYCStatusUser(domain, user, status);
    }

    /// @notice Clear KYC status for user
    ///
    /// - SIGNATURE REQUIRED:
    ///     Domain admin
    ///
    /// @param domain The KYC domain id
    /// @param user The address of user
    /// @param nonce The nonce
    /// @param signature The domain admin signature (proof)
    function clearKYCStatusWithProof(
        uint32 domain,
        address user,
        uint256 nonce,
        bytes calldata signature
    ) external {
        _verifyProof(domain, user, 1, nonce, signature);
        _setKYCStatusUser(domain, user, 1);
    }

    /// @dev This contract is called through the proxy.
    function initialize() external initializer nonReentrant {
        __ReentrancyGuard_init_unchained();
    }
}
