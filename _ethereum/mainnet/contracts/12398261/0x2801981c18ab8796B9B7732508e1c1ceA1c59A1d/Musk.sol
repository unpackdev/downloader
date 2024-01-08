// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
/** OpenZeppelin Dependencies Upgradeable */
// import "./Initializable.sol";
import "./Ownable.sol";
import "./ERC20.sol";
/** OpenZepplin non-upgradeable Swap Token (hex3t) */
import "./IERC20.sol";

/** Local Interfaces */

contract Musk is ERC20, Ownable {
    uint8 private constant _DECIMALS = 18;
    uint256 private constant _DECIMALFACTOR = 10**uint256(_DECIMALS);
    uint256 private initialSupply = 69420000000 * _DECIMALFACTOR;

    constructor() public ERC20('Wario Musk', 'wMusk') {
        _mint(msg.sender, initialSupply);
    }
}
