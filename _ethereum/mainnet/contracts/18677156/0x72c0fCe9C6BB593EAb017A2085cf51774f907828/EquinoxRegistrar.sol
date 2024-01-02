//SPDX-License-Identifier: MIT

pragma solidity ^0.8.21;

import "./BitMaps.sol";
import "./IERC721.sol";
import "./INameWrapper.sol";
import "./ENS.sol";

interface IERC6551Registry {
    /**
     * @dev Creates a token bound account for a non-fungible token.
     *
     * If account has already been created, returns the account address without calling create2.
     *
     * Emits ERC6551AccountCreated event.
     *
     * @return account The address of the token bound account
     */
    function createAccount(
        address implementation,
        bytes32 salt,
        uint256 chainId,
        address tokenContract,
        uint256 tokenId
    ) external returns (address account);
}

interface IAccountProxy {
    function initialize(address implementation) external;
}

contract FaeRegistrar {
    using BitMaps for BitMaps.BitMap;

    uint256 constant MIN_NORMAL_LENGTH = 3;
    uint32 constant SUBNAME_FUSES = PARENT_CANNOT_CONTROL | CAN_EXTEND_EXPIRY | CANNOT_UNWRAP | CANNOT_TRANSFER;
    IERC6551Registry constant ERC6551Registry = IERC6551Registry(0x000000006551c19487814612e58FE06813775758);

    INameWrapper immutable public wrapper;  // Address of the NameWrapper
    ENS immutable public ens;               // Address of the ENS registry
    IERC721 immutable public token;         // Address of the Equinox NFT token
    bytes32 immutable public baseNode;      // Namehash of the name to issue subdomains of
    address immutable accountProxy;         // Proxy contract for ERC6551 account
    address immutable accountImplementation;// Implementation of ERC6551 account
    uint256 immutable firstForgedId;        // First ID that qualifies to claim short names
    uint256 immutable lastForgedId;         // Last ID that qualifies to claim short names
    BitMaps.BitMap tokenUsed;               // Mapping of used token IDs

    event TokenUsed(uint256 tokenId, string name);

    error TokenAlreadyUsed(uint256 tokenId);
    error CallerDoesNotOwnToken(uint256 tokenId);
    error NameTooShort(string name);
    error NameAlreadyExists(string name);

    constructor(address _wrapper, address _token, bytes32 _baseNode, address _accountProxy, address _accountImplementation, uint256 _firstForgedId, uint256 _lastForgedId) {
        wrapper = INameWrapper(_wrapper);
        ens = wrapper.ens();
        token = IERC721(_token);
        baseNode = _baseNode;
        accountProxy = _accountProxy;
        accountImplementation = _accountImplementation;
        firstForgedId = _firstForgedId;
        lastForgedId = _lastForgedId;
    }

    function isTokenUsed(uint256 tokenId) external view returns(bool) {
        return tokenUsed.get(tokenId);
    }

    function claim(
        uint256 tokenId,
        string calldata name,
        address resolver
    ) external {
        if(tokenUsed.get(tokenId)) {
            revert TokenAlreadyUsed(tokenId);
        }
        if(token.ownerOf(tokenId) != msg.sender) {
            revert CallerDoesNotOwnToken(tokenId);
        }
        if((tokenId < firstForgedId || tokenId > lastForgedId) && bytes(name).length < MIN_NORMAL_LENGTH) {
            revert NameTooShort(name);
        }

        // Get address of the ERC6551 wallet that will own the name
        address owner = ERC6551Registry.createAccount(
            accountProxy,           // implementation
            bytes32(0),             // salt
            block.chainid,          // chainId
            address(token),         // token
            tokenId                 // token ID
        );

        // Initialize it if it isn't already
        try IAccountProxy(owner).initialize(accountImplementation) {} catch {}

        try wrapper.setSubnodeRecord(
            baseNode,           // node
            name,               // name
            owner,              // owner
            resolver,           // resolver
            0,                  // ttl
            SUBNAME_FUSES,      // fuses
            type(uint64).max    // expiry
        ) {
            tokenUsed.set(tokenId);
            emit TokenUsed(tokenId, name);
        } catch (bytes memory lowLevelData) {
            // Did it revert because the name already exists?
            bytes32 node = keccak256(bytes.concat(baseNode, keccak256(bytes(name))));
            if(ens.owner(node) != address(0)) {
                revert NameAlreadyExists(name);
            }

            // Otherwise, bubble up the revert
            assembly {
                revert(add(lowLevelData, 32), mload(lowLevelData))
            }
        }
    }
}