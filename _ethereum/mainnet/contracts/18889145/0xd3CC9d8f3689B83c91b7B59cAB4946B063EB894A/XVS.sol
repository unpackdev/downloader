// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.13;

import "./ERC20.sol";

import "./TokenController.sol";

/**
 * @title XVS
 * @author Venus
 * @notice XVS contract serves as a customized ERC-20 token with additional minting and burning functionality.
 *  It also incorporates access control features provided by the "TokenController" contract to ensure proper governance and restrictions on minting and burning operations.
 */

contract XVS is ERC20, TokenController {
    constructor(address accessControlManager_) ERC20("Venus XVS", "XVS") TokenController(accessControlManager_) {}

    /**
     * @notice Creates `amount_` tokens and assigns them to `account_`, increasing
     * the total supply. Checks access and eligibility.
     * @param account_ Address to which tokens are assigned.
     * @param amount_ Amount of tokens to be assigned.
     * @custom:access Controlled by AccessControlManager.
     * @custom:event Emits MintLimitDecreased with new available limit.
     * @custom:error MintLimitExceed is thrown when minting amount exceeds the maximum cap.
     */
    function mint(address account_, uint256 amount_) external whenNotPaused {
        _ensureAllowed("mint(address,uint256)");
        _isEligibleToMint(msg.sender, account_, amount_);
        _mint(account_, amount_);
    }

    /**
     * @notice Destroys `amount_` tokens from `account_`, reducing the
     * total supply. Checks access and eligibility.
     * @param account_ Address from which tokens be destroyed.
     * @param amount_ Amount of tokens to be destroyed.
     * @custom:access Controlled by AccessControlManager.
     * @custom:event Emits MintLimitIncreased with new available limit.
     */
    function burn(address account_, uint256 amount_) external whenNotPaused {
        _ensureAllowed("burn(address,uint256)");
        _burn(account_, amount_);
        _increaseMintLimit(msg.sender, amount_);
    }

    /**
     * @notice Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     * @param from_ Address of account from which tokens are to be transferred.
     * @param to_ Address of the account to which tokens are to be transferred.
     * @param amount_ The amount of tokens to be transferred.
     * @custom:error AccountBlacklisted is thrown when either `from` or `to` address is blacklisted.
     */
    function _beforeTokenTransfer(address from_, address to_, uint256 amount_) internal override whenNotPaused {
        if (_blacklist[to_]) {
            revert AccountBlacklisted(to_);
        }
        if (_blacklist[from_]) {
            revert AccountBlacklisted(from_);
        }
    }
}
