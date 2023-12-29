pragma solidity 0.4.16;


interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }



contract TokenERC20 {

    string public constant name = "Credit File";

    string public constant symbol = "CF";

    uint8 public constant decimals = 18; // 18 是建议的默认值

    uint256 public constant INIT_TOTALSUPPLY = 210000000;

    address public constant tokenWallet = 0x703aa484D04F7824e33B308Cc04df92F934a6D0D;

    uint256 public totalSupply;



    mapping (address => uint256) public balanceOf;

    mapping (address => mapping (address => uint256)) public allowance;



    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed from, address indexed to, uint256 value);
    
    event Burn(address indexed from, uint256 value);


    function TokenERC20() public {

        totalSupply = INIT_TOTALSUPPLY * 10 ** uint256(decimals);

        balanceOf[tokenWallet] = totalSupply;

    }





    function _transfer(address _from, address _to, uint _value) internal {

        require(balanceOf[_from] >= _value);

        require(balanceOf[_to] + _value > balanceOf[_to]);

        uint previousBalances = balanceOf[_from] + balanceOf[_to];

        balanceOf[_from] -= _value;

        balanceOf[_to] += _value;

        Transfer(_from, _to, _value);
        
        if(_to == address(0)) Burn(_from, _value);

        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);

    }



    function transfer(address _to, uint256 _value) public returns (bool) {

        _transfer(msg.sender, _to, _value);

        return true;

    }



    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {

        require(_value <= allowance[_from][msg.sender]); // Check allowance

        allowance[_from][msg.sender] -= _value;

        _transfer(_from, _to, _value);

        return true;

    }



    function approve(address _spender, uint256 _value) public returns (bool success) {

        allowance[msg.sender][_spender] = _value;
        
        Approval(msg.sender, _spender, _value);

        return true;

    }



    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {

        tokenRecipient spender = tokenRecipient(_spender);

        if (approve(_spender, _value)) {

            spender.receiveApproval(msg.sender, _value, this, _extraData);

            return true;

        }

    }

    function totalSupply() public view returns(uint256) {

        uint256 total_Supply = totalSupply - balanceOf[address(0)];

        return total_Supply;
        
    }

}