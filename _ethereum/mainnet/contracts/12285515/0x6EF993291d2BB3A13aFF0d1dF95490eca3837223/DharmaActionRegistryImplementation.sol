// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 *
 * In order to transfer ownership, a recipient must be specified, at which point
 * the specified recipient can call `acceptOwnership` and take ownership.
 */

contract TwoStepOwnable {
  address private _owner;

  address private _newPotentialOwner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
   * @dev Initialize contract by setting transaction submitter as initial owner.
   */
  constructor() {
    _setOwner(tx.origin);
  }

  /**
   * @dev Sets account as owner
   */
  function _setOwner(address account) internal {
    _owner = account;
    emit OwnershipTransferred(address(0), account);
  }

  /**
   * @dev Returns the address of the current owner.
   */
  function owner() public view returns (address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(isOwner(), "TwoStepOwnable: caller is not the owner.");
    _;
  }

  /**
   * @dev Returns true if the caller is the current owner.
   */
  function isOwner() public view returns (bool) {
    return msg.sender == _owner;
  }

  /**
   * @dev Allows a new account (`newOwner`) to accept ownership.
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(
      newOwner != address(0),
      "TwoStepOwnable: new potential owner is the zero address."
    );

    _newPotentialOwner = newOwner;
  }

  /**
   * @dev Cancel a transfer of ownership to a new account.
   * Can only be called by the current owner.
   */
  function cancelOwnershipTransfer() public onlyOwner {
    delete _newPotentialOwner;
  }

  /**
   * @dev Transfers ownership of the contract to the caller.
   * Can only be called by a new potential owner set by the current owner.
   */
  function acceptOwnership() public {
    require(
      msg.sender == _newPotentialOwner,
      "TwoStepOwnable: current owner must set caller as new potential owner."
    );

    delete _newPotentialOwner;

    emit OwnershipTransferred(_owner, msg.sender);

    _owner = msg.sender;
  }

  /**
   * @dev Transfers ownership of the contract to the null account, thereby
   * preventing it from being used to perform upgrades in the future. This
   * function may only be called by the owner of this contract.
   */
  function renounceOwnership() external onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }
}

interface ITypes {
  struct Call {
    address to;
    uint96 value;
    bytes data;
  }

  struct CallReturn {
    bool ok;
    bytes returnData;
  }
}

interface IDharmaActionRegistry {

  // events
  event AddedSelector(address account, bytes4 selector);
  event RemovedSelector(address account, bytes4 selector);
  event AddedSpender(address account, address spender);
  event RemovedSpender(address account, address spender);
  event AddedAllTokensApprovalAccount(address account);
  event RemovedAllTokensApprovalAccount(address account);

  struct AccountSelectors {
    address account;
    bytes4[] selectors;
  }

  struct AccountSpenders {
    address account;
    address[] spenders;
  }

  function isValidAction(ITypes.Call[] calldata calls) external view returns (bool valid);
  function addSelector(address account, bytes4 selector) external;
  function removeSelector(address account, bytes4 selector) external;
  function addSpender(address account, address spender) external;
  function removeSpender(address account, address spender) external;
  function addSpenderWithApprovalForAllTokens(address spender) external;
  function removeSpenderWithApprovalForAllTokens(address spender) external;
  function getVersion() external pure returns (uint256 version);
}

interface IERC20 {
  function approve(address spender, uint256 amount) external returns (bool);
}

/**
 * @title DharmaActionRegistry
 * @author cf
 * @notice This contracts implements the logic to determine if a Dharma "action" is valid i.e.
 * it's execution should be allowed in the Dharma Trade Reserve contract. The contract maintains a
 * collection of allowed function selectors and approved spenders to determine validity.
 */
