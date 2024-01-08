// Copyright (C) 2021 Exponent

// This file is part of Exponent.

// Exponent is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// Exponent is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with Exponent.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity 0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";

contract LPToken is ERC20, Ownable {
    constructor(string memory _name, string memory _symbol)
        ERC20(_name, _symbol)
    {}

    // @notice mint LP token share
    // @param receiver the address to receive the tokens
    // @param amount the amount of tokens to mint
    // @dev callable only by deployer
    function mint(address receiver, uint256 amount) public onlyOwner {
        _mint(receiver, amount);
    }

    // @notice burn LP token share
    // @param wallet the wallet to burn tokens from
    // @param amount the amount of tokens to be burned
    // @dev callable only by deployer
    function burn(address wallet, uint256 amount) public onlyOwner {
        _burn(wallet, amount);
    }
}
