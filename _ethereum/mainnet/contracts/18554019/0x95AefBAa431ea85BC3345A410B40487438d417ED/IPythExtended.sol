//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.18;

import "./IPyth.sol";

interface IPythExtended is IPyth {
    function priceFeedExists(bytes32 _id) external view returns (bool);
}
