//             AAA                                        tttt            iiii          RRRRRRRRRRRRRRRR      iiii                                       
//            A:::A                                    ttt:::t           i::::i         R::::::::::::::::R   i::::i                                      
//           A:::::A                                   t:::::t            iiii          R::::::RRRRRR:::::R   iiii                                       
//          A:::::::A                                  t:::::t                          RR:::::R     R:::::R                                             
//         A:::::::::A         nnnn  nnnnnnnn    ttttttt:::::ttttttt    iiiiiii           R::::R     R:::::R iiiiii     ssssssssss       eeeeeeeeeeee    
//        A:::::A:::::A        n:::nn::::::::nn  t:::::::::::::::::t    i:::::i           R::::R     R:::::R i::::i   ss::::::::::s    ee::::::::::::ee  
//       A:::::A A:::::A       n::::::::::::::nn t:::::::::::::::::t     i::::i           R::::RRRRRR:::::R  i::::i ss:::::::::::::s  e::::::eeeee:::::ee
//      A:::::A   A:::::A      nn:::::::::::::::ntttttt:::::::tttttt     i::::i           R:::::::::::::RR   i::::i s::::::ssss:::::se::::::e     e:::::e
//     A:::::A     A:::::A       n:::::nnnn:::::n      t:::::t           i::::i           R::::RRRRRR:::::R  i::::i  s:::::s  ssssss e:::::::eeeee::::::e
//    A:::::AAAAAAAAA:::::A      n::::n    n::::n      t:::::t           i::::i           R::::R     R:::::R i::::i    s::::::s      e:::::::::::::::::e 
//   A:::::::::::::::::::::A     n::::n    n::::n      t:::::t           i::::i           R::::R     R:::::R i::::i       s::::::s   e::::::eeeeeeeeeee  
//  A:::::AAAAAAAAAAAAA:::::A    n::::n    n::::n      t:::::t    tttttt i::::i           R::::R     R:::::R i::::i ssssss   s:::::s e:::::::e           
// A:::::A             A:::::A   n::::n    n::::n      t::::::tttt:::::ti::::::i        RR:::::RRRRRRR:::::R i::::i s:::::ssss::::::se::::::::e          
//A:::::A               A:::::A  n::::n    n::::n      tt::::::::::::::ti::::::i ...... R::::::R:::::R:::::R i::::i s::::::::::::::s  e::::::::eeeeeeee  
//A::::A                 A:::::A n::::n    n::::n        tt:::::::::::tti::::::i .::::. R::::::R:::::R::::R  i::::i  s::::::::::ss    ee:::::::::::::e  
//AAAAA                   AAAAAAAnnnnnn    nnnnnn          ttttttttttt  iiiiiiii ...... RRRRRRRRRRRRRRRRRR   iiiiii   sssssssssss        eeeeeeeeeeeeee 
                                                      

pragma solidity ^0.4.25;

contract Token {

    function totalSupply() constant returns (uint256 supply) {}
    function balanceOf(address _owner) constant returns (uint256 balance) {}
    function transfer(address _to, uint256 _value) returns (bool success) {}
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {}
    function approve(address _spender, uint256 _value) returns (bool success) {}
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {}

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}

contract StandardToken is Token {

    function transfer(address _to, uint256 _value) returns (bool success) {
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 public totalSupply;
}

contract AntiBise is StandardToken { 
    string public name;                  
    uint8 public decimals;                
    string public symbol;                 
    string public version = 'H1.0';
    uint256 public unitsOneEthCanBuy;     
    uint256 public totalEthInWei;         
    address public fundsWallet;           

    function AntiBise() {
        balances[msg.sender] = 100000000000000000000000;            
        totalSupply = 100000000000000000000000;                     
        name = "AntiBise";                                  
        decimals = 18;                                               
        symbol = "ANBIS";                                             
        fundsWallet = msg.sender;                                   
    }

    function() public payable{
        totalEthInWei = totalEthInWei + msg.value;
        uint256 amount = msg.value * unitsOneEthCanBuy;
        require(balances[fundsWallet] >= amount);

        balances[fundsWallet] = balances[fundsWallet] - amount;
        balances[msg.sender] = balances[msg.sender] + amount;

        Transfer(fundsWallet, msg.sender, amount); 
        fundsWallet.transfer(msg.value);                             
    }

    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);

        if(!_spender.call(bytes4(bytes32(sha3("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData)) { throw; }
        return true;
    }
}