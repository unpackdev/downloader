// File: contracts/AdminConversion.sol

// File: contracts/Ownable.sol

pragma solidity >=0.4.21 <0.6.0;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions". This adds two-phase
 * ownership control to OpenZeppelin's Ownable class. In this model, the original owner
 * designates a new owner but does not actually transfer ownership. The new owner then accepts
 * ownership and completes the transfer.
 */
contract Ownable {
  address _owner;

   event transferOwn(address _owner, address newOwner);

		modifier onlyOwner() {
			require(isOwner(msg.sender), "OwnerRole: caller does not have the Owner role");
			_;
		}

		function isOwner(address account) public view returns (bool) {
			return account == _owner;
		}

		function getOwner() public view returns (address) {
			return _owner;
		}

		 function transferOwnership(address newOwner) public onlyOwner returns (address) {
	         require( newOwner != address(0), "new owner address is invalid");
			 emit transferOwn(_owner, newOwner);
	         _owner = newOwner;
			 return _owner;
      }
}

// File: contracts/Authorizable.sol

pragma solidity >=0.4.21 <0.6.0;

/**
 * @title Authorizable
 * @dev The Authorizable contract has an authorizables address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Authorizable is Ownable {
  mapping(address => bool) public authorized;

		modifier onlyAuthorized() {
			require(isAuthorized(msg.sender), "AuthorizeError: caller does not have the Owner or Authorized role");
			_;
		}

		function isAuthorized(address account) public view returns (bool) {
			return authorized[account];
		}

		function addAuthorized(address _addr) public onlyOwner {

			authorized[_addr] = true;
		}

		function addAuthorizedInternal( address _addr ) internal {
			authorized[_addr] = true;
		}

		function removeAuthorizedInternal( address _addr ) internal {
			authorized[_addr] = false;
		}

		function removeAuthorized(address _addr) public onlyOwner {
   
			authorized[_addr] = false;
		}
}

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

pragma solidity ^0.4.24;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // assert(_b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn't hold
    return _a / _b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}

// File: contracts/TokenStorage.sol

pragma solidity >=0.4.21 <0.6.0;


/**
* @title TokenStorage
*/
contract TokenStorage  is Ownable{
  using SafeMath for uint256;

	// variables
	address internal _registryContract;

	uint8 internal _decimals;
	string internal _name;
	string internal _symbol;
	uint256 internal _supply;

	mapping( address => bool ) public whitelistedContracts;

	// struct
	struct tkyc {
		bytes32 dochash;
		bool status;
	}

	// mapping
	mapping(address => mapping(address => uint256)) internal _allowances;
	mapping(address => uint256) internal _balances;
	mapping(address => tkyc) internal _kycs;

	constructor() public {
    
		_owner = msg.sender;
		_decimals = 18;
		_name = "XfiniteAsset";
		_symbol = "XFA";

		_supply = 11500000000000000000000000; // 18 decimal places are allowed
		_balances[_owner] = _supply;
	}




	// proxy
	function _setRegistry(address _registry) public onlyOwner {
		require(_registry != address(0), "InvalidAddress: invalid address passed for proxy contract");
		_registryContract = _registry;
	}

	function _getRegistry() public view returns (address) {
		return _registryContract;
	}

	modifier isRegistry() {
		require(msg.sender == _registryContract, "AccessDenied: This address is not allowed to access the storage");
		_;
	}





	// utils
	function _getName() public view isRegistry returns (string) {
		return _name;
	}

	function _getSymbol() public view isRegistry returns (string) {
		return _symbol;
	}

	function _getDecimals() public view isRegistry returns (uint8) {
		return _decimals;
	}

	function _subSupply(uint256 _value) public isRegistry {
		_supply = _supply.sub(_value);
	}

	function _getSupply() public view isRegistry returns (uint256) {
		return _supply;
	}




	// allowance
	function _setAllowance(address _owner, address _spender, uint256 _value) public isRegistry {
 
		_allowances[_owner][_spender] = _value;
	}

	function _getAllowance(address _owner, address _spender) public view isRegistry returns (uint256) {

		return _allowances[_owner][_spender];
	}





	// balance
	function _addBalance(address _addr, uint256 _value) public isRegistry {
		require(_kycs[_addr].status == true, "KycError: Unable to make transaction");
		_balances[_addr] = _balances[_addr].add(_value);
	}

	function _subBalance(address _addr, uint256 _value) public isRegistry {
		require(_kycs[_addr].status == true, "KycError: Unable to make transaction");
		_balances[_addr] = _balances[_addr].sub(_value);
	}

	function _getBalance(address _addr) public view isRegistry returns (uint256) {
		return _balances[_addr];
	}



	// kyc
	function _setKyc(address _addr, bytes32 _value) public isRegistry {
		 tkyc memory item = tkyc( _value, true );
		_kycs[ _addr ] = item;
	}

	function _removeKyc(address _addr) public isRegistry {
		_kycs[_addr].dochash = "0x0";
		_kycs[_addr].status = false;
	}

	function _getKyc(address _addr) public view isRegistry returns (bytes32 dochash, bool status) {
		return (_kycs[_addr].dochash, _kycs[_addr].status);
	}

	function _verifyKyc(address _from, address _to) public view isRegistry returns (bool) {
		if (_kycs[_from].status == true && _kycs[_to].status == true) return true;
		return false;
	}

	function addWhitelistedContract( address _admin ) public onlyOwner returns (bool) {
		whitelistedContracts[_admin] = true;
	}

	function removeWhitelistedContract( address _admin ) public onlyOwner returns (bool) {
		whitelistedContracts[_admin] = false;
	}

	function isWhitelistedContract( address _admin ) public view returns (bool) {
		return whitelistedContracts[_admin];
	}
}

