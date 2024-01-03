// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

import "./ERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./ILpToken.sol";

contract LpToken is ILpToken, ERC20, Ownable {
    using SafeMath for uint256;

    address private _main;

    modifier onlyMain() {
        require(address(_main) == _msgSender(), "[1500] LP TOKEN: caller is not the main contract");
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _supply,
        address _mainAddress
    ) public ERC20(_name, _symbol) Ownable() {
        if (_supply > 0) {
            _mint(owner(), _supply * 10**uint256(decimals()));
        }

        _main = _mainAddress;
    }

    function mint(address beneficiary, uint amount) external override onlyMain {
        _mint(beneficiary, amount);
    }

    function burn(address spender, uint amount) external override onlyMain {
        _burn(spender, amount);
    }
}
