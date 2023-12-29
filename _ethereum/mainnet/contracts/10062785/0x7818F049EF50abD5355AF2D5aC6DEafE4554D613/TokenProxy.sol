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
		_name = "XFA";
		_symbol = "XFA";

		_supply = 1000000000 * 10**18; // 18 decimal places are allowed
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

// File: zos-lib/contracts/upgradeability/Proxy.sol

pragma solidity ^0.4.24;

/**
 * @title Proxy
 * @dev Implements delegation of calls to other contracts, with proper
 * forwarding of return values and bubbling of failures.
 * It defines a fallback function that delegates all calls to the address
 * returned by the abstract _implementation() internal function.
 */
contract Proxy {
  /**
   * @dev Fallback function.
   * Implemented entirely in `_fallback`.
   */
  function () payable external {
    _fallback();
  }

  /**
   * @return The Address of the implementation.
   */
  function _implementation() internal view returns (address);

  /**
   * @dev Delegates execution to an implementation contract.
   * This is a low level function that doesn't return to its internal call site.
   * It will return to the external caller whatever the implementation returns.
   * @param implementation Address to delegate.
   */
  function _delegate(address implementation) internal {
    assembly {
      // Copy msg.data. We take full control of memory in this inline assembly
      // block because it will not return to Solidity code. We overwrite the
      // Solidity scratch pad at memory position 0.
      calldatacopy(0, 0, calldatasize)

      // Call the implementation.
      // out and outsize are 0 because we don't know the size yet.
      let result := delegatecall(gas, implementation, 0, calldatasize, 0, 0)

      // Copy the returned data.
      returndatacopy(0, 0, returndatasize)

      switch result
      // delegatecall returns 0 on error.
      case 0 { revert(0, returndatasize) }
      default { return(0, returndatasize) }
    }
  }

  /**
   * @dev Function that is run as the first thing in the fallback function.
   * Can be redefined in derived contracts to add functionality.
   * Redefinitions must call super._willFallback().
   */
  function _willFallback() internal {
  }

  /**
   * @dev fallback implementation.
   * Extracted to enable manual triggering.
   */
  function _fallback() internal {
    _willFallback();
    _delegate(_implementation());
  }
}

// File: openzeppelin-solidity/contracts/AddressUtils.sol

pragma solidity ^0.4.24;


/**
 * Utility library of inline functions on addresses
 */
library AddressUtils {

  /**
   * Returns whether the target address is a contract
   * @dev This function will return false if invoked during the constructor of a contract,
   * as the code is not actually created until after the constructor finishes.
   * @param _addr address to check
   * @return whether the target address is a contract
   */
  function isContract(address _addr) internal view returns (bool) {
    uint256 size;
    // XXX Currently there is no better way to check if there is a contract in an address
    // than to check the size of the code at that address.
    // See https://ethereum.stackexchange.com/a/14016/36603
    // for more details about how this works.
    // TODO Check this again before the Serenity release, because all addresses will be
    // contracts then.
    // solium-disable-next-line security/no-inline-assembly
    assembly { size := extcodesize(_addr) }
    return size > 0;
  }

}

// File: zos-lib/contracts/upgradeability/UpgradeabilityProxy.sol

pragma solidity ^0.4.24;



/**
 * @title UpgradeabilityProxy
 * @dev This contract implements a proxy that allows to change the
 * implementation address to which it will delegate.
 * Such a change is called an implementation upgrade.
 */
contract UpgradeabilityProxy is Proxy {
  /**
   * @dev Emitted when the implementation is upgraded.
   * @param implementation Address of the new implementation.
   */
  event Upgraded(address implementation);

  /**
   * @dev Storage slot with the address of the current implementation.
   * This is the keccak-256 hash of "org.zeppelinos.proxy.implementation", and is
   * validated in the constructor.
   */
  bytes32 private constant IMPLEMENTATION_SLOT = 0x7050c9e0f4ca769c69bd3a8ef740bc37934f8e2c036e5a723fd8ee048ed3f8c3;

  /**
   * @dev Contract constructor.
   * @param _implementation Address of the initial implementation.
   */
  constructor(address _implementation) public {
    assert(IMPLEMENTATION_SLOT == keccak256("org.zeppelinos.proxy.implementation"));

    _setImplementation(_implementation);
  }

  /**
   * @dev Returns the current implementation.
   * @return Address of the current implementation
   */
  function _implementation() internal view returns (address impl) {
    bytes32 slot = IMPLEMENTATION_SLOT;
    assembly {
      impl := sload(slot)
    }
  }

  /**
   * @dev Upgrades the proxy to a new implementation.
   * @param newImplementation Address of the new implementation.
   */
  function _upgradeTo(address newImplementation) internal {
    _setImplementation(newImplementation);
    emit Upgraded(newImplementation);
  }

  /**
   * @dev Sets the implementation address of the proxy.
   * @param newImplementation Address of the new implementation.
   */
  function _setImplementation(address newImplementation) private {
    require(AddressUtils.isContract(newImplementation), "Cannot set a proxy implementation to a non-contract address");

    bytes32 slot = IMPLEMENTATION_SLOT;

    assembly {
      sstore(slot, newImplementation)
    }
  }
}

// File: contracts/TokenProxy.sol

pragma solidity >=0.4.21 <0.6.0;




/**
* @title TokenProxy
* @notice A proxy contract that serves the latest implementation of TokenProxy.
*/
contract TokenProxy is UpgradeabilityProxy, Authorizable {
	
  TokenStorage private dataStore;

	constructor(address _implementation, address storageAddress) public UpgradeabilityProxy(_implementation) {
  
		_owner = msg.sender;
		dataStore = TokenStorage(storageAddress);
	}

	function upgradeTo(address _nimplementation) public onlyOwner {
 
		_upgradeTo(_nimplementation);
	}

	function implementation() public view returns (address) {
 
		return _implementation();
	}
}