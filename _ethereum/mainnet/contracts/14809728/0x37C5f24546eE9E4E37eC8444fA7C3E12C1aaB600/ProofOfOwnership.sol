// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./ERC165Checker.sol";

interface IERC721 {
    function balanceOf(address owner) external view returns (uint256 balance);
}

interface IERC1155 {
    function balanceOf(address account, uint256 id) external view returns (uint256);
}

contract ProofOfOwnership {
    
    bytes4 constant _ERC721 = 0x80ac58cd;
    bytes4 constant _ERC1155 = 0xd9b67a26;

    mapping(address => address) public signers;
    
    constructor() {}

    function setSigner(address signer) external {
        signers[signer] = msg.sender;
    }

    /// ERC721 balance lookup
    /// @param contract_ Address for an ERC721 contract
    function balanceOf_ERC721(address account_, address contract_) external view returns (uint256) {
        require(ERC165Checker.supportsInterface(contract_, _ERC721), "Must be ERC721-compatible contract");
        
        uint256 balance = IERC721(contract_).balanceOf(account_);

        if (balance == 0 && signers[account_] > address(0)) {
            balance = IERC721(contract_).balanceOf(signers[account_]);
        }

        return balance;
    }

    /// ERC1155 balance lookup
    /// @param contract_ Address for an ERC1155 contract
    /// @param tokenId_ Token ID for ERC1155 token
    function balanceOf_ERC1155(address account_, address contract_, uint256 tokenId_) external view returns (uint256) {
        require(ERC165Checker.supportsInterface(contract_, _ERC1155), "Must be ERC1155-compatible contract");

        uint256 balance = IERC1155(contract_).balanceOf(account_, tokenId_);

        if (balance == 0 && signers[account_] > address(0)) {
            balance = IERC1155(contract_).balanceOf(signers[account_], tokenId_);
        }

        return balance;
    }
}