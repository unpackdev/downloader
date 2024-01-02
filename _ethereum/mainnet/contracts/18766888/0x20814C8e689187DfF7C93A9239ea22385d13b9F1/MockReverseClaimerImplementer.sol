//SPDX-License-Identifier: MIT
pragma solidity >=0.8.17 <0.9.0;

import "./ENS.sol";
import "./ReverseClaimer.sol";

contract MockReverseClaimerImplementer is ReverseClaimer {
    constructor(ENS ens, address claimant) ReverseClaimer(ens, claimant) {}
}