// File: contracts/XFAFirstVersionAbi.sol

pragma solidity >=0.4.21 <0.6.0;


// import "./ERC20.sol";
/**
* @title XFAFirstVersion
* @notice A basic ERC20 token with modular data storage
*/
contract XFAFirstVersion is Authorizable {

	TokenStorage private dataStore;

	uint256 public _version;

	// event
	event Burn(address indexed _burner, uint256 _value);
	event Transfer(address indexed _from, address indexed _to, uint256 _value);
	event Approval(address indexed _owner, address indexed _spender, uint256 _value);	

	constructor(address storeAddress) public {
		dataStore = TokenStorage(storeAddress);
	}

	// getters
	function name() public view returns (string) {
		return dataStore._getName();
	}

	function symbol() public view returns (string) {
		return dataStore._getSymbol();
	}

	function decimals() public view returns (uint8) {
		return dataStore._getDecimals();
	}


	function version() public view returns (uint256){
		return _version;
	}

	function totalSupply() public view returns (uint256) {
		return dataStore._getSupply();
	}

	function balanceOf(address account) public view returns (uint256) {
		return dataStore._getBalance(account);
	}

	function allowance(address _owner, address _spender) public view returns (uint256) {

		return dataStore._getAllowance(_owner, _spender);
	}

	function getAttributes(address _of) public view returns (bytes32 dochash, bool status) {

		return dataStore._getKyc(_of);
	}

	function verifyTransfer(address sender, address recipient, uint256 amount) public view returns (bool success) {
   
		require(sender != address(0), "AddressError: transfer from the zero address");
		require(recipient != address(0), "AddressError: transfer to the zero address");
		require(amount > 0, "Amount can not be 0 or less");
		return dataStore._verifyKyc(sender, recipient);
	}

	// setters
	function transfer(address _to, uint256 _value) public onlyAuthorized returns (bool) {
   
		require(verifyTransfer(msg.sender, _to, _value), "VerificationError: Unable ro process the transaction.");
		_transfer(msg.sender, _to, _value);
		return true;
	}

	function transferFrom(address _from, address _to, uint256 _value) public onlyAuthorized returns (bool) {
 
		require(verifyTransfer(_from, _to, _value), "VerificationError: Unable ro process the transaction.");
		require(dataStore._getAllowance(_from, msg.sender) >= _value, "AllowanceError: The spender does not hve the required allowance.");
		_transfer(_from, _to, _value);
		return true;
	}

	function approve(address _spender, uint256 _value) public onlyAuthorized returns (bool) {
    
		_approve(msg.sender, _spender, _value);
		return true;
	}


	function burn(uint256 _value) public returns (bool) {
  
		_burn(msg.sender, _value);
		return true;
	}

	function burnFrom(address _of, uint256 _value) public returns (bool) {
		bool isWhitelisted = dataStore.isWhitelistedContract( msg.sender );
		require( msg.sender == _owner || isWhitelisted );
		_burn(_of, _value);
		return true;
	}


	function setAttributes (address _of, bytes32 _dochash) public onlyOwner returns (bool) {
	 
		_setAttributes(_of, _dochash);
		return true;
	}

	function removeAttributes(address _of) public onlyOwner returns (bool) {
		
		_removeAttributes(_of);
		return true;
	}

	function addRole(address _addr) public onlyOwner returns (bool) {
		super.addAuthorized(_addr);
		return true;
	}

	function removeRole(address _addr) public onlyOwner returns (bool) {
		super.removeAuthorized(_addr);
		return true;
	}


	// internal
	function _approve(address owner, address spender, uint256 amount) internal {
   
		require(owner != address(0), "AddressError: approve from the zero address");
		require(spender != address(0), "AddressError: approve to the zero address");
		require(amount > 0, "Amount can not be 0 or less");
		require(dataStore._getBalance(owner) >= amount, "Insufficient Funds");

		dataStore._setAllowance(owner, spender, amount);
		emit Approval(owner, spender, amount);
	}

	function _transfer(address sender, address recipient, uint256 amount) internal {
   
		require(sender != address(0), "AddressError: transfer from the zero address");
		require(recipient != address(0), "AddressError: transfer to the zero address");
		require(amount > 0, "Amount can not be 0 or less");
		require(dataStore._getBalance(sender) >= amount, "Insufficient Funds");

		dataStore._subBalance(sender, amount);
		dataStore._addBalance(recipient, amount);
		emit Transfer(sender, recipient, amount);
	}

	function _burn(address sender, uint256 amount) internal {
		require(sender != address(0), "AddressError: transfer from the zero address");
		require(amount > 0, "Amount can not be 0 or less");
		require(dataStore._getBalance(sender) >= amount, "Insufficient Funds");

		dataStore._subBalance(sender, amount);
		dataStore._subSupply(amount);
		emit Burn(sender, amount);
	}

	function _setAttributes(address account, bytes32 dochash) internal {
		require(account != address(0), "AddressError: from the zero address");
		require(dochash.length > 0, "HashError: Hash can never be empty");
		dataStore._setKyc(account, dochash);
	}

	function _removeAttributes(address account) internal {
		require(account != address(0), "AddressError: from the zero address");
		dataStore._removeKyc(account);
	}
}

