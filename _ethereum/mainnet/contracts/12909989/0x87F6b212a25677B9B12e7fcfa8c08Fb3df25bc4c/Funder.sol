/*
    Copyright 2021 Empty Set Squad <emptysetsquad@protonmail.com>

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

pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

import "./Ownable.sol";
import "./IERC20.sol";

contract Funder is Ownable {
    uint256 private constant ONE_PERCENT = 16_500_000 ether;
    uint256 private constant DEFI_PULSE_TREASURY_AMOUNT = 5_000_000 ether;

    address private constant EMPTY_SET_TREASURY = address(0x460661bd4A5364A3ABCc9cfc4a8cE7038d05Ea22);
    address private constant DEFI_PULSE_TREASURY = address(0x866613c804Be33e9D7899a41D4EfE880c0de1FaD);

    IRegistry public registry;
    address public incentivizerUniswap;
    address public incentivizerCurve;
    address public sn2Vester;
    address public dfpVester;
    address public eqlVester;

    constructor(
        IRegistry _registry,
        address _incentivizerUniswap,
        address _incentivizerCurve,
        address _sn2Vester,
        address _dfpVester,
        address _eqlVester
    ) public {
        registry = _registry;
        incentivizerUniswap = _incentivizerUniswap;
        incentivizerCurve = _incentivizerCurve;
        sn2Vester = _sn2Vester;
        dfpVester = _dfpVester;
        eqlVester = _eqlVester;
    }

    function distribute() external onlyOwner {
        IStake stake = registry.stake();

        // Mint
        uint256 stakeAmount;
        stakeAmount += ONE_PERCENT * 103;                                // Migrator
        stakeAmount += (ONE_PERCENT * 3) + DEFI_PULSE_TREASURY_AMOUNT;   // Treasuries
        stakeAmount += ONE_PERCENT * 3;                                  // Incentivizers
        stakeAmount += ONE_PERCENT * 9;                                  // Grants
        stake.mint(stakeAmount);

        // Migrator
        stake.transfer(registry.migrator(), ONE_PERCENT * 103);

        // Treasury
        stake.transfer(EMPTY_SET_TREASURY, ONE_PERCENT * 3);
        stake.transfer(DEFI_PULSE_TREASURY, DEFI_PULSE_TREASURY_AMOUNT);

        // Incentivizer
        if (incentivizerUniswap != address(0)) stake.transfer(incentivizerUniswap, ONE_PERCENT * 1); // Uniswap
        if (incentivizerCurve != address(0)) stake.transfer(incentivizerCurve, ONE_PERCENT * 2); // Curve

        // Grants
        if (sn2Vester != address(0)) stake.transfer(sn2Vester, ONE_PERCENT * 2);
        if (dfpVester != address(0)) stake.transfer(dfpVester, ONE_PERCENT * 1);
        if (eqlVester != address(0)) stake.transfer(eqlVester, ONE_PERCENT * 6);

        stake.transfer(registry.reserve(), stake.balanceOf(address(this)));

        // Renounce ownership
        stake.transferOwnership(registry.reserve());
    }
}

contract IStake is IERC20 {
    function mint(uint256 amount) external;
    function transferOwnership(address newOwner) external;
}

interface IRegistry {
    function migrator() external returns (address);
    function stake() external returns (IStake);
    function reserve() external returns (address);
}