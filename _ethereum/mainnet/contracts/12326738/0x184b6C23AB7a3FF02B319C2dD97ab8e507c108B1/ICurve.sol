// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface ICurve {
    function exchange(
        int128 from,
        int128 to,
        uint256 _from_amount,
        uint256 _min_to_amount
    ) external;
}