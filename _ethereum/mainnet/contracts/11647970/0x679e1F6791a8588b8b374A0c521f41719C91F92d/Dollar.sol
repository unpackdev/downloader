/*
    Copyright 2020 Zero Collateral Devs, standing on the shoulders of the Empty Set Squad <zaifinance@protonmail.com>. Fixed & Forced by arct1c_team.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity ^0.5.17;
pragma experimental ABIEncoderV2;

import "./ERC20Burnable.sol";
import "./ERC20Detailed.sol";
import "./MinterRole.sol";
import "./Permittable.sol";
import "./IDollar.sol";

contract Dollar is
    IDollar,
    MinterRole,
    ERC20Detailed,
    Permittable,
    ERC20Burnable
{
    constructor()
        public
        ERC20Detailed("Zero Collateral Dai Fixed", "ZAF", 18)
        Permittable()
    {}

    function mint(address account, uint256 amount)
        public
        onlyMinter
        returns (bool)
    {
        _mint(account, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public returns (bool) {
        _transfer(sender, recipient, amount);
        if (allowance(sender, _msgSender()) != uint256(-1)) {
            _approve(
                sender,
                _msgSender(),
                allowance(sender, _msgSender()).sub(
                    amount,
                    "Dollar: transfer amount exceeds allowance"
                )
            );
        }
        return true;
    }
}
