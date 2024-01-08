pragma solidity 0.6.12;

import "./ERC20.sol";
import "./ERC20Burnable.sol";


contract ONUSToken is ERC20Burnable {

    constructor() public ERC20("ONUS", "ONUS") {
        ERC20._mint(_msgSender(), 40000000 * 10 ** 18);
    }

}
