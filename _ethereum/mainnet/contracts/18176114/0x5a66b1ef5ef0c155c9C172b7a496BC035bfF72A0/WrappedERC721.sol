// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721URIStorage.sol";
import "./ERC721.sol";
import "./Initializable.sol";

import "./IWrappedERC721.sol";

/// @title A custom ERC721 contract used in the bridge
contract WrappedERC721 is IWrappedERC721, ERC721URIStorage, Initializable {

    address internal _bridge;
    string internal _tokenName;
    string internal _tokenSymbol;  
    
    /// @dev Checks if the caller is the bridge contract
    modifier onlyBridge {
        require(msg.sender == _bridge, "Token: caller is not a bridge!");
        _;
    }

    /// @dev Creates an "empty" template token that will be cloned in the future
    constructor() ERC721("", "") {}

    /// @dev Upgrades an "empty" template. Initializes internal variables. 
    /// @param name_ The name of the token
    /// @param symbol_ The symbol of the token
    /// @param bridge_ The address of the bridge of the tokens 
    function initialize(
        string memory name_,
        string memory symbol_,
        address bridge_
    ) external initializer {
        require(bytes(name_).length > 0, "ERC721: initial token name can not be empty!");
        require(bytes(symbol_).length > 0, "ERC721: initial token symbol can not be empty!");
        require(bridge_ != address(0), "ERC721: initial bridge address can not be a zero address!");
        _bridge = bridge_;
        _tokenName = name_;
        _tokenSymbol = symbol_;
    }

    /// @notice Returns the name of the token
    /// @return The name of the token
    function name() public view override(ERC721, IWrappedERC721) returns(string memory) {
        return _tokenName;
    }

    /// @notice Returns the symbol of the token
    /// @return The symbol of the token
    function symbol() public view override(ERC721, IWrappedERC721) returns(string memory) {
        return _tokenSymbol;
    }

    /// @notice Creates tokens and assigns them to account
    /// @param to The receiver of tokens
    /// @param tokenId The ID of minted token
    function mint(address to, uint256 tokenId) external onlyBridge {
        _safeMint(to, tokenId);
        emit Mint(to, tokenId);
    }

    
    /// @notice Destroys a token with a given ID
    /// @param tokenId The ID of the token to destroy
    function burn(uint256 tokenId) external onlyBridge {
        _burn(tokenId);
        emit Burn(tokenId);
    }

    /// @notice Returns the address of the bridge
    /// @return The address of the bridge
    function bridge() external view returns(address) {
        return _bridge;
    }
}
