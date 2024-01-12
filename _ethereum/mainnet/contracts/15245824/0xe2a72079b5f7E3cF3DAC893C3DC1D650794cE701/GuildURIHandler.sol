// SPDX-License-Identifier: MIT

/// @title RaidParty Guild URI Handler

/**
 *   ___      _    _ ___          _
 *  | _ \__ _(_)__| | _ \__ _ _ _| |_ _  _
 *  |   / _` | / _` |  _/ _` | '_|  _| || |
 *  |_|_\__,_|_\__,_|_| \__,_|_|  \__|\_, |
 *                                    |__/
 */

pragma solidity ^0.8.0;

import "./StringsUpgradeable.sol";
import "./Initializable.sol";
import "./AccessControlEnumerableUpgradeable.sol";
import "./IERC721Upgradeable.sol";
import "./ECDSAUpgradeable.sol";
import "./draft-EIP712Upgradeable.sol";
import "./ERC721HolderUpgradeable.sol";
import "./MathUpgradeable.sol";
import "./IGuildURIHandler.sol";
import "./IERC20Burnable.sol";
import "./IParty.sol";

contract GuildURIHandler is
    Initializable,
    AccessControlEnumerableUpgradeable,
    EIP712Upgradeable,
    ERC721HolderUpgradeable,
    IGuildURIHandler
{
    using StringsUpgradeable for uint256;
    using ECDSAUpgradeable for bytes32;

    /** EVENTS */

    /// @notice Emitted when a user joins a given guild.
    event Join(address indexed user, uint256 indexed guildId);

    /// @notice Emitted when a user leaves a given guild.
    event Leave(address indexed user, uint256 indexed guildId);

    /// @notice Emitted when a user initiates a vault deposit.
    event VaultDeposit(address indexed user, uint256 amount);

    /// @notice Emitted when GCFTI is minted to a user.
    event Mint(address indexed user, uint256 amount);

    /// @notice Emitted when a user deposits GCFTI to a guild.
    event Deposit(
        address indexed user,
        uint256 indexed guildId,
        uint256 amount
    );

    /// @notice Emitted when a user stakes a hero.
    event Stake(address indexed user, uint256 hero);

    /// @notice Emitted when a user unstakes a hero.
    event Unstake(address indexed user, uint256 hero);

    /// @notice Emitted when a user upgrades their base guild level.
    event Upgrade(uint256 indexed guildId, uint16 level);

    /// @notice Emitted when a user upgrades the tech tree on a given guild.
    event UpgradeTechTree(uint256 indexed guildId, Branch branch, uint16 level);

    /** ERRORS */

    /// @notice Public state-changing functions are currently paused.
    error Paused();

    /// @notice Hero already staked.
    error HeroPresent();

    /// @notice No hero is currently staked.
    error HeroNotPresent();

    /// @notice User is currently in a guild.
    error GuildPresent();

    /// @notice User is not currently in a guild.
    error GuildNotPresent();

    /// @notice Guild has reached it's membership capacity.
    error GuildAtCapacity();

    /// @notice User is not currently in a guild.
    error GuildAtMaxLevel();

    /// @notice Insufficient funds to complete an operation.
    error InsufficientFunds(uint256 missingAmount);

    /// @notice User is not currently the owner of a given guild.
    error GuildNotOwned();

    /// @notice User is not currently a member of a given guild.
    error NotGuildMember();

    /// @notice Forage delay not yet passed.
    error ForageDelay(uint256 delay);

    /// @notice Invite redeemer is not a recipient.
    error NotRecipient();

    /// @notice Level requirement for upgrade not met.
    error LevelRequirementNotMet(Branch branch);

    /// @notice Name too long.
    error OutOfBounds();

    /// @notice Name taken.
    error NameUnavailable();

    /// @notice Invite timeout passed.
    error TimeoutExceeded();

    /// @notice Insufficient permissions.
    error InsufficientPermissions();

    /** CONSTANTS */

    uint16 private constant MAX_LEVEL = 5;
    uint16 private constant MAX_BRANCH_LEVEL = 5;

    string public constant INVITE_NAME = "Invite";
    string public constant INVITE_VERSION = "1";
    bytes32 public constant INVITE_TYPEHASH =
        keccak256("Invite(address user,uint256 guildId,uint256 timeout)");

    bytes32 public constant GCFTI_MINTER_ROLE = keccak256("GCFTI_MINTER_ROLE");

    /// @notice Precision of GCFTI / vault balance
    uint64 public constant DECIMALS = 10**3;
    /// @notice Decimal difference between GCFTI / vault balance and CFTI
    uint64 public constant DECIMAL_DELTA = 10**15;

    uint64 public constant FORAGE_DELAY = 1 weeks;
    uint64 public constant FORAGE_REWARD = 50 * DECIMALS;

    /** STATE */

    IERC721Upgradeable private _guild;
    IERC721Upgradeable private _hero;
    IERC20Burnable private _confetti;
    IParty private _party;
    address private _team;
    bool private _paused;

    mapping(uint256 => Guild) private _guilds;
    mapping(address => Member) private _members;
    mapping(bytes32 => bool) private _names;

    /** MODIFIERS */

    modifier whenNotPaused() {
        if (_paused) revert Paused();
        _;
    }

    /** ADMIN */

    function initialize(
        address admin,
        IERC721Upgradeable guild,
        IERC721Upgradeable hero,
        IERC20Burnable confetti,
        IParty party
    ) public initializer {
        __AccessControl_init();
        __EIP712_init(INVITE_NAME, INVITE_VERSION);
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        _setupRole(GCFTI_MINTER_ROLE, admin);
        _confetti = IERC20Burnable(confetti);
        _team = admin;
        _guild = guild;
        _hero = hero;
        _party = party;
        _paused = true;
    }

    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _paused = true;
    }

    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _paused = false;
    }

    /**
     * @notice Mints GCFTI to a given user.
     */
    function mint(address user, uint64 amount)
        external
        onlyRole(GCFTI_MINTER_ROLE)
        whenNotPaused
    {
        _mint(user, amount);
    }

    //** UTILITY */

    /**
     * @notice Sets a 32 byte name for a guild.
     */
    function setName(uint256 guildId, string calldata name)
        external
        whenNotPaused
    {
        if (bytes(name).length > 32) revert OutOfBounds();
        if (_guild.ownerOf(guildId) != msg.sender) revert GuildNotOwned();

        // Reset name if it was previously set
        if (_guilds[guildId].name != bytes32(0)) {
            _names[_guilds[guildId].name] = false;
        }

        // Check name availability
        bytes32 bName = bytes32(bytes(name));
        if (bName != bytes32(0)) {
            if (_names[bName]) revert NameUnavailable();
            _names[bName] = true;
        }

        // Set name
        _guilds[guildId].name = bName;
    }

    /**
     * @notice Locks CFTI into a users guild vault given an input amount.
     * Vault balances are further used for in-game effects.
     */
    function vaultDeposit(uint256 amount) external whenNotPaused {
        _confetti.burnFrom(msg.sender, amount);

        uint64 guildConfetti = toGuildConfetti(amount);

        // Convert CFTI amount directly into a lower precision value
        _members[msg.sender].vault += guildConfetti;
        // NOTE: Guild vault is an aggregate sum of each member's vault
        if (_members[msg.sender].guildId != 0) {
            _guilds[_members[msg.sender].guildId].vault += guildConfetti;
        }

        emit VaultDeposit(msg.sender, amount);
    }

    /**
     * @notice Locks CFTI in a form of a guild gCFTI balance, used for guild
     * progression.
     */
    function deposit(uint256 amount) external whenNotPaused {
        Member storage member = _members[msg.sender];
        if (member.guildId == 0) revert GuildNotPresent();
        Guild storage guild = _guilds[member.guildId];

        _confetti.burnFrom(msg.sender, amount);

        // When contributing CFTI to a guild, a user earns gCFTI in 1:1 ratio
        // but gets a linear bonus percentage of up to 100% depending on the guild vault.
        // NOTE: We specifically first calculate the rewards and only update
        // the guild vault afterwards, so the benefit is only for in subsequent deposits
        uint64 gcfti = _calculateRewards(amount, guild);
        guild.balance += gcfti;
        // Player vault is also filled by half of their direct deposit to a guild,
        // irrespective of the calculated reward amount
        uint64 vaultReward = toGuildConfetti(amount) / 2;
        member.vault += vaultReward;
        // ...and guild's vault is an aggregate sum of their member's vault
        guild.vault += vaultReward;

        emit Deposit(msg.sender, member.guildId, gcfti);
    }

    /**
     * @dev Convenience function that adjusts CFTI to GCFTI decimals
     */
    function toGuildConfetti(uint256 confetti)
        internal
        pure
        returns (uint64 gcfti)
    {
        unchecked {
            gcfti = uint64(confetti / DECIMAL_DELTA);
        }
    }

    /**
     * @notice Stake a hero.
     */
    function stake(uint32 id) external whenNotPaused {
        Member storage member = _members[msg.sender];
        if (member.hero != 0) revert HeroPresent();

        member.hero = id;
        member.lastForage = uint64(block.timestamp);

        _hero.safeTransferFrom(msg.sender, address(this), id);

        emit Stake(msg.sender, id);
    }

    /**
     * @notice Unstake a hero.
     */
    function unstake() external whenNotPaused {
        Member storage member = _members[msg.sender];
        uint32 hero = member.hero;
        if (hero == 0) revert HeroNotPresent();

        member.hero = 0;

        _hero.safeTransferFrom(address(this), msg.sender, hero);

        emit Unstake(msg.sender, hero);
    }

    /**
     * @notice Forage for GCFTI. This can occur once per time period if a user has staked a hero.
     */
    function forage() external whenNotPaused {
        Member storage member = _members[msg.sender];
        if (member.hero == 0) revert HeroNotPresent();
        if ((block.timestamp - member.lastForage) < FORAGE_DELAY)
            revert ForageDelay(block.timestamp - member.lastForage);
        uint64 count = (uint64(block.timestamp) - member.lastForage) /
            FORAGE_DELAY;
        member.lastForage = uint64(
            (block.timestamp / FORAGE_DELAY) * FORAGE_DELAY
        );
        _mint(msg.sender, count * FORAGE_REWARD);
    }

    /**
     * @notice Accepts a guild invite.
     */
    function join(Invite calldata invite, bytes memory signature)
        external
        whenNotPaused
    {
        if (invite.timeout < block.timestamp) revert TimeoutExceeded();

        Member storage member = _members[msg.sender];
        if (member.guildId != 0) revert GuildPresent();
        _verifyInvite(invite, signature);

        Guild storage guild = _guilds[invite.guildId];
        if (guild.members.length >= _getMaxMembers(guild.level))
            revert GuildAtCapacity();
        member.guildId = invite.guildId;
        member.lastForage = uint64(block.timestamp);
        member.slot = uint16(guild.members.length);
        // NOTE: Guild vault is an aggregate sum of each member's vault
        guild.vault += member.vault;
        guild.members.push(msg.sender);

        emit Join(msg.sender, invite.guildId);
    }

    /**
     * @notice Leaves the users current guild.
     */
    function leave() external whenNotPaused {
        Member storage member = _members[msg.sender];
        if (member.guildId == 0) revert GuildNotPresent();

        _removeMember(msg.sender, member);
    }

    /**
     * @notice Kicks a user from the guild.
     */
    function kick(address user) external whenNotPaused {
        Member storage member = _members[user];
        if (_guild.ownerOf(member.guildId) != msg.sender)
            revert GuildNotOwned();

        _removeMember(user, member);
    }

    /**
     * @notice Sets user authorization to spend gCFTI.
     */
    function setAuthorization(
        uint256 guildId,
        address user,
        bool authorized
    ) external whenNotPaused {
        if (_guild.ownerOf(guildId) != msg.sender) revert GuildNotOwned();

        if (_members[user].guildId != guildId) revert GuildNotPresent();

        _members[user].permissions = (authorized) ? 1 : 0;
    }

    /**
     * @notice Upgrades a guild's level.
     */
    function upgrade(uint256 guildId) external whenNotPaused {
        if (
            _guild.ownerOf(guildId) != msg.sender &&
            _members[msg.sender].permissions != 1
        ) revert InsufficientPermissions();

        Guild storage guild = _guilds[guildId];
        if (guild.level >= MAX_LEVEL) revert GuildAtMaxLevel();

        uint64 cost = getLevelCost(guild.level);
        if (cost > guild.balance)
            revert InsufficientFunds(cost - guild.balance);

        guild.balance -= cost;
        guild.level += 1;

        emit Upgrade(guildId, guild.level);
    }

    /**
     * @notice Upgrades a guild's tech tree.
     */
    function upgradeTechTree(uint256 guildId, Branch branch)
        external
        whenNotPaused
    {
        if (
            _guild.ownerOf(guildId) != msg.sender &&
            _members[msg.sender].permissions != 1
        ) revert InsufficientPermissions();

        Guild storage guild = _guilds[guildId];
        uint256 tree = guild.techTree;
        if (guild.level < uint16(branch)) revert LevelRequirementNotMet(branch);

        uint64 cost = getTreeCost(_getTechTreeLevel(tree, branch), branch);
        if (cost > guild.balance)
            revert InsufficientFunds(cost - guild.balance);

        guild.balance -= cost;
        tree = _incrementTechTreeLevel(tree, branch);
        guild.techTree = tree;

        emit UpgradeTechTree(guildId, branch, _getTechTreeLevel(tree, branch));
    }

    /** VIEWS */

    function getName(uint256 guildId) public view returns (string memory) {
        bytes32 name = _guilds[guildId].name;

        if (name == bytes32(0)) {
            return string(abi.encodePacked("Guild #", guildId.toString()));
        } else {
            return string(abi.encodePacked(_guilds[guildId].name));
        }
    }

    function tokenURI(uint256 tokenId) public pure returns (string memory) {
        return string(abi.encodePacked(_baseURI(), tokenId.toString()));
    }

    function getMaxMembers(uint256 guildId) public view returns (uint16) {
        uint16 level = _guilds[guildId].level;
        return _getMaxMembers(level);
    }

    function getMembers(uint256 guildId)
        external
        view
        returns (address[] memory)
    {
        return _guilds[guildId].members;
    }

    function getGuildLevel(uint256 guildId) external view returns (uint16) {
        return _guilds[guildId].level;
    }

    function getGuildTechLevel(uint256 guildId, Branch branch)
        external
        view
        returns (uint16)
    {
        return _getTechTreeLevel(_guilds[guildId].techTree, branch);
    }

    function getGuildTechTree(uint256 guildId)
        public
        view
        returns (TechTree memory)
    {
        return _getTechTree(_guilds[guildId].techTree);
    }

    function getGuildVault(uint256 guildId) external view returns (uint64) {
        return _guilds[guildId].vault;
    }

    function getGuildBalance(uint256 guildId) external view returns (uint64) {
        return _guilds[guildId].balance;
    }

    function getGuildData(uint256 guildId)
        external
        view
        returns (
            uint64 balance,
            uint16 level,
            uint64 vault,
            TechTree memory techTree,
            address[] memory members,
            string memory name
        )
    {
        Guild storage guild = _guilds[guildId];
        balance = guild.balance;
        level = guild.level;
        vault = guild.vault;
        members = guild.members;
        techTree = getGuildTechTree(guildId);
        name = getName(guildId);
    }

    function calculateRewards(uint256 rewards, uint256 guildId)
        external
        view
        returns (uint64)
    {
        return guildId == 0 ? 0 : _calculateRewards(rewards, _guilds[guildId]);
    }

    function getMember(address user) external view returns (Member memory) {
        return _members[user];
    }

    function getGuild(address user) external view returns (uint256) {
        return _members[user].guildId;
    }

    function getTreeCost(uint16 level, Branch branch)
        public
        pure
        returns (uint64)
    {
        uint64 cost;

        if (branch == Branch.FRUGALITY) {
            if (level == 0) {
                cost = 5_000;
            } else if (level == 1) {
                cost = 10_000;
            } else if (level == 2) {
                cost = 20_000;
            } else if (level == 3) {
                cost = 50_000;
            } else {
                cost = 100_000;
            }
        } else if (branch == Branch.DISCIPLINE) {
            if (level == 0) {
                cost = 10_000;
            } else if (level == 1) {
                cost = 20_000;
            } else if (level == 2) {
                cost = 50_000;
            } else if (level == 3) {
                cost = 100_000;
            } else {
                cost = 250_000;
            }
        } else if (branch == Branch.MORALE) {
            if (level == 0) {
                cost = 20_000;
            } else if (level == 1) {
                cost = 50_000;
            } else if (level == 2) {
                cost = 100_000;
            } else if (level == 3) {
                cost = 250_000;
            } else {
                cost = 500_000;
            }
        } else if (branch == Branch.INDEMNITY) {
            if (level == 0) {
                cost = 50_000;
            } else if (level == 1) {
                cost = 100_000;
            } else if (level == 2) {
                cost = 250_000;
            } else if (level == 3) {
                cost = 500_000;
            } else {
                cost = 1_000_000;
            }
        } else if (branch == Branch.SUPERSTITION) {
            if (level == 0) {
                cost = 100_000;
            } else if (level == 1) {
                cost = 250_000;
            } else if (level == 2) {
                cost = 500_000;
            } else if (level == 3) {
                cost = 1_000_000;
            } else {
                cost = 2_000_000;
            }
        } else {
            if (level == 0) {
                cost = 250_000;
            } else if (level == 1) {
                cost = 500_000;
            } else if (level == 2) {
                cost = 1_000_000;
            } else if (level == 3) {
                cost = 2_000_000;
            } else {
                cost = 4_000_000;
            }
        }

        return cost * DECIMALS;
    }

    function getLevelCost(uint16 level) public pure returns (uint64) {
        uint64 cost;

        if (level == 0) {
            cost = 10_000;
        } else if (level == 1) {
            cost = 20_000;
        } else if (level == 2) {
            cost = 40_000;
        } else if (level == 3) {
            cost = 160_000;
        } else {
            cost = 2_560_000;
        }

        return cost * DECIMALS;
    }

    function isAuthorized(address user) external view returns (bool) {
        return _members[user].permissions == 1;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(AccessControlEnumerableUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function inviteHash(Invite calldata invite) public view returns (bytes32) {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        INVITE_TYPEHASH,
                        invite.user,
                        invite.guildId,
                        invite.timeout
                    )
                )
            );
    }

    /** INTERNAL */

    function _baseURI() internal pure returns (string memory) {
        return "https://api.raid.party/metadata/guild/";
    }

    function _verifyInvite(Invite calldata invite, bytes memory signature)
        internal
        view
    {
        if (invite.user != msg.sender) revert NotRecipient();
        bytes32 hash = inviteHash(invite);
        address signer = ECDSAUpgradeable.recover(hash, signature);
        if (signer != _guild.ownerOf(invite.guildId)) revert GuildNotOwned();
    }

    function _mint(address user, uint64 amount) internal {
        Member storage member = _members[user];
        if (member.guildId == 0) revert GuildNotPresent();

        _guilds[member.guildId].balance += amount;

        emit Mint(user, amount);
    }

    function _getMaxMembers(uint16 level) internal pure returns (uint16) {
        if (level == 0) {
            return 10;
        } else if (level == 1) {
            return 15;
        } else if (level == 2) {
            return 25;
        } else if (level == 3) {
            return 35;
        } else if (level == 4) {
            return 50;
        } else {
            return 100;
        }
    }

    function _getTechTreeLevel(uint256 tree, Branch branch)
        internal
        pure
        returns (uint16)
    {
        unchecked {
            return uint16(tree >> (uint256(branch) * 16));
        }
    }

    function _getTechTree(uint256 tree)
        internal
        pure
        returns (TechTree memory)
    {
        TechTree memory techTree;

        assembly {
            mstore(techTree, tree)
            mstore(add(techTree, 0x20), shr(16, tree))
            mstore(add(techTree, 0x40), shr(32, tree))
            mstore(add(techTree, 0x60), shr(48, tree))
            mstore(add(techTree, 0x80), shr(64, tree))
            mstore(add(techTree, 0xa0), shr(80, tree))
        }

        return techTree;
    }

    function _incrementTechTreeLevel(uint256 tree, Branch branch)
        internal
        pure
        returns (uint256)
    {
        unchecked {
            if (_getTechTreeLevel(tree, branch) >= MAX_BRANCH_LEVEL)
                revert GuildAtMaxLevel();
            return tree + (1 << (uint256(branch) * 16));
        }
    }

    function _calculateRewards(uint256 rewards, Guild memory guild)
        internal
        pure
        returns (uint64)
    {
        unchecked {
            return
                toGuildConfetti(
                    rewards +
                        // Guild vault gives linearly up to extra +100% rewards,
                        // capped at 3M gCFTI (10^3 precision).
                        ((rewards *
                            MathUpgradeable.min(guild.vault, 3_000_000e3)) /
                            3_000_000e3)
                );
        }
    }

    function _removeMember(address user, Member storage member) internal {
        uint256 guildId = member.guildId;
        Guild storage guild = _guilds[guildId];
        // NOTE: Guild vault is an aggregate sum of each member's vault
        guild.vault -= member.vault;

        if (member.slot != (guild.members.length - 1)) {
            (
                guild.members[member.slot],
                guild.members[guild.members.length - 1]
            ) = (
                guild.members[guild.members.length - 1],
                guild.members[member.slot]
            );
            _members[guild.members[member.slot]].slot = member.slot;
        }
        guild.members.pop();

        member.permissions = 0;
        member.guildId = 0;
        member.slot = 0;

        _party.updateDamage(user);

        emit Leave(user, guildId);
    }
}
