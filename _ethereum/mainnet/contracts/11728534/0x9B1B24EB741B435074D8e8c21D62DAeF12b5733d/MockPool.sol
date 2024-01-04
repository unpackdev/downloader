/*
    Copyright 2020 Empty Set Squad <emptysetsquad@protonmail.com>

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

import "./Pool.sol";

contract MockPool is Pool {
    address private _dai;
    address private _dao;
    address private _dollar;
    address private _univ2;

    constructor(
        address _stakingToken,
        address _rewardsToken
    ) public Pool(IDAO(address(0)), IERC20(_stakingToken), IERC20(_rewardsToken)) {}

    function set(address dao, address dai, address dollar) external {
        _dao = dao;
        _dai = dai;
        _dollar = dollar;
    }

    function dai() public view returns (address) {
        return _dai;
    }

    function dao() public view returns (IDAO) {
        return IDAO(_dao);
    }

    function dollar() public view returns (IDollar) {
        return IDollar(_dollar);
    }
}
