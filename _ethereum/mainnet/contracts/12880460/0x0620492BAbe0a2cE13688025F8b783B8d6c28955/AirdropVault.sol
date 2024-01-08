//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./WhitelistVault.sol";

contract AirdropVault is WhitelistVault {
    constructor(address _tosAddress, uint256 _maxInputOnce)
        WhitelistVault("Airdrop", _tosAddress, _maxInputOnce)
    {}
}
