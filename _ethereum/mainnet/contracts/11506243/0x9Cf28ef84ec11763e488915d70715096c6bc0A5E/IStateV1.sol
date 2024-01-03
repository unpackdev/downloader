// SPDX-License-Identifier: MIT

pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

import "./TypesV1.sol";

interface IStateV1 {

    function getPosition(
        uint256 id
    )
        external
        view
        returns (TypesV1.Position memory);

}
