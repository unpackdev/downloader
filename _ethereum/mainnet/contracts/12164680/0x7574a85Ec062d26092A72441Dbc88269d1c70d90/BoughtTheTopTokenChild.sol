// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./AccessControl.sol";
import "./Context.sol";
import "./IChildToken.sol";

contract BoughtTheTopTokenChild is Context, AccessControl, IChildToken, ERC20 {
    /// @notice Role identifer for off-chain depositor
    bytes32 public constant DEPOSITOR_ROLE = keccak256("DEPOSITOR_ROLE");

    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE` to the account that deploys the contract.
     *
     * See {ERC20-constructor}.
     */
    constructor() ERC20("BoughtThe.top", "BTT") {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /**
     * @notice called when token is deposited on root chain
     * @dev Should be callable only by ChildChainManager
     * Should handle deposit by minting the required amount for user
     * Make sure minting is done only by this function
     * @param user user address for whom deposit is being done
     * @param depositData abi encoded amount
     */
    function deposit(address user, bytes calldata depositData) external override {
        require(hasRole(DEPOSITOR_ROLE, _msgSender()), "BoughtTheTopToken: must have depositor role");
        uint256 amount = abi.decode(depositData, (uint256));
        _mint(user, amount);
    }

    /**
     * @notice called when user wants to withdraw tokens back to root chain
     * @dev Should burn user's tokens. This transaction will be verified when exiting on root chain
     * @param amount amount of tokens to withdraw
     */
    function withdraw(uint256 amount) external {
        _burn(_msgSender(), amount);
    }
}
