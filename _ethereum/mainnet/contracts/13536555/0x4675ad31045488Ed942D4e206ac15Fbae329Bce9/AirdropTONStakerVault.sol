//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./DesignedVault.sol";

contract AirdropTONStakerVault is DesignedVault {
    constructor(address _docAddress)
        DesignedVault("AirdropTONStaker", _docAddress)
    {}
}
