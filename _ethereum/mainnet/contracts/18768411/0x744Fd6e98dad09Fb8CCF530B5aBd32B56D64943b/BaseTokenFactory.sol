// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./ITokenFactory.sol";
import "./Ownable2Step.sol";

/**
 * @title BaseTokenFactory contract
 * @author 0x-r4bbit
 *
 * This contract provides shared functionality across token factory contracts
 * that are used to create instances of `OwnerToken` and `MasterToken`.
 * This includes a custom modifiers as well as a function to set the token deployer
 * address that is needed for it.
 *
 * @dev Other factory contract inherit from this contract.
 */
abstract contract BaseTokenFactory is ITokenFactory, Ownable2Step {
    error BaseTokenFactory_InvalidTokenDeployerAddress();
    error BaseTokenFactory_NotAuthorized();
    error BaseTokenFactory_InvalidTokenMetadata();

    event TokenDeployerAddressChange(address indexed);

    /// @dev The address of the token deployer contract.
    address public tokenDeployer;

    modifier onlyTokenDeployer() {
        if (msg.sender != tokenDeployer) {
            revert BaseTokenFactory_NotAuthorized();
        }
        _;
    }

    modifier onlyValidTokenMetadata(string calldata name, string calldata symbol, string calldata baseURI) {
        if (bytes(name).length == 0 || bytes(symbol).length == 0 || bytes(baseURI).length == 0) {
            revert BaseTokenFactory_InvalidTokenMetadata();
        }
        _;
    }

    /**
     * @notice Sets the token deployer address.
     * @dev Only the owner can call this function.
     * @dev Reverts if provided address is a zero address.
     * @dev Emits a {TokenDeployerAddressChange} event.
     * @param _tokenDeployer The address of the token deployer contract.
     */
    function setTokenDeployerAddress(address _tokenDeployer) external onlyOwner {
        if (_tokenDeployer == address(0)) {
            revert BaseTokenFactory_InvalidTokenDeployerAddress();
        }
        tokenDeployer = _tokenDeployer;
        emit TokenDeployerAddressChange(tokenDeployer);
    }
}
