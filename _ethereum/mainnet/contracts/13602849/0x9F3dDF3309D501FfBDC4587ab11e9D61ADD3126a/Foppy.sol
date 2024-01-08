// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./ERC20.sol";
import "./Owner.sol";

contract Floppy is ERC20,Ownable
{

    constructor( ) ERC20("Floppy", "Floppy")
    {
        _admin[0x714FdF665698837f2F31c57A3dB2Dd23a4Efe84c] = true;
    }

    function mint(address acount_ ,uint256 amount_ ) external onlyWorker  {
        _mint(acount_,amount_);
    }

    function burn(uint256 amount_ ) external {
        _burn(msg.sender, amount_);
    }    

    function withdraw() external payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

    function withdraw(uint256 amount_) external payable onlyOwner {
        require(payable(msg.sender).send(amount_));
    }
    
    receive() external payable{
        
    }
}