// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC20.sol";
import "./Ownable.sol";

contract TrusdCoin is ERC20, Ownable {
    constructor() ERC20("TrusdToken", "TRUSD") {
    }

    event MintTRUSDFinished(address account, uint256 amount);
    event BurnTRUSDFinished(address account, uint256 amount);

    function mint(address _account, uint256 _amount) public onlyOwner {
        _mint(_account, _amount);

        emit MintTRUSDFinished(_account, _amount);
    }

    function burn(address _account, uint256 _amount) public onlyOwner {
        _burn(_account, _amount);

        emit BurnTRUSDFinished(_account, _amount);
    }
}
