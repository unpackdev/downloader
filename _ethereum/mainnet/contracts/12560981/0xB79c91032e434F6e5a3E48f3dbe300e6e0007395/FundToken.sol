// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.7.6;

import "./SafeMath.sol";
import "./ERC20.sol";

import "./IFundToken.sol";

contract FundToken is ERC20("Fund Token", "FP"), IFundToken {
    address private _exchanger;

    constructor(address exchanger_)  {
        require(exchanger_ != address(0), "exchanger cannot be zero address");
        _setupDecimals(6);
        _exchanger = exchanger_;
    }

    function mint(address account, uint256 value_) external override onlyExchanger {
        _mint(account, value_);
        emit Mint(account, value_);
    }

    function burn(address account, uint256 value_) external override onlyExchanger {
        _burn(account, value_);
        emit Burn(account, value_);
    }

    modifier onlyExchanger {
        require(msg.sender == _exchanger, "Only the exchanger can perform this action");
        _;
    }

    event Mint(address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);
}
