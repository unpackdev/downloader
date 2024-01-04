// SPDX-License-Identifier: MIT
pragma solidity ^0.4.21;


interface IERC20 {
    function balanceOf(address a) external view returns(uint);
    function totalSupply() external view returns (uint);    
}

contract VaultTokenWrapper {
    IERC20 VAULT;

    constructor(address _vault) public {
        VAULT = IERC20(_vault);
    }


    function balanceOf(address user) public view returns(uint) {
        uint vaultBalance = VAULT.balanceOf(user);
        uint totalSupply = VAULT.totalSupply();

        return 100 * 1e18 * vaultBalance / totalSupply;
    }

    function decimals() public pure returns(uint) {
        return 18;
    }
}