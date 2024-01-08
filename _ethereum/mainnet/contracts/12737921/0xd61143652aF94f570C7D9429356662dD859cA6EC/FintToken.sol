pragma solidity ^0.8.0;
import "./ERC20PresetFixedSupply.sol";

contract FintToken is ERC20PresetFixedSupply {
    constructor(address owner) ERC20PresetFixedSupply(
        "Fintropy",
        "FINT",
        30000000*10**18,
        owner
    ) {}
}