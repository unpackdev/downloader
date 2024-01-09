// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Initializable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./ECDSAUpgradeable.sol";

contract BNPLKYCStore is Initializable, ReentrancyGuardUpgradeable {
    using ECDSAUpgradeable for bytes32;

    mapping(uint32 => address) public publicKeys;
    mapping(uint256 => uint32) public domainPermissions;
    mapping(uint256 => uint32) public userKycStatuses;
    mapping(bytes32 => uint8) public proofUsed;
    mapping(uint32 => uint256) public domainKycMode;

    uint32 public constant PROOF_MAGIC = 0xfc203827;
    uint32 public constant DOMAIN_ADMIN_PERM = 0xffff;
    uint32 public domainCount;

    function encodeKYCUserDomainKey(uint32 domain, address user) internal pure returns (uint256) {
        return (uint256(uint160(user)) << 32) | uint256(domain);
    }

    modifier onlyDomainAdmin(uint32 domain) {
        require(
            domainPermissions[encodeKYCUserDomainKey(domain, msg.sender)] == DOMAIN_ADMIN_PERM,
            "User must be an admin for this domain to perform this action"
        );
        _;
    }

    function getDomainPermissions(uint32 domain, address user) external view returns (uint32) {
        return domainPermissions[encodeKYCUserDomainKey(domain, user)];
    }

    function _setDomainPermissions(
        uint32 domain,
        address user,
        uint32 permissions
    ) internal {
        domainPermissions[encodeKYCUserDomainKey(domain, user)] = permissions;
    }

    function getKYCStatusUser(uint32 domain, address user) public view returns (uint32) {
        return userKycStatuses[encodeKYCUserDomainKey(domain, user)];
    }

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

    function _setKYCStatusUser(
        uint32 domain,
        address user,
        uint32 status
    ) internal {
        userKycStatuses[encodeKYCUserDomainKey(domain, user)] = status;
    }

    function _orKYCStatusUser(
        uint32 domain,
        address user,
        uint32 status
    ) internal {
        userKycStatuses[encodeKYCUserDomainKey(domain, user)] |= status;
    }

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

    function setKYCDomainPublicKey(uint32 domain, address newPublicKey) external onlyDomainAdmin(domain) {
        publicKeys[domain] = newPublicKey;
    }

    function setKYCDomainMode(uint32 domain, uint256 mode) external onlyDomainAdmin(domain) {
        domainKycMode[domain] = mode;
    }

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

    function setKYCStatusUser(
        uint32 domain,
        address user,
        uint32 status
    ) external onlyDomainAdmin(domain) {
        _setKYCStatusUser(domain, user, status);
    }

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

    function getKYCSignatureHash(
        uint32 domain,
        address user,
        uint32 status,
        uint256 nonce
    ) public pure returns (bytes32) {
        return keccak256(getKYCSignaturePayload(domain, user, status, nonce));
    }

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

    function clearKYCStatusWithProof(
        uint32 domain,
        address user,
        uint256 nonce,
        bytes calldata signature
    ) external {
        _verifyProof(domain, user, 1, nonce, signature);
        _setKYCStatusUser(domain, user, 1);
    }

    function initialize() external initializer nonReentrant {
        __ReentrancyGuard_init_unchained();
    }
}
