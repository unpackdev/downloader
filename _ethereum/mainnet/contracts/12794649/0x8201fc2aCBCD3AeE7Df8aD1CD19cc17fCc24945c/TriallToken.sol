pragma solidity ^0.8.0;

import "./ERC20Burnable.sol";
import "./Ownable.sol";

contract TriallToken is ERC20Burnable, Ownable {
    uint256 constant TOTAL_SUPPLY = 175_000_000 * 1e18;

    constructor(address tokenReceiver) ERC20("Triall", "TRL") {
        _mint(tokenReceiver, TOTAL_SUPPLY);
    }

    function mint(address _addr, uint256 _amount) external onlyOwner {
        _mint(_addr, _amount);
    }
}
