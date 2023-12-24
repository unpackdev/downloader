/// token.sol -- ERC20 implementation with minting and burning

// Copyright (C) 2015, 2016, 2017  DappHub, LLC

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

// SPDX-License-Identifier: GPL-3.0-or-later

//https://www.boundfinance.co.uk/
//https://boundfinance.app/
//Twitter - @BoundFinance
//Discord - https://discord.com/invite/kBDEWndd7m
//Public sale Contract for BCKGOV Tokens

pragma solidity ^0.8.13;

import "./stop.sol";
import "./base.sol";

contract DSTokenGov is DSTokenBase(0), DSStop {

    string  public  symbol;
    uint256  public  decimals = 18; // standard token precision. override to customize
    string public name;
    uint256 immutable public maxSupply = 20000000 * 10 ** decimals;  // 20 million tokens, scaled by decimals

    constructor(string memory symbol_) public {
        symbol = symbol_;
    }

    event Mint(address indexed guy, uint wad);
    event Burn(address indexed guy, uint wad);

    function approve(address guy) public stoppable returns (bool) {
        return super.approve(guy, type(uint256).max);
    }

    function approve(address guy, uint wad) public stoppable override returns (bool) {
        return super.approve(guy, wad);
    }

    function transferFrom(address src, address dst, uint wad)
        public
        stoppable 
        override 
        returns (bool)
    {
        if (src != msg.sender && _approvals[src][msg.sender] != type(uint256).max) {
            _approvals[src][msg.sender] = _approvals[src][msg.sender] - wad;
        }

        _balances[src] = _balances[src] - wad;
        _balances[dst] = _balances[dst] + wad;

        emit Transfer(src, dst, wad);

        return true;
    }

    function push(address dst, uint wad) public {
        transferFrom(msg.sender, dst, wad);
    }
    function pull(address src, uint wad) public {
        transferFrom(src, msg.sender, wad);
    }
    function move(address src, address dst, uint wad) public {
        transferFrom(src, dst, wad);
    }

    function mint(uint wad) public {
        mint(msg.sender, wad);
    }
    function burn(uint wad) public {
        burn(msg.sender, wad);
    }
    function mint(address guy, uint wad) public auth stoppable {
        require(_supply + wad <= maxSupply, "Exceeds max supply");
        _balances[guy] = _balances[guy] + wad;
        _supply = _supply + wad;
        emit Mint(guy, wad);
    }
    function burn(address guy, uint wad) public auth stoppable {
        if (guy != msg.sender && _approvals[guy][msg.sender] != type(uint256).max) {
            _approvals[guy][msg.sender] = _approvals[guy][msg.sender] - wad;
        }

        _balances[guy] = _balances[guy] - wad;
        _supply = _supply - wad;
        emit Burn(guy, wad);
    }

    // Optional token name

    function setName(string memory name_) public auth {
        name = name_;
    }
}
