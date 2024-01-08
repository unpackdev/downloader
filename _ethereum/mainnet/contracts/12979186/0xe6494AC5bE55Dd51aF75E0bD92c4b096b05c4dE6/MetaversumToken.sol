// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "./ERC20.sol";

contract MetaversumToken is ERC20 {

    constructor(uint256 _supply) ERC20("Metaversum", "MEV") {
        _mint(msg.sender, _supply * (10 ** decimals()));
    }

}
