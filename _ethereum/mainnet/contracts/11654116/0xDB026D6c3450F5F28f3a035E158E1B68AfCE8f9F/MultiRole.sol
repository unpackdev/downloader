// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

library Exclusive {
  struct RoleMembership {
    address member;
  }

  function isMember(
    RoleMembership storage roleMembership,
    address memberToCheck
  ) internal view returns (bool) {
    return roleMembership.member == memberToCheck;
  }

  function resetMember(RoleMembership storage roleMembership, address newMember)
    internal
  {
    require(newMember != address(0x0), 'Cannot set an exclusive role to 0x0');
    roleMembership.member = newMember;
  }

  function getMember(RoleMembership storage roleMembership)
    internal
    view
    returns (address)
  {
    return roleMembership.member;
  }

  function init(RoleMembership storage roleMembership, address initialMember)
    internal
  {
    resetMember(roleMembership, initialMember);
  }
}

library Shared {
  struct RoleMembership {
    mapping(address => bool) members;
  }

  function isMember(
    RoleMembership storage roleMembership,
    address memberToCheck
  ) internal view returns (bool) {
    return roleMembership.members[memberToCheck];
  }

  function addMember(RoleMembership storage roleMembership, address memberToAdd)
    internal
  {
    require(memberToAdd != address(0x0), 'Cannot add 0x0 to a shared role');
    roleMembership.members[memberToAdd] = true;
  }

  function removeMember(
    RoleMembership storage roleMembership,
    address memberToRemove
  ) internal {
    roleMembership.members[memberToRemove] = false;
  }

  function init(
    RoleMembership storage roleMembership,
    address[] memory initialMembers
  ) internal {
    for (uint256 i = 0; i < initialMembers.length; i++) {
      addMember(roleMembership, initialMembers[i]);
    }
  }
}

abstract contract MultiRole {
  using Exclusive for Exclusive.RoleMembership;
  using Shared for Shared.RoleMembership;

  enum RoleType {Invalid, Exclusive, Shared}

  struct Role {
    uint256 managingRole;
    RoleType roleType;
    Exclusive.RoleMembership exclusiveRoleMembership;
    Shared.RoleMembership sharedRoleMembership;
  }

  mapping(uint256 => Role) private roles;

  event ResetExclusiveMember(
    uint256 indexed roleId,
    address indexed newMember,
    address indexed manager
  );
  event AddedSharedMember(
    uint256 indexed roleId,
    address indexed newMember,
    address indexed manager
  );
  event RemovedSharedMember(
    uint256 indexed roleId,
    address indexed oldMember,
    address indexed manager
  );

  modifier onlyRoleHolder(uint256 roleId) {
    require(
      holdsRole(roleId, msg.sender),
      'Sender does not hold required role'
    );
    _;
  }

  modifier onlyRoleManager(uint256 roleId) {
    require(
      holdsRole(roles[roleId].managingRole, msg.sender),
      'Can only be called by a role manager'
    );
    _;
  }

  modifier onlyExclusive(uint256 roleId) {
    require(
      roles[roleId].roleType == RoleType.Exclusive,
      'Must be called on an initialized Exclusive role'
    );
    _;
  }

  modifier onlyShared(uint256 roleId) {
    require(
      roles[roleId].roleType == RoleType.Shared,
      'Must be called on an initialized Shared role'
    );
    _;
  }

  function holdsRole(uint256 roleId, address memberToCheck)
    public
    view
    returns (bool)
  {
    Role storage role = roles[roleId];
    if (role.roleType == RoleType.Exclusive) {
      return role.exclusiveRoleMembership.isMember(memberToCheck);
    } else if (role.roleType == RoleType.Shared) {
      return role.sharedRoleMembership.isMember(memberToCheck);
    }
    revert('Invalid roleId');
  }

  function resetMember(uint256 roleId, address newMember)
    public
    onlyExclusive(roleId)
    onlyRoleManager(roleId)
  {
    roles[roleId].exclusiveRoleMembership.resetMember(newMember);
    emit ResetExclusiveMember(roleId, newMember, msg.sender);
  }

  function getMember(uint256 roleId)
    public
    view
    onlyExclusive(roleId)
    returns (address)
  {
    return roles[roleId].exclusiveRoleMembership.getMember();
  }

  function addMember(uint256 roleId, address newMember)
    public
    onlyShared(roleId)
    onlyRoleManager(roleId)
  {
    roles[roleId].sharedRoleMembership.addMember(newMember);
    emit AddedSharedMember(roleId, newMember, msg.sender);
  }

  function removeMember(uint256 roleId, address memberToRemove)
    public
    onlyShared(roleId)
    onlyRoleManager(roleId)
  {
    roles[roleId].sharedRoleMembership.removeMember(memberToRemove);
    emit RemovedSharedMember(roleId, memberToRemove, msg.sender);
  }

  function renounceMembership(uint256 roleId)
    public
    onlyShared(roleId)
    onlyRoleHolder(roleId)
  {
    roles[roleId].sharedRoleMembership.removeMember(msg.sender);
    emit RemovedSharedMember(roleId, msg.sender, msg.sender);
  }

  modifier onlyValidRole(uint256 roleId) {
    require(
      roles[roleId].roleType != RoleType.Invalid,
      'Attempted to use an invalid roleId'
    );
    _;
  }

  modifier onlyInvalidRole(uint256 roleId) {
    require(
      roles[roleId].roleType == RoleType.Invalid,
      'Cannot use a pre-existing role'
    );
    _;
  }

  function _createSharedRole(
    uint256 roleId,
    uint256 managingRoleId,
    address[] memory initialMembers
  ) internal onlyInvalidRole(roleId) {
    Role storage role = roles[roleId];
    role.roleType = RoleType.Shared;
    role.managingRole = managingRoleId;
    role.sharedRoleMembership.init(initialMembers);
    require(
      roles[managingRoleId].roleType != RoleType.Invalid,
      'Attempted to use an invalid role to manage a shared role'
    );
  }

  function _createExclusiveRole(
    uint256 roleId,
    uint256 managingRoleId,
    address initialMember
  ) internal onlyInvalidRole(roleId) {
    Role storage role = roles[roleId];
    role.roleType = RoleType.Exclusive;
    role.managingRole = managingRoleId;
    role.exclusiveRoleMembership.init(initialMember);
    require(
      roles[managingRoleId].roleType != RoleType.Invalid,
      'Attempted to use an invalid role to manage an exclusive role'
    );
  }
}
