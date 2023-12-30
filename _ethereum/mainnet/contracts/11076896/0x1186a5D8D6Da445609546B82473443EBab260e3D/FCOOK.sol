pragma solidity ^0.4.26;

contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}


// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------
contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

contract FCOOK is ERC20Interface, Owned, SafeMath {

    string public constant name = "Farming.Cooking";
    string public constant symbol = "FCOOK";
    uint8 public constant decimals = 18;  

    mapping(address => uint256) balances;

    mapping(address => mapping (address => uint256)) allowed;
    
    uint256 totalSupply_;
    uint256 totalBurned_;

    constructor() public {  
	    totalSupply_ = 2500 * 10 ** uint256(decimals);
	    balances[msg.sender] = totalSupply_;
    }  

    function totalSupply() public view returns (uint256) {
	    return totalSupply_;
    }
    
    function totalBurned() public view returns (uint256) {
	    return totalBurned_;
    }
    
    function balanceOf(address tokenOwner) public  view returns (uint256) {
        return balances[tokenOwner];
    }

    function transfer(address receiver, uint256 numTokens) public  returns (bool) {
        require(numTokens <= balances[msg.sender]);
        balances[msg.sender] = safeSub(balances[msg.sender],numTokens);
        balances[receiver] = safeAdd(balances[receiver],numTokens);
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }

    function approve(address delegate, uint256 numTokens) public  returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function allowance(address owner, address delegate) public  view returns (uint) {
        return allowed[owner][delegate];
    }

    function transferFrom(address owner, address buyer, uint256 numTokens) public  returns (bool) {
        require(numTokens <= balances[owner]);    
        require(numTokens <= allowed[owner][msg.sender]);
    
        balances[owner] = safeSub(balances[owner],numTokens);
        allowed[owner][msg.sender] = safeSub(allowed[owner][msg.sender],numTokens);
        balances[buyer] = safeAdd(balances[buyer],numTokens);
        emit Transfer(owner, buyer, numTokens);
        return true;
    }


    event Burn(address indexed burner, uint256 value);

    function burn(uint256 _value) public {
        _burn(msg.sender, _value);
    }

    function _burn(address _who, uint256 _value) internal {

        require(_value <= balances[_who]);
        balances[_who] = safeSub(balances[_who],_value);
        totalSupply_ = safeSub(totalSupply_,_value);
        totalBurned_ = safeAdd(totalBurned_,_value);
        emit Burn(_who, _value);
        emit Transfer(_who, address(0), _value);
    } 

    struct memoryWithDetails {
        uint256 _receiveTime;
        uint256 _receiveAmount;
        address _senderAddr;
        string _senderMemo;
    }

    mapping(address => memoryWithDetails[]) memoTexts;

    function sendtokenwithmemo(uint256 _amount, address _to, string memory _memo)  public returns(uint256) {
        memoTexts[_to].push(memoryWithDetails(now, _amount, msg.sender, _memo));
        transfer(_to, _amount);
        return 200;
    }

   function _checkmemotexts(address _addr, uint256 _index) public view returns(uint256,
   uint256,
   string memory,
   address) {

       uint256 rTime = memoTexts[_addr][_index]._receiveTime;
       uint256 rAmount = memoTexts[_addr][_index]._receiveAmount;
       string memory sMemo = memoTexts[_addr][_index]._senderMemo;
       address sAddr = memoTexts[_addr][_index]._senderAddr;
       if(memoTexts[_addr][_index]._receiveTime == 0){
            return (0, 0,"0", _addr);
        } else {
            return (rTime, rAmount,sMemo, sAddr);
        }
    }

   function getmemotextcountforaddr(address _addr) view public returns(uint256) {
       return  memoTexts[_addr].length;
   }
   
   // ------------------------------------------------------------------------
    // Don't accept ETH
    // ------------------------------------------------------------------------
    function () public payable {
        revert();
    }


    // ------------------------------------------------------------------------
    // Owner can transfer out any accidentally sent ERC20 tokens
    // ------------------------------------------------------------------------
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
}