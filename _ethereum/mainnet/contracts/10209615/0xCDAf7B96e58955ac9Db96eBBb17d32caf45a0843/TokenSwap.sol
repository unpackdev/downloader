pragma solidity ^0.6.8;

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * See https://github.com/ethereum/EIPs/issues/179
 */
abstract contract ERC20Basic {
  function totalSupply() public view virtual returns (uint256);
  function balanceOf(address who) public view virtual returns (uint256);
  function transfer(address to, uint256 value) public virtual returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// This is an token swap contract for the Pamp Network (PAMP): https://pamp.network
contract TokenSwap is Ownable {
    
    // The token being swapped
    ERC20Basic public _oldToken;
    
    ERC20Basic public _newToken;
    
    event TokensClaimed(address addr, uint amount);
    
    mapping(address => bool) claimedAddrs;
    
    event Address(address addr);

    
    constructor (ERC20Basic oldToken, ERC20Basic newToken) public {
        _oldToken = oldToken;
        _newToken = newToken;
        
    }
    
    
    function swapTokens() public {
        require(!claimedAddrs[msg.sender], "Address already swapped tokens");
        claimedAddrs[msg.sender] = true;
        uint balance = _oldToken.balanceOf(msg.sender);
        _newToken.transfer(msg.sender, balance);
        emit TokensClaimed(msg.sender, balance);
    }
    
    function transferTokens(address to, uint256 amount) public onlyOwner {
        _newToken.transfer(to, amount);
    }
    
}