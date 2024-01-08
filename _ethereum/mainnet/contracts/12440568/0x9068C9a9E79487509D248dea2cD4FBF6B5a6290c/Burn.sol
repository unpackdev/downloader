pragma solidity 0.8.0;


import "./ERC20.sol";


contract BurnERC20 is ERC20 {
    constructor(
        string memory name,
        string memory symbol,
        uint256 supply
    ) public ERC20(name, symbol) {

    }
}
