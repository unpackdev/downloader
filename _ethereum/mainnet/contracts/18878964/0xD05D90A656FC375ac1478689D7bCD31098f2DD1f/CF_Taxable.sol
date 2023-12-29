// SPDX-License-Identifier: MIT

pragma solidity 0.8.23;

import "./CF_Ownable.sol";
import "./CF_Common.sol";
import "./CF_ERC20.sol";

abstract contract CF_Taxable is CF_Ownable, CF_Common, CF_ERC20 {
  event SetTaxBeneficiary(uint8 slot, address account, uint24[3] percent, uint24[3] penalty);
  event SetEarlyPenaltyTime(uint32 time);
  event TaxDistributed(uint256 amount);
  event RenouncedTaxable();

  struct taxBeneficiaryView {
    address account;
    uint24[3] percent;
    uint24[3] penalty;
    uint256 unclaimed;
  }

  modifier lockDistributing {
    _distributing = true;
    _;
    _distributing = false;
  }

  /// @notice Permanently renounce and prevent the owner from being able to update the tax features
  /// @dev Existing settings will continue to be effective
  function renounceTaxable() external onlyOwner {
    _renounced.Taxable = true;

    emit RenouncedTaxable();
  }

  /// @notice Total amount of taxes collected so far
  function totalTaxCollected() external view returns (uint256) {
    return _totalTaxCollected;
  }

  /// @notice Tax applied per transfer
  /// @dev Taking in consideration your wallet address
  function txTax() external view returns (uint24) {
    return txTax(msg.sender);
  }

  /// @notice Tax applied per transfer
  /// @param from Sender address
  function txTax(address from) public view returns (uint24) {
    unchecked {
      return from == address(this) || _whitelisted[from] || from == _dex.pair ? 0 : (_holder[from].penalty || _tradingEnabled + _earlyPenaltyTime >= _timestamp() ? _totalPenaltyTxTax : _totalTxTax);
    }
  }

  /// @notice Tax applied for buying
  /// @dev Taking in consideration your wallet address
  function buyTax() external view returns (uint24) {
    return buyTax(msg.sender);
  }

  /// @notice Tax applied for buying
  /// @param from Buyer's address
  function buyTax(address from) public view returns (uint24) {
    unchecked {
      return from == address(this) || _whitelisted[from] || from == _dex.pair ? 0 : (_holder[from].penalty || _tradingEnabled + _earlyPenaltyTime >= _timestamp() ? _totalPenaltyBuyTax : _totalBuyTax);
    }
  }
  /// @notice Tax applied for selling
  /// @dev Taking in consideration your wallet address
  function sellTax() external view returns (uint24) {
    return sellTax(msg.sender);
  }

  /// @notice Tax applied for selling
  /// @param to Seller's address
  function sellTax(address to) public view returns (uint24) {
    unchecked {
      return to == address(this) || _whitelisted[to] || to == _dex.pair || to == _dex.router ? 0 : (_holder[to].penalty || _tradingEnabled + _earlyPenaltyTime >= _timestamp() ? _totalPenaltySellTax : _totalSellTax);
    }
  }

  /// @notice List of all tax beneficiaries and their assigned percentage, according to type of transfer
  /// @custom:return `list[].account` Beneficiary address
  /// @custom:return `list[].percent[3]` Index 0 is for tx tax, 1 is for buy tax, 2 is for sell tax, multiplied by denominator
  /// @custom:return `list[].penalty[3]` Index 0 is for tx penalty, 1 is for buy penalty, 2 is for sell penalty, multiplied by denominator
  function listTaxBeneficiaries() external view returns (taxBeneficiaryView[] memory list) {
    list = new taxBeneficiaryView[](5);

    unchecked {
      for (uint8 i; i < 5; i++) { list[i] = taxBeneficiaryView(_taxBeneficiary[i].account, _taxBeneficiary[i].percent, _taxBeneficiary[i].penalty, _taxBeneficiary[i].unclaimed); }
    }
  }

  /// @notice Sets a tax beneficiary
  /// @dev Maximum of 5 wallets can be assigned
  /// @param slot Slot number (0 to 4)
  /// @param account Beneficiary address
  /// @param percent[3] Index 0 is for tx tax, 1 is for buy tax, 2 is for sell tax, multiplied by denominator
  /// @param penalty[3] Index 0 is for tx penalty, 1 is for buy penalty, 2 is for sell penalty, multiplied by denominator
  function setTaxBeneficiary(uint8 slot, address account, uint24[3] memory percent, uint24[3] memory penalty) external onlyOwner {
    require(!_renounced.Taxable);

    _setTaxBeneficiary(slot, account, percent, penalty);
  }

  function _setTaxBeneficiary(uint8 slot, address account, uint24[3] memory percent, uint24[3] memory penalty) internal {
    require(slot < 5);
    require(account != address(this) && account != address(0));

    taxBeneficiary storage _taxBeneficiary = _taxBeneficiary[slot];

    if (account == address(0xdEaD) && _taxBeneficiary.exists && _taxBeneficiary.unclaimed > 0) { revert("Unclaimed taxes"); }

    _taxBeneficiary.account = account;
    _taxBeneficiary.percent = percent;
    _taxBeneficiary.penalty = penalty;

    unchecked {
      _totalTxTax += percent[0] - (_taxBeneficiary.exists ? _taxBeneficiary.percent[0] : 0);
      _totalBuyTax += percent[1] - (_taxBeneficiary.exists ? _taxBeneficiary.percent[1] : 0);
      _totalSellTax += percent[2] - (_taxBeneficiary.exists ? _taxBeneficiary.percent[2] : 0);
      _totalPenaltyTxTax += penalty[0] - (_taxBeneficiary.exists ? _taxBeneficiary.penalty[0] : 0);
      _totalPenaltyBuyTax += penalty[1] - (_taxBeneficiary.exists ? _taxBeneficiary.penalty[1] : 0);
      _totalPenaltySellTax += penalty[2] - (_taxBeneficiary.exists ? _taxBeneficiary.penalty[2] : 0);

      require(_totalTxTax <= 25 * _denominator && _totalBuyTax <= 25 * _denominator && _totalSellTax <= 25 * _denominator, "High Tax");
      require(_totalPenaltyTxTax <= 50 * _denominator && _totalPenaltyBuyTax <= 50 * _denominator && _totalPenaltySellTax <= 50 * _denominator, "High Penalty");
    }

    if (!_taxBeneficiary.exists) { _taxBeneficiary.exists = true; }

    emit SetTaxBeneficiary(slot, account, percent, penalty);
  }

  /// @notice Triggers the tax distribution
  /// @dev Will only be executed if there is no ongoing swap or tax distribution and the min. threshold has been reached unless forced
  /// @param force Ignore the min. threshold amount
  function autoTaxDistribute(bool force) external onlyOwner {
    require(!_swapping && !_distributing);

    _autoTaxDistribute(force);
  }

  function _autoTaxDistribute(bool force) internal lockDistributing {
    if (!force) {
      if (address(_reflectionToken) == address(this) && (_amountForTaxDistribution == 0 || _balance[address(this)] < _amountForTaxDistribution || _amountForTaxDistribution < _minTaxDistributionAmount)) { return; }
      if (address(_reflectionToken) == _dex.WETH && (_ethForTaxDistribution == 0 || _ethForTaxDistribution < address(this).balance)) { return; }
      if (address(_reflectionToken) != address(this) && address(_reflectionToken) != _dex.WETH && (_reflectionTokensForTaxDistribution == 0 || _reflectionTokensForTaxDistribution < _reflectionToken.balanceOf(address(this)))) { return; }
    }

    unchecked {
      uint256 distributed;

      for (uint8 i; i < 5; i++) {
        address account = _taxBeneficiary[i].account;
        uint256 unclaimed = _taxBeneficiary[i].unclaimed;

        if (unclaimed == 0 || account == address(0xdEaD) || account == _dex.pair) { continue; }

        uint256 _distributed = _distribute(account, unclaimed);

        if (_distributed > 0) { _taxBeneficiary[i].unclaimed -= _distributed; }

        distributed += _distributed;
      }

      _lastTaxDistribution = _timestamp();

      emit TaxDistributed(distributed);
    }
  }

  function _distribute(address account, uint256 unclaimed) private returns (uint256) {
    if (address(_reflectionToken) == address(this)) {
      super._transfer(address(this), account, unclaimed);

      _amountForTaxDistribution -= unclaimed;
    } else {
      uint256 percent = (uint256(_denominator) * unclaimed * 100) / _amountSwappedForTaxDistribution;
      uint256 amount;

      if (address(_reflectionToken) == _dex.WETH) {
        amount = _percentage(_ethForTaxDistribution, percent);

        if (_ethForTaxDistribution < amount) { return 0; }

        (bool success, ) = payable(account).call{ value: amount, gas: 30000 }("");

        if (!success) { return 0; }

        _ethForTaxDistribution -= amount;
      } else {
        amount = _percentage(_reflectionTokensForTaxDistribution, percent);

        if (_reflectionTokensForTaxDistribution < unclaimed) { return 0; }

        _reflectionToken.transfer(account, amount);
        _reflectionTokensForTaxDistribution -= amount;
      }

      _amountSwappedForTaxDistribution -= unclaimed;
    }

    return unclaimed;
  }

  /// @notice Suspend or reinstate tax collection
  /// @dev Also applies to early penalties
  /// @param status True to suspend, False to reinstate existent taxes
  function suspendTaxes(bool status) external onlyOwner {
    require(!_renounced.Taxable);

    _suspendTaxes = status;
  }

  /// @notice Checks if tax collection is currently suspended
  function taxesSuspended() external view returns (bool) {
    return _suspendTaxes;
  }

  /// @notice Returns the minimum percentage of the total supply accumulated in the Smart-Contract balance to trigger tax distribution
  function getMinTaxDistributionPercent() external view returns (uint24) {
    return _minTaxDistributionPercent;
  }

  /// @notice Sets the minimum percentage of the total supply accumulated in the Smart-Contract balance to trigger tax distribution
  /// @param percent Desired percentage, multiplied by denominator
  function setMinTaxDistributionPercent(uint24 percent) external onlyOwner {
    require(!_renounced.Taxable);
    require(percent >= 1 && percent <= 1000, "0.001% to 1%");

    _setMinTaxDistributionPercent(percent);
  }

  function _setMinTaxDistributionPercent(uint24 percent) internal {
    _minTaxDistributionPercent = percent;
    _minTaxDistributionAmount = _percentage(_totalSupply, uint256(percent));
  }

  /// @notice Removes the penalty status of a wallet
  /// @param account Address to depenalize
  function removePenalty(address account) external onlyOwner {
    require(!_renounced.Taxable);

    _holder[account].penalty = false;
  }

  /// @notice Check if a wallet is penalized due to an early transaction
  /// @param account Address to check
  function isPenalized(address account) external view returns (bool) {
    return _holder[account].penalty;
  }

  /// @notice Defines the period of time from contract creation during which early buyers will be penalized
  /// @param time Time, in seconds
  function setEarlyPenaltyTime(uint32 time) external onlyOwner {
    require(!_renounced.Taxable);
    require(time <= 7 days);

    _setEarlyPenaltyTime(time);
  }

  function _setEarlyPenaltyTime(uint32 time) internal {
    _earlyPenaltyTime = time;

    emit SetEarlyPenaltyTime(time);
  }
}
