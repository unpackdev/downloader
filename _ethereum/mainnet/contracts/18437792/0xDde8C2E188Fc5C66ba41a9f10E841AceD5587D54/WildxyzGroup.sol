// SPDX-License-Identifier: GPL-3.0-or-later

// ░██╗░░░░░░░██╗░██╗░██╗░░░░░░██████╗░░██╗░░██╗░██╗░░░██╗░███████╗
// ░██║░░██╗░░██║░██║░██║░░░░░░██╔══██╗░╚██╗██╔╝░╚██╗░██╔╝░╚════██║
// ░╚██╗████╗██╔╝░██║░██║░░░░░░██║░░██║░░╚███╔╝░░░╚████╔╝░░░░███╔═╝
// ░░████╔═████║░░██║░██║░░░░░░██║░░██║░░██╔██╗░░░░╚██╔╝░░░██╔══╝░░
// ░░╚██╔╝░╚██╔╝░░██║░███████╗░██████╔╝░██╔╝╚██╗░░░░██║░░░░███████╗
// ░░░╚═╝░░░╚═╝░░░╚═╝░╚══════╝░╚═════╝░░╚═╝░░╚═╝░░░░╚═╝░░░░╚══════╝

// It ain't much, but it's honest work.

pragma solidity ^0.8.17;

import "./Ownable.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";

import "./Math.sol";

import "./UseAdminBeacon.sol";

import "./ISanctionsList.sol";
import "./IDelegationRegistry.sol";

import "./IWildxyzGroup.sol";

