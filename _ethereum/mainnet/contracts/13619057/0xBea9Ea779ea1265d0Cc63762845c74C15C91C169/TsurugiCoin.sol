// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC20.sol";
import "./Ownable.sol";

contract TsurugiCoin is ERC20, Ownable {
    constructor() ERC20("TSURUGIToken", "TRGX") {
    }

    event MintTRGXFinished(address account, uint256 amount);
    event BurnTRGXFinished(address account, uint256 amount);

    function mint(address _account, uint256 _amount) public onlyOwner {
        _mint(_account, _amount);

        emit MintTRGXFinished(_account, _amount);
    }

    function burn(address _account, uint256 _amount) public onlyOwner {
        _burn(_account, _amount);

        emit BurnTRGXFinished(_account, _amount);
    }
}
