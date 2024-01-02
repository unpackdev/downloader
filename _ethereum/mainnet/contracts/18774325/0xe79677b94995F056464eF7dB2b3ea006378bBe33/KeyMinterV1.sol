// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./UUPSUpgradeable.sol";
import "./Initializable.sol";
import "./AccessControlUpgradeable.sol";
import "./EIP712Upgradeable.sol";
import "./IERC721.sol";
import "./IERC6551Account.sol";
import "./IERC6551Registry.sol";
import "./ISpaceshipUniverse1.sol";
import "./IKeyUniverse1.sol";
import "./Error.sol";

/// @title KeyMinterV1
/// @dev KeyMinterV1 is a contract for minting Keys and collecting contributions.
contract KeyMinterV1 is
    Initializable,
    UUPSUpgradeable,
    AccessControlUpgradeable,
    EIP712Upgradeable,
    Error
{
    /* ============ Variables ============ */
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    bytes32 public constant KEY_MINT_PARAMS_TYPEHASH =
        keccak256(
            "KeyMintParams(address profileContractAddress,uint256 profileTokenId,uint256 spaceshipTokenId,uint256 keyTokenId,uint256 contribution)"
        );
    bytes32 public constant KEY_BATCH_MINT_PARAMS_TYPEHASH =
        keccak256(
            "KeyBatchMintParams(address profileContractAddress,uint256 profileTokenId,uint256 spaceshipTokenId,uint256[] keyTokenIds,uint256 contribution)"
        );

    address payable public vault;
    address public serviceAdmin;
    IKeyUniverse1 public keyUniverse1;
    ISpaceshipUniverse1 public spaceshipUniverse1;
    IERC6551Account public tokenBoundImplementation;
    IERC6551Registry public tokenBoundRegistry;

    uint128[] public maxContributionSchedulePerMint;
    uint128 public maxContributionPerUser;
    uint256 public maxTotalContribution;
    uint256 public currentTotalContribution;
    bool public isRefundEnabled;

    mapping(address => User) private _userStatus;

    struct User {
        uint128 contribution;
        uint128 mintCount;
    }

    struct KeyMintParams {
        address profileContractAddress;
        uint256 profileTokenId;
        uint256 spaceshipTokenId;
        uint256 keyTokenId;
        uint256 contribution;
    }

    struct KeyBatchMintParams {
        address profileContractAddress;
        uint256 profileTokenId;
        uint256 spaceshipTokenId;
        uint256[] keyTokenIds;
        uint256 contribution;
    }

    /* ============ Events ============ */

    event SetVault(address vault);
    event SetMaxContributionSchedulePerMint(
        uint128[] maxContributionSchedulePerMint
    );
    event SetMaxContributionPerUser(uint128 maxContributionPerUser);
    event SetMaxTotalContribution(uint256 maxTotalContribution);
    event SetIsRefundEnabled(bool isRefundEnabled);
    event SetServiceAdmin(address serviceAdmin);
    event Refund(address indexed user, uint256 amount);
    event SetTokenBoundImplementation(address contractAddress);
    event SetTokenBoundRegistry(address contractAddress);

    /* ============ Constructor ============ */

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address payable _vault,
        address defaultAdmin,
        address operator,
        address _serviceAdmin,
        ISpaceshipUniverse1 _spaceshipUniverse1,
        IKeyUniverse1 _keyUniverse1,
        IERC6551Registry _tokenBoundRegistry,
        IERC6551Account _tokenBoundImplementation
    ) public initializer {
        __EIP712_init("KeyMinterUniverse1", "1");
        vault = _vault;
        keyUniverse1 = _keyUniverse1;
        _grantRole(DEFAULT_ADMIN_ROLE, defaultAdmin);
        _grantRole(OPERATOR_ROLE, operator);
        serviceAdmin = _serviceAdmin;
        tokenBoundRegistry = (_tokenBoundRegistry);
        tokenBoundImplementation = (_tokenBoundImplementation);
        spaceshipUniverse1 = _spaceshipUniverse1;
        maxContributionSchedulePerMint = [10 ether];
        maxContributionPerUser = 1000 ether;
        maxTotalContribution = 1000000 ether;

        emit SetMaxContributionPerUser(maxContributionPerUser);
        emit SetMaxContributionPerUser(maxContributionPerUser);
        emit SetMaxTotalContribution(maxTotalContribution);
        emit SetVault(_vault);
        emit SetServiceAdmin(_serviceAdmin);
        emit SetTokenBoundImplementation(address(_tokenBoundImplementation));
        emit SetTokenBoundRegistry(address(_tokenBoundRegistry));
    }

    /* ============ Modifiers ============ */

    modifier notDuringRefundPeriod() {
        if (isRefundEnabled && msg.value > 0) {
            revert NotDuringRefundPeriod();
        }
        _;
    }

    modifier onlyDuringRefundPeriod() {
        if (!isRefundEnabled) {
            revert OnlyDuringRefundPeriod();
        }
        _;
    }

    modifier sendFundToVault() {
        _;
        if (address(this).balance > 0) {
            (bool success, ) = vault.call{
                value: address(this).balance,
                // it takes about 6300 gas to send eth to gnosis safe(without using access lists)
                gas: 8000 
            }("");
            require(success, "failed to send ether to vault");
        }
    }

    /* ============ Operator Functions ============ */

    function setMaxContributionSchedulePerMint(
        uint128[] memory _maxContributionSchedulePerMint
    ) external onlyRole(OPERATOR_ROLE) {
        maxContributionSchedulePerMint = _maxContributionSchedulePerMint;
        emit SetMaxContributionSchedulePerMint(_maxContributionSchedulePerMint);
    }

    function setMaxContributionPerUser(
        uint128 _maxContributionPerUser
    ) external onlyRole(OPERATOR_ROLE) {
        maxContributionPerUser = _maxContributionPerUser;
        emit SetMaxContributionPerUser(_maxContributionPerUser);
    }

    function setMaxTotalContribution(
        uint256 _maxTotalContribution
    ) external onlyRole(OPERATOR_ROLE) {
        maxTotalContribution = _maxTotalContribution;
        emit SetMaxTotalContribution(_maxTotalContribution);
    }

    function setServiceAdmin(
        address _serviceAdmin
    ) external onlyRole(OPERATOR_ROLE) {
        serviceAdmin = _serviceAdmin;
        emit SetServiceAdmin(_serviceAdmin);
    }

    /* ============ Admin Functions ============ */

    function setVault(
        address payable _vault
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        vault = _vault;
        emit SetVault(_vault);
    }

    function setIsRefundEnabled(
        bool _isRefundEnabled
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        isRefundEnabled = _isRefundEnabled;
        emit SetIsRefundEnabled(_isRefundEnabled);
    }

    function setTokenBoundImplementation(
        IERC6551Account contractAddress
    ) external virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        if (address(contractAddress) == address(0)) revert InvalidAddress();
        tokenBoundImplementation = contractAddress;
        emit SetTokenBoundImplementation(address(contractAddress));
    }

    function setTokenBoundRegistry(
        IERC6551Registry contractAddress
    ) external virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        if (address(contractAddress) == address(0)) revert InvalidAddress();
        tokenBoundRegistry = contractAddress;
        emit SetTokenBoundRegistry(address(contractAddress));
    }

    /* ============ External Functions ============ */

    function mintKey(
        address profileContractAddress,
        uint256 profileTokenId,
        uint256 spaceshipTokenId,
        uint256 keyTokenId,
        bytes memory signature
    ) external payable virtual notDuringRefundPeriod sendFundToVault {
        address signer = getSigner(
            KeyMintParams(
                profileContractAddress,
                profileTokenId,
                spaceshipTokenId,
                keyTokenId,
                msg.value
            ),
            signature
        );

        if (signer != serviceAdmin) {
            revert InvalidSignature();
        }

        _checkNFTOwnership(profileContractAddress, profileTokenId);

        address nftTBA = tokenBoundRegistry.account(
            address(tokenBoundImplementation),
            block.chainid,
            profileContractAddress,
            profileTokenId,
            0
        );

        if (spaceshipUniverse1.ownerOf(spaceshipTokenId) != nftTBA) {
            revert OnlySpaceshipOwner();
        }

        User storage user = _userStatus[msg.sender];
        if (msg.value > _getMaxContributionPerMint(user.mintCount)) {
            revert ExceedMaxContributionPerMint();
        }
        user.contribution += uint128(msg.value);
        user.mintCount += 1;
        currentTotalContribution += msg.value;

        if (user.contribution > maxContributionPerUser) {
            revert ExceedMaxContributionPerUser();
        }
        if (currentTotalContribution > maxTotalContribution) {
            revert ExceedMaxTotalContribution();
        }

        address spaceshipTBA = tokenBoundRegistry.account(
            address(tokenBoundImplementation),
            block.chainid,
            address(spaceshipUniverse1),
            spaceshipTokenId,
            0
        );

        keyUniverse1.mint(spaceshipTBA, keyTokenId);
    }

    function batchMintKey(
        address profileContractAddress,
        uint256 profileTokenId,
        uint256 spaceshipTokenId,
        uint256[] memory keyTokenIds,
        bytes memory signature
    ) external payable virtual notDuringRefundPeriod sendFundToVault {
        address signer = getSigner(
            KeyBatchMintParams(
                profileContractAddress,
                profileTokenId,
                spaceshipTokenId,
                keyTokenIds,
                msg.value
            ),
            signature
        );

        if (signer != serviceAdmin) {
            revert InvalidSignature();
        }

        _checkNFTOwnership(profileContractAddress, profileTokenId);

        address nftTBA = tokenBoundRegistry.account(
            address(tokenBoundImplementation),
            block.chainid,
            profileContractAddress,
            profileTokenId,
            0
        );

        if (spaceshipUniverse1.ownerOf(spaceshipTokenId) != nftTBA) {
            revert OnlySpaceshipOwner();
        }

        uint256 keyTokenIdsLength = keyTokenIds.length;
        User storage user = _userStatus[msg.sender];
        if (
            msg.value >
            _getMaxContributionPerBatchMint(user.mintCount, keyTokenIdsLength)
        ) {
            revert ExceedMaxContributionPerMint();
        }

        user.contribution += uint128(msg.value);
        user.mintCount += uint128(keyTokenIdsLength);
        currentTotalContribution += msg.value;

        if (user.contribution > maxContributionPerUser) {
            revert ExceedMaxContributionPerUser();
        }
        if (currentTotalContribution > maxTotalContribution) {
            revert ExceedMaxTotalContribution();
        }

        address spaceshipTBA = tokenBoundRegistry.account(
            address(tokenBoundImplementation),
            block.chainid,
            address(spaceshipUniverse1),
            spaceshipTokenId,
            0
        );

        for (uint256 i = 0; i < keyTokenIdsLength; i++) {
            keyUniverse1.mint(spaceshipTBA, keyTokenIds[i]);
        }
    }

    /* ============ Emergency Functions ============ */

    receive() external payable virtual onlyDuringRefundPeriod {}

    function refund() external virtual onlyDuringRefundPeriod {
        User storage user = _userStatus[msg.sender];
        payable(msg.sender).transfer(user.contribution);
        emit Refund(msg.sender, user.contribution);
        user.contribution = 0;
    }

    /* ============ Internal Functions ============ */

    function _getMaxContributionPerMint(
        uint256 currentMintCount
    ) internal view virtual returns (uint128) {
        if (maxContributionSchedulePerMint.length == 0) {
            return type(uint128).max;
        }

        if (currentMintCount >= maxContributionSchedulePerMint.length) {
            return
                maxContributionSchedulePerMint[
                    maxContributionSchedulePerMint.length - 1
                ];
        }

        return maxContributionSchedulePerMint[currentMintCount];
    }

    function _getMaxContributionPerBatchMint(
        uint256 currentMintCount,
        uint256 amount
    ) internal view virtual returns (uint128) {
        if (maxContributionSchedulePerMint.length == 0) {
            return type(uint128).max;
        }

        uint128 maxContribution = 0;

        for (uint256 i = currentMintCount; i < currentMintCount + amount; i++) {
            if (i >= maxContributionSchedulePerMint.length) {
                maxContribution += maxContributionSchedulePerMint[
                    maxContributionSchedulePerMint.length - 1
                ];
            } else {
                maxContribution += maxContributionSchedulePerMint[i];
            }
        }

        return maxContribution;
    }

    function _checkNFTOwnership(
        address profileContractAddress,
        uint256 profileTokenId
    ) internal virtual {
        if (
            IERC721(profileContractAddress).ownerOf(profileTokenId) !=
            msg.sender
        ) {
            revert OnlyNFTOwner();
        }
    }

    function _authorizeUpgrade(
        address
    ) internal virtual override onlyRole(DEFAULT_ADMIN_ROLE) {}

    /* ============ View Functions ============ */

    function DOMAIN_SEPARATOR() external view virtual returns (bytes32) {
        return _domainSeparatorV4();
    }

    function getUserContribution(
        address user
    ) external view virtual returns (uint128) {
        return _userStatus[user].contribution;
    }

    function getUserMintCount(
        address user
    ) external view virtual returns (uint128) {
        return _userStatus[user].mintCount;
    }

    function getSigner(
        KeyMintParams memory keyMintParams,
        bytes memory signature
    ) public view virtual returns (address) {
        bytes32 structHash = keccak256(
            abi.encode(
                KEY_MINT_PARAMS_TYPEHASH,
                keyMintParams.profileContractAddress,
                keyMintParams.profileTokenId,
                keyMintParams.spaceshipTokenId,
                keyMintParams.keyTokenId,
                keyMintParams.contribution
            )
        );
        bytes32 digest = _hashTypedDataV4(structHash);

        (address signer, ) = ECDSAUpgradeable.tryRecover(digest, signature);
        return signer;
    }

    function getSigner(
        KeyBatchMintParams memory keyBatchMintParams,
        bytes memory signature
    ) public view virtual returns (address) {
        bytes32 structHash = keccak256(
            abi.encode(
                KEY_BATCH_MINT_PARAMS_TYPEHASH,
                keyBatchMintParams.profileContractAddress,
                keyBatchMintParams.profileTokenId,
                keyBatchMintParams.spaceshipTokenId,
                keccak256(abi.encodePacked(keyBatchMintParams.keyTokenIds)),
                keyBatchMintParams.contribution
            )
        );
        bytes32 digest = _hashTypedDataV4(structHash);

        (address signer, ) = ECDSAUpgradeable.tryRecover(digest, signature);
        return signer;
    }
}
