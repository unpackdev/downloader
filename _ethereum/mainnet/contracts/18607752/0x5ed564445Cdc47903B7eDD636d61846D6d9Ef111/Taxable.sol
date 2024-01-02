// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Context.sol";

abstract contract Taxable is Context {
  event TaxOn(address account);
  event TaxOff(address account);
  event TaxChanged(address account);
  event TaxDestinationChanged(address account);

  bool private _taxed = false;
  uint private _thetax = 500;
  uint private immutable _maxtax = 1000;
  uint private immutable _mintax = 25;
  address private _taxdestination = address(0);

  modifier whenNotTaxed() {
    _requireNotTaxed();
    _;
  }

  modifier whenTaxed() {
    _requireTaxed();
    _;
  }

  function taxed() public view virtual returns (bool) {
    return _taxed;
  }

  function thetax() public view virtual returns (uint) {
    return _thetax;
  }

  function taxdestination() public view virtual returns (address) {
    return _taxdestination;
  }

  function _requireNotTaxed() internal view virtual {
    require(!taxed(), "Taxable: taxed");
  }

  function _requireTaxed() internal view virtual {
    require(taxed(), "Taxable: not taxed");
  }

  function _taxon() internal virtual whenNotTaxed {
    _taxed = true;
    emit TaxOn(_msgSender());
  }

  function _taxoff() internal virtual whenTaxed {
    _taxed = false;
    emit TaxOff(_msgSender());
  }

  function _updatetax(uint newtax) internal virtual {
    require(newtax <= _maxtax, "Taxable: tax is too high");
    require(newtax >= _mintax, "Taxable: tax is too low");
    _thetax = newtax;
    emit TaxChanged(_msgSender());
  }

  function _updatetaxdestination(address newdestination) internal virtual {
    _taxdestination = newdestination;
    emit TaxDestinationChanged(_msgSender());
  }
}
