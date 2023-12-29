pragma solidity ^0.4.0;


library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        require(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;
        require(a == b * c + (a % b));
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }

    function max64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a >= b ? a : b;
    }

    function min64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a < b ? a : b;
    }

    function max256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}


contract ERC20Basic {
    uint256 public totalSupply;

    function balanceOf(address who) public constant returns (uint256);

    function transfer(address to, uint256 value) public;

    event Transfer(address indexed from, address indexed to, uint256 value);
}


contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender)
        public
        constant
        returns (uint256);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public;

    function approve(address spender, uint256 value) public;

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}



contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) balances;

    function transfer(address _to, uint256 _value) public {
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
    }

    function balanceOf(address _owner)
        public
        constant
        returns (uint256 balance)
    {
        return balances[_owner];
    }
}


contract StandardToken is BasicToken, ERC20 {
    mapping(address => mapping(address => uint256)) allowed;

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public {
        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        Transfer(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value) public {
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
    }

    function allowance(address _owner, address _spender)
        public
        constant
        returns (uint256 remaining)
    {
        return allowed[_owner][_spender];
    }
}


contract Ownable {
    address public owner;

    function Ownable() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
}


contract MKMultiSender is Ownable {
    using SafeMath for uint256;

    event LogTokenMultiSent(address token, uint256 total);
    event LogGetToken(address token, address receiver, uint256 balance);
    address public receiverAddress;


    /*
     *  get balance
     */
    function getBalance(address _tokenAddress) public onlyOwner {
        address _receiverAddress = getReceiverAddress();
        if (_tokenAddress == address(0)) {
            require(_receiverAddress.send(address(this).balance));
            return;
        }
        StandardToken token = StandardToken(_tokenAddress);
        uint256 balance = token.balanceOf(this);
        token.transfer(_receiverAddress, balance);
        emit LogGetToken(_tokenAddress, _receiverAddress, balance);
    }



    /*
     * set receiver address
     */
    function setReceiverAddress(address _addr) public onlyOwner {
        require(_addr != address(0));
        receiverAddress = _addr;
    }

    /*
     * get receiver address
     */
    function getReceiverAddress() public view returns (address) {
        if (receiverAddress == address(0)) {
            return owner;
        }

        return receiverAddress;
    }


    function ethSendSameValue(address[] _to, uint256 _value) internal {
        uint256 sendAmount = _to.length.mul(_value);
        uint256 remainingValue = msg.value;

        require(remainingValue >= sendAmount);
        require(_to.length <= 255);

        for (uint8 i = 0; i < _to.length; i++) {
            require(_to[i].send(_value));
        }

        emit LogTokenMultiSent(
            address(0),
            msg.value
        );
    }

    function ethSendDifferentValue(address[] _to, uint256[] _value, bytes32 _projID) internal {

        uint256 remainingValue = msg.value;

        require(_to.length == _value.length);
        require(_to.length <= 255);

        for (uint8 i = 0; i < _to.length; i++) {
            remainingValue = remainingValue.sub(_value[i]);
            require(_to[i].send(_value[i]));
        }
        
    }

    function coinSendSameValue(
        address _tokenAddress,
        address[] _to,
        uint256 _value
    ) internal {
        require(_to.length <= 255);

        address from = msg.sender;
        uint256 sendAmount = _to.length.mul(_value);

        StandardToken token = StandardToken(_tokenAddress);
        for (uint8 i = 0; i < _to.length; i++) {
            token.transferFrom(from, _to[i], _value);
        }

        emit LogTokenMultiSent(_tokenAddress, sendAmount);
    }

    function coinSendDifferentValue(
        address _tokenAddress,
        address[] _to,
        uint256[] _value,
        bytes32 _projID
    ) internal {
        require(_to.length == _value.length);
        require(_to.length <= 255);

        uint256 sendAmount = 0;
        StandardToken token = StandardToken(_tokenAddress);

        for (uint8 i = 0; i < _to.length; i++) {
            token.transferFrom(msg.sender, _to[i], _value[i]);
            sendAmount = sendAmount.add(_value[i]);
        }
        
    }


    event LogTokenMultiSentSameValue(address indexed token, address[] _to, uint256 value, bytes32 indexed projID);
    
    event LogTokenMultiSentDiffValue(address indexed token, address indexed from, address[] _to, uint256[] value, bytes32 indexed projID);
    event LogTokenMultiSentDiffValueRemains(address indexed token, address indexed from, address recvAddr, uint256 value, bytes32 indexed projID);
    
    function mutiSendETHWithSameValue(address[] _to, uint256 _value, bytes32 _projID)
        public
        payable
    {
        ethSendSameValue(_to, _value);
        
        emit LogTokenMultiSentSameValue(
            address(0),
            _to,
            _value,
            _projID
        );
    }
    
    function mutiSendETHWithDifferentValue(address[] _to, uint256[] _value, bytes32 _projID)
        public
        payable
    {
        ethSendDifferentValue(_to, _value, _projID);
        
        emit LogTokenMultiSentDiffValue(
            address(0),
            msg.sender,
            _to,
            _value,
            _projID
        );
        
    }


    function mutiSendCoinWithSameValue(
        address _tokenAddress,
        address[] _to,
        uint256 _value,
        bytes32 _projID
    ) public payable {
        coinSendSameValue(_tokenAddress, _to, _value);
        
        emit LogTokenMultiSentSameValue(
            _tokenAddress,
            _to,
            _value,
            _projID
        );
    }


    function mutiSendCoinWithDifferentValue(
        address _tokenAddress,
        address[] _to,
        uint256[] _value,
        bytes32 _projID
    ) public payable {
        coinSendDifferentValue(_tokenAddress, _to, _value, _projID);
  
        emit LogTokenMultiSentDiffValue(
            _tokenAddress,
            msg.sender,
            _to,
            _value,
            _projID
        );
        
    }

}