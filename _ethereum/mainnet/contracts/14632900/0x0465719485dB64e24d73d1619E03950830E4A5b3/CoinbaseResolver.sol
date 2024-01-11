// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.8.13;

import "./ERC165.sol";
import "./EnumerableSet.sol";
import "./IExtendedResolver.sol";
import "./Manageable.sol";
import "./SignatureVerifier.sol";
import "./IResolverService.sol";

/**
 * @notice Coinbase Offchain ENS Resolver.
 * @dev Adapted from: https://github.com/ensdomains/offchain-resolver/blob/2bc616f19a94370828c35f29f71d5d4cab3a9a4f/packages/contracts/contracts/OffchainResolver.sol
 */
contract CoinbaseResolver is ERC165, Manageable, IExtendedResolver {
    using EnumerableSet for EnumerableSet.AddressSet;

    /// @dev Gateway URL to use to perform offchain lookup.
    string private _url;
    /// @dev Addresses for the set of signers.
    EnumerableSet.AddressSet private _signers;

    /// @notice Event raised when a new gateway URL is set.
    event UrlSet(string indexed previousUrl, string indexed newUrl);
    /// @notice Event raised when a new signer is added.
    event SignerAdded(address indexed addedSigner);
    /// @notice Event raised when a signer is removed.
    event SignerRemoved(address indexed removedSigner);

    /**
     * @dev Error to raise when an offchain lookup is required.
     * @param sender Sender address (address of this contract).
     * @param urls URLs to request to perform the offchain lookup.
     * @param callData Call data contains all the data to perform the offchain lookup.
     * @param callbackFunction Callback function that should be called after lookup.
     * @param extraData Optional extra data to send.
     */
    error OffchainLookup(
        address sender,
        string[] urls,
        bytes callData,
        bytes4 callbackFunction,
        bytes extraData
    );

    /**
     * @notice Initializes the contract with the initial parameters.
     * @param newOwner Owner address.
     * @param newSignerManager Signer manager address.
     * @param newGatewayManager Gateway manager address.
     * @param newUrl Gateway URL.
     * @param newSigners Signer addresses.
     */
    constructor(
        address newOwner,
        address newSignerManager,
        address newGatewayManager,
        string memory newUrl,
        address[] memory newSigners
    ) {
        _transferOwnership(newOwner);
        _changeSignerManager(newSignerManager);
        _changeGatewayManager(newGatewayManager);
        _setUrl(newUrl);
        _addSigners(newSigners);
    }

    /**
     * @notice Returns the gateway URL.
     * @return Gateway URL.
     */
    function url() external view returns (string memory) {
        return _url;
    }

    /**
     * @notice Returns a list of signers.
     * @return List of signers.
     */
    function signers() external view returns (address[] memory) {
        return _signers.values();
    }

    /**
     * @notice Returns whether a given account is a signer.
     * @return True if a given account is a signer.
     */
    function isSigner(address account) external view returns (bool) {
        return _signers.contains(account);
    }

    /**
     * @notice Set the gateway URL.
     * @dev Can only be called by the gateway manager.
     * @param newUrl New gateway URL.
     */
    function setUrl(string calldata newUrl) external onlyGatewayManager {
        _setUrl(newUrl);
    }

    /**
     * @notice Add a set of new signers.
     * @dev Can only be called by the signer manager.
     * @param signersToAdd Signer addresses.
     */
    function addSigners(address[] calldata signersToAdd)
        external
        onlySignerManager
    {
        _addSigners(signersToAdd);
    }

    /**
     * @notice Remove a set of existing signers.
     * @dev Can only be called by the signer manager.
     * @param signersToRemove Signer addresses.
     */
    function removeSigners(address[] calldata signersToRemove)
        external
        onlySignerManager
    {
        uint256 length = signersToRemove.length;
        for (uint256 i = 0; i < length; i++) {
            address signer = signersToRemove[i];
            if (_signers.remove(signer)) {
                emit SignerRemoved(signer);
            }
        }
    }

    /**
     * @notice Support ERC-165 introspection.
     * @param interfaceID Interface ID.
     * @return True if a given interface ID is supported.
     */
    function supportsInterface(bytes4 interfaceID)
        public
        view
        override
        returns (bool)
    {
        return
            interfaceID == type(IExtendedResolver).interfaceId ||
            super.supportsInterface(interfaceID);
    }

    /**
     * @notice Initiate a resolution conforming to the ENSIP-10. Reverts with an OffchainLookup error.
     * @param name DNS-encoded name to resolve.
     * @param data ABI-encoded data for the underlying resolution function (e.g. addr(bytes32), text(bytes32,string)).
     * @return Always reverts with an OffchainLookup error.
     */
    function resolve(bytes calldata name, bytes calldata data)
        external
        view
        override
        returns (bytes memory)
    {
        bytes memory callData = abi.encodeWithSelector(
            IResolverService.resolve.selector,
            name,
            data
        );
        string[] memory urls = new string[](1);
        urls[0] = _url;
        revert OffchainLookup(
            address(this),
            urls,
            callData,
            this.resolveWithProof.selector,
            callData
        );
    }

    /**
     * @notice Callback used by CCIP-read compatible clients to verify and parse the response.
     * @dev Reverts if the signature is invalid.
     * @param response ABI-encoded response data in the form of (bytes result, uint64 expires, bytes signature).
     * @param extraData Original request data.
     * @return ABI-encoded result data for the underlying resolution function.
     */
    function resolveWithProof(bytes calldata response, bytes calldata extraData)
        external
        view
        returns (bytes memory)
    {
        (address signer, bytes memory result) = SignatureVerifier.verify(
            extraData,
            response
        );
        require(
            _signers.contains(signer),
            "CoinbaseResolver::resolveWithProof: invalid signature"
        );
        return result;
    }

    /**
     * @notice Generates a hash for signing and verifying the offchain response.
     * @param expires Time at which the signature expires.
     * @param request Request data.
     * @param result Result data.
     * @return Hashed data for signing and verifying.
     */
    function makeSignatureHash(
        uint64 expires,
        bytes calldata request,
        bytes calldata result
    ) external view returns (bytes32) {
        return
            SignatureVerifier.makeSignatureHash(
                address(this),
                expires,
                request,
                result
            );
    }

    /**
     * @notice Sets the new gateway URL and emits a UrlSet event.
     * @param newUrl New URL to be set.
     */
    function _setUrl(string memory newUrl) private {
        string memory previousUrl = _url;
        _url = newUrl;
        emit UrlSet(previousUrl, newUrl);
    }

    /**
     * @notice Adds new signers and emits a SignersAdded event.
     * @param signersToAdd List of addresses to add as signers.
     */
    function _addSigners(address[] memory signersToAdd) private {
        uint256 length = signersToAdd.length;
        for (uint256 i = 0; i < length; i++) {
            address signer = signersToAdd[i];
            if (_signers.add(signer)) {
                emit SignerAdded(signer);
            }
        }
    }
}
