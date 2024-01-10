// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./OKLGWithdrawable.sol";

/**
 * @title OKLGAffiliate
 * @dev Support affiliate logic
 */
contract OKLGAffiliate is OKLGWithdrawable {
  modifier onlyAffiliateOrOwner() {
    require(
      msg.sender == owner() || affiliates[msg.sender].feePercent > 0,
      'caller must be affiliate or owner'
    );
    _;
  }

  struct Affiliate {
    uint256 feePercent;
    uint256 revenue;
  }

  uint16 public defaultAffiliateDiscount = 1000; // 10%
  uint16 public constant PERCENT_DENOMENATOR = 10000;
  address public paymentWallet = 0x0000000000000000000000000000000000000000;

  mapping(address => Affiliate) public affiliates; // value is percentage of fees for affiliate (denomenator of 10000)
  address[] public affiliateList;
  mapping(address => uint256) public overrideDiscounts; // value is percentage off for customer (denomenator of 10000)

  event AddAffiliate(address indexed wallet, uint256 percent);
  event RemoveAffiliate(address indexed wallet);
  event AddDiscount(address indexed wallet, uint256 percent);
  event RemoveDiscount(address indexed wallet);
  event Pay(address indexed payee, uint256 amount);

  function getAllAffiliates() external view returns (address[] memory) {
    return affiliateList;
  }

  function pay(
    address _caller,
    address _referrer,
    uint256 _basePrice
  ) internal {
    uint256 balanceBefore = address(this).balance - msg.value;
    uint256 price = getFinalPrice(_caller, _referrer, _basePrice);
    require(msg.value >= price, 'not enough ETH to pay');

    // affiliate fee if applicable
    if (affiliates[_referrer].feePercent > 0) {
      uint256 referrerFee = (price * affiliates[_referrer].feePercent) /
        PERCENT_DENOMENATOR;
      (bool sent, ) = payable(_referrer).call{ value: referrerFee }('');
      require(sent, 'affiliate payment did not go through');
      affiliates[_referrer].revenue += price;
      price -= referrerFee;
    }

    // if affiliate does not take everything, send normal payment
    if (price > 0) {
      address wallet = paymentWallet == address(0) ? owner() : paymentWallet;
      (bool sent, ) = payable(wallet).call{ value: price }('');
      require(sent, 'main payment did not go through');
    }

    require(
      address(this).balance >= balanceBefore,
      'cannot take from contract what you did not send'
    );
    emit Pay(msg.sender, _basePrice);
  }

  function getFinalPrice(
    address _caller,
    address _referrer,
    uint256 _basePrice
  ) public view returns (uint256) {
    if (overrideDiscounts[_caller] > 0) {
      return
        _basePrice -
        ((_basePrice * overrideDiscounts[_caller]) / PERCENT_DENOMENATOR);
    } else if (affiliates[_referrer].feePercent > 0) {
      return
        _basePrice -
        ((_basePrice * defaultAffiliateDiscount) / PERCENT_DENOMENATOR);
    }
    return _basePrice;
  }

  function overrideDiscount(address _wallet, uint256 _percent)
    external
    onlyAffiliateOrOwner
  {
    require(
      msg.sender == owner() || _percent <= PERCENT_DENOMENATOR / 2, // max 50% off
      'cannot have more than 50% discount'
    );
    overrideDiscounts[_wallet] = _percent;
    emit AddDiscount(_wallet, _percent);
  }

  function removeDiscount(address _wallet) external onlyAffiliateOrOwner {
    require(overrideDiscounts[_wallet] > 0, 'affiliate must exist');
    delete overrideDiscounts[_wallet];
    emit RemoveDiscount(_wallet);
  }

  function addAffiliate(address _wallet, uint256 _percent) public onlyOwner {
    require(
      _percent <= PERCENT_DENOMENATOR,
      'cannot have more than 100% referral fee'
    );
    if (affiliates[_wallet].feePercent == 0) {
      affiliateList.push(_wallet);
    }
    affiliates[_wallet].feePercent = _percent;
    emit AddAffiliate(_wallet, _percent);
  }

  function addAffiliatesBulk(
    address[] memory _wallets,
    uint256[] memory _percents
  ) external onlyOwner {
    require(_wallets.length == _percents.length, 'must be same length');
    for (uint256 i = 0; i < _wallets.length; i++) {
      addAffiliate(_wallets[i], _percents[i]);
    }
  }

  function removeAffiliate(address _wallet) external onlyOwner {
    require(affiliates[_wallet].feePercent > 0, 'affiliate must exist');
    for (uint256 i = 0; i < affiliateList.length; i++) {
      if (affiliateList[i] == _wallet) {
        affiliateList[i] = affiliateList[affiliateList.length - 1];
        affiliateList.pop();
        break;
      }
    }
    affiliates[_wallet].feePercent = 0;
    emit RemoveAffiliate(_wallet);
  }

  function setDefaultAffiliateDiscount(uint16 _discount) external onlyOwner {
    require(_discount < PERCENT_DENOMENATOR, 'cannot be more than 100%');
    defaultAffiliateDiscount = _discount;
  }

  function setPaymentWallet(address _wallet) external onlyOwner {
    paymentWallet = _wallet;
  }
}
