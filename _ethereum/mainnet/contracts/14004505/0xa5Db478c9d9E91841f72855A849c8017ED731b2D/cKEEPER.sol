// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import "./ERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";


contract cKEEPER is ERC20, Ownable {
    using SafeMath for uint;

    bool public requireSellerApproval;

    mapping( address => bool ) public isApprovedSeller;
    
    constructor() ERC20("Call Keeper", "cKEEPER") {
        uint initSupply = 500000000 * 1e18;
        _addApprovedSeller( address(this) );
        _addApprovedSeller( msg.sender );
        _mint( msg.sender, initSupply );
        requireSellerApproval = true;
    }

    function allowOpenTrading() external onlyOwner() returns ( bool ) {
        requireSellerApproval = false;
        return requireSellerApproval;
    }

    function _addApprovedSeller( address approvedSeller_ ) internal {
        isApprovedSeller[approvedSeller_] = true;
    }

    function addApprovedSeller( address approvedSeller_ ) external onlyOwner() returns ( bool ) {
        _addApprovedSeller( approvedSeller_ );
        return isApprovedSeller[approvedSeller_];
    }

    function addApprovedSellers( address[] calldata approvedSellers_ ) external onlyOwner() returns ( bool ) {
        for( uint iteration_; iteration_ < approvedSellers_.length; iteration_++ ) {
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
        for( uint iteration_; iteration_ < disapprovedSellers_.length; iteration_++ ) {
            _removeApprovedSeller( disapprovedSellers_[iteration_] );
        }
        return true;
    }

    function _beforeTokenTransfer(address from_, address to_, uint256 amount_ ) internal override {
        require( (balanceOf(to_) > 0 || isApprovedSeller[from_] == true || !requireSellerApproval), "Account not approved to transfer cKEEPER." );
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
}