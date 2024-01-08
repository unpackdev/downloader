//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.3;

import "./QuadraticBondingCurve.sol";

contract PSI is QuadraticBondingCurve {
    address public DEEP_GEMS_CONTRACT;
    
    constructor()
        QuadraticBondingCurve("PSI", "PSI", 
            5e15, // Curve scaling factor
            2500000 * 1e18 // Total supply: 2,500,000 tokens
        )
    {}

    function initialize(address deepGemsContract) public {
        require(DEEP_GEMS_CONTRACT == address(0), "already initialized");
        DEEP_GEMS_CONTRACT = deepGemsContract;
    }

    // This calls the internal transfer function, bypassing the allowance
    // check when transferring psi to the deep gems contract.
    // It can only be called by the deep gems contract.
    function transferToDeepGems(address sender, uint256 amount) public {
        require(
            msg.sender == DEEP_GEMS_CONTRACT,
            "transferToDeepGems can only be called by the deep gems contract"
        );
        _transfer(sender, DEEP_GEMS_CONTRACT, amount);
    }
}
