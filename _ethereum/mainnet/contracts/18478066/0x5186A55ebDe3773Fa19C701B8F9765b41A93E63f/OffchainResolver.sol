// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "./Ownable.sol";
import "./ECDSA.sol";

interface ISupportsInterface {
    function supportsInterface(bytes4 interfaceId) external pure returns (bool);
}

abstract contract SupportsInterface is ISupportsInterface {
    function supportsInterface(bytes4 interfaceID) virtual override public pure returns(bool) {
        return interfaceID == type(ISupportsInterface).interfaceId;    
    }
}

interface IExtendedResolver {
    function resolve(bytes memory name, bytes memory data) external view returns (bytes memory);
}

interface IResolverService {
    function resolve(bytes calldata name, bytes calldata data)
        external
        view
        returns (bytes memory result, uint64 expires, bytes memory sig);
}

/**
 * @title OffchainResolver
 * @author Lifeworld
 *
 * @notice Implements an ENS resolver that directs all queries to a CCIP read gateway.
 * @dev Callers must implement EIP 3668 and ENSIP 10.
 */
contract OffchainResolver is SupportsInterface, IExtendedResolver, Ownable {

    //////////////////////////////////////////////////
    // ERRORS
    ////////////////////////////////////////////////// 

    /**
     * @dev Revert to indicate an offchain CCIP lookup. See: https://eips.ethereum.org/EIPS/eip-3668
     *
     * @param sender           Address of this contract.
     * @param urls             List of lookup gateway URLs.
     * @param callData         Data to call the gateway with.
     * @param callbackFunction 4 byte function selector of the callback function on this contract.
     * @param extraData        Additional data required by the callback function.
     */
    error OffchainLookup(address sender, string[] urls, bytes callData, bytes4 callbackFunction, bytes extraData);

    /// @dev Revert queries for unimplemented resolver functions.
    error ResolverFunctionNotSupported();

    /// @dev Revert if the recovered signer address is not an authorized signer.
    error InvalidSigner();    

    /// @dev Revert if the signature has expired.
    error SignatureExpired(uint64 deadline);

    //////////////////////////////////////////////////
    // EVENTS
    ////////////////////////////////////////////////// 

    /**
     * @dev Emit an event when the contract owner authorizes a new signer.
     *
     * @param signer Address of the authorized signer.
     */
    event AddSigner(address indexed signer);

    /**
     * @dev Emit an event when the contract owner removes an authorized signer.
     *
     * @param signer Address of the removed signer.
     */
    event RemoveSigner(address indexed signer);

    //////////////////////////////////////////////////
    // STORAGE
    ////////////////////////////////////////////////// 

    /**
     * @dev URL of the CCIP lookup gateway.
     */
    string public url;

    /**
     * @dev Mapping of signer address to authorized boolean.
     */    
    mapping(address => bool) public isAuthorized;

    //////////////////////////////////////////////////
    // CONSTRUCTOR
    ////////////////////////////////////////////////// 

    /**
     * @notice Set the resolver owner, lookup gateway URL, and initial signer.
     *
     * @param _url          Lookup gateway URL. This value is set permanently.
     * @param _initialOwner Initial owner address.
     * @param _signer       Initial authorized signer address.     
     */
    constructor(string memory _url, address _initialOwner, address _signer) Ownable(_initialOwner) {
        url = _url;
        isAuthorized[_signer] = true;
        emit AddSigner(_signer);
    }  

    //////////////////////////////////////////////////
    // RESOLVER VIEWS
    //////////////////////////////////////////////////  

    /**
     * @notice Resolve the provided ENS name, as specified by ENSIP10.
     *         This function will always revert to indicate an offchain lookup.     
     *
     * @param name: The DNS-encoded name to resolve.
     * @param data: The ABI encoded data for the underlying resolution function (Eg, addr(bytes32), text(bytes32,string), etc).
     *
     * @return The return data, ABI encoded identically to the underlying function.
     */
    function resolve(bytes calldata name, bytes calldata data) external view returns (bytes memory) {
        bytes memory callData = abi.encodeWithSelector(IResolverService.resolve.selector, name, data);
        string[] memory urls = new string[](1);
        urls[0] = url;
        revert OffchainLookup(address(this), urls, callData, this.resolveWithProof.selector, callData);
    }

    /**
     * @notice Offchain lookup callback. The caller must provide the signed response returned by
     *         the lookup gateway.
     *
     * @param response: An ABI encoded tuple of `(bytes result, uint64 expires, bytes sig)`, where `result` is the data to return
     *        to the caller (abi.encoded address associated with username), 
     *        and `sig` is the (r,s,v) encoded message signature.
     * @param extraData: The original request that sent to CCIP gateway. Used in hash digest creation
     *        to recover associated signature
     *
     * @return ABI-encoded address of the fname owner.
     */     
    function resolveWithProof(bytes calldata response, bytes calldata extraData) external view returns (bytes memory) {        
        // Decode response into encoded result (address of resolved username), sig expiry timestamp, and signature
        (bytes memory result, uint64 expires, bytes memory sig) =
            abi.decode(response, (bytes, uint64, bytes));        
        // Attempt to recovery signer from hashed digest + signature
        address signer = ECDSA.recover(_makeSignatureHash(address(this), expires, extraData, result), sig);  
        // Check if sig has expired
        if (expires < block.timestamp) revert SignatureExpired(expires);                  
        // Check if recovered signer address is authorized signer
        if (!isAuthorized[signer]) revert InvalidSigner();
        // Return encoded result
        return result;
    }    

    //////////////////////////////////////////////////
    // ADMIN
    //////////////////////////////////////////////////   

    /**
     * Changes stored gateway url. Only callable by contract owner.
     */
    function setUrl(string memory _url) external {
        url = _url;
    }

    /**
     * Adds signers for the resolver service. Only callable by contract owner.
     */
    function addSigners(address[] calldata _signers) onlyOwner external {
        for (uint256 i = 0; i < _signers.length; i++) {
            isAuthorized[_signers[i]] = true;
            emit AddSigner(_signers[i]);
        }
    }    

    /**
     * Removes signers for the resolver service. Only callable by contract owner signers.
     */
    function removeSigners(address[] calldata _signers) onlyOwner external {
        for (uint256 i = 0; i < _signers.length; i++) {
            isAuthorized[_signers[i]] = false;
            emit RemoveSigner(_signers[i]);
        }
    }          

    //////////////////////////////////////////////////
    // INTERFACE DETECTION
    //////////////////////////////////////////////////      

    function supportsInterface(bytes4 interfaceID) public pure override returns (bool) {
        return interfaceID == type(IExtendedResolver).interfaceId || super.supportsInterface(interfaceID);
    }
    
    //////////////////////////////////////////////////
    // HELPERS
    ////////////////////////////////////////////////// 

    /**
     * @dev Generates a hash for signing/verifying.
     * @param target: The address the signature is for.
     * @param request: The original request that was sent.
     * @param result: The `result` field of the response (not including the signature part).
     */
    function _makeSignatureHash(
        address target,
        uint64 expires,
        bytes calldata request,
        bytes memory result
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    hex"1900",
                    target,
                    expires,
                    keccak256(request),
                    keccak256(result)
                )
            );
    }    

    // NOTE: can potentialyl delete the external version of this? unclear why it was here in the first place
    // NOTE: literally just helpful for test suite. can prob just move it into there
    function makeSignatureHash(address target, uint64 expires, bytes calldata request, bytes memory result)
        external
        pure
        returns (bytes32)
    {
        return _makeSignatureHash(target, expires, request, result);
    }    
}
