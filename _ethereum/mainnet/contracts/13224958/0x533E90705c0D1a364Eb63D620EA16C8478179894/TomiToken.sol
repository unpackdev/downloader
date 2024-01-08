// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./ERC20.sol";

contract TomiToken is ERC20 {
    uint8 private constant COMMUNITY_INDEX = 0;
    uint8 private constant DEVELOPMENT_INDEX = 1;
    uint8 private constant LIQUIDITY_INDEX = 2;
    uint8 private constant COMMUNITY_LOCKER1_INDEX = 3;
    uint8 private constant COMMUNITY_LOCKER2_INDEX = 4;
    uint8 private constant INVALID_INDEX = 5;

    // 1500 M total supply
    uint256[5] private _pools_amount = [
        375 * 10**(6 + 18), // COMMUNITY_SUPPLY_AT_LAUCH, // 375M at lauch date
        250 * 10**(6 + 18), // DEVELOPMENT_SUPPLY,
        750 * 10**(6 + 18), // LIQUIDITY_SUPPLY,
        100 * 10**(6 + 18), // COMMUNITY_LOCKER1_SUPPLY, 100M from 2nd year – Sep 12th, 2022
        25 * 10**(6 + 18) // COMMUNITY_LOCKER2_SUPPLY, 25M from 3rd year – Sep 12th 2023
    ];

    bool[5] public _minted_pool;
    address private _owner;

    constructor(
        address community,
        address develop,
        address liquidity
    ) public ERC20("TOMI", "TOMI") {
        require(community != address(0), "TomiToken: ZERO ADDRESS");
        require(develop != address(0), "TomiToken: ZERO ADDRESS");
        require(liquidity != address(0), "TomiToken: ZERO ADDRESS");

        _owner = msg.sender;

        _mint(community, _pools_amount[COMMUNITY_INDEX]);
        _minted_pool[COMMUNITY_INDEX] = true;

        _mint(develop, _pools_amount[DEVELOPMENT_INDEX]);
        _minted_pool[DEVELOPMENT_INDEX] = true;

        _mint(liquidity, _pools_amount[LIQUIDITY_INDEX]);
        _minted_pool[LIQUIDITY_INDEX] = true;

        _minted_pool[COMMUNITY_LOCKER1_INDEX] = false;
        _minted_pool[COMMUNITY_LOCKER2_INDEX] = false;
    }

    function addLocker(uint8 pool_index, address pool_address) external {
        require(msg.sender == _owner);
        require(pool_address != address(0), "TomiToken: ZERO ADDRESS");
        require(pool_index >= COMMUNITY_LOCKER1_INDEX);
        require(pool_index <= COMMUNITY_LOCKER2_INDEX);
        require(_minted_pool[pool_index] == false);

        _mint(pool_address, _pools_amount[pool_index]);
        _minted_pool[pool_index] = true;
    }
}
