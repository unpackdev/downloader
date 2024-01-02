// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
}

contract BurnProposal {
    IERC20 public constant TORN = IERC20(0x77777FeDdddFfC19Ff86DB637967013e6C6A116C);
    // 25% supply of TORN
    uint public constant BURN_AMOUNT = 2_500_000 ether;
    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    /**
     * @dev Burn 25% supply of unused TORN in order to increase value
     */
    function executeProposal() external {
        TORN.transfer(BURN_ADDRESS, BURN_AMOUNT);
    }
}