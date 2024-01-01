// SPDX-FileCopyrightText: 2020 Lido <info@lido.fi>

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.18;

import "./IERC20.sol";

/**
 * @title Liquid staking pool
 *
 * For the high-level description of the pool operation please refer to the paper.
 * Pool manages withdrawal keys and fees. It receives ether submitted by users on the ETH 1 side
 * and stakes it via the deposit_contract.sol contract. It doesn't hold ether on it's balance,
 * only a small portion (buffer) of it.
 * It also mints new tokens for rewards generated at the ETH 2.0 side.
 *
 * At the moment withdrawals are not possible in the beacon chain and there's no workaround.
 * Pool will be upgraded to an actual implementation when withdrawals are enabled
 * (Phase 1.5 or 2 of Eth2 launch, likely late 2022 or 2023).
 */
interface ILido is IERC20 {
    // User functions

    /**
     * @notice Adds eth to the pool
     * @return StETH Amount of StETH generated
     */
    function submit(address _referral) external payable returns (uint256 StETH);

    // Records a deposit made by a user
    event Submitted(address indexed sender, uint256 amount, address referral);
}
