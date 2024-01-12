//SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "./draft-ERC20Permit.sol";
import "./SafeERC20.sol";
import "./ERC20.sol";
import "./CitizenAlpha.sol";
import "./ObservationLib.sol";
import "./TwabLib.sol";
import "./ExtendedSafeCastLib.sol";

/**
 * @title TrustToken
 * @author Kames Geraghty
 * @notice TrustToken is a Web3 of Trust experiment: implementing time-weighted average balances.
           Credit: PoolTogether Inc (Brendan Asselstine)
 */
contract TrustToken is ERC20Permit {
  using SafeERC20 for IERC20;
  using ExtendedSafeCastLib for uint256;
  CitizenAlpha private citizenAlpha;
  uint256 private distribution = 10000e18;
  mapping(address => bool) private _claimed;

  bytes32 private immutable _DELEGATE_TYPEHASH =
    keccak256("Delegate(address user,address delegate,uint256 nonce,uint256 deadline)");

  /// @notice Record of token holders TWABs for each account.
  mapping(address => TwabLib.Account) internal userTwabs;

  /// @notice Record of tickets total supply and ring buff parameters used for observation.
  TwabLib.Account internal totalSupplyTwab;

  /// @notice Mapping of delegates.  Each address can delegate their ticket power to another.
  mapping(address => address) internal delegates;

  /**
   * @notice Emitted when TWAB balance has been delegated to another user.
   * @param delegator Address of the delegator.
   * @param delegate Address of the delegate.
   */
  event Delegated(address indexed delegator, address indexed delegate);

  /**
   * @notice Emitted when a new TWAB has been recorded.
   * @param delegate The recipient of the ticket power (may be the same as the user).
   * @param newTwab Updated TWAB of a ticket holder after a successful TWAB recording.
   */
  event NewUserTwab(address indexed delegate, ObservationLib.Observation newTwab);

  /**
   * @notice Emitted when a new total supply TWAB has been recorded.
   * @param newTotalSupplyTwab Updated TWAB of tickets total supply after a successful total supply TWAB recording.
   */
  event NewTotalSupplyTwab(ObservationLib.Observation newTotalSupplyTwab);

  constructor(
    CitizenAlpha citizenAlpha_,
    string memory name,
    string memory symbol
  ) ERC20Permit("Web3Citizen TrustToken") ERC20(name, symbol) {
    citizenAlpha = citizenAlpha_;
  }

  /* ===================================================================================== */
  /* External Functions                                                                    */
  /* ===================================================================================== */

  function claim() external {
    require(citizenAlpha.isCitizen(msg.sender), "TrustToken:not-trusted");
    require(!_claimed[msg.sender], "TrustToken:trust-previously-issued");
    _claimed[msg.sender] = true;
    _mint(msg.sender, distribution);
  }

  function getAccountDetails(address _user) external view returns (TwabLib.AccountDetails memory) {
    return userTwabs[_user].details;
  }

  function getTwab(address _user, uint16 _index)
    external
    view
    returns (ObservationLib.Observation memory)
  {
    return userTwabs[_user].twabs[_index];
  }

  function getBalanceAt(address _user, uint64 _target) external view returns (uint256) {
    TwabLib.Account storage account = userTwabs[_user];

    return
      TwabLib.getBalanceAt(
        account.twabs,
        account.details,
        uint32(_target),
        uint32(block.timestamp)
      );
  }

  function getAverageBalancesBetween(
    address _user,
    uint64[] calldata _startTimes,
    uint64[] calldata _endTimes
  ) external view returns (uint256[] memory) {
    return _getAverageBalancesBetween(userTwabs[_user], _startTimes, _endTimes);
  }

  function getAverageTotalSuppliesBetween(
    uint64[] calldata _startTimes,
    uint64[] calldata _endTimes
  ) external view returns (uint256[] memory) {
    return _getAverageBalancesBetween(totalSupplyTwab, _startTimes, _endTimes);
  }

  function getAverageBalanceBetween(
    address _user,
    uint64 _startTime,
    uint64 _endTime
  ) external view returns (uint256) {
    TwabLib.Account storage account = userTwabs[_user];

    return
      TwabLib.getAverageBalanceBetween(
        account.twabs,
        account.details,
        uint32(_startTime),
        uint32(_endTime),
        uint32(block.timestamp)
      );
  }

  function getBalancesAt(address _user, uint64[] calldata _targets)
    external
    view
    returns (uint256[] memory)
  {
    uint256 length = _targets.length;
    uint256[] memory _balances = new uint256[](length);

    TwabLib.Account storage twabContext = userTwabs[_user];
    TwabLib.AccountDetails memory details = twabContext.details;

    for (uint256 i = 0; i < length; i++) {
      _balances[i] = TwabLib.getBalanceAt(
        twabContext.twabs,
        details,
        uint32(_targets[i]),
        uint32(block.timestamp)
      );
    }

    return _balances;
  }

  function getTotalSupplyAt(uint64 _target) external view returns (uint256) {
    return
      TwabLib.getBalanceAt(
        totalSupplyTwab.twabs,
        totalSupplyTwab.details,
        uint32(_target),
        uint32(block.timestamp)
      );
  }

  function getTotalSuppliesAt(uint64[] calldata _targets) external view returns (uint256[] memory) {
    uint256 length = _targets.length;
    uint256[] memory totalSupplies = new uint256[](length);

    TwabLib.AccountDetails memory details = totalSupplyTwab.details;

    for (uint256 i = 0; i < length; i++) {
      totalSupplies[i] = TwabLib.getBalanceAt(
        totalSupplyTwab.twabs,
        details,
        uint32(_targets[i]),
        uint32(block.timestamp)
      );
    }

    return totalSupplies;
  }

  function delegateOf(address _user) external view returns (address) {
    return delegates[_user];
  }

  function delegateWithSignature(
    address _user,
    address _newDelegate,
    uint256 _deadline,
    uint8 _v,
    bytes32 _r,
    bytes32 _s
  ) external virtual {
    require(block.timestamp <= _deadline, "Ticket/delegate-expired-deadline");

    bytes32 structHash = keccak256(
      abi.encode(_DELEGATE_TYPEHASH, _user, _newDelegate, _useNonce(_user), _deadline)
    );

    bytes32 hash = _hashTypedDataV4(structHash);

    address signer = ECDSA.recover(hash, _v, _r, _s);
    require(signer == _user, "Ticket/delegate-invalid-signature");

    _delegate(_user, _newDelegate);
  }

  function delegate(address _to) external virtual {
    _delegate(msg.sender, _to);
  }

  /* ===================================================================================== */
  /* External Functions                                                                    */
  /* ===================================================================================== */

  /// @notice Delegates a users chance to another
  /// @param _user The user whose balance should be delegated
  /// @param _to The delegate
  function _delegate(address _user, address _to) internal {
    uint256 balance = balanceOf(_user);
    address currentDelegate = delegates[_user];

    if (currentDelegate == _to) {
      return;
    }

    delegates[_user] = _to;

    _transferTwab(currentDelegate, _to, balance);

    emit Delegated(_user, _to);
  }

  /**
   * @notice Retrieves the average balances held by a user for a given time frame.
   * @param _account The user whose balance is checked.
   * @param _startTimes The start time of the time frame.
   * @param _endTimes The end time of the time frame.
   * @return The average balance that the user held during the time frame.
   */
  function _getAverageBalancesBetween(
    TwabLib.Account storage _account,
    uint64[] calldata _startTimes,
    uint64[] calldata _endTimes
  ) internal view returns (uint256[] memory) {
    uint256 startTimesLength = _startTimes.length;
    require(startTimesLength == _endTimes.length, "Ticket/start-end-times-length-match");

    TwabLib.AccountDetails memory accountDetails = _account.details;

    uint256[] memory averageBalances = new uint256[](startTimesLength);
    uint32 currentTimestamp = uint32(block.timestamp);

    for (uint256 i = 0; i < startTimesLength; i++) {
      averageBalances[i] = TwabLib.getAverageBalanceBetween(
        _account.twabs,
        accountDetails,
        uint32(_startTimes[i]),
        uint32(_endTimes[i]),
        currentTimestamp
      );
    }

    return averageBalances;
  }

  /// @notice Transfers the given TWAB balance from one user to another
  /// @param _from The user to transfer the balance from.  May be zero in the event of a mint.
  /// @param _to The user to transfer the balance to.  May be zero in the event of a burn.
  /// @param _amount The balance that is being transferred.
  function _transferTwab(
    address _from,
    address _to,
    uint256 _amount
  ) internal {
    // If we are transferring tokens from a delegated account to an undelegated account
    if (_from != address(0)) {
      _decreaseUserTwab(_from, _amount);

      if (_to == address(0)) {
        _decreaseTotalSupplyTwab(_amount);
      }
    }

    // If we are transferring tokens from an undelegated account to a delegated account
    if (_to != address(0)) {
      _increaseUserTwab(_to, _amount);

      if (_from == address(0)) {
        _increaseTotalSupplyTwab(_amount);
      }
    }
  }

  /**
   * @notice Increase `_to` TWAB balance.
   * @param _to Address of the delegate.
   * @param _amount Amount of tokens to be added to `_to` TWAB balance.
   */
  function _increaseUserTwab(address _to, uint256 _amount) internal {
    if (_amount == 0) {
      return;
    }

    TwabLib.Account storage _account = userTwabs[_to];

    (
      TwabLib.AccountDetails memory accountDetails,
      ObservationLib.Observation memory twab,
      bool isNew
    ) = TwabLib.increaseBalance(_account, _amount.toUint208(), uint32(block.timestamp));

    _account.details = accountDetails;

    if (isNew) {
      emit NewUserTwab(_to, twab);
    }
  }

  /**
   * @notice Decrease `_to` TWAB balance.
   * @param _to Address of the delegate.
   * @param _amount Amount of tokens to be added to `_to` TWAB balance.
   */
  function _decreaseUserTwab(address _to, uint256 _amount) internal {
    if (_amount == 0) {
      return;
    }

    TwabLib.Account storage _account = userTwabs[_to];

    (
      TwabLib.AccountDetails memory accountDetails,
      ObservationLib.Observation memory twab,
      bool isNew
    ) = TwabLib.decreaseBalance(
        _account,
        _amount.toUint208(),
        "Ticket/twab-burn-lt-balance",
        uint32(block.timestamp)
      );

    _account.details = accountDetails;

    if (isNew) {
      emit NewUserTwab(_to, twab);
    }
  }

  /// @notice Decreases the total supply twab.  Should be called anytime a balance moves from delegated to undelegated
  /// @param _amount The amount to decrease the total by
  function _decreaseTotalSupplyTwab(uint256 _amount) internal {
    if (_amount == 0) {
      return;
    }

    (
      TwabLib.AccountDetails memory accountDetails,
      ObservationLib.Observation memory tsTwab,
      bool tsIsNew
    ) = TwabLib.decreaseBalance(
        totalSupplyTwab,
        _amount.toUint208(),
        "Ticket/burn-amount-exceeds-total-supply-twab",
        uint32(block.timestamp)
      );

    totalSupplyTwab.details = accountDetails;

    if (tsIsNew) {
      emit NewTotalSupplyTwab(tsTwab);
    }
  }

  /// @notice Increases the total supply twab.  Should be called anytime a balance moves from undelegated to delegated
  /// @param _amount The amount to increase the total by
  function _increaseTotalSupplyTwab(uint256 _amount) internal {
    if (_amount == 0) {
      return;
    }

    (
      TwabLib.AccountDetails memory accountDetails,
      ObservationLib.Observation memory _totalSupply,
      bool tsIsNew
    ) = TwabLib.increaseBalance(totalSupplyTwab, _amount.toUint208(), uint32(block.timestamp));

    totalSupplyTwab.details = accountDetails;

    if (tsIsNew) {
      emit NewTotalSupplyTwab(_totalSupply);
    }
  }

  // @inheritdoc ERC20
  function _beforeTokenTransfer(
    address _from,
    address _to,
    uint256 _amount
  ) internal override {
    if (_from == _to) {
      return;
    }

    address _fromDelegate;
    if (_from != address(0)) {
      _fromDelegate = delegates[_from];
    }

    address _toDelegate;
    if (_to != address(0)) {
      _toDelegate = delegates[_to];
    }

    _transferTwab(_fromDelegate, _toDelegate, _amount);
  }
}
