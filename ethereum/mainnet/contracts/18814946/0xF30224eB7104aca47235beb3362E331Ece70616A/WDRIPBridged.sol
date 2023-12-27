// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//Made with ☕ by https://t.me/Quin_6 and https://t.me/Defi_Owll

import "./ERC20Burnable.sol";
import "./ERC20Permit.sol";
import "./ReentrancyGuard.sol";

import "./OFT.sol";

contract WDRIPBridged is OFT, ERC20Burnable, ERC20Permit {
    constructor(
        address _layerZeroEndpoint
    )
        OFT("Wrapped Drip", "WDRIP", _layerZeroEndpoint)
        ERC20Permit("Wrapped Drip")
    {}
}
