pragma solidity ^0.8.0;

import "./ERC20.sol";

contract ArbitragePreSaleToken is ERC20 {
    uint256 initialSupply = 50000000;
    address immutable FLUID_TREASURY = 0x7f41eE0Cf90bf4401385f5A0187F3A0ABaEB82Ab;
    constructor() ERC20("Fluid Arbitrage Fund Sale", "FAFS") {
        _mint(FLUID_TREASURY, initialSupply * (10 ** uint256(decimals())));
    }
}