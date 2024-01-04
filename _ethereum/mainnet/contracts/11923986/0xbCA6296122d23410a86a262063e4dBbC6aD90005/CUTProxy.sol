// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;

/**
 * Proxy Contract
 *
 * To implement public interface, and store the location of the CUT Stateless
 * lib in order to proxy function calls to the current live ABI.
 *
 * The public interface is ERC-20 compatible.
 */

import "./AccessControl.sol";
import "./Context.sol";
import "./SafeMath.sol";
import "./Address.sol";

import "./ICUTLib.sol";


contract CUTProxy is Context, AccessControl, ICUTLib {

    using SafeMath for uint256;
    using Address for address;

    address private productionLibrary;

    constructor () {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function setProductionLibrary(address newLibrary) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "C:ADMIN");

        productionLibrary = newLibrary;
    }

    function playLog(uint256 _type, address a, address b, uint256 amount) public
    returns (bool) {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "C:ADMIN");

        if (_type == 0) {
            emit Transfer(a, b, amount);
        } else if (_type == 1) {
            emit Approval(a, b, amount);
        }

        return true;
    }

    function getProductionLibrary() public
    view
    returns (address) {
        return productionLibrary;
    }

    function name() public view override
    returns (string memory) {
        return ICUTImpl(productionLibrary).name();
    }

    function symbol() public view override
    returns (string memory) {
        return ICUTImpl(productionLibrary).symbol();
    }

    function decimals() public view override
    returns (uint8) {
        return ICUTImpl(productionLibrary).decimals();
    }

    function totalSupply() public view override
    returns (uint256) {
        return ICUTImpl(productionLibrary).totalSupply();
    }

    function balanceOf(address account) public view override
    returns (uint256) {
        return ICUTImpl(productionLibrary).balanceOf(account);
    }

    function allowance(address owner, address spender) public view override
    returns (uint256) {
        return ICUTImpl(productionLibrary).allowance(owner, spender);
    }

    function transfer(address recipient, uint256 amount) public override
    returns (bool) {
        ICUTImpl(productionLibrary).transfer(_msgSender(), recipient, amount);

        emit Transfer(_msgSender(), recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public override
    returns (bool) {
        ICUTImpl(productionLibrary).approve(_msgSender(), spender, amount);

        emit Approval(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address from, address recipient, uint256 amount) public override
    returns (bool) {
        ICUTImpl(productionLibrary).transferFrom(_msgSender(), from, recipient, amount);

        emit Transfer(from, recipient, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public override
    returns (bool) {
        uint256 newAllowance = ICUTImpl(productionLibrary).increaseAllowance(
            _msgSender(), spender, addedValue);

        emit Approval(_msgSender(), spender, newAllowance);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public override
    returns (bool) {
        uint256 newAllowance = ICUTImpl(productionLibrary).decreaseAllowance(
            _msgSender(), spender, subtractedValue);

        emit Approval(_msgSender(), spender, newAllowance);
        return true;
    }

    function signalRetireIntent(uint256 retirementAmount) public override {
        return ICUTImpl(productionLibrary).signalRetireIntent(_msgSender(), retirementAmount);
    }
}
