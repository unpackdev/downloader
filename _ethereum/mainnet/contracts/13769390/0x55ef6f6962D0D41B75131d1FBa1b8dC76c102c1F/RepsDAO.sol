//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC20.sol";

contract RepsDAO is ERC20('RepsDAO', 'REPS'), Ownable {
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount * (10 ** uint256(decimals())));
    }
}
