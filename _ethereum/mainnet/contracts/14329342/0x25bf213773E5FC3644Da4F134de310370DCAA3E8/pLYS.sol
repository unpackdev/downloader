

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import "./ERC20.sol";
import "./Ownable.sol";
import "./Super.sol";

import "./SafeMath.sol";

contract PreElysianToken is Super {

  using SafeMath for uint256;

  bool public requireSellerApproval;
  bool public allowMinting;

  mapping( address => bool ) public isApprovedSeller;
  
  constructor(address _owner) Super( "Pre-Elysian", "pLYS", 18 ) Ownable(_owner) {
    uint256 initialSupply_ = 1000000000 * 1e18;
    requireSellerApproval = false;
    allowMinting = true;
    _addApprovedSeller( address(this) );
    _addApprovedSeller( _owner );
    _mint( _owner, initialSupply_ );
  }

  function allowOpenTrading() external onlyOwner() returns ( bool ) {
    requireSellerApproval = false;
    return requireSellerApproval;
  }

  function disableMinting() external onlyOwner() returns ( bool ) {
    allowMinting = false;
    MintingDisabled( msg.sender );
    return allowMinting;
  }

  function enableMinting() external onlyOwner() returns ( bool ) {
    allowMinting = true;
    MintingEnabled( msg.sender );
    return allowMinting;
  }

  function _addApprovedSeller( address approvedSeller_ ) internal {
    isApprovedSeller[approvedSeller_] = true;
  }

  function addApprovedSeller( address approvedSeller_ ) external onlyOwner() returns ( bool ) {
    _addApprovedSeller( approvedSeller_ );
    return isApprovedSeller[approvedSeller_];
  }

  function addApprovedSellers( address[] calldata approvedSellers_ ) external onlyOwner() returns ( bool ) {

    for( uint256 iteration_; approvedSellers_.length > iteration_; iteration_++ ) {
      _addApprovedSeller( approvedSellers_[iteration_] );
    }
    return true;
  }

  function _removeApprovedSeller( address disapprovedSeller_ ) internal {
    isApprovedSeller[disapprovedSeller_] = false;
  }

  function removeApprovedSeller( address disapprovedSeller_ ) external onlyOwner() returns ( bool ) {
    _removeApprovedSeller( disapprovedSeller_ );
    return isApprovedSeller[disapprovedSeller_];
  }

  function removeApprovedSellers( address[] calldata disapprovedSellers_ ) external onlyOwner() returns ( bool ) {
    for( uint256 iteration_; disapprovedSellers_.length > iteration_; iteration_++ ) {
      _removeApprovedSeller( disapprovedSellers_[iteration_] );
    }
    return true;
  }
  
  function _beforeTokenTransfer(address from_, address to_, uint256 amount_ ) internal override {
    require( (_balances[to_] > 0 || isApprovedSeller[from_] == true), "Account not approved to transfer pLYS." );
  }

  function mint( address recipient_, uint256 amount_) public virtual onlyOwner() {
    require( allowMinting, "Minting has been disabled." );
    _mint( recipient_, amount_ );
  }

   function burn(uint256 amount_) public virtual {
    _burn( msg.sender, amount_ );
  }

    function burnFrom( address account_, uint256 amount_ ) public virtual {
      _burnFrom( account_, amount_ );
    }

    function _burnFrom( address account_, uint256 amount_ ) internal virtual {
       uint256 decreasedAllowance_ = allowance( account_, msg.sender ).sub( amount_, "ERC20: burn amount exceeds allowance");
      _approve( account_, msg.sender, decreasedAllowance_ );
      _burn( account_, amount_ );
    }

    event MintingDisabled( address indexed operator );
    event MintingEnabled( address indexed operator );

}