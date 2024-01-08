// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";

interface ISupportingExternalReflection {
    function setReflectorAddress(address payable _reflectorAddress) external;
}
