// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./BaseTokenFactory.sol";
import "./OwnerToken.sol";

/**
 * @title CommunityOwnerTokenFactory contract
 * @author 0x-r4bbit
 *
 * @notice This contract creates instances of `OwnerToken`.
 * @dev This contract inherits `BaseTokenFactory` to get access to
 * shared modifiers and other functions.
 */
contract CommunityOwnerTokenFactory is BaseTokenFactory {
    error CommunityOwnerTokenFactory_InvalidReceiverAddress();
    error CommunityOwnerTokenFactory_InvalidSignerPublicKey();

    event CreateToken(address indexed);

    /**
     * @notice Creates an instance of `OwnerToken`.
     * @dev Only the token deployer contract can call this function.
     * @dev Emits a {CreateToken} event.
     * @param _name The name of the `OwnerToken`.
     * @param _symbol The symbol of the `OwnerToken`.
     * @param _baseURI The base token URI of the `OwnerToken`.
     * @param _receiver The address of the token owner.
     * @param _signerPublicKey The public key of the trusted signer of the community
     * that the `OwnerToken` instance belongs to.
     * @return address The address of the created `OwnerToken` instance.
     */
    function create(
        string calldata _name,
        string calldata _symbol,
        string calldata _baseURI,
        address _receiver,
        bytes memory _signerPublicKey
    )
        external
        onlyTokenDeployer
        onlyValidTokenMetadata(_name, _symbol, _baseURI)
        returns (address)
    {
        if (_receiver == address(0)) {
            revert CommunityOwnerTokenFactory_InvalidReceiverAddress();
        }

        if (_signerPublicKey.length == 0) {
            revert CommunityOwnerTokenFactory_InvalidSignerPublicKey();
        }

        OwnerToken ownerToken = new OwnerToken(
          _name, 
          _symbol, 
          _baseURI, 
          _receiver,
          _signerPublicKey
        );
        emit CreateToken(address(ownerToken));
        return address(ownerToken);
    }
}
