// SPDX-License-Identifier: Apache-2.0

/*
    Copyright 2022 0xPlasma Alliance
*/

/***
 *      ______             _______   __                                             
 *     /      \           |       \ |  \                                            
 *    |  $$$$$$\ __    __ | $$$$$$$\| $$  ______    _______  ______ ____    ______  
 *    | $$$\| $$|  \  /  \| $$__/ $$| $$ |      \  /       \|      \    \  |      \ 
 *    | $$$$\ $$ \$$\/  $$| $$    $$| $$  \$$$$$$\|  $$$$$$$| $$$$$$\$$$$\  \$$$$$$\
 *    | $$\$$\$$  >$$  $$ | $$$$$$$ | $$ /      $$ \$$    \ | $$ | $$ | $$ /      $$
 *    | $$_\$$$$ /  $$$$\ | $$      | $$|  $$$$$$$ _\$$$$$$\| $$ | $$ | $$|  $$$$$$$
 *     \$$  \$$$|  $$ \$$\| $$      | $$ \$$    $$|       $$| $$ | $$ | $$ \$$    $$
 *      \$$$$$$  \$$   \$$ \$$       \$$  \$$$$$$$ \$$$$$$$  \$$  \$$  \$$  \$$$$$$$
 *                                                                                  
 *                                                                                  
 *                                                                                  
 */
 
pragma solidity ^0.6.5;
pragma experimental ABIEncoderV2;

import "./IEtherTokenV06.sol";
import "./AuthorizableV06.sol";
import "./IStaking.sol";

/// @dev The collector contract for protocol fees
contract FeeCollector is AuthorizableV06 {
    /// @dev Allow ether transfers to the collector.
    receive() external payable { }

    constructor() public {
        _addAuthorizedAddress(msg.sender);
    }

    /// @dev   Approve the staking contract and join a pool. Only an authority
    ///        can call this.
    /// @param weth The WETH contract.
    /// @param staking The staking contract.
    /// @param poolId The pool ID this contract is collecting fees for.
    function initialize(
        IEtherTokenV06 weth,
        IStaking staking,
        bytes32 poolId
    )
        external
        onlyAuthorized
    {
        weth.approve(address(staking), type(uint256).max);
        staking.joinStakingPoolAsMaker(poolId);
    }

    /// @dev Convert all held ether to WETH. Only an authority can call this.
    /// @param weth The WETH contract.
    function convertToWeth(
        IEtherTokenV06 weth
    )
        external
        onlyAuthorized
    {
        if (address(this).balance > 0) {
            weth.deposit{value: address(this).balance}();
        }
    }
}
