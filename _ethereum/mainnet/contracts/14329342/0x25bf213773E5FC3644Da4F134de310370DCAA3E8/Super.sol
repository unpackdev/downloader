pragma solidity 0.7.5;

import "./ERC20.sol";
import "./Ownable.sol";

abstract contract Super is ERC20, Ownable {

    constructor ( string memory name_, string memory symbol_, uint8 decimals_ ) ERC20( name_, symbol_, decimals_ ) {}
}