pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC20.sol";

contract Ecc is Ownable, ERC20 {
    constructor() ERC20("Etherconnect Coin", "ECC") {
        _mint(msg.sender, 1000000000 * (10 ** uint256(decimals())));
    }
    function decimals() public view virtual override returns (uint8) {
        return 8;
    }
}
