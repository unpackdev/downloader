// SPDX-License-Identifier: MIT
pragma solidity 0.7.3;

import "./EnumerableSet.sol";
import "./AccessControl.sol";
import "./IApprovedTokenRegistry.sol";

contract ApprovedTokenRegistry is IApprovedTokenRegistry, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    bytes32 public constant TOKEN_REGISTER_ROLE =
        keccak256("TOKEN_REGISTER_ROLE");

    EnumerableSet.AddressSet private approvedTokens;
    bool private allTokensApproved;

    event TokenContractApproved(address _tokenContract, bool _approved);

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(TOKEN_REGISTER_ROLE, msg.sender);
    }

    /// @notice Returns if a token has been approved or not.
    /// @dev Sender must have the TOKEN_REGISTER_ROLE Role.
    /// @param _tokenContract Contract of token being checked.
    /// @return True if the token is allowed, false otherwise.
    function isApprovedToken(address _tokenContract)
        external
        view
        override
        returns (bool)
    {
        return allTokensApproved || approvedTokens.contains(_tokenContract);
    }

    /// @notice Adds a token to the list of approved tokens.
    /// @param _tokenContract Contract of token being approved.
    function addApprovedToken(address _tokenContract) external override {
        require(_tokenContract != address(0), "Invalid Address");
        require(hasRole(TOKEN_REGISTER_ROLE, msg.sender), "Unauthorized");
        approvedTokens.add(_tokenContract);
        emit TokenContractApproved(_tokenContract, true);
    }

    /// @notice Removes a token from the approved tokens list.
    /// @param _tokenContract Contract of token being approved.
    function removeApprovedToken(address _tokenContract) external override {
        require(_tokenContract != address(0), "Invalid Address");
        require(hasRole(TOKEN_REGISTER_ROLE, msg.sender), "Unauthorized");
        approvedTokens.remove(_tokenContract);
        emit TokenContractApproved(_tokenContract, false);
    }

    /// @notice Sets whether all token contracts should be approved.
    /// @dev Sender must have the TOKEN_REGISTER_ROLE Role.
    /// @param _allTokensApproved Bool denoting if all tokens should be approved.
    function setAllTokensApproved(bool _allTokensApproved) external override {
        require(hasRole(TOKEN_REGISTER_ROLE, msg.sender), "Unauthorized");
        allTokensApproved = _allTokensApproved;
    }
}
