pragma solidity ^0.8.2;

import "./Initializable.sol";

abstract contract BurnModule is Initializable {
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    event Burn (address indexed owner, uint amount);
}