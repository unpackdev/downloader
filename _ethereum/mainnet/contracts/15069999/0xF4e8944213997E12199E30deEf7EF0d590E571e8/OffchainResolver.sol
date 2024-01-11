// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./ERC165.sol";
import "./IExtendedResolver.sol";
import "./IResolverService.sol";
import "./SignatureVerifier.sol";

/// @title An offchain ENS resolver
/// @notice Directs all queries to a CCIP read gateway
/// @dev Callers must implement EIP 3668 and ENSIP 10
contract OffchainResolver is IExtendedResolver, ERC165 {

    // --- Events / Errors ---
    event Rely(address usr);
    event Deny(address usr);
    event Hope(address signer);
    event Nope(address signer);
    event UpdateURL(string url);
    error OffchainLookup(address sender, string[] urls, bytes callData, bytes4 callbackFunction, bytes extraData);

    // --- Auth ---
    mapping (address => uint) public wards;
    function rely(address usr) external auth { wards[usr] = 1; emit Rely(usr); }
    function deny(address usr) external auth { wards[usr] = 0; emit Deny(usr); }
    modifier auth {
        require(wards[msg.sender] == 1, "Offchain/not-authorized");
        _;
    }

    mapping(address => bool) public signers;
    function hope(address usr) external auth { signers[usr] = true; emit Hope(usr); }
    function nope(address usr) external auth { signers[usr] = false; emit Nope(usr); }

    // --- Data ---
    string public url;

    constructor() {
        wards[msg.sender] = 1;
    }

    /// @notice Set the "url" at which the offchain resolver functions
    /// @param _url The URL string
    function setUrl(string memory _url) public auth {
        url = _url;
        emit UpdateURL(_url);
    }

    function makeSignatureHash(address target, uint64 expires, bytes memory request, bytes memory result) external pure returns(bytes32) {
        return SignatureVerifier.makeSignatureHash(target, expires, request, result);
    }

    /// @notice Resolves a name, as specified by ENSIP 10.
    /// @param name The DNS-encoded name to resolve.
    /// @param data The ABI encoded data for the underlying resolution function (Eg, addr(bytes32), text(bytes32,string), etc).
    /// @return The return data, ABI encoded identically to the underlying function.
    function resolve(bytes calldata name, bytes calldata data) external override view returns(bytes memory, address) {
        require(bytes(url).length > 0, 'Offchain/no-url');
        bytes memory callData = abi.encodeWithSelector(IResolverService.resolve.selector, name, data);
        string[] memory urls = new string[](1);
        urls[0] = url;
        revert OffchainLookup(
            address(this),
            urls,
            callData,
            OffchainResolver.resolveWithProof.selector,
            callData
        );
    }

    /// @notice Callback used by CCIP read compatible clients to verify and parse response
    /// @param response from the offchain resolver that needs verification
    /// @param extraData fasd
    /// @return sdf
    function resolveWithProof(bytes calldata response, bytes calldata extraData) external view returns(bytes memory) {
        (address signer, bytes memory result) = SignatureVerifier.verify(extraData, response);
        require(
            signers[signer],
            "SignatureVerifier: Invalid sigature");
        return result;
    }

    /// @notice ERC165 support for IExtendedResolver
    /// @param interfaceID that is being queried if supported
    /// @return true if interfaceId (or a parent interface) is supported, false otherwise
    function supportsInterface(bytes4 interfaceID) public view override returns(bool) {
        return interfaceID == type(IExtendedResolver).interfaceId || super.supportsInterface(interfaceID);
    }
}
