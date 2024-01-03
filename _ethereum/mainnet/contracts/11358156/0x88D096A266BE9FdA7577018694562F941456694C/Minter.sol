// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.6.11;

// https://github.com/curvefi/curve-dao-contracts/blob/master/contracts/Minter.vy
interface Minter {
    function mint(address) external;
}
