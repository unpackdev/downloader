pragma solidity ^0.8.0; 


import "./ERC20.sol";
import "./Ownable.sol";

contract DysToken is ERC20("DysToken", "DGLD"), Ownable {
    uint256 public MaxSupply = 10000000;
    uint256 public burnMint = 10000000000000000000000;
    

    function mint(address account) external onlyOwner() {
        _mint(account, burnMint);
    }
}