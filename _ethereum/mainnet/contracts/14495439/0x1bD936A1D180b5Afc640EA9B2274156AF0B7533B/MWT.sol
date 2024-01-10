pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IERC20.sol";
import "./ERC20Burnable.sol";

/**
* Mountain Wolf
* https://www.mountainwolf.com
*/
contract MountainWolfToken is Ownable, ERC20Burnable {

    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) {
        uint256 totalSupply = 2 * 1e8 * 1e18; // 200.000.000 tokens

        /*
           _mint is an internal function in ERC20.sol that is only called here,
           and CANNOT be called ever again
       */
        _mint(msg.sender, totalSupply);
    }

    function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyOwner {
        IERC20(tokenAddress).transfer(owner(), tokenAmount);
    }

    function recoverETH(uint256 amount) external onlyOwner {
        (bool sent, bytes memory data) = owner().call{value: amount}("");
        require(sent, "Failed to send Ether");
    }

    receive() external payable {}
}
