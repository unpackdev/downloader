// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

import "./Address.sol";
import "./IERC1155.sol";
import "./ReentrancyGuard.sol";
import "./AccessControl.sol";

import "./WhitelistInterface.sol";
import "./EmissionBooster.sol";
import "./ErrorCodes.sol";

contract Whitelist is WhitelistInterface, AccessControl, ReentrancyGuard {
    using Address for address;
    /// @notice The given member was added to the whitelist
    event MemberAdded(address);
    /// @notice The given member was removed from the whitelist
    event MemberRemoved(address);
    /// @notice Protocol operation mode switched
    event WhitelistModeWasTurnedOff();
    /// @notice Amount of maxMembers changed
    event MaxMemberAmountChanged(uint256);

    /// @notice A maximum number of members. When membership reaches this number, no new members may
    /// join.
    uint256 public maxMembers;

    /// @notice The total number of members stored in the map.
    uint256 public memberCount;

    /// @notice Boolean variable. Protocol operation mode. In whitelist mode, only members
    /// from whitelist and who have NFT can work with protocol.
    bool public whitelistModeEnabled = true;

    // @notice Mapping of "accounts in the WhiteList"
    mapping(address => bool) public accountMembership;

    /// @notice EmissionBooster contract
    EmissionBooster public emissionBooster;

    /// @notice The right part is the keccak-256 hash of variable name
    bytes32 public constant GATEKEEPER = bytes32(0x20162831d2f54c3e11eebafebfeda495d4c52c67b1708251179ec91fb76dd3b2);

    constructor(
        address _admin,
        EmissionBooster emissionBooster_,
        uint256 _maxMembers,
        address[] memory memberList
    ) {
        require(Address.isContract(address(emissionBooster_)), ErrorCodes.CONTRACT_DOES_NOT_SUPPORT_INTERFACE);
        require(memberList.length <= _maxMembers, ErrorCodes.MEMBERSHIP_LIMIT);

        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _grantRole(GATEKEEPER, _admin);
        emissionBooster = emissionBooster_;
        maxMembers = _maxMembers;

        uint256 savedMembers = 0;
        for (uint256 i = 0; i < memberList.length; i++) {
            if (accountMembership[memberList[i]]) {
                continue;
            }
            accountMembership[memberList[i]] = true;
            savedMembers++;
            emit MemberAdded(memberList[i]);
        }
        memberCount = savedMembers;
    }

    /**
     * @notice Add a new member to the whitelist.
     * @param newAccount The account that is being added to the whitelist.
     */
    function addMember(address newAccount) external override onlyRole(GATEKEEPER) {
        require(!accountMembership[newAccount], ErrorCodes.MEMBER_ALREADY_ADDED);
        require(memberCount < maxMembers, ErrorCodes.MEMBERSHIP_LIMIT_REACHED);

        accountMembership[newAccount] = true;
        memberCount++;

        emit MemberAdded(newAccount);
    }

    /**
     * @notice Remove a member from the whitelist.
     * @param accountToRemove The account that is being removed from the whitelist.
     */
    function removeMember(address accountToRemove) external override onlyRole(GATEKEEPER) {
        require(accountMembership[accountToRemove], ErrorCodes.MEMBER_NOT_EXIST);

        delete accountMembership[accountToRemove];
        memberCount--;

        emit MemberRemoved(accountToRemove);
    }

    /**
     * @notice Disables whitelist mode and enables emission boost mode.
     * @dev Admin function for disabling whitelist mode.
     */
    function turnOffWhitelistMode() external override onlyRole(DEFAULT_ADMIN_ROLE) nonReentrant {
        whitelistModeEnabled = false;
        emit WhitelistModeWasTurnedOff();
        emissionBooster.enableEmissionBoosting();
    }

    /**
     * @notice Set a new threshold of participants.
     * @param newThreshold New number of participants.
     */
    function setMaxMembers(uint256 newThreshold) external override onlyRole(GATEKEEPER) {
        require(newThreshold >= memberCount, ErrorCodes.MEMBERSHIP_LIMIT);
        maxMembers = newThreshold;
        emit MaxMemberAmountChanged(newThreshold);
    }

    /**
     * @notice Check protocol operation mode. In whitelist mode, only members from whitelist and who have
     *         EmissionBooster can work with protocol.
     * @param who The address of the account to check for participation.
     */
    function isWhitelisted(address who) external view override returns (bool) {
        return !whitelistModeEnabled || accountMembership[who] || emissionBooster.isAccountHaveTiers(who);
    }

    /// @dev Returns true if this contract implements the interface defined by `interfaceId`
    function supportsInterface(bytes4 interfaceId) public pure override(AccessControl, IERC165) returns (bool) {
        return interfaceId == type(WhitelistInterface).interfaceId;
    }
}
