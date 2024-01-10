//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.11;

import "./SafeMath.sol";
import "./IERC20.sol";
import "./ERC20.sol";
import "./ERC20Burnable.sol";


contract HospitalityToken is ERC20,ERC20Burnable {
constructor(address _privates, address _publics, address _dev, address _market, address _staking, address _lp)  ERC20("HospitalityToken", "HT") {
        _mint(_privates, 2 * 10**28);
        _mint(_publics, 243 * 10**26);
        _mint(_dev, 2 * 10**28);
        _mint(_market, 1 * 10**28);
        _mint(_staking, 114 * 10**26);
        _mint(_lp, 143 * 10**26);
    } 
}
