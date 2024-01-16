pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC20.sol";

contract GoldPlanAndLearnToEarnToken is ERC20, Ownable {
    constructor() ERC20("GOLF PLAY & LEARN TO EARN", "GPLE") {
        _mint(_msgSender(), 5_000_000_000_000_000_000_000_000_000);
    }

    function mint(address account, uint256 amount) public onlyOwner {
        _mint(account, amount);
    }
}
