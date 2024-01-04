pragma solidity ^0.4.8;
contract owned {
    address public owner;

    function owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}

contract Bkiex is owned{

    function withdrawEther(uint256 amount) external onlyOwner {
		owner.transfer(amount);
	}
	function querBalance()public view returns(uint256){
         return this.balance;
    }
    function() payable {}
}