pragma solidity ^0.8.4;

import "./ERC20.sol";
import "./Ownable.sol";

contract CRYPTO is ERC20,Ownable {
    uint256 MAX = 100000000 * 1e18;

    constructor() public ERC20('New Crypto Space', 'CRYPTO'){
        _mint(msg.sender, MAX);
    }
}
