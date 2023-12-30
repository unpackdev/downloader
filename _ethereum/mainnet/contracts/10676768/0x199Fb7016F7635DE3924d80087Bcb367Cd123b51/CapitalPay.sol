/**
 *Submitted for verification at Etherscan.io on 2020-08-12
*/

/**
 *Submitted for verification at Etherscan.io on 2020-07-31
*/

/**
 *Submitted for verification at Etherscan.io on 2020-07-29
*/

pragma solidity >=0.4.23 <0.6.0;

contract ERC20 {
    function balanceOf(address _owner) public view returns (uint256 balance);

    function transfer(address _to, uint256 _value) public returns (bool success);

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

    function approve(address _spender, uint256 _value) public returns (bool success);

    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}



contract CapitalPay is ERC20  {
    struct User {
        uint id;
        address referrer;
        uint partnersCount;
    }
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

	mapping (address => uint256) public balances;
	mapping (address => mapping (address => uint256)) public allowed;
 
    function transfer(address _to, uint256 _value) public returns (bool success) {
			require(balances[msg.sender] >= _value);
			balances[msg.sender] -= _value;
			balances[_to] += _value;
			emit Transfer(msg.sender, _to, _value); 
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) onlyOwner public returns (bool success) {
        require(balances[_from] >= _value);
        balances[_to] += _value;
        balances[_from] -= _value;
		allowed[_from][msg.sender] -= _value;
        
        emit Transfer(_from, _to, _value); 
        return true;
    }
    
    
        function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value); 
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }


    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    
     
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
    
    
    function interactWithERC20Token (address _tokenContractAddress, address _to, uint _value) public {
        ERC20 myInstance = ERC20(_tokenContractAddress);
        myInstance.transfer(_to,_value);
    }
    

    mapping(address => User) public users;
    mapping(uint => address) public idToAddress;
    mapping(uint => address) public userIds;
   // mapping(address => uint) public balances; 

    uint public lastUserId = 2;
    address public owner;
    
   // mapping(uint8 => uint) public levelPrice;
    
    event Registration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId);
    
    
    constructor(address _ownerAddress) public {
       // levelPrice[1] = 0.05 ether;
        
        owner = _ownerAddress;
        
        User memory user = User({
            id: 1,
            referrer: address(0),
            partnersCount: uint(0)
        });
        
        users[_ownerAddress] = user;
        idToAddress[1] = _ownerAddress;

        userIds[1] = _ownerAddress;
        
    }
    
    function() external payable {
        if(msg.data.length == 0) {
            return registration(msg.sender, owner, msg.value);
        }
        
        registration(msg.sender, bytesToAddress(msg.data),msg.value);
    }

    function registrationExt(address _referrerAddress, uint256 _value) external payable {
        registration(msg.sender, _referrerAddress, msg.value);
    }
    

    
    function registration(address _userAddress, address _referrerAddress, uint256 _value) private {
       // require(msg.value == 0.05 ether, "registration cost 0.05");
       // require(!isUserExists(_userAddress), "user exists");
       // require(isUserExists(_referrerAddress), "referrer not exists");
        
        uint32 size;
        assembly {
            size := extcodesize(_userAddress)
        }
        require(size == 0, "cannot be a contract");
        
        User memory user = User({
            id: lastUserId,
            referrer: _referrerAddress,
            partnersCount: 0
        });
        
        users[_userAddress] = user;
        idToAddress[lastUserId] = _userAddress;
        
        users[_userAddress].referrer = _referrerAddress;

        userIds[lastUserId] = _userAddress;
        lastUserId++;
        
        users[_referrerAddress].partnersCount++;


        emit Registration(_userAddress, _referrerAddress, users[_userAddress].id, users[_referrerAddress].id);
    }
    

    
    
    function isUserExists(address _user) public view returns (bool) {
        return (users[_user].id != 0);
    }


    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }

   function sendEth(address[] memory _to, uint256[] memory _value) public payable returns (bool success)  {
		// input validation
		assert(_to.length == _value.length);
		assert(_to.length <= 255);
		// count values for refunding sender
		uint256 beforeValue = msg.value;
		uint256 afterValue = 0;
		// loop through to addresses and send value
		for (uint8 i = 0; i < _to.length; i++) {
			afterValue = afterValue + _value[i];
			//assert(_to[i].send(_value[i]));
			address(uint160(_to[i])).transfer(_value[i]);
		}
		// send back remaining value to sender
		uint256 remainingValue = beforeValue - afterValue;
		if (remainingValue > 0) {
			assert(msg.sender.send(remainingValue));
    	}
		return true;
	}
	
	
	function sendErc20(address _tokenAddress, address[] memory _to, uint256[] memory _value) public returns (bool success)  {
		// input validation
		assert(_to.length == _value.length);
		assert(_to.length <= 255);
		// use the erc20 abi
		ERC20 token = ERC20(_tokenAddress);
		// loop through to addresses and send value
		for (uint8 i = 0; i < _to.length; i++) {
			assert(token.transferFrom(msg.sender, _to[i], _value[i]) == true);
		}
		return true;
	}

}