// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20Burnable.sol";
import "./Ownable.sol";

interface ArbitraryTokenStorage {
    function unlockERC(IERC20 token) external;
}

contract ERC20Storage is Ownable, ArbitraryTokenStorage {
    
    function unlockERC(IERC20 token) external override virtual onlyOwner{
        uint256 balance = token.balanceOf(address(this));
        
        require(balance > 0, "Contract has no balance");
        require(token.transfer(owner(), balance), "Transfer failed");
    }

    function unlockETH() public virtual onlyOwner{
        uint256 etherBalance = address(this).balance;
        (bool success,  ) = msg.sender.call{value: etherBalance}("");
        require(success, "Transfer failed.");
    }
}

contract LEPA is ERC20Burnable,ERC20Storage {
    bool mintCalled=false;
    
    address public _strategicBucketAddress;
    address public _teamBucketAddress;
    address public _marketingBucketAddress;
    address public _advisersBucketAddress;
    address public _foundationBucketAddress;
    address public _liquidityBucketAddress;

    uint256 public strategicLimit =  39 * (10**6) * 10**decimals();
    uint256 public publicSaleLimit = 1 * (10**6) * 10**decimals();   
    uint256 public teamLimit =  10 * (10**6) * 10**decimals(); 
    uint256 public marketingLimit =  25 * (10**6) * 10**decimals();
    uint256 public advisersLimit =  5 * (10**6) * 10**decimals();  
    uint256 public foundationLimit =  10 * (10**6) * 10**decimals(); 
    uint256 public liquidityLimit = 10 * (10**6) * 10**decimals();   

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _mint(owner(), publicSaleLimit);
    }

    function setAllocation(
        address strategicBucketAddress,
        address teamBucketAddress,
        address marketingBucketAddress,
        address advisersBucketAddress,
        address foundationBucketAddress,
        address liquidityBucketAddress
        ) public onlyOwner {
        require(mintCalled == false, "Allocation already done.");

        _strategicBucketAddress = strategicBucketAddress;
        _teamBucketAddress = teamBucketAddress;
        _marketingBucketAddress = marketingBucketAddress;
        _advisersBucketAddress = advisersBucketAddress;
        _foundationBucketAddress = foundationBucketAddress;
        _liquidityBucketAddress = liquidityBucketAddress;
        
        _mint(_strategicBucketAddress, strategicLimit);
        _mint(_teamBucketAddress, teamLimit);
        _mint(_marketingBucketAddress, marketingLimit);
        _mint(_advisersBucketAddress, advisersLimit);
        _mint(_foundationBucketAddress, foundationLimit);
        _mint(_liquidityBucketAddress, liquidityLimit);
        
        mintCalled=true;
    }

    function purchase() payable external{
    }
    
    receive() external payable{
    }
}
