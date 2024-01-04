//SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./AccessControl.sol";
import "./SafeMath.sol";
import "./IERC20.sol";


/**
 * @title Multiplier
 * @dev This contract handles spendable and global token effects on contracts like farming pools.
 *
 * Default numeric values used for percentage calculations should be divided by 1000.
 * If the default value for amount in SpendableInfo is 20, it's meant to represeent 2% (i * amount / 1000)
 *
 */

contract Multiplier is AccessControlUpgradeSafe {
  using SafeMath for uint256;
  bytes32 public constant MODIFIER_ROLE = keccak256("MODIFIER_ROLE");

  struct SpendableInfo {
    uint256 amount;
    uint256 cost;
    bytes32 data;
  }

  // Contract -> User -> Vault -> Epoch -> Total Level (just total level bookkeeping);
  mapping(address => mapping(address => mapping(uint256 => mapping(uint256 => uint256)))) public userTotalLevel;

  // Contract -> User -> Token -> Vault -> Epoch -> Level -> (Last purchased level for particular token in particular Contract
  mapping(address => mapping(address => mapping(address => mapping(uint256 => mapping(uint256 => uint256)))))
    public userLastLevelForTokenInContract;

  // Contract -> Vault -> Token -> Spendable amount, value and it's cost
  mapping(address => mapping(uint256 => mapping(address => SpendableInfo[]))) public spendableInfos;

  // Contract -> Vault -> Tokens-array (what tokens are used in this particular contract)
  mapping(address => mapping(uint256 => address[])) public spendableTokensPerContract;
  mapping(address => uint256) public spendableTokenCountPerContract;

  // Contract -> User -> Token -> Vault -> Epoch -> AmountSpent (who much user has spent a particular token in this particular contract)
  mapping(address => mapping(address => mapping(address => mapping(uint256 => mapping(uint256 => uint256))))) public spentTokensPerContract;

  // Contract -> User -> Vault -> Epoch -> Value from spendables (total spendable multiplier for an user in a Contract)
  mapping(address => mapping(address => mapping(uint256 => mapping(uint256 => uint256)))) public userValueFromSpending;

  /** @dev A regular initializer due proxy usage */
  function initialize() external initializer {
    __AccessControl_init();
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    _setupRole(MODIFIER_ROLE, _msgSender());
  }

  /******************** FUNCIONALITY */
  /** @dev Keep track of user purchase amounts */
  function purchase(
    address _contract,
    address _user,
    address _token,
    uint256 _newLevel,
    uint256 _epoch,
    uint256 _pid
  ) external {
    require(hasRole(MODIFIER_ROLE, _msgSender()) || hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Slaps! Bad caller.");

    // Cost of the NEW level being purchased
    uint256 cost = getSpendableCostPerTokenForUser(_contract, _user, _token, _newLevel, _epoch, _pid);

    // Get the old amount gained from spendables
    uint256 oldTotalValueFromSpending = userValueFromSpending[_contract][_user][_pid][_epoch];
    uint256 lastLevel = userLastLevelForTokenInContract[_contract][_user][_token][_pid][_epoch];

    uint256 lastLevelValueFromSpending = spendableInfos[_contract][_pid][_token][lastLevel].amount;

    // Add the new amount
    userValueFromSpending[_contract][_user][_pid][_epoch] = spendableInfos[_contract][_pid][_token][_newLevel]
      .amount
      .sub(lastLevelValueFromSpending)
      .add(oldTotalValueFromSpending);

    // Add spent for this particular pool and token
    spentTokensPerContract[_contract][_user][_token][_pid][_epoch] = spentTokensPerContract[_contract][_user][_token][_pid][_epoch].add(
      cost
    );

    // Bookkeeping for total level
    userTotalLevel[_contract][_user][_pid][_epoch] = userTotalLevel[_contract][_user][_pid][_epoch].add(_newLevel.sub(lastLevel));
    userLastLevelForTokenInContract[_contract][_user][_token][_pid][_epoch] = _newLevel;
  }

  /** @dev This function sets the tokens and their corresponding spendable amount info for a pool. */
  function addSpendableTokenForContract(
    address _contract,
    uint256 _pid,
    address _spendableToken,
    SpendableInfo[] memory _spendableInfos
  ) external {
    require(hasRole(MODIFIER_ROLE, _msgSender()) || hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Slaps! Bad caller.");

    // Set the spendables used
    spendableTokensPerContract[_contract][_pid].push(_spendableToken);
    spendableTokenCountPerContract[_contract]++;

    delete spendableInfos[_contract][_pid][_spendableToken];

    // Set the level prices
    for (uint256 i; i < _spendableInfos.length; i++) {
      spendableInfos[_contract][_pid][_spendableToken].push(
        SpendableInfo({ amount: _spendableInfos[i].amount, cost: _spendableInfos[i].cost, data: _spendableInfos[i].data })
      );
    }
  }

  function removeSpendableTokenFromContract(
    address _contract,
    address _spendableToken,
    uint256 _pid
  ) external {
    require(hasRole(MODIFIER_ROLE, _msgSender()) || hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Slaps! Bad caller.");
    for (uint256 i; i < spendableTokensPerContract[_contract][_pid].length; i++) {
      if (spendableTokensPerContract[_contract][_pid][i] == _spendableToken) {
        delete spendableTokensPerContract[_contract][_pid][i];
      }
    }
    spendableTokenCountPerContract[_contract]--;
  }

  /******************** VIEWS */

  /** @dev Cheeck if the token supplied is actually used in the contract */
  function isSpendableTokenInContract(
    address _contract,
    address _token,
    uint256 _pid
  ) external view returns (bool) {
    bool result;
    for (uint256 i; i < spendableTokensPerContract[_contract][_pid].length; i++) {
      if (!result) {
        result = spendableTokensPerContract[_contract][_pid][i] == _token;
      } else break;
    }
    return result;
  }

  /** @dev For ease of access supply a view for a particular tokens latest level for a particular user in a contract */
  function getLastTokenLevelForUser(
    address _contract,
    address _user,
    address _token,
    uint256 _epoch,
    uint256 _pid
  ) external view returns (uint256) {
    return userLastLevelForTokenInContract[_contract][_user][_token][_pid][_epoch];
  }

  /** @dev Return the sum of all spendable levels */
  function getTotalLevel(
    address _contract,
    address _user,
    uint256 _epoch,
    uint256 _pid
  ) external view returns (uint256) {
    return userTotalLevel[_contract][_user][_pid][_epoch];
  }

  /** @dev Get particular tokens spent per particular contract and user */
  function getTokensSpentPerContract(
    address _contract,
    address _token,
    address _user,
    uint256 _epoch,
    uint256 _pid
  ) external view returns (uint256) {
    return spentTokensPerContract[_contract][_user][_token][_pid][_epoch];
  }

  /** @dev Get the level cost for particulart token in a particular contract */
  function getSpendableCostPerTokenForUser(
    address _contract,
    address _user,
    address _token,
    uint256 _level,
    uint256 _epoch,
    uint256 _pid
  ) public view returns (uint256) {
    uint256 spent = spentTokensPerContract[_contract][_user][_token][_pid][_epoch];
    uint256 cost = spendableInfos[_contract][_pid][_token][_level].cost;

    uint256 discount;
    if (userDiscount[_user][_epoch] > 0) {
      discount = userDiscount[_user][_epoch];
    } else if (discountEpoch[_epoch - 1] > 0 && userValueFromSpending[_contract][_user][_pid][_epoch - 1] > 0) {
      discount = discountEpoch[_epoch - 1];
    }
    if (discount > 0) {
      cost = cost.sub(cost.mul(discount).div(1000));
      if (spent > cost) return 0;
    }
    return cost.sub(spent);
  }

  /** @dev Get the total value for user in a pool, accounting for global */
  function getTotalValueForUser(
    address _contract,
    address _user,
    uint256 _epoch,
    uint256 _pid
  ) external view returns (uint256) {
    return userValueFromSpending[_contract][_user][_pid][_epoch];
  }

  mapping(uint256 => uint256) public discountEpoch;
  mapping(address => mapping(uint256 => uint256)) public userDiscount;

  function setDiscountForAccount(
    uint256 _epoch,
    uint256 _amt,
    address _account
  ) external {
    require(hasRole(MODIFIER_ROLE, _msgSender()) || hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Slaps! Bad caller.");
    userDiscount[_account][_epoch] = _amt;
  }

  function setDiscountEpoch(uint256 _epoch, uint256 _amt) external {
    require(hasRole(MODIFIER_ROLE, _msgSender()) || hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Slaps! Bad caller.");
    discountEpoch[_epoch] = _amt;
  }
}
