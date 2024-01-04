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

import "./SafeMath.sol";
import "./Oracle.sol";
import "./Regulator.sol";
import "./Bonding.sol";
import "./Govern.sol";
import "./Constants.sol";

contract Implementation is State, Bonding, Regulator, Govern {
    using SafeMath for uint256;

    event Advance(uint256 indexed epoch, uint256 block, uint256 timestamp);
    event Incentivization(address indexed account, uint256 amount);

    function initialize() public initializer {
        if (address(_state.provider.dollar) != address(0)) {
            // Reward committer
            incentivize(msg.sender, Constants.getAdvanceIncentive());
        }
    }

    function initializeOracle() public {
        require(address(dollar()) != address(0), "dollar not initialized!");
        require(address(_state.provider.oracle) == address(0), "oracle initialized!");
        Oracle oracle = new Oracle(address(dollar()));
        oracle.setup();
        
        _state.provider.oracle = IOracle(address(oracle));
    }

    function initializeTokenAddresses(IDollar dollar, IERC20 gov) public {
        require(address(_state.provider.dollar) == address(0), "dollar initialized!");
        require(address(_state.provider.governance) == address(0), "governance initialized!");

        _state.provider.dollar = dollar;
        _state.provider.governance = gov;
    }

    function initializePoolAddresses(
        address poolBonding,
        address poolLP,
        address poolGov
    ) public {
        require(_state.provider.poolBonding == address(0), "pool bonding initialized!");
        require(_state.provider.poolLP == address(0), "pool LP initialized!");
        require(_state.provider.poolGov == address(0), "pool gov initialized!");

        _state.provider.poolBonding = poolBonding;
        _state.provider.poolLP = poolLP;
        _state.provider.poolGov = poolGov;
    }

    function advance() external {
        // No -1 here as epoch only gets incremented on Bonding.step
        if (bootstrappingAt(epoch())) {
            // QSD #4
            // QSD #5
            incentivize(0xC1b89f59c600e4beFfD6df16186048f828d411f6, 1682e16); // 16.82
            incentivize(0xdBba5c9AB0F3Ac341Fc741b053678Ade367236e6, 1683e16); // 16.83
            incentivize(0x5aB60b1c7d78014c4490D5e78BA551D51729E1De, 6e18);
            incentivize(0xbcb8171050Fe9c08066a5008f5Da484cC5E8e3FF, 6e18);
            incentivize(0x8d4CA87F859D9581954586e671a66B2636fD7Bdd, 5e18);
            incentivize(0xB006be3e08b54DBdA89725a313803f4B1875259f, 6e18);
            incentivize(0xD6F82502F20647dd8d78DFFb6AD7F8D8193d5e29, 1093e16); // 10.93
            incentivize(0x81725dFB3F92f8301DDADe77E29536605e8Df162, 2986e16); // 29.86
            incentivize(0x82e1dE949DF695AAA8053f53008320F8EAd52814,  528e16); // 5.28
            incentivize(0x5dDE36a3d062150AdbF1107c976A33D8E835aE62,  528e16); // 5.28
        } else {
            incentivize(poolGov(), 108e18); // 108 QSD to QSG stakers every epoch
        }

        Bonding.step();
        Regulator.step();

        emit Advance(epoch(), block.number, block.timestamp);
    }

    function incentivize(address account, uint256 amount) private {
        mintToAccount(account, amount);
        emit Incentivization(account, amount);
    }
}
