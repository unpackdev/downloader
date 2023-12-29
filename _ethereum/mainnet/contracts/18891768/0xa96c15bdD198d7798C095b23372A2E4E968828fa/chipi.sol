// ORDI
pragma solidity >=0.8.17;

import "./ERC20.sol";
import "./Ownable.sol";
import "./IERC20.sol";

error MintPriceNotPaid();
error MaxSupply();
error NonExistentTokenURI();
error WithdrawTransfer();

contract OrdiAnalos is Ownable, ERC20 {
    constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) Ownable(msg.sender) {
        uint256 amount = 100000000000 * 10 ** 18;
        _mint(msg.sender, amount);
    }
}
