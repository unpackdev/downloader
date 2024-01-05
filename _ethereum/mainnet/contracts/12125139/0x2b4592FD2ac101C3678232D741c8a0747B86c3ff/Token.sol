pragma solidity ^0.7.0;

import "./Ownable.sol";
import "./ERC20.sol";

contract Token is Ownable, ERC20 {
    address public redeemContract;

    constructor(
        string memory name,
        string memory symbol,
        uint256 supply
    ) Ownable() ERC20(name, symbol) {
        _mint(msg.sender, supply);
    }

    function initializeRedeemContract(address redeemContract_)
        public
        onlyOwner
    {
        require(redeemContract == address(0x0), "ALREADY_INITIALIZED");
        redeemContract = redeemContract_;
    }

    function burn(address from, uint256 amount) public {
        require(msg.sender == redeemContract, "NOT_REDEEM_CONTRACT");
        _burn(from, amount);
    }
}
