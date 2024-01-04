// SPDX-License-Identifier: MIT
// fork https://github.com/1inch-exchange/mooniswap/blob/master/contracts/mocks/TokenMock.sol

pragma solidity ^0.6.0;

import "./Ownable.sol";
import "./Math.sol";
import "./SafeMath.sol";
import "./ERC20.sol";
import "./SafeERC20.sol";


contract TokenMock is ERC20, Ownable {
    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals
    )
    public
    ERC20(name, symbol)
    {
        _setupDecimals(decimals);
    }

    function mint(address account, uint256 amount) external onlyOwner {
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) external onlyOwner {
        _burn(account, amount);
    }
}