// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;


import "./Ownable.sol";
import "./ERC20.sol";


contract MEO is Ownable, ERC20 {
    constructor() ERC20("MEO", "MEO") {
        _mint(msg.sender, 1 * 10**8 * 10**18);
    }

    receive() external payable {}
}