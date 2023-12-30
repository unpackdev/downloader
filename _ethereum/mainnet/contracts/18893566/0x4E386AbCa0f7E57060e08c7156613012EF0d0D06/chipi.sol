// Oval3 coin
pragma solidity >=0.8.17;

import "./ERC20.sol";
import "./Ownable.sol";
import "./IERC20.sol";

error MintPriceNotPaid();
error MaxSupply();
error NonExistentTokenURI();
error WithdrawTransfer();

contract Oval3 is Ownable, ERC20 {
    constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) Ownable(msg.sender) {
        uint256 amount = 5000000 * 10 ** 18;
        _mint(msg.sender, amount);
    }

    function burn(address from, uint256 value) external onlyOwner {
        _burn(from, value);
    }
}
