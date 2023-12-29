// File: contracts/XFI.sol

// File: contracts/XFI.sol

pragma solidity >=0.4.21 <0.6.0;

// Safemath library 
library SafeMath {

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }
  

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }
  

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }
  

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

// ownable contract
contract Ownable {
  address owner;

   event transferOwn(address _owner, address newOwner);

		modifier onlyOwner() {
			require(isOwner(msg.sender), "OwnerRole: caller does not have the Owner role");
			_;
		}

		function isOwner(address account) public view returns (bool) {
			return account == owner;
		}

		function getOwner() public view returns (address) {
			return owner;
		}

		 function transferOwnership(address newOwner) public onlyOwner returns (address) {
	         require( newOwner != address(0), "new owner address is invalid");
			 emit transferOwn(owner, newOwner);
	         owner = newOwner;
			 return owner;
      }
}


contract XFITOKEN is Ownable {
    
    using SafeMath for uint256;
    bool public freeTransfer = false;
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) internal allowed;
    struct tlock {
		uint256 amount;
		uint256 validity;
	}
    mapping(address => tlock) internal _locks;
    
 event Approval(address indexed owner, address indexed spender, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Burn(address indexed _burner, uint256 _value);
  event Lock(address indexed _of, uint256 _value, uint256 _time);
  event Unlock(address indexed _of);
    
    string public _name;  
    string public  _symbol;
    uint8 public _decimals;
    uint public _totalSupply ;
    uint256 public _lockTime = 31536000;

    mapping ( address => bool ) whitelistedContracts;

    
  constructor() public {
		owner = msg.sender;
		_decimals = 18;
		_name = "XFI";
		_symbol = "XFI";

		_totalSupply = 1000000000 * 10**18; // 18 decimal places are allowed
		balances[owner] = _totalSupply;
	}


  

  function setTokenName(string memory newName) public onlyOwner {
        _name = newName;

    }
  function getTokenName() public view returns( string memory){
    return _name;
  }
  function setTokenSymbol(string memory newTokenSymbol) public onlyOwner {
        _symbol = newTokenSymbol;

    }
  function getTokenSymbol() public view returns( string memory){
    return _symbol;
  }
 
  function decimals() public view returns ( uint8 ){
    return _decimals;
  }

  function totalSupply() public view returns( uint256 ){
    return _totalSupply;
  }
	

   modifier ownerOrEnabledTransfer() {
        require(freeTransfer || msg.sender == owner || _isWhitelistedContract( msg.sender) , "cannot transfer since freetransfer is false or sender not owner");
        _;
    }
    
  // only payload size
//   modifier onlyPayloadSize(uint size) {
//         assert(msg.data.length == size + 4);
//         _;
//     }
    
  // enable the transfer by the owner
  function enableTransfer() public onlyOwner {
        freeTransfer = true;
    }

  // transfer lock 
  function transferLock(address _to, uint256 _value, uint256 _time) public returns (bool) {
	 require(
        balances[msg.sender]>= _value
        && _value > 0
        );
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
		_lock(_to, _value, now.add(_time));
		return true;
	}

 function lock(address _to, uint256 _value, uint256 _time) ownerOrEnabledTransfer public returns (bool) {
		_lock(_to, _value, now.add(_time));
		return true;
	}

  function _changeLockTimeDefault( uint256 _newlockTime ) public onlyOwner returns( bool ){
    _lockTime = _newlockTime;
    return true;
  } 
	
    function unlock(address _of) public returns (bool)
     {
		   _unlock(_of);
		   return true;
       }
       
    function burn(uint256 _value) public onlyOwner returns (bool) {
		_burn(msg.sender, _value);
		return true;
	}
	
	function burnFrom(address _of, uint256 _value) public onlyOwner returns (bool) {
		_burn(_of, _value);
		return true;
	}
	
	function getLockedData(address _of) public view returns (uint256 validity, uint256 amount) {
		return _getLockedData(_of);
	}
	
	
	function getLockValidity(address _of) public view returns (uint256 validity, uint256 amount) {
		return _getLockedData(_of);
	}
	

  function transfer(address _to, uint256 _value) ownerOrEnabledTransfer public returns (bool) {
        require(
        getTransferrableAmount(msg.sender)>= _value
        && _value > 0
        );
        if( !freeTransfer && msg.sender == owner ){
          require( _lockTime > 0 );
          _lock(_to, _value, block.timestamp.add(_lockTime));
        }
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

  function getTransferrableAmount( address _of ) public view returns (uint256) {
   uint amount = _getLockAmount(_of);
    return balances[_of].sub(amount);
  }

 
  function balanceOf(address _owner) public view returns (uint256 bal) {
    return balances[_owner];
  }
  
  function transferFrom(address _from, address _to, uint256 _value) ownerOrEnabledTransfer public returns (bool) {
    uint256 _allowance = allowed[_from][msg.sender];
    // Safe math functions will throw if value invalid
    require( getTransferrableAmount( _from ) >= _value );
    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }
 
  function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }
  
  	function _lock(address recipient, uint256 amount, uint256 validity) internal {
		require(recipient != address(0), "ERC20: transfer from the zero address");
		require(amount > 0, "Amount can not be 0 or less");
		require(validity > 0, "validity can not be 0");
        uint256 avalidity = _getLockValidity(recipient);
		if ( _locks[recipient].amount > 0 ) {
		    _locks[recipient].amount = _locks[recipient].amount.add(amount);
			//_addLockAmount(recipient, amount);
		} else {
			_locks[recipient] = tlock(amount, validity);
		}
		emit Lock(recipient, amount, validity);
	}

      function unlockOwner( address _of ) public onlyOwner {
        _locks[_of].validity = now;
        _locks[_of].amount = 0;
      }
	
	
	  function _unlock(address _of) internal {
		require(_locks[_of].validity > now, "LockError: Unable to unlock");
		_locks[_of].validity = now;
		_locks[_of].amount = 0;
		emit Unlock(_of);
	}

     function _burn(address _of, uint256 amount) internal {
	   require(amount <= balances[_of]);
        _totalSupply -= amount;
        balances[_of] -= amount;
		emit Burn(_of, amount);
	}
	
  // get the lock amount
	function _getLockAmount(address _of) public view returns (uint256) {
		if (_locks[_of].validity > now) return _locks[_of].amount;
    return 0;
	}

  // get the lock validity
    function _getLockValidity(address _of) public view  returns (uint256) {
		if (_locks[_of].validity > 0) return _locks[_of].validity;
    return 0;
	}

	function _getLockedData(address _of) public view returns (uint256 validity, uint256 amount) {
		if (_locks[_of].validity > now) return (_locks[_of].validity, _locks[_of].amount);
		return (now, 0);
	}
   
   // extend the validity of lock of a user
    function _extendLockValidity(address _of, uint256 _time) internal {
		_locks[_of].validity = _locks[_of].validity.add(_time);
	}

  // function to add the lock amount
  // will be callable only by the owner
    function _addLockAmount(address _of, uint256 _amount) public onlyOwner returns (bool) {
     require( balances[_of] >= _locks[_of].amount.add( _amount ));
     _locks[_of].amount = _locks[_of].amount.add(_amount);
     return true;
	}

  // function to get the lock amount 
  // the amount should be less than the balance of the account 
  // this function should be callable by the owner only
  // when lock amount is reduced , the rest tokens become transferrable
	function _reduceLockAmount(address _of, uint256 _amount) public onlyOwner returns (bool) {
    require( balances[ _of ] >= _amount );
		_locks[_of].amount = _locks[_of].amount.sub(_amount);
    return true;
	}


  function _addWhitelistedContract( address _admin ) public onlyOwner returns (bool) {
    whitelistedContracts[_admin] = true;
    return true;
  }

  function _removeWhitelistedContract( address _admin ) public onlyOwner returns (bool) {
    whitelistedContracts[_admin] = false;
    return true;
  }

  function _isWhitelistedContract( address _admin ) public view returns (bool) {
    return whitelistedContracts[_admin];
  }
  

}