// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./BaseTokenFactory.sol";
import "./MasterToken.sol";

/**
 * @title CommunityMasterTokenFactory contract
 * @author 0x-r4bbit
 *
 * @notice This contract creates instances of `MasterToken`.
 * @dev This contract inherits `BaseTokenFactory` to get access to
 * shared modifiers and other functions.
 */
contract CommunityMasterTokenFactory is BaseTokenFactory {
    error CommunityMasterTokenFactory_InvalidOwnerTokenAddress();

    event CreateToken(address indexed);

    /**
     * @notice Creates an instance of `MasterToken`.
     * @dev Only the token deployer contract can call this function.
     * @dev Emits a {CreateToken} event.
     * @param _name The name of the `MasterToken`.
     * @param _symbol The symbol of the `MasterToken`.
     * @param _baseURI The base token URI of the `MasterToken`.
     * @param _ownerToken The address of the `OwnerToken`.
     * @return address The address of the created `MasterToken` instance.
     */
    function create(
        string calldata _name,
        string calldata _symbol,
        string calldata _baseURI,
        address _ownerToken,
        bytes memory
    )
        external
        onlyTokenDeployer
        onlyValidTokenMetadata(_name, _symbol, _baseURI)
        returns (address)
    {
        if (_ownerToken == address(0)) {
            revert CommunityMasterTokenFactory_InvalidOwnerTokenAddress();
        }

        MasterToken masterToken = new MasterToken(
          _name, 
          _symbol, 
          _baseURI, 
          _ownerToken
        );
        emit CreateToken(address(masterToken));
        return address(masterToken);
    }
}
