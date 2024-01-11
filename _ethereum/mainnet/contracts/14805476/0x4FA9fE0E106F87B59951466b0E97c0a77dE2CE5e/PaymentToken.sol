// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC20.sol";
import "./ERC20Capped.sol";
import "./Ownable.sol";

/**
 * PaymentToken
 *
 * A relatively straight forward ERC20 token with the following additions:
 * - Ownable, transferrable, renouncable
 * - Mintable by owner, capped
 * - Approvals can initially be disabled and later enabled by the owner
 */
contract PaymentToken is ERC20, ERC20Capped, Ownable {
    bool private _approveAllowed;

    event ApprovalsAllowed();

    constructor(string memory name_, string memory symbol_, uint256 cap_, bool approveAllowed_) ERC20(name_, symbol_) ERC20Capped(cap_) {
        _approveAllowed = approveAllowed_;
    }

    /**
     * @dev Throws if approvals aren't allowed
     */
    modifier onlyIfApproveAllowed() {
        require(_approveAllowed, "Approve currently isn't allowed");
        _;
    }

    /**
     * @dev Public mint function
     * see ERC20.sol:_mint() for details.
     */
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    /**
     * @dev Enable approvals
     * Throw if they already are allowed
     */
    function allowApprovals() public onlyOwner {
        require(!_approveAllowed, "Approve is already allowed");
        _approveAllowed = true;
        emit ApprovalsAllowed();
    }

    /**
     * @dev override for methods in bases
     */
    function _mint(address account, uint256 amount) internal virtual override(ERC20, ERC20Capped) {
        super._mint(account, amount);
    }

    /**
     * @dev override for methods in bases
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual override onlyIfApproveAllowed {
        super._approve(owner, spender, amount);
    }
}
