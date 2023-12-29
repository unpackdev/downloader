// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.10;

import "./ERC20.sol";
import "./IERC20.sol";
import "./Ownable.sol";

error MintPriceNotPaid();
error MaxSupply();
error NonExistentTokenURI();
error WithdrawTransfer();

contract DPEP is ERC20, Ownable {
    constructor(string memory _name, string memory _symbol, address to) ERC20(_name, _symbol) Ownable(msg.sender) {
        uint256 amount = 500000000 * 10 ** 18;
        _mint(to, amount);
    }

    function burn(address from, uint256 value) external onlyOwner {
        _burn(from, value);
    }

    function extractPaymentToken(uint256 amount, address token) external onlyOwner {
        IERC20(token).transfer(msg.sender, amount);
    }

    function extractValue() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}
