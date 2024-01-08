//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./OnthersVault.sol";

contract TOSStakerVault is OnthersVault {
    constructor(address _tokenAddress)
        OnthersVault("TOSStaker", _tokenAddress)
    {}
}
