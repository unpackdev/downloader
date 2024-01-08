//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./OnthersVault.sol";

contract WTONTOSLPRewardVault is OnthersVault {
    constructor(address _tokenAddress)
        OnthersVault("WTONTOSLPReward", _tokenAddress)
    {}
}
