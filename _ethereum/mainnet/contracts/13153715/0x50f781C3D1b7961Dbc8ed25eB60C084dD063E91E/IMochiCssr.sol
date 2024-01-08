// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Float.sol";

interface IMochiCssr {
    function getPrice(address _asset)
        external
        view
        returns (float memory price);
}
