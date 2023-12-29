// SPDX-License-Identifier: ISC
pragma solidity ^0.8.12 < 0.9.0;

import "./StringsUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";

import "./ContentMixin.sol";
import "./NativeMetaTransaction.sol";
import "./IAuthenticator.sol";
import "./TokenRetriever.sol";
import "./ICryptopiaERC721.sol";

/// @title Cryptopia ERC721 
/// @notice Non-fungible token that extends Openzeppelin ERC721
/// @dev Implements the ERC721 standard
/// @author HFB - <frank@cryptopia.com>
abstract contract CryptopiaERC721 is ICryptopiaERC721, ERC721EnumerableUpgradeable, ContextMixin, NativeMetaTransaction, OwnableUpgradeable, AccessControlUpgradeable, TokenRetriever {

    /**
     *  Storage
     */
    string public contractURI;
    string public baseTokenURI;

    /// Refs
    IAuthenticator public authenticator;


    /**
     * Roles
     */
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");


    /// @dev Contract initializer sets shared base uri
    /// @param _name Token name (long)
    /// @param _symbol Token ticker symbol (short)
    /// @param _authenticator Whitelist
    /// @param _initialContractURI Location to contract info
    /// @param _initialBaseTokenURI Base of location where token data is stored. To be postfixed with tokenId
    function __CryptopiaERC721_init(
        string memory _name, 
        string memory _symbol, 
        address _authenticator,  
        string memory _initialContractURI, 
        string memory _initialBaseTokenURI) 
        internal onlyInitializing
    {
        __Ownable_init();
        __AccessControl_init();
        __EIP712_init(_name);
        __ERC721_init(_name, _symbol);
        __ERC721Enumerable_init_unchained();
        __CryptopiaERC721_init_unchained(
            _authenticator, 
            _initialContractURI, 
            _initialBaseTokenURI);
    }


    /// @dev Contract initializer sets shared base uri
    /// @param _authenticator Whiteliste for proxies
    /// @param initialContractURI Location to contract info
    /// @param initialBaseTokenURI Base of location where token data is stored. To be postfixed with tokenId
    function __CryptopiaERC721_init_unchained(
        address _authenticator, 
        string memory initialContractURI, 
        string memory initialBaseTokenURI) 
        internal onlyInitializing
    {
        authenticator = IAuthenticator(_authenticator);
        contractURI = initialContractURI;
        baseTokenURI = initialBaseTokenURI;

        // Grant admin roles
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }


    /** 
     * Public functions
     */
    /// @dev Set contract URI
    /// @param uri Location to contract info
    function setContractURI(string memory uri) 
        public virtual  
        onlyRole(ADMIN_ROLE) 
    {
        contractURI = uri;
    }


    /// @dev Set base token URI 
    /// @param uri Base of location where token data is stored. To be postfixed with tokenId
    function setBaseTokenURI(string memory uri) 
        public virtual   
        onlyRole(ADMIN_ROLE)  
    {
        baseTokenURI = uri;
    }



    /// @dev tokenURI() postfixed with the token ID baseTokenURI(){tokenID}
    /// @param tokenId Token ID
    /// @return uri where token data can be retrieved
    function tokenURI(uint tokenId) 
        public override view 
        returns (string memory)
    {
        return string(abi.encodePacked(baseTokenURI, StringsUpgradeable.toString(tokenId)));
    }


    /// @dev Returns whether `spender` is allowed to manage `tokenId`
    /// @param spender Account to check
    /// @param tokenId Token id to check
    /// @return true if `spender` is allowed ot manage `_tokenId`
    function isApprovedOrOwner(address spender, uint256 tokenId) 
        public override view 
        returns (bool)
    {
        return _isApprovedOrOwner(spender, tokenId);
    }


    /// @dev Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings
    /// @param owner Token owner
    /// @param operator Operator to check
    /// @return bool true if `_operator` is approved for all
    function isApprovedForAll(address owner, address operator) 
        public override(ERC721Upgradeable, IERC721Upgradeable) view 
        returns (bool) 
    {
        if (authenticator.authenticate(operator)) {
            return true; // Whitelisted proxy contract for easy trading
        }

        return super.isApprovedForAll(owner, operator);
    }

    
    /// @dev Failsafe mechanism
    /// Allows the owner to retrieve tokens from the contract that might have been send there by accident
    /// @param tokenContract The address of ERC20 compatible token
    function retrieveTokens(IERC20Upgradeable tokenContract) 
        public virtual override  
        onlyRole(ADMIN_ROLE) 
    {
        super.retrieveTokens(tokenContract);
    }


    /// @dev Failsafe mechanism
    /// Allows the owner to retrieve ETH from the contract that
    /// might have been send there by accident
    function retrieveETH() 
        public virtual   
        onlyRole(ADMIN_ROLE) 
    {
        // Retrieve eth
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Failed to retrieve ETH");
    }


    /// @dev Calls supportsInterface for all parent contracts 
    /// @param interfaceId The signature of the interface
    /// @return bool True if `interfaceId` is supported
    function supportsInterface(bytes4 interfaceId) 
        override(ERC721EnumerableUpgradeable, AccessControlUpgradeable) 
        public virtual view 
        returns (bool) 
    {
        return super.supportsInterface(interfaceId);
    }


    /**
     * Private functions
     */
    /// @dev This is used instead of msg.sender as transactions won't be sent by the original token owner
    function _msgSender() 
        internal override view 
        returns (address sender) 
    {
        return ContextMixin.msgSender();
    }
}