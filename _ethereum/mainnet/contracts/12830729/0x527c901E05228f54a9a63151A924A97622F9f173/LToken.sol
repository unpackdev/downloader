// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

import "./SafeERC20.sol";
import "./ERC20.sol";
import "./Address.sol";

import "./WadRayMath.sol";

import "./ILToken.sol";
import "./IMoneyPool.sol";
import "./IIncentivePool.sol";

/**
 * @title ELYFI LToken
 * @author ELYSIA
 * @notice LTokens are the basis for repayment of loans and interest on their deposits. When Money Pool
 * investors deposit or withdraw assets from the Money Pool Contract, the Smart Contract automatically
 * issues or destroys LTokens accordingly.
 * @dev LTokens comply with the ERC20 token standard. Some functions are restricted to the general user.
 */
contract LToken is ILToken, ERC20 {
  using SafeERC20 for IERC20;
  using WadRayMath for uint256;

  IMoneyPool internal _moneyPool;
  IIncentivePool internal _incentivePool;
  address internal _underlyingAsset;

  constructor(
    IMoneyPool moneyPool,
    address underlyingAsset,
    IIncentivePool incentivePool,
    string memory name,
    string memory symbol
  ) ERC20(name, symbol) {
    _moneyPool = moneyPool;
    _underlyingAsset = underlyingAsset;
    _incentivePool = incentivePool;
  }

  function mint(
    address account,
    uint256 amount,
    uint256 index
  ) external override onlyMoneyPool {
    uint256 implicitBalance = amount.rayDiv(index);

    require(amount != 0, 'LTokenInvalidMintAmount');

    _incentivePool.updateIncentivePool(account);
    _mint(account, implicitBalance);

    emit Mint(account, implicitBalance, index);
  }

  function burn(
    address account,
    address receiver,
    uint256 amount,
    uint256 index
  ) external override onlyMoneyPool {
    uint256 implicitBalance = amount.rayDiv(index);

    require(amount != 0, 'LTokenInvalidBurnAmount');

    _incentivePool.updateIncentivePool(account);
    _burn(account, implicitBalance);

    IERC20(_underlyingAsset).safeTransfer(receiver, amount);

    emit Burn(account, receiver, implicitBalance, index);
  }

  /**
   * @return Returns implicit balance multipied by ltoken interest index
   **/
  function balanceOf(address account) public view override(IERC20, ERC20) returns (uint256) {
    return super.balanceOf(account).rayMul(_moneyPool.getLTokenInterestIndex(_underlyingAsset));
  }

  function implicitBalanceOf(address account) external view override returns (uint256) {
    return super.balanceOf(account);
  }

  function implicitTotalSupply() public view override returns (uint256) {
    return super.totalSupply();
  }

  function totalSupply() public view override(IERC20, ERC20) returns (uint256) {
    return super.totalSupply().rayMul(_moneyPool.getLTokenInterestIndex(_underlyingAsset));
  }

  /**
   * @dev Transfers the underlying asset to receiver.
   * @param receiver The recipient of the underlying asset
   * @param amount The amount getting transferred
   **/
  function transferUnderlyingTo(address receiver, uint256 amount) external override onlyMoneyPool {
    IERC20(_underlyingAsset).safeTransfer(receiver, amount);
  }

  /**
   * @dev Transfers LToken
   * @param from The from address
   * @param to The recipient of LToken
   * @param amount The amount getting transferred, but actual amount is implicit balance
   * @param validate If true, validate and finalize transfer
   **/
  function _transfer(
    address from,
    address to,
    uint256 amount,
    bool validate
  ) internal {
    uint256 index = _moneyPool.getLTokenInterestIndex(_underlyingAsset);
    validate;
    _incentivePool.beforeTokenTransfer(from, to);
    super._transfer(from, to, amount.rayDiv(index));
  }

  /**
   * @dev Overriding ERC20 _transfer for reflecting implicit balance
   * @param from The from address
   * @param to The recipient of LToken
   * @param amount The amount getting transferred
   **/
  function _transfer(
    address from,
    address to,
    uint256 amount
  ) internal override {
    _transfer(from, to, amount, true);
  }

  /**
   * @dev Returns the address of the underlying asset of this aToken (E.g. WETH for aWETH)
   **/
  function getUnderlyingAsset() external view override returns (address) {
    return _underlyingAsset;
  }

  function updateIncentivePool(address newIncentivePool) external override onlyMoneyPool {
    _incentivePool = IIncentivePool(newIncentivePool);
  }

  modifier onlyMoneyPool {
    require(_msgSender() == address(_moneyPool), 'OnlyMoneyPool');
    _;
  }
}
