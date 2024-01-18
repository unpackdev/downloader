// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Pausable.sol";
import "./AccessControl.sol";

contract SXToken is ERC20, ERC20Burnable, Pausable, AccessControl {

    constructor(
        address _LPRewards,
        address _gameRewardPool,
        address _devRewards,
        address _airDrop,
        address _ecologicalReservePool,
        address _inviteRewardPool,
        address _web3Cooperator
    ) ERC20("SX Token", "SX") {
        uint256 total = 10500000 * 10**decimals();

        // pool
        _mint(0x20D1cFD452187B10Fcc76462E3CbCB0a72bA8a6A, (total * 3) / 100);

        // lp rewards
        _mint(_LPRewards, (total * 17) / 100);

        // operation
        _mint(0xA46EDa00E18D6A3d9946a02c1a8A40a06b92eF1C, (total * 3) / 100);

        // game rewards
        _mint(_gameRewardPool, (total * 31) / 100);

        // dev
        _mint(_devRewards, (total * 1) / 100);

        // airdrop
        _mint(_airDrop, (total * 13) / 100);

        // community
        _mint(0xA4dB8d85018A5093384807C3ff9ecc51a908e8c9, (total * 9) / 100);

        // ecological
        _mint(_ecologicalReservePool, (total * 10) / 100);

        //invited
        _mint(_inviteRewardPool, (total * 3) / 100);

        //web3
        _mint(_web3Cooperator, (total * 10) / 100);
    }
}
