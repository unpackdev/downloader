// SPDX-License-Identifier: MIT
pragma solidity ^0.5.0;

import "./ERC20.sol";
import "./Crowdsale.sol";
import "./TimedCrowdsale.sol";
import "./WhitelistedRole.sol";
import "./Ownable.sol";

contract WavepoolICO is Crowdsale, TimedCrowdsale, WhitelistedRole, Ownable {
  enum ICOStage { PRESALE, ICO }
  ICOStage public _stage = ICOStage.PRESALE;
  uint256 private _stageRate;
  uint256 private _weiCap;
  mapping(address => uint256) public _contributions;

  constructor(
    uint256 _rate,
    uint256 _cap,
    address payable _wallet,
    ERC20 _token,
    uint256 _open,
    uint256 _close
  )
    Crowdsale(_rate, _wallet, _token)
    TimedCrowdsale(_open, _close)
    public
  {
    _stageRate = _rate;
    _weiCap = _cap;
  }
  
  function rate() public view returns (uint256) {
    return _stageRate;
  }

  function _getTokenAmount(uint256 weiAmount) internal view returns (uint256) {
    return weiAmount.mul(_stageRate);
  }
  
  function addManyWhitelisted(address[] memory accounts) public onlyWhitelistAdmin {
    for (uint256 account = 0; account < accounts.length; account++) {
      addWhitelisted(accounts[account]);
    }
  }

  function closePresale() public onlyOwner {
    require(_stage == ICOStage.PRESALE, "Presale already closed");
    _stage = ICOStage.ICO;
    _stageRate = 5000000;
  }

  function closeICO() public onlyOwner {
    require(hasClosed(), "ICO is still open");
    _deliverTokens(wallet(), token().balanceOf(address(this)));
  }

  function _preValidatePurchase(address beneficiary, uint256 weiAmount) internal view {
    if (_stage == ICOStage.PRESALE) { require(isWhitelisted(beneficiary), "Wallet address has not been whitelisted"); }
    require(_contributions[beneficiary].add(weiAmount) <= _weiCap, "Beneficiary cap exceeded");
    super._preValidatePurchase(beneficiary, weiAmount);
  }
  
  function _updatePurchasingState(address beneficiary, uint256 weiAmount) internal {
    super._updatePurchasingState(beneficiary, weiAmount);
    _contributions[beneficiary] = _contributions[beneficiary].add(weiAmount);
  }
}