// File: contracts/XFIAbi.sol

pragma solidity >=0.4.21 <0.6.0;

// ownable contract
contract Ownabled {
  address public owner;


  function Ownable() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    owner = newOwner;
  }
}


contract ERC20  {
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public  returns (bool);
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Burn(address indexed _burner, uint256 _value);
  event Lock(address indexed _of, uint256 _value, uint256 _time);
  event Unlock(address indexed _of);
}

contract XFITOKEN is ERC20, Ownabled {
    
    bool public freeTransfer = false;
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;
    struct tlock {
		uint256 amount;
		uint256 validity;
	}
    mapping(address => tlock) internal _locks;
    
    mapping ( address => bool ) whitelistedContracts;

    string public _name;  
    string public  _symbol;
    uint8 public _decimals;
    uint public _totalSupply ;
    uint256 public _lockTime;

    function name() public view returns( string ){
      return _name;
    }

    function symbol() public view returns( string ){
      return _symbol;
    }

    function decimals() public view returns ( uint8 ){
      return _decimals;
    }

    function totalSupply() public view returns( uint256 ){
      return _totalSupply;
    }
    
       
    constructor() public {
        owner = msg.sender;
        _decimals = 18;
        _name = "XfiniteUtility";
        _symbol = "XFI";

        _totalSupply = 4000000000000000000000000000; // 18 decimal places are allowed
        balances[owner] = _totalSupply;
      }


    modifier ownerOrEnabledTransfer() {
         require(freeTransfer || msg.sender == owner || _isWhitelistedContract( msg.sender) , "cannot transfer since freetransfer is false or sender not owner");
         _;
     }
       
    
  modifier onlyPayloadSize(uint size) {
        assert(msg.data.length == size + 4);
        _;
    }
    
  function enableTransfer() ownerOrEnabledTransfer() {
        freeTransfer = true;
    }

  function transferLock(address _to, uint256 _value, uint256 _time) public returns (bool) {

  }
	
    function unlock(address _of) public returns (bool){}
    
    function lock(address _to, uint256 _value, uint256 _time) ownerOrEnabledTransfer public returns (bool) {}

       
    function burn(uint256 _value) public onlyOwner returns (bool) {}
	
	function burnFrom(address _of, uint256 _value) public onlyOwner returns (bool) {}
	
	function getLockedData(address _of) public view returns (uint256 validity, uint256 amount) {}
	
	
	function getLockValidity(address _of) public view returns (uint256 validity, uint256 amount) {}
	

  function transfer(address _to, uint256 _value) ownerOrEnabledTransfer public returns (bool) {}

  function getTransferrableAmount( address _of ) public view returns (uint256) {}

 
  function balanceOf(address _owner) public view returns (uint256 bal) { }
  
  function transferFrom(address _from, address _to, uint256 _value) ownerOrEnabledTransfer public returns (bool) {}

  function approve(address _spender, uint256 _value) public returns (bool) {}
 
  function allowance(address _owner, address _spender) public view returns (uint256 remaining) {}
  
  function _lock(address recipient, uint256 amount, uint256 validity) internal {}

  function unlockOwner( address _of ) public onlyOwner {}
	
	
	 function _unlock(address _of) internal {}

  function _burn(address _of, uint256 amount) public view returns (bool) {}
	
	function _getLockAmount(address _of) public view returns (uint256) {}

    function _getLockValidity(address _of) public view  returns (uint256) {}

	function _getLockedData(address _of) returns (uint256 validity, uint256 amount) {}
   
   // extend the validity of lock of a user
  function _extendLockValidity(address _of, uint256 _time) internal {}

  // function to add the lock amount
  // will be callable only by the owner
  function _addLockAmount(address _of, uint256 _amount) public onlyOwner returns (bool) {}

  // function to get the lock amount 
  // the amount should be less than the balance of the account 
  // this function should be callable by the owner only
  // when lock amount is reduced , the rest tokens become transferrable
	function _reduceLockAmount(address _of, uint256 _amount) public onlyOwner returns (bool) {}
	
  function _addWhitelistedContract( address _admin ) public onlyOwner returns (bool) {}

  function _removeWhitelistedContract( address _admin ) public onlyOwner returns (bool) {}

  function _isWhitelistedContract( address _admin ) public view returns (bool) {}
  

}

