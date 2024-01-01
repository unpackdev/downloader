// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "./Initializable.sol";
import "./AccessControlUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./Create2Upgradeable.sol";
import "./NFTProxy.sol";
import "./NFT.sol";
import "./INFTDeployer.sol";
import "./INFT.sol";
import "./INFTRegistry.sol";
import "./INFTOperator.sol";

contract NFTDeployer is
    INFTDeployer,
    Initializable,
    AccessControlUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable
{
    bytes32 public constant VERSION = "1.0.0";
    bytes32 public constant DEPLOYER_ROLE = keccak256("DEPLOYER_ROLE");

    address public proxyAdmin;
    INFTRegistry public nftRegistry;
    INFTOperator public nftOperator;

    event ProxyAdminSet(address indexed proxyAdmin);
    event NFTRegistrySet(address indexed nftRegistry);
    event NFTOperatorSet(address indexed nftOperator);
    event ProxyDeployed(address indexed proxy);
    event ImplementationDeployed(address indexed implementation);

    error ZeroProxyAdmin();
    error ZeroNFTRegistry();
    error ZeroNFTOperator();

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address proxyAdmin_, address nftRegistry_, address nftOperator_) external initializer {
        if (proxyAdmin_ == address(0)) {
            revert ZeroProxyAdmin();
        }
        proxyAdmin = proxyAdmin_;

        if (nftRegistry_ == address(0)) {
            revert ZeroNFTRegistry();
        }
        nftRegistry = INFTRegistry(nftRegistry_);

        if (nftOperator_ == address(0)) {
            revert ZeroNFTOperator();
        }
        nftOperator = INFTOperator(nftOperator_);

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function setProxyAdmin(address proxyAdmin_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (proxyAdmin_ == address(0)) {
            revert ZeroProxyAdmin();
        }

        proxyAdmin = proxyAdmin_;
        emit ProxyAdminSet(proxyAdmin_);
    }

    function setNFTRegistry(address nftRegistry_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (nftRegistry_ == address(0)) {
            revert ZeroNFTRegistry();
        }

        nftRegistry = INFTRegistry(nftRegistry_);
        emit NFTRegistrySet(nftRegistry_);
    }

    function setNFTOperator(address nftOperator_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (nftOperator_ == address(0)) {
            revert ZeroNFTOperator();
        }

        nftOperator = INFTOperator(nftOperator_);
        emit NFTOperatorSet(nftOperator_);
    }

    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    function deploy(
        uint256 collectionId,
        string memory name,
        string memory symbol
    ) external nonReentrant whenNotPaused onlyRole(DEPLOYER_ROLE) returns (address) {
        bytes32 salt = _generateSalt(collectionId, name, symbol);
        address nft = address(new NFT{ salt: salt }());
        emit ImplementationDeployed(nft);

        address nftProxy = address(new NFTProxy{ salt: salt }(nft, proxyAdmin));
        emit ProxyDeployed(nftProxy);

        INFT(nftProxy).initialize(name, symbol, nftRegistry, nftOperator);
        INFT(nftProxy).transferOwnership(msg.sender);

        return nftProxy;
    }

    function computeProxyAddress(
        uint256 collectionId,
        string memory name,
        string memory symbol
    ) external view returns (address) {
        // slither-disable-next-line too-many-digits
        bytes memory creationCode = type(NFTProxy).creationCode;
        address implementation = computeImplementationAddress(collectionId, name, symbol);
        bytes memory args = abi.encode(implementation, proxyAdmin);

        bytes32 salt = _generateSalt(collectionId, name, symbol);
        bytes32 bytecodeHash = keccak256(abi.encodePacked(creationCode, args));
        return Create2Upgradeable.computeAddress(salt, bytecodeHash);
    }

    function computeImplementationAddress(
        uint256 collectionId,
        string memory name,
        string memory symbol
    ) public view returns (address) {
        bytes32 salt = _generateSalt(collectionId, name, symbol);
        // slither-disable-next-line too-many-digits
        bytes memory creationCode = type(NFT).creationCode;
        bytes32 bytecodeHash = keccak256(abi.encodePacked(creationCode, bytes("")));
        return Create2Upgradeable.computeAddress(salt, bytecodeHash);
    }

    function _generateSalt(
        uint256 collectionId,
        string memory name,
        string memory symbol
    ) private pure returns (bytes32) {
        return keccak256(abi.encode(collectionId, name, symbol));
    }
}
