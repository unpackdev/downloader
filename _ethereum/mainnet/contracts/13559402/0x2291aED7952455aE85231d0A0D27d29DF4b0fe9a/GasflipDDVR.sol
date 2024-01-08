
// SPDX License Indentifier: MIT License

import "./Context.sol";
import "./IERC20.sol";
import "./ERC20.sol";


pragma solidity ^0.8.3;

contract Token is ERC20 {

    constructor () ERC20("Dodona Metaverse", "DDVR") {
        _mint(msg.sender, 77777777 * (10 ** uint256(decimals())));
    }
}
