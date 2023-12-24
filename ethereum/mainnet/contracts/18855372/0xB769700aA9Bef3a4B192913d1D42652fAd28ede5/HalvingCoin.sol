//SPDX-License-Identifier: MIT
 
pragma solidity ^0.8.7;
 
contract HalvingCoin {
 
uint private _totalSupply = 20000000000 * 10 ** 18;
string private _name = "HalvingCoin";
string private _symbol = "HC";
uint private _decimals = 18;

mapping(address => uint) private _balances;

constructor(){
    _balances[msg.sender] = _totalSupply;
}

function name() public view returns (string memory){
    return _name;
}
 
function symbol() public view returns (string memory){
    return _symbol;
}
 
 function decimals() public view virtual returns (uint8) {
        return 18;
}

function balanceOf(address owner) public view returns(uint){
    return _balances[owner];
}

function transfer(address to, uint value) public returns(bool){
    require(balanceOf(msg.sender) >= value, "Insuficient balance.");
    _balances[to] += value;
    _balances[msg.sender] -= value;
    emit Transfer(msg.sender, to, value);
    return true;
}

event Transfer(address indexed from, address indexed to, uint value);

}