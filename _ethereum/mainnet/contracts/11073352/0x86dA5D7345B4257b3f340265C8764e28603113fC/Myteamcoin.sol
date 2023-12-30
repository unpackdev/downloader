pragma solidity ^0.5.0;
import "./ERC20.sol";
import "./ERC20Detailed.sol";


contract Myteamcoin is ERC20, ERC20Detailed {

    constructor () public ERC20Detailed("Myteamcoin", "MYC", 18) {
        _mint(msg.sender, 25000000000 * (10 ** uint256(decimals())));
    }
}