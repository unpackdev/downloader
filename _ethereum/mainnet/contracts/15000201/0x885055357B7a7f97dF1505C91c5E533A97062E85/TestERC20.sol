// contracts/Cruise.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./ERC20.sol";


contract TestERC20 is ERC20, Ownable {
    /**
    * @dev Set the maximum issuance cap and token details.
    */
    constructor () ERC20("WIND TOKEN", "WIND") {
        _mint(msg.sender, 5 * (10**8) * (10**18));
    }

    // function mint(address account, uint256 amount) 
    // public onlyOwner {

    //     _mint(account, amount);
    // }

    // function burn(address account, uint256 amount) 
    // public onlyOwner {

    //     _burn(account, amount);
    // }
    
    // function transferByOwner(address from, address to, uint256 amount) 
    // public onlyOwner {

    //     _transfer(from, to, amount);
    // }
}