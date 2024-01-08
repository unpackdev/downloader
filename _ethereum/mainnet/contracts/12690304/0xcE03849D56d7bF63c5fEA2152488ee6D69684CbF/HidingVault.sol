// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./LibHidingVault.sol";
import "./SafeERC20.sol";

/**
 * @title KeeperDAO's HidingVault
 * @author KeeperDAO
 * @dev This contract encapsulates a DeFi position, this contract 
 * and is deployed for each user. A user can deploy multiple Hiding Vaults
 * if he/she wants to isolate their compound positions from each other.
 */
contract HidingVault {
    using SafeERC20 for IERC20;

    constructor() { 
        LibHidingVault.state().nft = NFTLike(msg.sender);
    }

    receive () external payable {}

    /**
     * @notice allows the owner of the contract to recover non-blacklisted tokens.
     */
    function recoverTokens(address payable _to, address _token, uint256 _amount) external {
        require(_to != address(0), "HidingVault: _to cannot be 0x0");
        require(
            !LibHidingVault.state().recoverableTokensBlacklist[_token],
            "HidingVault: token is not recoverable"
        );
        require(
            LibHidingVault.state().nft.ownerOf(uint256(uint160(address(this)))) == msg.sender,
            "HidingVault: caller is not the owner"
        );

        if (_token == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
           (bool success,) = _to.call{ value: _amount }("");
            require(success, "Transfer Failed");
        } else {
            IERC20(_token).safeTransfer(_to, _amount);
        }
    }

    /**
     * @notice find implementation for function that is called and execute the
     *  function if an implementation is found and return any value.
     */
    fallback() external payable {
        address implementation = LibHidingVault.state().nft.implementations(msg.sig);
        require(implementation != address(0), "HidingVault: Function does not exist");
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
                case 0 {
                    revert(0, returndatasize())
                }
                default {
                    return(0, returndatasize())
                }
        }
    }    
}