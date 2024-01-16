// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "./Fixed18.sol";

interface IContractPayoffProvider {
    function payoff(Fixed18 price) external view returns (Fixed18 payoff);
}
