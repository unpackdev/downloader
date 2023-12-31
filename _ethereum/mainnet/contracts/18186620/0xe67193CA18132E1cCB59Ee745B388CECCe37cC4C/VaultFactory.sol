// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./IVaultFactory.sol";
import "./IVaultDeployer.sol";
import "./IPaymentModule.sol";
import "./IVault.sol";
import "./IVaultKey.sol";
import "./Whitelist.sol";

contract VaultFactory is Whitelist, IVaultFactory {
    address public constant burnAddress = 0x000000000000000000000000000000000000dEaD;

    enum VaultStatus {
        Inactive,
        Locked,
        Unlocked
    }
    mapping(uint256 => address) public vaultByKey;
    mapping(address => VaultStatus) public vaultStatus;

    address public override paymentModule;
    address public vaultDeployer;
    uint256 public maxTokensPerVault;

    uint256 public vaultUnlockedLastBlock;
    uint256 public vaultCreatedLastBlock;
    uint256 public vaultExtendedLastBlock;
    uint256 public vaultBurnedLastBlock;

    event MaxTokensUpdated(uint256 indexed oldMax, uint256 indexed newMax);
    event PaymentModuleUpdated(address indexed oldModule, address indexed newModule);
    event VaultDeployerUpdated(address indexed oldDeployer, address indexed newDeployer);
    event VaultUnlocked(uint256 previousBlock, address indexed vault, uint256 timestamp, bool isCompletelyUnlocked);

    event VaultCreated(
        uint256 previousBlock,
        address indexed vault,
        uint256 key,
        address benefactor,
        address indexed beneficiary,
        address indexed referrer,
        uint256 unlockTimestamp,
        FungibleTokenDeposit[] fungibleTokenDeposits,
        NonFungibleTokenDeposit[] nonFungibleTokenDeposits,
        MultiTokenDeposit[] multiTokenDeposits,
        bool isVesting
    );

    event TokensBurned(
        uint256 indexed previousBlock,
        address indexed benefactor,
        address indexed referrer,
        FungibleTokenDeposit[] fungibleTokenDeposits,
        NonFungibleTokenDeposit[] nonFungibleTokenDeposits,
        MultiTokenDeposit[] multiTokenDeposits
    );

    event VaultLockExtended(uint256 indexed previousBlock, address indexed vault, uint256 oldUnlockTimestamp, uint256 newUnlockTimestamp);

    constructor(address _paymentModule, uint256 maxTokens) {
        paymentModule = _paymentModule;
        maxTokensPerVault = maxTokens;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function setMaxTokensPerVault(uint256 newMax) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 oldMax = maxTokensPerVault;
        maxTokensPerVault = newMax;
        emit MaxTokensUpdated(oldMax, newMax);
    }

    function createVault(
        address referrer,
        address beneficiary,
        uint256 unlockTimestamp,
        FungibleTokenDeposit[] memory fungibleTokenDeposits,
        NonFungibleTokenDeposit[] memory nonFungibleTokenDeposits,
        MultiTokenDeposit[] memory multiTokenDeposits,
        bool isVesting
    ) external payable override onlyWhitelisted(msg.sender) {
        _createVault(referrer, beneficiary, unlockTimestamp, fungibleTokenDeposits, nonFungibleTokenDeposits, multiTokenDeposits, isVesting, true);
    }

    function createVaultWithoutKey(
        address referrer,
        address beneficiary,
        uint256 unlockTimestamp,
        FungibleTokenDeposit[] memory fungibleTokenDeposits,
        NonFungibleTokenDeposit[] memory nonFungibleTokenDeposits,
        MultiTokenDeposit[] memory multiTokenDeposits,
        bool isVesting
    ) external payable override onlyWhitelisted(msg.sender) {
        _createVault(referrer, beneficiary, unlockTimestamp, fungibleTokenDeposits, nonFungibleTokenDeposits, multiTokenDeposits, isVesting, false);
    }

    function _createVault(
        address referrer,
        address beneficiary,
        uint256 unlockTimestamp,
        FungibleTokenDeposit[] memory fungibleTokenDeposits,
        NonFungibleTokenDeposit[] memory nonFungibleTokenDeposits,
        MultiTokenDeposit[] memory multiTokenDeposits,
        bool isVesting,
        bool shouldMintKey
    ) private {
        require(unlockTimestamp >= block.timestamp, "VaultFactory:createVault:UNLOCK_IN_PAST");
        require(
            fungibleTokenDeposits.length > 0 || nonFungibleTokenDeposits.length > 0 || multiTokenDeposits.length > 0,
            "VaultFactory:createVault:NO_DEPOSITS"
        );
        require(
            fungibleTokenDeposits.length + nonFungibleTokenDeposits.length + multiTokenDeposits.length < maxTokensPerVault,
            "VaultFactory:createVault:MAX_DEPOSITS_EXCEEDED"
        );
        require(msg.sender != referrer, "VaultFactory:createVault:SELF_REFERRAL");
        require(beneficiary != referrer, "VaultFactory:createVault:REFERRER_IS_BENEFICIARY");
        for (uint256 i = 0; i < fungibleTokenDeposits.length; i++) {
            require(fungibleTokenDeposits[i].amount > 0, "VaultFactory:createVault:ZERO_DEPOSIT");
        }
        for (uint256 i = 0; i < multiTokenDeposits.length; i++) {
            require(multiTokenDeposits[i].amount > 0, "VaultFactory:createVault:ZERO_DEPOSIT");
        }

        // Early definition of vault address variable to allow usage by the
        // conditional branches of this function.
        address vault;

        if (isVesting) {
            require(nonFungibleTokenDeposits.length == 0 && multiTokenDeposits.length == 0, "VaultFactory:createVault:ONLY_FUNGIBLE_VESTING");
            vault = IVaultDeployer(vaultDeployer).createVestingVault(shouldMintKey, beneficiary, unlockTimestamp, abi.encode(fungibleTokenDeposits));
        } else {
            vault = IVaultDeployer(vaultDeployer).createBatchVault(
                shouldMintKey,
                beneficiary,
                unlockTimestamp,
                abi.encode(fungibleTokenDeposits),
                abi.encode(nonFungibleTokenDeposits),
                abi.encode(multiTokenDeposits)
            );
        }

        IPaymentModule(paymentModule).processPayment{ value: msg.value }(
            IPaymentModule.ProcessPaymentParams({
                vault: vault,
                user: msg.sender,
                referrer: referrer,
                fungibleTokenDeposits: fungibleTokenDeposits,
                nonFungibleTokenDeposits: nonFungibleTokenDeposits,
                multiTokenDeposits: multiTokenDeposits,
                isVesting: isVesting
            })
        );

        uint256 keyId = IVault(vault).vaultKeyId();
        if (keyId != 0) {
            vaultByKey[keyId] = vault;
        }
        vaultStatus[vault] = VaultStatus.Locked;

        emit VaultCreated(
            vaultCreatedLastBlock,
            vault,
            keyId,
            msg.sender,
            beneficiary,
            referrer,
            unlockTimestamp,
            fungibleTokenDeposits,
            nonFungibleTokenDeposits,
            multiTokenDeposits,
            isVesting
        );
        vaultCreatedLastBlock = block.number;
    }

    function burn(
        address referrer,
        FungibleTokenDeposit[] memory fungibleTokenDeposits,
        NonFungibleTokenDeposit[] memory nonFungibleTokenDeposits,
        MultiTokenDeposit[] memory multiTokenDeposits
    ) external payable override onlyWhitelisted(msg.sender) {
        require(
            fungibleTokenDeposits.length > 0 || nonFungibleTokenDeposits.length > 0 || multiTokenDeposits.length > 0,
            "VaultFactory:createVault:NO_DEPOSITS"
        );
        require(
            fungibleTokenDeposits.length + nonFungibleTokenDeposits.length + multiTokenDeposits.length < maxTokensPerVault,
            "VaultFactory:createVault:MAX_DEPOSITS_EXCEEDED"
        );
        require(msg.sender != referrer, "VaultFactory:createVault:SELF_REFERRAL");
        for (uint256 i = 0; i < fungibleTokenDeposits.length; i++) {
            require(fungibleTokenDeposits[i].amount > 0, "VaultFactory:createVault:ZERO_DEPOSIT");
        }
        for (uint256 i = 0; i < multiTokenDeposits.length; i++) {
            require(multiTokenDeposits[i].amount > 0, "VaultFactory:createVault:ZERO_DEPOSIT");
        }

        IPaymentModule(paymentModule).processPayment{ value: msg.value }(
            IPaymentModule.ProcessPaymentParams({
                vault: burnAddress,
                user: msg.sender,
                referrer: referrer,
                fungibleTokenDeposits: fungibleTokenDeposits,
                nonFungibleTokenDeposits: nonFungibleTokenDeposits,
                multiTokenDeposits: multiTokenDeposits,
                isVesting: false
            })
        );

        emit TokensBurned(vaultBurnedLastBlock, msg.sender, referrer, fungibleTokenDeposits, nonFungibleTokenDeposits, multiTokenDeposits);
        vaultBurnedLastBlock = block.number;
    }

    function notifyUnlock(bool isCompletelyUnlocked) external override {
        require(vaultStatus[msg.sender] == VaultStatus.Locked, "VaultFactory:notifyUnlock:ALREADY_FULL_UNLOCKED");

        if (isCompletelyUnlocked) {
            vaultStatus[msg.sender] = VaultStatus.Unlocked;
        }

        emit VaultUnlocked(vaultUnlockedLastBlock, msg.sender, block.timestamp, isCompletelyUnlocked);
        vaultUnlockedLastBlock = block.number;
    }

    function updatePaymentModule(address newModule) external onlyRole(DEFAULT_ADMIN_ROLE) {
        address oldModule = paymentModule;
        paymentModule = newModule;

        emit PaymentModuleUpdated(oldModule, newModule);
    }

    function updateVaultDeployer(address newDeployer) external onlyRole(DEFAULT_ADMIN_ROLE) {
        address oldDeployer = vaultDeployer;
        vaultDeployer = newDeployer;
        emit VaultDeployerUpdated(oldDeployer, newDeployer);
    }

    function lockExtended(uint256 oldUnlockTimestamp, uint256 newUnlockTimestamp) external override {
        require(vaultStatus[msg.sender] == VaultStatus.Locked, "VaultFactory:lockExtended:ALREADY_FULL_UNLOCKED");
        emit VaultLockExtended(vaultExtendedLastBlock, msg.sender, oldUnlockTimestamp, newUnlockTimestamp);
        vaultExtendedLastBlock = block.number;
    }
}
