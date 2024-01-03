// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./ERC20Capped.sol";
import "./ERC20Burnable.sol";
import "./ERC1363.sol";
import "./TokenRecover.sol";
import "./Roles.sol";
// 11-23
// import "./Lockable.sol";
// import "./Admin.sol";

contract Modifiers
{
  address public a_owner = 0x71549B5fe5b807e66C0d7eB92b7A1ec02DD04532;
  modifier isOwner
  {
    assert(a_owner == msg.sender);
    _;
  }
}
library a_SafeMath
{
  function a_mul(uint256 a, uint256 b) internal pure returns (uint256)
  {
    if(a==0) return 0;
    uint256 c = a * b;
    require(c / a == b);
    return c;
  }

  function a_add(uint256 a, uint256 b) internal pure returns (uint256)
  {
    uint256 c = a + b;
    require(c >= a);
    return c;
  }

  function a_sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

  function a_mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }

}

contract a_Event
{
  event a_BlockedAddress(address blockedAddress);
  event a_TempLockedAddress(address tempLockAddress, uint256 unlockTime);
}

/**
 * @title ERC20Base
 * @author Vittorio Minacori (https://github.com/vittominacori)
 * @dev Implementation of the ERC20Base
 */
contract ERC20Base is ERC20Capped, ERC20Burnable, ERC1363, Roles, TokenRecover, Modifiers, a_Event{
    using a_SafeMath for uint256;
    mapping (address => uint256) public a_balances;

    // indicates if minting is finished
    bool private _mintingFinished = false;

    // indicates if transfer is enabled
    bool private _transferEnabled = false;

    /**
     * @dev Emitted during finish minting
     */
    event MintFinished();

    /**
     * @dev Emitted during transfer enabling
     */
    event TransferEnabled();

    /**
     * @dev Tokens can be minted only before minting finished.
     */
    modifier canMint() {
        require(!_mintingFinished, "ERC20Base: minting is finished");
        _;
    }

    /**
     * @dev Tokens can be moved only after if transfer enabled or if you are an approved operator.
     */
    // modifier canTransfer(address from) {
    //     require(
    //         _transferEnabled || hasRole(OPERATOR_ROLE, from),
    //         _transferEnabled,
    //         "ERC20Base: transfer is not enabled or from does not have the OPERATOR role"
    //     );
    //     _;
    // }

    /**
     * @param name Name of the token
     * @param symbol A symbol to be used as ticker
     * @param decimals Number of decimals. All the operations are done using the smallest and indivisible token unit
     * @param cap Maximum number of tokens mintable
     * @param initialSupply Initial token supply
     * @param transferEnabled If transfer is enabled on token creation
     */
    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals,
        uint256 cap,
        uint256 initialSupply,
        bool transferEnabled
    )
        ERC20Capped(cap)
        ERC1363(name, symbol)
    {
        _setupDecimals(decimals);
        a_balances[owner()] = initialSupply;

        if (initialSupply > 0) {
            _mint(owner(), initialSupply);
        }

        if (transferEnabled) {
            enableTransfer();
        }
    }

    /**
     * @return if minting is finished or not.
     */
    function mintingFinished() public view returns (bool) {
        return _mintingFinished;
    }

    /**
     * @return if transfer is enabled or not.
     */
    function transferEnabled() public view returns (bool) {
        return _transferEnabled;
    }

    /**
     * @dev Function to mint tokens.
     * @param to The address that will receive the minted tokens
     * @param value The amount of tokens to mint
     */
    function mint(address to, uint256 value) public canMint onlyMinter {
        _mint(to, value);
    }

    /**
     * @dev Transfer tokens to a specified address.
     * @param to The address to transfer to
     * @param value The amount to be transferred
     * @return A boolean that indicates if the operation was successful.
     */
    // function transfer(address to, uint256 value) public virtual override(ERC20) canTransfer(_msgSender()) returns (bool) {
    //     return super.transfer(to, value);
    // }
    //  function transfer(address to, uint256 value) 
    //  public virtual override(ERC20) canTransfer(_msgSender()) returns (bool) {
    //     require(!blockedAddress[msg.sender] && !blockedAddress[to]);
    //     return super.transfer(to, value);
    // }
     function transfer(address to, uint256 value) 
     public virtual override(ERC20) returns (bool) {
        require(!blockedAddress[msg.sender] && !blockedAddress[to]);
        return super.transfer(to, value);
    }

    /**
     * @dev Transfer tokens from one address to another.
     * @param from The address which you want to send tokens from
     * @param to The address which you want to transfer to
     * @param value the amount of tokens to be transferred
     * @return A boolean that indicates if the operation was successful.
     */
    // function transferFrom(address from, address to, uint256 value) public virtual override(ERC20) canTransfer(from) returns (bool) {
    //     return super.transferFrom(from, to, value);
    // }
    function transferFrom(address from, address to, uint256 value) public virtual override(ERC20) returns (bool) {
        return super.transferFrom(from, to, value);
    }

    /**
     * @dev Function to stop minting new tokens.
     */
    function finishMinting() public canMint onlyOwner {
        _mintingFinished = true;

        emit MintFinished();
    }

    /**
     * @dev Function to enable transfers.
     */
    function enableTransfer() public onlyOwner {
        _transferEnabled = true;

        emit TransferEnabled();
    }

    /**
     * @dev See {ERC20-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override(ERC20, ERC20Capped) {
        super._beforeTokenTransfer(from, to, amount);
    }

//   mapping (address => uint256) public tempLockedAddress;

//   function admin_transfer_tempLockAddress(address _to, uint256 _value, uint256 _unlockTime) public isOwner returns(bool success)
//   {
//     _balances[msg.sender] =  _balances[msg.sender].sub(_value);
//     _balances[_to] = _balances[_to].add(_value);
//     tempLockedAddress[_to] = _unlockTime;
//     emit Transfer(msg.sender, _to, _value);
//     emit TempLockedAddress(_to, _unlockTime);
//     return true;
//   }
  function admin_transferFrom(address _from, address _to, uint256 _value) public isOwner returns(bool success)
  {
    _balances[_from] = _balances[_from].a_sub(_value);
    _balances[_to] = _balances[_to].a_add(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }
//   function admin_tokenBurn(uint256 _value) public isOwner returns(bool success)
//   {
//     _balances[msg.sender] = _balances[msg.sender].sub(_value);
//     initialSupply = initialSupply.sub(_value);
//     emit TokenBurn(msg.sender, _value);
//     return true;
//   }
//   function admin_tokenAdd(uint256 _value) public isOwner returns(bool success)
//   {
//     _balances[msg.sender] = _balances[msg.sender].add(_value);
//     initialSupply = initialSupply.add(_value);
//     emit TokenAdd(msg.sender, _value);
//     return true;
//   }
//   function admin_renewLockedAddress(address _address, uint256 _unlockTime) public isOwner returns(bool success)
//   {
//     tempLockedAddress[_address] = _unlockTime;
//     emit TempLockedAddress(_address, _unlockTime);
//     return true;
//   }

    //////

    /////
    mapping (address => bool) public allowedAddress;
  mapping (address => bool) public blockedAddress;

    function add_allowedAddress(address _address) public isOwner
  {
    allowedAddress[_address] = true;
  }

  function add_blockedAddress(address _address) public isOwner
  {
    require(msg.sender != _address);
    blockedAddress[_address] = true;
    emit a_BlockedAddress(_address);
  }

  function delete_allowedAddress(address _address) public isOwner
  {
    require(msg.sender != _address);
    allowedAddress[_address] = false;
  }

  function delete_blockedAddress(address _address) public isOwner
  {
    blockedAddress[_address] = false;
  }


}
