// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/// @author: @props


import "./PaymentSplitter.sol";
import "./IRoyalty.sol";
import "./ReentrancyGuard.sol";
import "./AccessControl.sol";
import "./Ownable.sol";

import "./console.sol";
/**
 * @dev 
 */
contract Royalty is
    PaymentSplitter,
    ReentrancyGuard,
    AccessControl, 
    Ownable,
    IRoyalty {

    address public approvedContract;

    bytes32 public constant CONTRACT_ADMIN_ROLE = keccak256("CONTRACT_ADMIN_ROLE");

    constructor(address __approvedContract) {
        approvedContract = __approvedContract;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(CONTRACT_ADMIN_ROLE, msg.sender);
    }


     function toggleAllowRelease(bool __on) external onlyRole(CONTRACT_ADMIN_ROLE) {
        _toggleAllowRelease(__on);
    }

    function setApprovedContract(address __contractAddress) external onlyRole(CONTRACT_ADMIN_ROLE) {
        approvedContract = __contractAddress;
    }

    function toggleReleaseAbility(bool __allowRelease) external onlyRole(CONTRACT_ADMIN_ROLE) {
        allowRelease = __allowRelease;
    }


    /**
     * @dev only contract admin
     */
    function withdrawEther( address payable account, uint256 _amount) external onlyRole(CONTRACT_ADMIN_ROLE) {
      _withdrawEther(account, _amount);
    }

    function withdrawToken(IERC20 token, address payable account, uint256 _amount) external onlyRole(CONTRACT_ADMIN_ROLE) {
       _withdrawToken(token, account, _amount);
    }

    /**
     * @dev see {IERC165-supportsInterface}
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, AccessControl) returns (bool) {
        return interfaceId == type(IRoyalty).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
    * @dev see {IRoyalty-removeShare}
    */
    function toggleShares(address from, address to) external onlyApprovedContract {
        console.log('--------------------------');
        console.log('toggleShares from', from);
        console.log('toggleShares to', to);
        console.log('-----');
        if (address(from) == address(0)){
            console.log('adding share to', to);
            addShare(to);
        }
        else if (address(from) != address(0) && address(to) != address(0)) {
             console.log('removing share from', from);
            removeShare(from);
             console.log('adding share to', to);
            addShare(to);
        } else if (address(to) == address(0)) {
            console.log('removing share from', from);
            removeShare(from);
        }
        console.log('--------------------------');
    }

    /**
    * @dev see {IRoyalty-addShare}
    */
    function addShare(address _account) public onlyApprovedContract {
        // increment shares for _account if they're already a shareholder
        // otherwise add _account as a shareholder and give them a share
        unchecked {
            if (_shares[_account] > 0) {
                console.log("adding share to:::", _account);
                _shares[_account] += 1;
                _incrementTotalShares();
            } else {
                console.log("adding payee:::", _account);
                _addPayee(_account, 1);
            }
        }
        
    }

    /**
    * @dev see {IRoyalty-removeShare}
    */
    function removeShare(address _account) public onlyApprovedContract {
        if (_shares[_account] > 0) {
            _shares[_account] -= 1;
            _decrementTotalShares();
        }
    }

    modifier onlyApprovedContract {
        require(approvedContract == msg.sender, "Only allowed by approved contract");
        _;
    }
   

}