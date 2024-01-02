/** 
   (                  )     (               (     
   )\     (   (    ( /( (   )\ )  (     (   )\ )  
 (((_)   ))\  )(   )\()))\ (()/(  )\   ))\ (()/(  
 )\___  /((_)(()\ (_))/((_) /(_))((_) /((_) ((_)) 
((/ __|(_))   ((_)| |_  (_)(_) _| (_)(_))   _| |  
 | (__ / -_) | '_||  _| | | |  _| | |/ -_)/ _` |  
  \___|\___| |_|   \__| |_| |_|   |_|\___|\__,_|

Web: https://certifiedprotocol.net/

TG: https://t.me/Certified_Portal

Twitter (X): https://twitter.com/certified__eth

**/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

contract ERC20Basic {
    uint8 private constant _decimals = 9;
    uint256 private constant _tTotal = 100 * 10**6 * 10**_decimals;
    string private constant _name = unicode"Certified";
    string private constant _symbol = unicode"CFD";


    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Transfer(address indexed from, address indexed to, uint tokens);

    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;


    constructor() { 
        balances[msg.sender] = _tTotal;
    }  

    function totalSupply() public pure returns (uint256) {
	    return _tTotal;
    }
    
    function balanceOf(address tokenOwner) public view returns (uint) {
        return balances[tokenOwner];
    }

    function transfer(address receiver, uint numTokens) public returns (bool) {
        require(numTokens <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender] - numTokens;
        balances[receiver] = balances[receiver] + numTokens;
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }

    function approve(address delegate, uint numTokens) public returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function allowance(address owner, address delegate) public view returns (uint) {
        return allowed[owner][delegate];
    }

    function transferFrom(address owner, address buyer, uint numTokens) public returns (bool) {
        require(numTokens <= balances[owner]);    
        require(numTokens <= allowed[owner][msg.sender]);
    
        balances[owner] = balances[owner] - numTokens;
        allowed[owner][msg.sender] = allowed[owner][msg.sender] - numTokens;
        balances[buyer] = balances[buyer] + numTokens;
        emit Transfer(owner, buyer, numTokens);
        return true;
    }
}