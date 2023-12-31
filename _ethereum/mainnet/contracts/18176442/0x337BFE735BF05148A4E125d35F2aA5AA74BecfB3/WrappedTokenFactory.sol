// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IWrappedTokenFactory.sol";
import "./WrappedERC20.sol";
import "./WrappedERC721.sol";
import "./WrappedERC1155.sol";
import "./Clones.sol";


/// @title A factory of custom ERC20, ERC721, ERC1155 tokens used in the bridge
contract WrappedTokenFactory is IWrappedERC20Factory, Initializable {
    // @dev Padding 100 words of storage for upgradeability. Follows OZ's guidance.
    uint256[100] private __gap;
    /// @dev Addresses of token templates to clone
    address private ERC20Template;
    address private ERC721Template;
    address private ERC1155Template;

    /// @dev Map of addresses of tokens in the original and target chains
    mapping(address => address) internal originalToWrappedTokens;

    /// @dev Struct holds the name of the original chain and the address of the original token
    /// @dev Used to see what was the original chain of the wrapped token
    struct TokenInfo {
        string originalChain;
        address originalAddress;
    }

    /// @dev Map of addresses of wrapped tokens and addresses of original tokens and original chains
    mapping(address => TokenInfo) internal wrappedToOriginalTokens;

    /// @dev Map of names and addresses of wrapped tokens
    /// @dev Should be used by the back/front-end
    mapping(string => address) internal wrappedNameToAddress;

    /// @dev Map of token IDs and addresses of wrapped token
    /// @dev Should be used by the back/front-end
    mapping(string => address) internal wrappedUriToAddress;

    /// @dev config token templates to copy and upgrade it later
    /// @param _ERC20Template template for ERC20 tokens
    /// @param _ERC721Template template for ERC721 tokens
    /// @param _ERC1155Template template for ERC1155 tokens
    function initialize(
        address _ERC20Template,
        address _ERC721Template,
        address _ERC1155Template
    ) public initializer
    {
        ERC20Template = _ERC20Template;
        ERC721Template = _ERC721Template;
        ERC1155Template = _ERC1155Template;
    }

    /// @notice Checks if there is a wrapped token in the target chain for the original token 
    /// @param originalToken The address of the original token to check
    /// @return True if a wrapped token exists for a given original token
    function checkTargetToken(address originalToken) public view returns (bool) {
        require(originalToken != address(0), "Factory: original token can not have a zero address!");
        // If there is no value for `originalToken` key then address(0) will be returned from the map
        if (originalToWrappedTokens[originalToken] != address(0)) {
            return true;
        }
        return false;
    }

    /// @notice Returns the name of the original token and the original chain for a wrapped token
    /// @param wrappedToken The address of the wrapped token
    /// @return The name of the original chain and the address of the original token
    function getOriginalToken(address wrappedToken) external view returns (TokenInfo memory) {
        require(wrappedToken != address(0), "Factory: wrapped token can not have a zero address!");
        require(
            bytes(wrappedToOriginalTokens[wrappedToken].originalChain).length > 0,
            "Factory: no original token found for a wrapped token!"
        );
        return wrappedToOriginalTokens[wrappedToken];

    }

    /// @notice Returns the address of the wrapped token by its name
    /// @dev Used only for ERC20 and ERC721
    function getWrappedAddressByName(string memory name) external view returns (address) {
        require(bytes(name).length > 0 , "Factory: token name is too short!");
        require(wrappedNameToAddress[name] != address(0), "Factory: no wrapped token with this name!");
        return wrappedNameToAddress[name];
    }

    /// @notice Returns the address of the wrapped token by its URI
    /// @dev Used only for ERC1155
    function getWrappedAddressByUri(string memory uri) external view returns (address) {
        require(bytes(uri).length > 0 , "Factory: token URI is too short!");
        require(wrappedUriToAddress[uri] != address(0), "Factory: no wrapped token with this URI!");
        return wrappedUriToAddress[uri];
    }

    /// @notice Creates a new wrapped ERC20 token on the target chain
    /// @dev Should be deployed on the target chain
    /// @param originalChain The name of the original chain
    /// @param originalToken The address of the original token
    /// @param name The name of the new token
    /// @param symbol The symbol of the new token
    /// @param decimals The number of decimals of the new token
    /// @param bridge The address of the bridge of tokens
    /// @return The address of a new token
    function createERC20Token(
        string memory originalChain,
        address originalToken,
        string memory name,
        string memory symbol,
        uint8 decimals,
        address bridge
    ) external returns (address) {

        require(bytes(originalChain).length > 0, "Factory: chain name is too short!");
        require(bytes(name).length > 0, "Factory: new token name is too short!");
        require(bytes(symbol).length > 0, "Factory: new token symbol is too short!");
        require(decimals > 0, "Factory: invalid decimals!");
        require(bridge != address(0), "Factory: bridge can not have a zero address!");

        // Check if a wrapped token for the original token already exists
        require(checkTargetToken(originalToken) == false, "Factory: wrapped ERC20 token already exists!");

        // Copy the template functionality and create a new token (proxy pattern)
        // This will create a new token on the same chain the factory is deployed on (target chain)
        address wrappedToken = Clones.clone(ERC20Template);
        // Map the original token to the wrapped token 
        originalToWrappedTokens[originalToken] = wrappedToken;

        // And do the same backwards: map the wrapped token to the original token and original chain
        TokenInfo memory wrappedTokenInfo = TokenInfo(originalChain, originalToken);
        wrappedToOriginalTokens[address(wrappedToken)] = wrappedTokenInfo;

        // Save tokens address and name to be used off-chain
        wrappedNameToAddress[name] = wrappedToken;

        WrappedERC20(wrappedToken).initialize(name, symbol, decimals, bridge);
        
        emit CreateERC20Token(originalChain, originalToken, name, wrappedToken);
        
        return address(wrappedToken);
    }

    /// @notice Creates a new ERC721 token to be used in the bridge
    /// @param originalChain The name of the original chain
    /// @param originalToken The address of the original token on the original chain
    /// @param name The name of the new token
    /// @param symbol The symbol of the new token
    /// @return The address of a new token
    function createERC721Token(
        string memory originalChain,
        address originalToken,
        string memory name,
        string memory symbol,
        address bridge
    ) external returns (address) {

        require(bytes(originalChain).length > 0, "Factory: chain name is too short!");
        require(bytes(name).length > 0, "Factory: new token name is too short!");
        require(bytes(symbol).length > 0, "Factory: new token symbol is too short!");
        require(bridge != address(0), "Factory: bridge can not have a zero address!");

        // Check if a wrapped token for the original token already exists
        require(checkTargetToken(originalToken) == false, "Factory: wrapped ERC721 token already exists!");

        // Copy the template functionality and create a new token (proxy pattern)
        // This will create a new token on the same chain the factory is deployed on (target chain)
        address wrappedToken = Clones.clone(ERC721Template);
        // Map the original token to the wrapped token 
        originalToWrappedTokens[originalToken] = wrappedToken;

        // And do the same backwards: map the wrapped token to the original token and original chain
        TokenInfo memory wrappedTokenInfo = TokenInfo(originalChain, originalToken);
        wrappedToOriginalTokens[address(wrappedToken)] = wrappedTokenInfo;

        // Save tokens address and name to be used off-chain
        wrappedNameToAddress[name] = wrappedToken;

        WrappedERC721(wrappedToken).initialize(name, symbol, bridge);

        emit CreateERC721Token(originalChain, originalToken, name, wrappedToken);
        
        return address(wrappedToken);
    }

    /// @notice Creates a new ERC 1155 token to be used in the bridge
    /// @param originalChain The name of the original chain
    /// @param originalToken The address of the original token on the original chain
    /// @param tokenUri The URI of the token
    /// @return The address of a new token
    function createERC1155Token(
        string memory originalChain,
        address originalToken,
        string memory tokenUri,
        address bridge
    ) external returns (address) {

        require(bytes(originalChain).length > 0, "Factory: chain name is too short!");
        require(bytes(tokenUri).length > 0, "Factory: new token URI is too short!");
        require(bridge != address(0), "Factory: bridge can not have a zero address!");

        // Check if a wrapped token for the original token already exists
        require(checkTargetToken(originalToken) == false, "Factory: wrapped ERC1155 token already exists!");

        // Copy the template functionality and create a new token (proxy pattern)
        // This will create a new token on the same chain the factory is deployed on (target chain)
        address wrappedToken = Clones.clone(ERC1155Template);
        // Map the original token to the wrapped token 
        originalToWrappedTokens[originalToken] = wrappedToken;

        // And do the same backwards: map the wrapped token to the original token and original chain
        TokenInfo memory wrappedTokenInfo = TokenInfo(originalChain, originalToken);
        wrappedToOriginalTokens[address(wrappedToken)] = wrappedTokenInfo;

        // Save tokens address and URI to be used off-chain
        wrappedUriToAddress[tokenUri] = wrappedToken;

        WrappedERC1155(wrappedToken).initialize(tokenUri, bridge);

        emit CreateERC1155Token(originalChain, originalToken, tokenUri, wrappedToken);
        
        return address(wrappedToken);
    }
}
