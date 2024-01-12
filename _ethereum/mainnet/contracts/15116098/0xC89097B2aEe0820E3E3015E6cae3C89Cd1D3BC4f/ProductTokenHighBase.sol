// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./SafeMathUpgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./ProductTokenCore.sol";

/**
 * @title ProductToken High Base
 *
 * @notice High base represent only trading in HIGH token, and bonding curve is based on HIGH to calculate price
 *
 * @notice Prdocut is pausable and owner have authority to make pause only. oterwise
 *         there is also a sunset(endTime) feature, after sunset there is no able to buy and sell product anymore
 *         only can redeem product.
 *
 * @dev See ProductTokenCore for more details
 *
 */
contract ProductTokenHighBase is ProductTokenCore {

  /// @dev Link to HIGH STREET ERC20 Token instance
  address public HIGH;

  /**
   * @dev initializer function.
   *
   * @param _name the name of this token
   * @param _symbol the symbol of this token
   * @param _bondingCurve bonding curve instance address
   * @param _productNft product nft instance address
   * @param _reserveRatio the reserve ratio in the curve function. Number in parts per million
   * @param _maxTokenCount the amount of token that will exist for this type.
   * @param _supplyOffset this amount is used to determine initial price.
   * @param _baseReserve the base amount of reserve tokens, in accordance to _supplyOffset.
   * @param _time time array compose of three setup times, index 0 is start time, index 1 is endtime, index 2 is cool time.
   *
  */

  function initialize(
    string memory _name,
    string memory _symbol,
    address _high,
    address _bondingCurve,
    address _productNft,
    uint32 _reserveRatio,
    uint32 _maxTokenCount,
    uint32 _supplyOffset,
    uint256 _baseReserve,
    uint256[3] memory _time,
    uint256 _brandTokenId
  ) public virtual initializer{
    require(_high != address(0), "invalid high address");
    HIGH = _high;
    ProductTokenCore.__initialize(
      _name,
      _symbol,
      _bondingCurve,
      _productNft,
      _reserveRatio,
      _maxTokenCount,
      _supplyOffset,
      _baseReserve,
      _time[0],
      _time[1],
      _time[2],
      _brandTokenId
    );
  }

  /**
  * @notice buy product with maximum acceptable price and can only buy one at a time
  *
  * @dev This function is implemented by using HIGH token as currency
  * @dev when endTime is arrived then can not buy product anymore
  *
  * @param maxPrice_ maximum acceptable price.
  *
  */
  function buy(uint256 maxPrice_) external virtual whenNotPaused nonReentrant {
    require(now256() >= startTime, "sale hasn't start");
    if(endTime[FEATURE_ENDTIME_BUY] != 0) {
      require(now256() < endTime[FEATURE_ENDTIME_BUY], "sale is expire");
    }
    require(maxPrice_ > 0, "invalid max price");

    transferFromHighToken(_msgSender(), address(this), maxPrice_);

    (uint256 change)  = _buy(maxPrice_);
    if(change > 0) {
      transferHighToken(_msgSender(), change);
    }
    if(coolDownTime > 0) {
      coolDownTimes[_msgSender()] = now256() + coolDownTime;
    }
  }

  /**
  * @notice sell products and return equivalent HIGH token
  *
  * @dev This function is implemented by using HIGH token as currency
  * @dev when endTime is arrived then can not buy product anymore
  *
  * @param amount_ amount of product want to sell
  */
  function sell(uint32 amount_) external virtual whenNotPaused nonReentrant {
    require(now256() >= startTime, "sale hasn't start");
    if(endTime[FEATURE_ENDTIME_SELL] != 0) {
      require(now256() < endTime[FEATURE_ENDTIME_SELL], "sale is expire");
    }

    require(now256() > coolDownTimes[_msgSender()], "wait to cool down");

    require(amount_ > 0, "Amount must be non-zero.");
    require(balanceOf(_msgSender()) >= amount_, "Insufficient tokens.");

    uint256 price = _sell(amount_);
    transferHighToken(_msgSender(), price);
  }

  /**
  * @notice When user wants to trade in their token for retail product
  *
  * @param amount_ amount of tokens that user wants to trade in.
  */
  function tradein(uint32 amount_) external virtual whenNotPaused nonReentrant{
    require(now256() >= startTime, "sale hasn't start");
    if(endTime[FEATURE_ENDTIME_TRADEIN] != 0) {
      require(now256() < endTime[FEATURE_ENDTIME_TRADEIN], "sale is expire");
    }
    require(amount_ > 0 && amount_ < 10, "Invalid amount");
    require(balanceOf(_msgSender()) >= amount_, "Insufficient tokens.");
    _tradein(amount_);
  }

  /**
  * @inheritdoc ProductTokenCore
  *
  * @dev Additionally to the parent smart contract, implementing transaction logic
  */
  function _claim(uint256 amount_) internal override virtual {
    transferHighToken(_msgSender(), amount_);
  }

  /**
  * @dev Executes SafeERC20.safeTransfer on a HIGH token
  *
  */
  function transferHighToken(address to_, uint256 value_) internal virtual{
    SafeERC20Upgradeable.safeTransfer(IERC20Upgradeable(HIGH), to_, value_);
  }

  /**
  * @dev Executes SafeERC20.safeTransferFrom on a HIGH token
  *
  */
  function transferFromHighToken(address from_, address to_, uint256 value_) internal virtual{
    SafeERC20Upgradeable.safeTransferFrom(IERC20Upgradeable(HIGH), from_, to_, value_);
  }

}
