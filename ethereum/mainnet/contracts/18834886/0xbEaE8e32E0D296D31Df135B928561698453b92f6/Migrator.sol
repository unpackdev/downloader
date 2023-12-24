// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./PausableUpgradeable.sol";
import "./AccessControlEnumerableUpgradeable.sol";
import "./Initializable.sol";
import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./MerkleProof.sol";

contract Migrator is
    Initializable,
    PausableUpgradeable,
    AccessControlEnumerableUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    enum MigrationPreference {
        BALANCED, // 0
        DEUS, // 1
        SYMM // 2
    }

    struct Migration {
        address user;
        address token;
        uint256 amount;
        uint256 timestamp;
        uint256 block;
        MigrationPreference migrationPreference;
    }

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant UNPAUSER_ROLE = keccak256("UNPAUSER_ROLE");
    bytes32 public constant WITHDRAWER_ROLE = keccak256("WITHDRAWER_ROLE");
    bytes32 public constant SETTER_ROLE = keccak256("SETTER_ROLE");

    address public constant DEUS = 0xDE5ed76E7c05eC5e4572CfC88d1ACEA165109E44;

    uint256 public earlyMigrationDeadline;

    // total migrated amount by token address by project
    mapping(MigrationPreference => mapping(address => uint256))
        public totalLateMigratedAmount;

    mapping(MigrationPreference => mapping(address => uint256))
        public totalEarlyMigratedAmount;

    // user migrated amount: project => user => token => amount
    mapping(MigrationPreference => mapping(address => mapping(address => uint256)))
        public migratedAmount;

    // list of user migrations
    mapping(address => Migration[]) public migrations;

    bytes32 public legacyDEIMerkleRoot;
    bytes32 public bDEIMerkleRoot;

    // users converted amount: user => token => amount
    // address public 
    mapping(address => mapping(address => uint256)) public convertedAmount;
    address public bDEI;

    event Migrate(
        address[] token,
        uint256[] amount,
        MigrationPreference[] migrationPreference,
        address receiver
    );
    event Split(address user, uint256 index, uint256 amount);
    event Transfer(address user, uint256 index, address receiver);
    event Undo(address user, uint256 index);
    event ChangePreference(
        address user,
        uint256 index,
        MigrationPreference newPreference
    );
    event SetMerkleRoots(bytes32 legacyDEIMerkleRoot, bytes32 bDEIMerkleRoot);
    event Convert(address token, uint256 tokenAmount, uint256 deusAmount);

    error InvalidProof();

    function initialize(address _admin) external initializer {
        __Pausable_init();
        __AccessControlEnumerable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, _admin);

        earlyMigrationDeadline = block.timestamp + 30 days;
    }

    function pause() external onlyRole(PAUSER_ROLE) whenNotPaused {
        _pause();
    }

    function unpause() external onlyRole(UNPAUSER_ROLE) {
        _unpause();
    }

    function setMerkleRoots(bytes32 legacyDEIMerkleRoot_, bytes32 bDEIMerkleRoot_) external onlyRole(SETTER_ROLE) {
        legacyDEIMerkleRoot = legacyDEIMerkleRoot_;
        bDEIMerkleRoot = bDEIMerkleRoot_;

        emit SetMerkleRoots(legacyDEIMerkleRoot_, bDEIMerkleRoot_);
    }

    function setBDEIAddress(address bDEI_) external onlyRole(SETTER_ROLE) {
        bDEI = bDEI_;
    }

    function deposit(
        address[] memory tokens,
        uint256[] memory amounts,
        MigrationPreference[] memory migrationPreferences,
        address receiver
    ) external whenNotPaused {
        for (uint256 i; i < tokens.length; ++i) {
            IERC20Upgradeable(tokens[i]).safeTransferFrom(
                msg.sender,
                address(this),
                amounts[i]
            );

            if (block.timestamp < earlyMigrationDeadline) {
                totalEarlyMigratedAmount[migrationPreferences[i]][
                    tokens[i]
                ] += amounts[i];
            } else {
                totalLateMigratedAmount[migrationPreferences[i]][
                    tokens[i]
                ] += amounts[i];
            }

            migratedAmount[migrationPreferences[i]][receiver][
                tokens[i]
            ] += amounts[i];

            migrations[receiver].push(
                Migration({
                    user: receiver,
                    token: tokens[i],
                    amount: amounts[i],
                    timestamp: block.timestamp,
                    block: block.number,
                    migrationPreference: migrationPreferences[i]
                })
            );
        }

        emit Migrate(tokens, amounts, migrationPreferences, receiver);
    }

    function getUserMigrations(
        address user
    ) external view returns (Migration[] memory userMigrations) {
        userMigrations = new Migration[](migrations[user].length);
        for (uint256 i; i < userMigrations.length; ++i) {
            userMigrations[i] = migrations[user][i];
        }
    }

    function getTotalEarlyMigratedAmounts(
        address[] memory tokens
    )
        external
        view
        returns (
            uint256[] memory balancedAmounts,
            uint256[] memory deusAmounts,
            uint256[] memory symmAmounts
        )
    {
        balancedAmounts = new uint256[](tokens.length);
        deusAmounts = new uint256[](tokens.length);
        symmAmounts = new uint256[](tokens.length);
        for (uint256 i; i < tokens.length; ++i) {
            balancedAmounts[i] = totalEarlyMigratedAmount[
                MigrationPreference.BALANCED
            ][tokens[i]];
            deusAmounts[i] = totalEarlyMigratedAmount[MigrationPreference.DEUS][
                tokens[i]
            ];
            symmAmounts[i] = totalEarlyMigratedAmount[MigrationPreference.SYMM][
                tokens[i]
            ];
        }
    }

    function getTotalLateMigratedAmounts(
        address[] memory tokens
    )
        external
        view
        returns (
            uint256[] memory balancedAmounts,
            uint256[] memory deusAmounts,
            uint256[] memory symmAmounts
        )
    {
        balancedAmounts = new uint256[](tokens.length);
        deusAmounts = new uint256[](tokens.length);
        symmAmounts = new uint256[](tokens.length);
        for (uint256 i; i < tokens.length; ++i) {
            balancedAmounts[i] = totalLateMigratedAmount[
                MigrationPreference.BALANCED
            ][tokens[i]];
            deusAmounts[i] = totalLateMigratedAmount[MigrationPreference.DEUS][
                tokens[i]
            ];
            symmAmounts[i] = totalLateMigratedAmount[MigrationPreference.SYMM][
                tokens[i]
            ];
        }
    }

    function split(uint256 index, uint256 amount) external whenNotPaused {
        require(index < migrations[msg.sender].length, "Index Out Of Range");

        Migration storage migration = migrations[msg.sender][index];

        require(migration.amount > amount, "Amount Too High");

        migration.amount -= amount;

        migrations[msg.sender].push(
            Migration({
                user: msg.sender,
                token: migration.token,
                amount: amount,
                timestamp: migration.timestamp,
                block: migration.block,
                migrationPreference: migration.migrationPreference
            })
        );

        emit Split(msg.sender, index, amount);
    }

    function transfer(uint256 index, address receiver) external whenNotPaused {
        require(index < migrations[msg.sender].length, "Index Out Of Range");
        require(receiver != msg.sender, "Transfer To Owner");

        // transfer the migration to receiver
        Migration memory migration = migrations[msg.sender][index];
        migration.user = receiver;
        migrations[receiver].push(migration);

        // remove the migration from msg.sender migrations
        migrations[msg.sender][index] = migrations[msg.sender][
            migrations[msg.sender].length - 1
        ];
        migrations[msg.sender].pop();

        // update migratedAmount for msg.sender and receiver
        migratedAmount[migration.migrationPreference][msg.sender][
            migration.token
        ] -= migration.amount;
        migratedAmount[migration.migrationPreference][receiver][
            migration.token
        ] += migration.amount;

        emit Transfer(msg.sender, index, receiver);
    }

    function undo(uint256 index) external whenNotPaused {
        require(index < migrations[msg.sender].length, "Index Out Of Range");

        // remove the migration from msg.sender migrations
        Migration memory migration = migrations[msg.sender][index];
        migrations[msg.sender][index] = migrations[msg.sender][
            migrations[msg.sender].length - 1
        ];
        migrations[msg.sender].pop();

        // reduce user's migrated amount
        migratedAmount[migration.migrationPreference][msg.sender][
            migration.token
        ] -= migration.amount;

        // reduce total early/late migrated amount
        if (migration.timestamp < earlyMigrationDeadline) {
            totalEarlyMigratedAmount[migration.migrationPreference][
                migration.token
            ] -= migration.amount;
        } else {
            totalLateMigratedAmount[migration.migrationPreference][
                migration.token
            ] -= migration.amount;
        }

        // transfer migrated token back
        IERC20Upgradeable(migration.token).safeTransfer(
            msg.sender,
            migration.amount
        );

        emit Undo(msg.sender, index);
    }

    function changePreference(
        uint256 index,
        MigrationPreference newPreference
    ) external whenNotPaused {
        require(index < migrations[msg.sender].length, "Index Out Of Range");

        Migration storage migration = migrations[msg.sender][index];

        require(
            migration.migrationPreference != newPreference,
            "Same Migration Preference"
        );

        // undo storages which migration preference effects
        migratedAmount[migration.migrationPreference][msg.sender][
            migration.token
        ] -= migration.amount;

        if (migration.timestamp < earlyMigrationDeadline) {
            totalEarlyMigratedAmount[migration.migrationPreference][
                migration.token
            ] -= migration.amount;
        } else {
            totalLateMigratedAmount[migration.migrationPreference][
                migration.token
            ] -= migration.amount;
        }

        // update migration preference
        migration.migrationPreference = newPreference;

        // redo storages which migration preference effects
        migratedAmount[migration.migrationPreference][msg.sender][
            migration.token
        ] += migration.amount;

        if (migration.timestamp < earlyMigrationDeadline) {
            totalEarlyMigratedAmount[migration.migrationPreference][
                migration.token
            ] += migration.amount;
        } else {
            totalLateMigratedAmount[migration.migrationPreference][
                migration.token
            ] += migration.amount;
        }

        emit ChangePreference(msg.sender, index, newPreference);
    }

    function withdraw(
        address[] memory tokens
    ) external onlyRole(WITHDRAWER_ROLE) {
        for (uint256 i; i < tokens.length; ++i) {
            IERC20Upgradeable(tokens[i]).safeTransfer(
                msg.sender,
                IERC20Upgradeable(tokens[i]).balanceOf(address(this))
            );
        }
    }

    function wipeMigrations(
        address[] memory users,
        address[] memory tokens
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint256 i = 0; i < users.length; ++i) {
            address user = users[i];
            uint256 length = migrations[user].length;
            for (uint256 k = 0; k < tokens.length; ++k) {
                uint256 j = 0;
                while (j < length) {
                    if (migrations[user][j].token == tokens[k]) {
                        length -= 1;
                        migrations[user][j] = migrations[user][length];
                        migrations[user].pop();
                    } else {
                        j += 1;
                    }
                }
            }
        }
    }

    function convertBDEI(uint256 amount, uint256 maxAmount, bytes32[] memory proof) external whenNotPaused {
        require(amount <= maxAmount, "Invalid Amount");
         if (
            !MerkleProof.verify(
                proof,
                bDEIMerkleRoot,
                keccak256(abi.encode(msg.sender, maxAmount))
            )
        ) revert InvalidProof();

        convertedAmount[msg.sender][bDEI] += amount;
        require(convertedAmount[msg.sender][bDEI] <= maxAmount, "Amount Too High");

        IERC20Upgradeable(bDEI).safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );

        uint256 deusAmount = amount / 185;
        IERC20Upgradeable(DEUS).safeTransfer(msg.sender, deusAmount);

        emit Convert(bDEI, amount, deusAmount);
    }

    function convertLegacyDEI(uint256 amount, uint256 maxAmount, bytes32[] memory proof) external whenNotPaused {
        require(amount <= maxAmount, "Invalid Amount");
         if (
            !MerkleProof.verify(
                proof,
                legacyDEIMerkleRoot,
                keccak256(abi.encode(msg.sender, maxAmount))
            )
        ) revert InvalidProof();

        address legacyDEI = 0xDE12c7959E1a72bbe8a5f7A1dc8f8EeF9Ab011B3;
        convertedAmount[msg.sender][legacyDEI] += amount;
        require(convertedAmount[msg.sender][legacyDEI] <= maxAmount, "Amount Too High");

        IERC20Upgradeable(legacyDEI).safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );

        uint256 deusAmount = amount / 217;
        IERC20Upgradeable(DEUS).safeTransfer(msg.sender, deusAmount);

        emit Convert(legacyDEI, amount, deusAmount);
    }

    function convertXDEUS(uint256 amount) external whenNotPaused {
        address xDeus = 0x953Cd009a490176FcEB3a26b9753e6F01645ff28;
        IERC20Upgradeable(xDeus).safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );

        convertedAmount[msg.sender][xDeus] += amount;

        IERC20Upgradeable(DEUS).safeTransfer(msg.sender, amount);

        emit Convert(xDeus, amount, amount);
    }
}
