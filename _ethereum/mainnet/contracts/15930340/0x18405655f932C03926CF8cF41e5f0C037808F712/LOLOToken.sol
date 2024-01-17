pragma solidity ^0.8.0;
import "./ERC20.sol";

contract LOLOToken is ERC20 {
    uint8 private constant _decimals = 18;
    uint256 private constant _initSupply = 1_000_000_000;

    constructor(address tokenHolder) ERC20('LOLO', 'LOLO') {
        _mint(tokenHolder, _initSupply * (10**uint256(_decimals)));
    }
}