contract DharmaActionRegistryImplementation is IDharmaActionRegistry, TwoStepOwnable {

  uint256 private constant _VERSION = 1;

  // Map storing the allowed function selectors by account
  mapping(address => bytes4[]) internal _functionSelectors;
  mapping(address => mapping(bytes4 => uint256)) public _functionSelectorIndices;

  // Map storing the allowed spenders selectors by account
  mapping(address => address[]) internal _accountSpenders;
  mapping(address => mapping(address => uint256)) public _spenderIndices;

  // Map storing the spenders that have approval for all tokens
  address[] internal _allTokensApprovalAccounts;
  mapping (address => uint256) private _allTokensApprovalAccountIndices;

  /**
   * @dev Only called from the proxy contract during deployment
   */
  function initialize() external {
    // Ensure that this function is only callable during contract construction.
    assembly { if extcodesize(address()) { revert(0, 0) } }

    _setOwner(tx.origin);
  }

  /**
   * @notice implementation version
   */
  function getVersion() external pure override returns (uint256 version) {
    version = _VERSION;
  }

  /**
   * @notice Check if each call of the calls array is valid. Exit early if an invalid call is detected.
   */
  function isValidAction(
    ITypes.Call[] calldata calls
  ) external override view returns (bool valid) {
    valid = true;
    for (uint256 i = 0; i < calls.length; i++) {

      valid = _validCall(calls[i].to, calls[i].data);

      if (!valid) {
        break;
      }
    }
  }

  /**
   * @dev Determine if a call is valid with the following criteria:
   *  - the function-selector is "approve" and target spender can be granted approval for all tokens
   *  - the function-selector is "approve" and the spender is granted approval for a specific token
   *  - the function-selector is not "approve" and it is allowed
   */
  function _validCall(address to, bytes calldata callData) internal view returns (bool) {
    if (callData.length < 4) {
      return false;
    }

    bytes memory functionSelectorBytes = abi.encodePacked(callData[:4], bytes28(0));
    bytes4 functionSelector = abi.decode(functionSelectorBytes, (bytes4));

    if (functionSelector == IERC20.approve.selector) {
      // check if spender has been granted approval

      bytes memory argumentBytes = abi.encodePacked(callData[4:], bytes28(0));

      if (argumentBytes.length < 68) {
        return false;
      }

      (address spender,) = abi.decode(argumentBytes, (address, uint256));

      // spender has been grated approval for all tokens
      if (_allTokensApprovalAccountIndices[spender] != 0) {
        return true;
      }

      // spender has been grated approval for a specific token
      uint256 spenderIndex = _spenderIndices[to][spender];

      if (spenderIndex != 0) {
        return true;
      }
    } else {
      // check if function selector is allowed
      uint256 functionSelectorIndex = _functionSelectorIndices[to][functionSelector];
      if (functionSelectorIndex != 0) {
        return true;
      }
    }

    return false;
  }

  /**
   * @notice Get account selectors by account
   */
  function getAccountSelectors(address account) public view returns (bytes4[] memory selectors) {
    selectors = _functionSelectors[account];
  }

  /**
   * @notice Get spenders by account
   */
  function getAccountSpenders(address account) public view returns (address[] memory spenders) {
    spenders = _accountSpenders[account];
  }

  /**
   * @notice Get all account spenders with approval for all tokens
   */
  function getAccountSpendersWithAllTokensApproval() public view returns (address[] memory accounts) {
    accounts = _allTokensApprovalAccounts;
  }

  /**
   * @notice Add function selector by account
   */
  function addSelector(address account, bytes4 selector) external override onlyOwner {
    _addSelector(account, selector);
  }

  /**
   * @notice Remove function selector by account
   */
  function removeSelector(address account, bytes4 selector) external override onlyOwner {
    _removeSelector(account, selector);
  }

  /**
   * @notice Add approved spender by account
   */
  function addSpender(address account, address spender) external override onlyOwner {
    _addSpender(account, spender);
  }

  /**
   * @notice Remove approved spender by account
   */
  function removeSpender(address account, address spender) external override onlyOwner {
    _removeSpender(account, spender);
  }

  /**
   * @notice Add spender with approval for all tokens
   */
  function addSpenderWithApprovalForAllTokens(address spender) external override onlyOwner {
    _addAllTokensApproval(spender);
  }

  /**
   * @notice Remove spender with approval for all tokens
   */
  function removeSpenderWithApprovalForAllTokens(address spender) external override onlyOwner {
    _removeAllTokensApproval(spender);
  }

  /**
   * @notice Get count of spenders approval for all tokens
   */
  function getSpendersWithApprovalForAllTokensCount() public view returns (uint256 count) {
    count = _allTokensApprovalAccounts.length;
  }

  /**
   * @notice Get spender with approval for all tokens by index
   */
  function getSpenderWithApprovalForAllTokensByIndex(uint256 index) public view returns (address spender) {
    spender = _allTokensApprovalAccounts[index];
  }

  /**
   * @notice Add selector and spenders by account
   */
  function addSelectorsAndSpenders(
    AccountSelectors[] memory accountSelectors,
    AccountSpenders[] memory accountSpenders
  ) public onlyOwner {
    _addAccountSelectors(accountSelectors);
    _addAccountSpenders(accountSpenders);
  }

  function _addAccountSelectors(AccountSelectors[] memory accountSelectors) public onlyOwner {
    for (uint256 i = 0; i < accountSelectors.length; i++) {
      for (uint256 j = 0; j < accountSelectors[i].selectors.length; j++) {
        _addSelector(accountSelectors[i].account, accountSelectors[i].selectors[j]);
      }
    }
  }

  function _addAccountSpenders(AccountSpenders[] memory accountSpenders) public onlyOwner {
    for (uint256 i = 0; i < accountSpenders.length; i++) {
      for (uint256 j = 0; j < accountSpenders[i].spenders.length; j++) {
        _addSpender(accountSpenders[i].account, accountSpenders[i].spenders[j]);
      }
    }
  }

  function _addSelector(address account, bytes4 selector) internal {
    require(
      _functionSelectorIndices[account][selector] == 0,
      "Selector for the provided account already exists."
    );

    _functionSelectors[account].push(selector);
    _functionSelectorIndices[account][selector] = _functionSelectors[account].length;

    emit AddedSelector(account, selector);
  }

  function _removeSelector(address account, bytes4 selector) internal {
    uint256 removedSelectorIndex = _functionSelectorIndices[account][selector];

    require(
      removedSelectorIndex != 0,
      "No selector found for the provided account."
    );

    // swap account to remove with the last one then pop from the array.
    bytes4 lastSelector = _functionSelectors[account][_functionSelectors[account].length - 1];
    _functionSelectors[account][removedSelectorIndex - 1] = lastSelector;
    _functionSelectorIndices[account][lastSelector] = removedSelectorIndex;
    _functionSelectors[account].pop();
    delete _functionSelectorIndices[account][selector];

    emit RemovedSelector(account, selector);
  }

  function _addSpender(address account, address spender) internal {
    require(
      _spenderIndices[account][spender] == 0,
      "Spender for the provided account already exists."
    );

    _accountSpenders[account].push(spender);
    _spenderIndices[account][spender] = _accountSpenders[account].length;

    emit AddedSpender(account, spender);
  }

  function _removeSpender(address account, address spender) internal {
    uint256 removedSpenderIndex = _spenderIndices[account][spender];

    require(
      removedSpenderIndex != 0,
      "No spender found for the provided account."
    );

    // swap account to remove with the last one then pop from the array.
    address lastSpender = _accountSpenders[account][_accountSpenders[account].length - 1];
    _accountSpenders[account][removedSpenderIndex - 1] = lastSpender;
    _spenderIndices[account][lastSpender] = removedSpenderIndex;
    _accountSpenders[account].pop();
    delete _spenderIndices[account][spender];

    emit RemovedSpender(account, spender);
  }

  function _addAllTokensApproval(address account) internal {
    require(
      _allTokensApprovalAccountIndices[account] == 0,
      "Account matching the provided account already exists."
    );
    _allTokensApprovalAccounts.push(account);
    _allTokensApprovalAccountIndices[account] = _allTokensApprovalAccounts.length;

    emit AddedAllTokensApprovalAccount(account);
  }

  function _removeAllTokensApproval(address account) internal {
    uint256 removedAccountIndex = _allTokensApprovalAccountIndices[account];
    require(
      removedAccountIndex != 0,
      "No account found matching the provided account."
    );

    // swap account to remove with the last one then pop from the array.
    address lastAccount = _allTokensApprovalAccounts[_allTokensApprovalAccounts.length - 1];
    _allTokensApprovalAccounts[removedAccountIndex - 1] = lastAccount;
    _allTokensApprovalAccountIndices[lastAccount] = removedAccountIndex;
    _allTokensApprovalAccounts.pop();
    delete _allTokensApprovalAccountIndices[account];

    emit RemovedAllTokensApprovalAccount(account);
  }
}