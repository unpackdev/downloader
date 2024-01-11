// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./Ownable.sol";
import "./IERC165.sol";
import "./ITokenManagerSelector.sol";

contract TokenManagerSelector is ITokenManagerSelector, Ownable {
    bytes4 public constant INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 public constant INTERFACE_ID_ERC1155 = 0xd9b67a26;

    address public immutable TOKEN_MANAGER_ERC721;
    address public immutable TOKEN_MANAGER_ERC1155;

    mapping(address => address) public tokenManagerSelectorForTokenAddress;

    event TokenManagerSet(address indexed tokenAddress, address indexed tokenManager);
    event TokenManagerRemoved(address indexed tokenAddress);

    constructor(address tokenManagerERC721, address tokenManagerERC1155) {
        TOKEN_MANAGER_ERC721 = tokenManagerERC721;
        TOKEN_MANAGER_ERC1155 = tokenManagerERC1155;
    }

    function setTokenManager(address tokenAddress, address tokenManager) external onlyOwner {
        require(tokenAddress != address(0), "TokenManagerSelector: tokenAddress cannot be null address");
        require(tokenManager != address(0), "TokenManagerSelector: tokenManager cannot be null address");

        tokenManagerSelectorForTokenAddress[tokenAddress] = tokenManager;

        emit TokenManagerSet(tokenAddress, tokenManager);
    }

    function removeTokenManager(address tokenAddress) external onlyOwner {
        require(
            tokenManagerSelectorForTokenAddress[tokenAddress] != address(0),
            "TokenManagerSelector: tokenAddress has no token manager"
        );

        tokenManagerSelectorForTokenAddress[tokenAddress] = address(0);

        emit TokenManagerRemoved(tokenAddress);
    }

    function getManagerAddress(address tokenAddress) external view returns (address) {
        address transferManager = tokenManagerSelectorForTokenAddress[tokenAddress];

        if (transferManager == address(0)) {
            if (IERC165(tokenAddress).supportsInterface(INTERFACE_ID_ERC721)) {
                transferManager = TOKEN_MANAGER_ERC721;
            } else if (IERC165(tokenAddress).supportsInterface(INTERFACE_ID_ERC1155)) {
                transferManager = TOKEN_MANAGER_ERC1155;
            }
        }

        return transferManager;
    }
}