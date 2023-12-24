/*
    Copyright 2020 Empty Set Squad <emptysetsquad@protonmail.com>
    Copyright 2023 Lucky8 Lottery

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

pragma solidity ^0.8.20;
pragma experimental ABIEncoderV2;

import "./IERC20.sol";
import "./State.sol";
import "./Permission.sol";
import "./Upgradeable.sol";

import "./VRFCoordinatorV2Interface.sol";

import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router.sol";

contract Migrator1 is State, Permission, Upgradeable {
    // migration for new token
    function initialize() initializer override public {
        IToken newToken = IToken(0x5e72AD4Bf50c952B11A63B6769d02bB486A9a897);

        IUniswapV2Pair oldPair = IUniswapV2Pair(token().pair());
        IUniswapV2Pair newPair = IUniswapV2Pair(newToken.pair());

        // snapshot balance before LP removal
        uint tokenBalanceBeforeLPRemove = token().balanceOf(address(this));
        uint usdcBalanceBeforeLPRemove = usdc().balanceOf(address(this));

        // burn old LP token
        oldPair.transfer(address(oldPair), oldPair.balanceOf(address(this)));
        oldPair.burn(address(this));

        // determine amounts to seed new pool with
        uint tokenLPAmount = token().balanceOf(address(this)) - tokenBalanceBeforeLPRemove;
        uint usdcLPAmount = usdc().balanceOf(address(this)) - usdcBalanceBeforeLPRemove;

        // migrate to new token
        newToken.setMigrationEnabled(true);
        token().approve(address(newToken), type(uint).max);
        newToken.migrateFromV2(token().balanceOf(address(this)));

        // seed new LP pool
        newToken.transfer(address(newPair), tokenLPAmount);
        usdc().transfer(address(newPair), usdcLPAmount);
        newPair.mint(address(this));

        // update token in state
        _state.provider.token = newToken;

        // resolve pending lottery draws
        for(uint i = 0; i < epoch(); i++){
            uint256 requestId = VRFCoordinatorV2Interface(VRFCoordinator()).requestRandomWords(
                VRFKeyhash(), // keyHash
                ChainlinkSubId(),
                3, // minimumRequestConfirmations
                1_000_000, // callbackGasLimit
                uint32(getWinningTickets()) // numWords
            );

            // Store chainlink request id
            setChainlinkRequestId(i, requestId);
        }

        upgradeTo(address(0x30BA9743a384D2b81172acCaf608456341fBdE2b));
    }
}