// File: contracts/AdminConversion.sol

pragma solidity >=0.4.21 <0.6.0;





contract AdminConversion is Ownable{

	mapping( address => uint ) last_accrual_payment_timestamp;

	XFAFirstVersion xfaProxy;
	XFITOKEN xfiToken;

	// the constructor value
	constructor( address _xfaProxy, address _xfi ) public {
		xfaProxy = XFAFirstVersion( _xfaProxy );
		xfiToken = XFITOKEN( _xfi );
		_owner = msg.sender;
	}

	// function to calculate the accrual against the last accrual done time
	function _calculateAccrual( address _of ) public view returns( uint256, uint256 ) {
		uint256 _balance = xfaProxy.balanceOf( _of );
		uint256 _currentTimeStamp = now;
		uint256 _lastTimestamp = last_accrual_payment_timestamp[ _of ];
		if( _lastTimestamp == 0 ){
			_lastTimestamp = 1585699200; // 04/01/2020 @ 12:00am (UTC)
		}
		uint256 _days  = (_currentTimeStamp - _lastTimestamp)/( 60 * 60 * 24 );
		uint256 _accrualAmount = (_balance * _days * 5 ) / (365 * 2);
		return ( _accrualAmount, _currentTimeStamp );

	}


	// function to calculate for the conversion part
	function _calculateConversion( address _of , uint256 _amount ) public view returns( uint256 ){
		uint256 _balance = xfaProxy.balanceOf( _of );
		require( _amount <= _balance );
		return 50 * _amount;
	} 

	// function to burn xfa of the address and also send the tokens in xfi 
	function _payoutAccrual( address _of, uint256  _time) public onlyOwner returns( bool ){
		var ( _amount, _updateLast) = _calculateAccrual( _of );
		// check the approval 
		require( xfiToken.allowance( xfiToken.owner(), address( this) ) >= _amount, "Insufficient tokens in admin contract");
		last_accrual_payment_timestamp[ _of ] = _updateLast;
		xfiToken.transferFrom( xfiToken.owner(), _of, _amount );
	    xfiToken.lock(_of, _amount, _time);
		return true;
	}

	// function payout conversion 
	function _payoutConversion( address _of, uint256 _amount, uint256 _time ) public onlyOwner returns ( bool ){
		uint256 _value = _calculateConversion( _of, _amount );
		require( xfiToken.allowance( xfiToken.owner(), address( this) ) >= _amount, "Insufficient tokens in admin contract" );
		xfaProxy.burnFrom( _of, _amount );
		//xfiToken.transferLock(_of, _amount, _time);
		xfiToken.transferFrom( xfiToken.owner(), _of, _value );
		xfiToken.lock(_of, _value, _time);
		return true;
	}


}