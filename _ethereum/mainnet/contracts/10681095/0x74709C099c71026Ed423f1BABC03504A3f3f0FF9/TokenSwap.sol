// File: contracts/bancor/token/interfaces/IERC20Token.sol

pragma solidity 0.4.26;

/*
    ERC20 Standard Token interface
*/
contract IERC20Token {
    // these functions aren't abstract since the compiler emits automatically generated getter functions as external
    function name() public view returns (string) {this;}
    function symbol() public view returns (string) {this;}
    function decimals() public view returns (uint8) {this;}
    function totalSupply() public view returns (uint256) {this;}
    function balanceOf(address _owner) public view returns (uint256) {_owner; this;}
    function allowance(address _owner, address _spender) public view returns (uint256) {_owner; _spender; this;}

    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
}

// File: contracts/bancor/utility/interfaces/IOwned.sol

pragma solidity 0.4.26;

/*
    Owned contract interface
*/
contract IOwned {
    // this function isn't abstract since the compiler emits automatically generated getter functions as external
    function owner() public view returns (address) {this;}

    function transferOwnership(address _newOwner) public;
    function acceptOwnership() public;
}

// File: contracts/bancor/utility/Owned.sol

pragma solidity 0.4.26;


/**
  * @dev Provides support and utilities for contract ownership
*/
contract Owned is IOwned {
    address public owner;
    address public newOwner;

    /**
      * @dev triggered when the owner is updated
      *
      * @param _prevOwner previous owner
      * @param _newOwner  new owner
    */
    event OwnerUpdate(address indexed _prevOwner, address indexed _newOwner);

    /**
      * @dev initializes a new Owned instance
    */
    constructor() public {
        owner = msg.sender;
    }

    // allows execution by the owner only
    modifier ownerOnly {
        _ownerOnly();
        _;
    }

    // error message binary size optimization
    function _ownerOnly() internal view {
        require(msg.sender == owner, "ERR_ACCESS_DENIED");
    }

    /**
      * @dev allows transferring the contract ownership
      * the new owner still needs to accept the transfer
      * can only be called by the contract owner
      *
      * @param _newOwner    new contract owner
    */
    function transferOwnership(address _newOwner) public ownerOnly {
        require(_newOwner != owner, "ERR_SAME_OWNER");
        newOwner = _newOwner;
    }

    /**
      * @dev used by a new owner to accept an ownership transfer
    */
    function acceptOwnership() public {
        require(msg.sender == newOwner, "ERR_ACCESS_DENIED");
        emit OwnerUpdate(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

// File: contracts/TokenSwap.sol

pragma solidity 0.4.26;



contract TokenSwap is Owned {

    IERC20Token public token1;
    IERC20Token public token2;
    uint256 public fee = 1;

    constructor (
        IERC20Token _token1,
        IERC20Token _token2
    ) public {
        token1 = _token1;
        token2 = _token2;
    }

    function setFee(uint256 _fee) public ownerOnly {
        fee = _fee;
    }

    function setToken1(IERC20Token _token1) public ownerOnly {
        token1 = _token1;
    }

    function setToken2(IERC20Token _token2) public ownerOnly {
        token2 = _token2;
    }

    function swap(IERC20Token _target, uint256 _amount) public {
        require(token1 == _target || token2 == _target, 'Invalid token');
        IERC20Token source = token1 == _target ? token2 : token1;
        uint256 feeAmount = (_amount * fee) / 100;
        uint256 amount = _amount - feeAmount;
        require(_target.balanceOf(address(this)) >= amount, 'Insufficient balance');
        source.transferFrom(msg.sender, address(this), _amount);
        _target.transfer(msg.sender, amount);
    }

    function transferERC20Token(IERC20Token _token, address _to, uint256 _amount) public ownerOnly {
        _token.transfer(_to, _amount);
    }

}