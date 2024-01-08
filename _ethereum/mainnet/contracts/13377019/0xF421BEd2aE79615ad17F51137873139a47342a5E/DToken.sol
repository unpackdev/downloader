// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

import "./Context.sol";

import "./WadRayMath.sol";
import "./Math.sol";

import "./IDToken.sol";
import "./IMoneyPool.sol";

/**
 * @title DToken
 * @notice The DToken balance of borrower is the amount of money that the borrower
 * would be required to repay and seize the collateralized asset bond token.
 *
 * @author Elysia
 **/
contract DToken is IDToken, Context {
  using WadRayMath for uint256;

  uint256 internal _totalAverageRealAssetBorrowRate;
  mapping(address => uint256) internal _userLastUpdateTimestamp;
  mapping(address => uint256) internal _userAverageRealAssetBorrowRate;
  uint256 internal _lastUpdateTimestamp;

  uint256 internal _totalSupply;
  mapping(address => uint256) internal _balances;

  string private _name;
  string private _symbol;

  IMoneyPool internal _moneyPool;
  address internal _underlyingAsset;

  constructor(
    IMoneyPool moneyPool,
    address underlyingAsset_,
    string memory name_,
    string memory symbol_
  ) {
    _moneyPool = moneyPool;
    _underlyingAsset = underlyingAsset_;

    _name = name_;
    _symbol = symbol_;
  }

  /**
   * @dev Returns the name of the token.
   */
  function name() public view virtual override returns (string memory) {
    return _name;
  }

  /**
   * @dev Returns the symbol of the token, usually a shorter version of the
   * name.
   */
  function symbol() public view virtual override returns (string memory) {
    return _symbol;
  }

  /**
   * @dev Returns the decimals of the token.
   */
  function decimals() public view virtual override returns (uint8) {
    return 18;
  }

  function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
    recipient;
    amount;
    require(false, 'DTokenTransferNotAllowed');
    return true;
  }

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) public virtual override returns (bool) {
    sender;
    recipient;
    amount;
    require(false, 'DTokenTransferFromNotAllowed');
    return true;
  }

  function allowance(address owner, address spender)
    public
    view
    virtual
    override
    returns (uint256)
  {
    owner;
    spender;
    require(false, 'DTokenAllowanceNotAllowed');
    return 0;
  }

  function approve(address spender, uint256 amount) public virtual override returns (bool) {
    spender;
    amount;
    require(false, 'DTokenApproveNotAllowed');
    return true;
  }

  /**
   * @dev Returns the average stable rate across all the stable rate debt
   * @return the average stable rate
   **/
  function getTotalAverageRealAssetBorrowRate() external view virtual override returns (uint256) {
    return _totalAverageRealAssetBorrowRate;
  }

  /**
   * @dev Returns the timestamp of the last account action
   * @return The last update timestamp
   **/
  function getUserLastUpdateTimestamp(address account)
    external
    view
    virtual
    override
    returns (uint256)
  {
    return _userLastUpdateTimestamp[account];
  }

  /**
   * @dev Returns the stable rate of the account
   * @param account The address of the account
   * @return The stable rate of account
   **/
  function getUserAverageRealAssetBorrowRate(address account)
    external
    view
    virtual
    override
    returns (uint256)
  {
    return _userAverageRealAssetBorrowRate[account];
  }

  /**
   * @dev Calculates the current account debt balance
   * @return The accumulated debt of the account
   **/
  function balanceOf(address account) public view virtual override returns (uint256) {
    uint256 accountBalance = _balances[account];
    uint256 stableRate = _userAverageRealAssetBorrowRate[account];

    // strict equality is not dangerous here
    // divide-before-multiply dangerous-strict-equalities
    if (accountBalance == 0) {
      return 0;
    }
    uint256 cumulatedInterest = Math.calculateCompoundedInterest(
      stableRate,
      _userLastUpdateTimestamp[account],
      block.timestamp
    );
    return accountBalance.rayMul(cumulatedInterest);
  }

  struct MintLocalVars {
    uint256 previousSupply;
    uint256 nextSupply;
    uint256 amountInRay;
    uint256 newStableRate;
    uint256 currentAvgStableRate;
  }

  /**
   * @dev Mints debt token to the `receiver` address.
   * -  Only callable by the LendingPool
   * - The resulting rate is the weighted average between the rate of the new debt
   * and the rate of the principal debt
   * @param account The address receiving the borrowed underlying, being the delegatee in case
   * of credit delegate, or same as `receiver` otherwise
   * @param receiver The address receiving the debt tokens
   * @param amount The amount of debt tokens to mint
   * @param rate The rate of the debt being minted
   **/
  function mint(
    address account,
    address receiver,
    uint256 amount,
    uint256 rate
  ) external override onlyMoneyPool {
    MintLocalVars memory vars;

    (, uint256 currentBalance, uint256 balanceIncrease) = _calculateBalanceIncrease(receiver);

    vars.previousSupply = totalSupply();
    vars.currentAvgStableRate = _totalAverageRealAssetBorrowRate;
    vars.nextSupply = _totalSupply = vars.previousSupply + amount;

    vars.amountInRay = amount.wadToRay();

    (, vars.newStableRate) = Math.calculateRateInIncreasingBalance(
      _userAverageRealAssetBorrowRate[receiver],
      currentBalance,
      amount,
      rate
    );

    _userAverageRealAssetBorrowRate[receiver] = vars.newStableRate;

    //solium-disable-next-line
    _lastUpdateTimestamp = _userLastUpdateTimestamp[receiver] = block.timestamp;

    // Calculates the updated average stable rate
    (, vars.currentAvgStableRate) = Math.calculateRateInIncreasingBalance(
      vars.currentAvgStableRate,
      vars.previousSupply,
      amount,
      rate
    );

    _totalAverageRealAssetBorrowRate = vars.currentAvgStableRate;

    _mint(receiver, amount + balanceIncrease);

    emit Transfer(address(0), receiver, amount);

    emit Mint(
      account,
      receiver,
      amount + balanceIncrease,
      currentBalance,
      balanceIncrease,
      vars.newStableRate,
      vars.currentAvgStableRate,
      vars.nextSupply
    );
  }

  /**
   * @dev Burns debt of `account`
   * @param account The address of the account getting his debt burned
   * @param amount The amount of debt tokens getting burned
   **/
  function burn(address account, uint256 amount) external override onlyMoneyPool {
    (, uint256 currentBalance, uint256 balanceIncrease) = _calculateBalanceIncrease(account);

    uint256 previousSupply = totalSupply();
    uint256 newAvgStableRate = 0;
    uint256 nextSupply = 0;
    uint256 userStableRate = _userAverageRealAssetBorrowRate[account];

    // Since the total supply and each single account debt accrue separately,
    // there might be accumulation errors so that the last borrower repaying
    // mght actually try to repay more than the available debt supply.
    // In this case we simply set the total supply and the avg stable rate to 0
    if (previousSupply <= amount) {
      _totalAverageRealAssetBorrowRate = 0;
      _totalSupply = 0;
    } else {
      nextSupply = _totalSupply = previousSupply - amount;
      uint256 firstTerm = _totalAverageRealAssetBorrowRate.rayMul(previousSupply.wadToRay());
      uint256 secondTerm = userStableRate.rayMul(amount.wadToRay());

      // For the same reason described above, when the last account is repaying it might
      // happen that account rate * account balance > avg rate * total supply. In that case,
      // we simply set the avg rate to 0
      if (secondTerm >= firstTerm) {
        newAvgStableRate = _totalAverageRealAssetBorrowRate = _totalSupply = 0;
      } else {
        newAvgStableRate = _totalAverageRealAssetBorrowRate = (firstTerm - secondTerm).rayDiv(
          nextSupply.wadToRay()
        );
      }
    }

    if (amount == currentBalance) {
      _userAverageRealAssetBorrowRate[account] = 0;
      _userLastUpdateTimestamp[account] = 0;
    } else {
      //solium-disable-next-line
      _userLastUpdateTimestamp[account] = block.timestamp;
    }
    //solium-disable-next-line
    _lastUpdateTimestamp = block.timestamp;

    if (balanceIncrease > amount) {
      uint256 amountToMint = balanceIncrease - amount;
      _mint(account, amountToMint);
      emit Mint(
        account,
        account,
        amountToMint,
        currentBalance,
        balanceIncrease,
        userStableRate,
        newAvgStableRate,
        nextSupply
      );
    } else {
      uint256 amountToBurn = amount - balanceIncrease;
      _burn(account, amountToBurn);
      emit Burn(
        account,
        amountToBurn,
        currentBalance,
        balanceIncrease,
        newAvgStableRate,
        nextSupply
      );
    }

    emit Transfer(account, address(0), amount);
  }

  /**
   * @dev Calculates the increase in balance since the last account interaction
   * @param account The address of the account for which the interest is being accumulated
   * @return The principal principal balance, the new principal balance and the balance increase
   **/
  function _calculateBalanceIncrease(address account)
    internal
    view
    returns (
      uint256,
      uint256,
      uint256
    )
  {
    uint256 previousprincipalBalance = _balances[account];

    // strict equality is not dangerous here
    // divide-before-multiply dangerous-strict-equalities
    if (previousprincipalBalance == 0) {
      return (0, 0, 0);
    }

    // Calculation of the accrued interest since the last accumulation
    uint256 balanceIncrease = balanceOf(account) - previousprincipalBalance;

    return (previousprincipalBalance, previousprincipalBalance + balanceIncrease, balanceIncrease);
  }

  /**
   * @dev Returns the principal and total supply, the average borrow rate and the last supply update timestamp
   **/
  function getDTokenData()
    public
    view
    override
    returns (
      uint256,
      uint256,
      uint256,
      uint256
    )
  {
    uint256 avgRate = _totalAverageRealAssetBorrowRate;
    return (_totalSupply, _calcTotalSupply(avgRate), avgRate, _lastUpdateTimestamp);
  }

  /**
   * @dev Returns the the total supply and the average stable rate
   **/
  function getTotalSupplyAndAvgRate() public view override returns (uint256, uint256) {
    uint256 avgRate = _totalAverageRealAssetBorrowRate;
    return (_calcTotalSupply(avgRate), avgRate);
  }

  /**
   * @dev Returns the total supply
   **/
  function totalSupply() public view override returns (uint256) {
    return _calcTotalSupply(_totalAverageRealAssetBorrowRate);
  }

  /**
   * @dev Returns the timestamp at which the total supply was updated
   **/
  function getTotalSupplyLastUpdated() public view override returns (uint256) {
    return _lastUpdateTimestamp;
  }

  /**
   * @dev Returns the principal debt balance of the account from
   * @param account The account's address
   * @return The debt balance of the account since the last burn/mint action
   **/
  function principalBalanceOf(address account) external view virtual override returns (uint256) {
    return _balances[account];
  }

  /**
   * @dev Returns the address of the lending pool where this aToken is used
   **/
  function POOL() public view returns (IMoneyPool) {
    return _moneyPool;
  }

  /**
   * @dev For internal usage in the logic of the parent contracts
   **/
  function _getMoneyPool() internal view returns (IMoneyPool) {
    return _moneyPool;
  }

  /**
   * @dev Calculates the total supply
   * @param avgRate The average rate at which the total supply increases
   * @return The debt balance of the account since the last burn/mint action
   **/
  function _calcTotalSupply(uint256 avgRate) internal view virtual returns (uint256) {
    uint256 principalSupply = _totalSupply;

    // strict equality is not dangerous here
    // divide-before-multiply dangerous-strict-equalities
    if (principalSupply == 0) {
      return 0;
    }

    uint256 cumulatedInterest = Math.calculateCompoundedInterest(
      avgRate,
      _lastUpdateTimestamp,
      block.timestamp
    );

    return principalSupply.rayMul(cumulatedInterest);
  }

  /**
   * @dev Mints stable debt tokens to an account
   * @param account The account receiving the debt tokens
   * @param amount The amount being minted
   **/
  function _mint(address account, uint256 amount) internal {
    uint256 oldAccountBalance = _balances[account];
    _balances[account] = oldAccountBalance + amount;
  }

  /**
   * @dev Burns stable debt tokens of an account
   * @param account The account getting his debt burned
   * @param amount The amount being burned
   **/
  function _burn(address account, uint256 amount) internal {
    uint256 oldAccountBalance = _balances[account];
    _balances[account] = oldAccountBalance - amount;
  }

  modifier onlyMoneyPool {
    require(_msgSender() == address(_moneyPool), 'OnlyMoneyPool');
    _;
  }
}