abstract contract WildxyzGroup is IWildxyzGroup, UseAdminBeacon, Pausable, ReentrancyGuard {
  // private variables

  mapping(uint256 => Group) internal groups;
  uint256 internal numGroups;

  /// @dev One-time variable used to set up the contract.
  bool private isSetup = false;

  // drop variables

  /// @notice Max supply of NFTs available. Same as NFT contract.
  uint256 public maxSupply;

  /// @notice Wildxyz royalty percentage.
  /// @dev Wildxyz royalty is `wildRoyalty`%. Artist royalty is `100 - wildRoyalty`% (100 - wildRoyalty).
  uint256 public wildRoyalty;

  /// @notice Royalty total denominator.
  uint256 public royaltyTotal = 100;

  /// @notice Wildxyz royalty wallet
  /// @dev This is the wallet that will receive the `wildRoyalty`% of the primary sale eth.
  address payable public wildWallet;

  /// @notice Artist royalty wallet
  /// @dev This is the wallet that will receive the `100 - wildRoyalty`% of the primary sale eth.
  address payable public artistWallet;

  /// @notice The OFAC sanctions list contract address.
  /// @dev Used to block unsanctioned addresses from minting NFTs.
  ISanctionsList public sanctionsList;

  /// @notice The DelegateCash registry address.
  IDelegationRegistry public delegationRegistry = IDelegationRegistry(0x00000000000076A84feF008CDAbe6409d2FE638B);

  // minter variables

  uint256 public maxPerAddress;

  mapping(address => uint256) public addressTotalSupply;

  // modifiers

  modifier setupOnce() {
    if (isSetup) revert AlreadySetup();
    isSetup = true;
    _;
  }
  
  modifier onlyLive() {
    if (getState() != State.Live) revert NotLive();
    _;
  }

  modifier beforeEndTime() {
    uint256 lastGroupId = numGroups - 1;
    if (groups[lastGroupId].endTime != 0 && block.timestamp >= groups[lastGroupId].endTime) revert NotLive();
    _;
  }

  modifier validGroup(uint256 _groupId) {
    _validGroup(_groupId);
    _;
  }

  modifier onlyUnsanctioned(address _to) {
    if (sanctionsList.isSanctioned(_to)) revert SanctionedAddress(_to);
    _;
  }

  modifier onlyDelegated(address _vault, address _contract) {
    if (!delegationRegistry.checkDelegateForContract(msg.sender, _vault, _contract)) revert NotDelegated(msg.sender, _vault, _contract);
    _;
  }

  modifier nonZeroAmount(uint256 _amount) {
    _nonZeroAmount(_amount);
    _;
  }

  modifier validGroupPriceSupplyAllowance(address _receiver, uint256 _amount, uint256 _groupId) {
    _validGroupPriceSupplyAllowance(_receiver, _amount, _groupId);
    _;
  }

  modifier validGroupPriceSupply(uint256 _amount, uint256 _groupId) {
    _validGroupPriceSupply(_amount, _groupId);
    _;
  }

  /** @notice Base constructor
   * @param _maxSupply The max supply of the NFT (same as WildNFT)
   * @param _maxPerAddress The max number of NFTs that can be minted per address
   * @param _wildRoyalty The royalty percentage for Wildxyz
   * @param _wildWallet The wallet address for Wildxyz
   * @param _artistWallet The wallet address for the artist
   * @param _adminBeacon The admin address
   * @param _sanctions The sanctions list contract address
   */
  constructor(uint256 _maxSupply, uint256 _maxPerAddress, uint256 _wildRoyalty, address _wildWallet, address _artistWallet, IAdminBeaconUpgradeable _adminBeacon, ISanctionsList _sanctions) {
    maxSupply = _maxSupply;
    maxPerAddress = _maxPerAddress;

    wildRoyalty = _wildRoyalty;
    wildWallet = payable(_wildWallet);
    artistWallet = payable(_artistWallet);

    _setAdminBeacon(_adminBeacon);

    sanctionsList = _sanctions;
  }

  // internal functions

  function _createGroup(string memory _name, uint256 _startTime, uint256 _endTime, uint256 _price, uint256 _reserveSupply) internal onlyOwner returns (uint256 groupId) {
    groupId = numGroups;

    // check if total reserve supply exceeds max supply
    if (_reserveSupply > maxSupply) revert ReserveSupplyExceedsMaxSupply(_reserveSupply, maxSupply);

    groups[groupId] = Group(_name, groupId, _startTime, _endTime, _price, _reserveSupply);

    numGroups++;
  }

  // function validation hooks

  function _isGroupLive(uint256 _groupId) internal view returns (bool) {
    if (_groupId >= numGroups) return false;
    return block.timestamp >= groups[_groupId].startTime && (groups[_groupId].endTime == 0 || block.timestamp < groups[_groupId].endTime);
  }

  function _nonZeroAmount(uint256 _amount) internal pure {
    if (_amount < 1) revert ZeroAmount();
  }

  function _validGroup(uint256 _groupId) internal view {
    if (_groupId >= numGroups) revert GroupDoesNotExist(_groupId);
  }

  function _groupAllowed(uint256 _group) internal view {
    if (!_isGroupLive(_group)) revert GroupNotLive(_group);
  }

  function _validPrice(uint256 _amount, uint256 _groupId) internal view {
    if (msg.value < _amount * groups[_groupId].price) revert InsufficientFunds();
  }

  function _validSupply(uint256 _amount) internal view {
    if (_amount > _remainingSupply()) revert MaxSupplyExceeded();
  }

  function _validAllowance(address _receiver, uint256 _amount) internal view {
    if (addressTotalSupply[_receiver] + _amount > maxPerAddress) revert MaxPerAddressExceeded(_receiver, _amount);
  }

  function _validGroupPriceSupplyAllowance(address _receiver, uint256 _amount, uint256 _groupId) internal view virtual {
    _groupAllowed(_groupId);
    _validPrice(_amount, _groupId);
    _validSupply(_amount);
    _validAllowance(_receiver, _amount);
  }

  function _validGroupPriceSupply(uint256 _amount, uint256 _groupId) internal view virtual {
    _groupAllowed(_groupId);
    _validPrice(_amount, _groupId);
    _validSupply(_amount);
  }

  // helpers

  /// @dev Withdraws the funds to wild and artist wallets acconting for royalty fees. Only callable by owner.
  function _withdraw() internal virtual {
    // send a fraction of the balance to wild first
    if (wildRoyalty > 0) {
      (bool successWild, ) = wildWallet.call{value: ((address(this).balance * wildRoyalty) / royaltyTotal)}('');
      if (!successWild) revert FailedToWithdraw('wild', wildWallet);
    }

    // then, send the rest to payee
    (bool successPayee, ) = artistWallet.call{value: address(this).balance}('');
    if (!successPayee) revert FailedToWithdraw('artist', artistWallet);
  }

  /// @dev Implemented in child contracts to hold total supply logic.
  function _totalSupply() internal view virtual returns (uint256) {}

  /// @dev Returns adjusted maxSupply for reserve quantities.
  function _remainingSupply() internal view virtual returns (uint256) {
    if (groups[0].reserveSupply == 0 || groups[0].reserveSupply == maxSupply) return maxSupply - _totalSupply();

    uint256 _currentGroupId; // get the last group that is live based on start time
    for (uint256 i = 0; i < numGroups; i++) {
      if (block.timestamp >= groups[i].startTime) {
        _currentGroupId = i;
      }
    }

    uint256 cumulativeReserveSupply = 0; // including current _currentGroupId

    if (_currentGroupId == numGroups - 1) {
      return maxSupply - _totalSupply();
    } else {
      for (uint256 i = 0; i <= _currentGroupId; i++) {
        cumulativeReserveSupply += groups[i].reserveSupply;
      }
      cumulativeReserveSupply = Math.min(maxSupply, cumulativeReserveSupply);
    }

    return cumulativeReserveSupply - _totalSupply();
  }

  function _addAddressTotalSupply(address _receiver, uint256 _amount) internal {
    addressTotalSupply[_receiver] += _amount;
  }

  function _getGroupsArray() internal view virtual returns (Group[] memory _groups) {
    _groups = new Group[](numGroups);
    for (uint256 i = 0; i < numGroups; i++) {
      _groups[i] = groups[i];
    }
  }

  // public admin-only functions

  /** @notice Pause the minter.
   * @dev Sets the minter state to Paused and pauses the minter and any mint functions. Only callable by admin.
   */
  function pause() public virtual onlyAdmin {
    _pause();
  }

  /** @notice Unpause the minter.
   * @dev Resumes normal minter state and any mint functions. Only callable by admin.
   */
  function unpause() public virtual onlyAdmin {
    _unpause();
  }

  /** @notice Sets the DelegateCash contract address.
   * @dev Can only be called by the contract admin.
   * @param _delegationRegistry The new delegation registry contract address.
   */
  function setDelegationRegistry(address _delegationRegistry) external onlyAdmin {
    delegationRegistry = IDelegationRegistry(_delegationRegistry);
  }

  /** @notice Sets the max per address.
   * @dev Sets the given max per address. Only callable by admin.
   * @param _maxPerAddress The new max per address.
   */
  function setMaxPerAddress(uint256 _maxPerAddress) public onlyAdmin {
    maxPerAddress = _maxPerAddress;
  }

  /** @notice Sets the group price.
   * @dev Sets the given group price. Only callable by admin.
   * @param _groupId The group ID. Must be a valid group ID.
   * @param _price The new price of the group. Must be non-zero.
   */
  function setGroupPrice(uint256 _groupId, uint256 _price) public virtual validGroup(_groupId) nonZeroAmount(_price) onlyAdmin {
    groups[_groupId].price = _price;
  }

  /** @notice Sets the group start time.
   * @dev Sets the given group start time. Only callable by admin.
   * @param _groupId The group ID. Must be a valid group ID.
   * @param _startTime The new start time of the group.
   */
  function setGroupStartTime(uint256 _groupId, uint256 _startTime) public virtual validGroup(_groupId) onlyAdmin {
    groups[_groupId].startTime = _startTime;
  }

  /** @notice Sets the group end time.
   * @dev Sets the given group end time. Only callable by admin.
   * @param _groupId The group ID. Must be a valid group ID.
   * @param _endTime The new end time of the group.
   */
  function setGroupEndTime(uint256 _groupId, uint256 _endTime) public virtual validGroup(_groupId) onlyAdmin {
    groups[_groupId].endTime = _endTime;
  }

  function setGroupName(uint256 _groupId, string memory _name) public virtual validGroup(_groupId) onlyAdmin {
    groups[_groupId].name = _name;
  }

  // public only-owner functions

  /** @notice Withdraws funds to wild and artist wallets.
   * @dev Withdraws the funds to wild and artist wallets acconting for royalty fees. Only callable by owner.
   */
  function withdraw() public virtual onlyOwner {
    _withdraw();
  }

  // public functions

  /** @notice Get the current minter state.
   * @dev Returns the current minter state. If groups are not directly one after another (ie presale), it is possible to re-enter Setup state.
   * @return state Minter state (0 = Setup, 1 = Live, 2 = Complete, 3 = Paused).
   */
  function getState() public view virtual returns (State) {
    if (paused()) {
      return State.Paused;
    }

    // if sold out, return Complete state
    // NOTE: this would not work with a ReserveAuction where this minter holds the token!!!!
    if (_totalSupply() == maxSupply) {
      return State.Complete;
    }

    bool allGroupsEnded = true;

    // check if we are in any group using _isGroupLive
    // if we are in a group, return Live state
    // note: if groups are not directly one after another (ie presale), it is possible to re-enter Setup state
    for (uint256 groupId = 0; groupId < numGroups; groupId++) {
      if (_isGroupLive(groupId)) {
        return State.Live;
      }

      if (groups[groupId].endTime == 0 || block.timestamp < groups[groupId].endTime) {
        allGroupsEnded = false;
      }
    }

    if (allGroupsEnded) {
      return State.Complete;
    } else {
      return State.Setup;
    }
  }

  function getUserGroup(address _user, bytes memory _signature) public view virtual returns (uint256) {}

  // returns user allowance: Y
  function getUserGroupAllowance(address _user, uint256 /*_groupId*/) public view virtual returns (uint256) {
    uint256 supplyRemaining = _remainingSupply();
    if (supplyRemaining == 0) {
      return 0;
    }

    // Y = R (R = maxPerAddress)
    return Math.min(maxPerAddress - addressTotalSupply[_user], supplyRemaining);
  }

  function getUserGroupTotalSupply(address _user, uint256 /*_groupId*/) public view virtual returns (uint256) {
    return addressTotalSupply[_user];
  }

  function getGroups() public view returns (Group[] memory _groups) {
    _groups = new Group[](numGroups);
    for (uint256 i = 0; i < numGroups; i++) {
      _groups[i] = groups[i];
    }
  }

  function getGroup(uint256 _groupId) public view validGroup(_groupId) returns (Group memory) {
    return groups[_groupId];
  }

  function getGroupStartTime(uint256 _groupId) public view validGroup(_groupId) returns (uint256) {
    return groups[_groupId].startTime;
  }

  function getGroupEndTime(uint256 _groupId) public view validGroup(_groupId) returns (uint256) {
    return groups[_groupId].endTime;
  }

  function getGroupPrice(uint256 _groupId) public view validGroup(_groupId) returns (uint256) {
    return groups[_groupId].price;
  }

  // generic deposit

  receive() external payable {}
}
