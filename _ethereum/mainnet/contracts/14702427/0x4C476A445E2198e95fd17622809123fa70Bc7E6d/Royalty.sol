// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/// @author: @props

import "./Base.sol";
import "./PaymentSplitter.sol";
import "./IRoyalty.sol";

/**
 * @dev 
 */
contract Royalty is
    Base,
    PaymentSplitter,
    IRoyalty {

    constructor() {}

    /**
     * @dev see {IERC165-supportsInterface}
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, Base) returns (bool) {
        return interfaceId == type(IRoyalty).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
    * @dev see {IRoyalty-addShare}
    */
    function addShare(address _account) external onlyRole(CONTRACT_ADMIN_ROLE) nonReentrant {
        // increment shares for _account if they're already a shareholder
        // otherwise add _account as a shareholder and give them a share
        unchecked {
            if (_shares[_account] > 0) {
                _shares[_account] += 1;
            } else {
                _addPayee(_account, 1);
            }
        }
        
    }

    /**
    * @dev see {IRoyalty-removeShare}
    */
    function removeShare(address _account) external onlyRole(CONTRACT_ADMIN_ROLE) nonReentrant {
        if (_shares[_account] > 0) {
            _shares[_account] -= 1;
        }
    }

}