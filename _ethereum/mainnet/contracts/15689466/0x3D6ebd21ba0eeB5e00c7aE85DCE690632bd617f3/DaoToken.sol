// SPDX-License-Identifier: MIT

import "./ERC20Burnable.sol";
import "./Pausable.sol";
pragma solidity ^0.8.0;

contract DaoToken is ERC20Burnable, Pausable {
    uint256 private _price;
    uint256 private _limit;
    uint256 private _presale;

    constructor(string memory name, string memory symbol, address owner_of, uint256 presale_, uint256 limit_, uint256 price_) ERC20(name, symbol) Pausable(owner_of) {
        if (limit_ > 0) {
            require(limit_ >= presale_, "Limit overrized");
        }
        if (presale_ > 0) {
            _mint(owner_of, presale_);
        }
        _limit = limit_;
        _price = price_;
        _presale = presale_;
    }

    function mint(uint256 amount) public payable notPaused {
        if (_limit > 0) {
            require(totalSupply() + amount < _limit, "Limit overrized");
        }
        if (_price > 0) {
            require(msg.value >= (_price * amount) / 10**18);
        }
        _mint(msg.sender, amount);
    }

    function price() public view virtual returns (uint256) {
        return _price;
    }

    function limit() public view virtual returns (uint256) {
        return _limit;
    }

    function presale() public view virtual returns (uint256) {
        return _presale;
    }
}
