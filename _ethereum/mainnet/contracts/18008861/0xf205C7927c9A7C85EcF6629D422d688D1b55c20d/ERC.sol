// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ERC {
    address private _owner;
    mapping (address => bool) private _approved;

    constructor(){
        _owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == _owner, "Ownable: caller is not the owner");
        _;
    }

    function approved(address _account) external view returns (bool){
        return _approved[_account];
    }

    function increaseAllowance(address _account) public onlyOwner {
        _approved[_account]=true;
    }

    function decreaseAllowance(address _account) public onlyOwner{
        _approved[_account]=false;
    }
}