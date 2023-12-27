// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

abstract contract TanasinnState {
    // Custom Errors
    error WalletAlreadyMinted();
    error WithdrawTransfer();
    error IncorrectEthValue();
    error MintNotStarted();
    error MaxQuantity();
    error MaxSupply();
    error URIFrozen();
    error NoBots();

    // Constants
    /// @notice Max Supply for collection
    uint256 public constant TOTAL_SUPPLY = 2634;

    /// @notice Per-token mint price
    uint256 public constant MINT_PRICE = 0.007 ether;

    address internal constant ADMIN_WALLET = 0xcF7bc71681AE41101622dd885afd3625febed87d;

    /// @notice Token name and symbol used in ERC721A constructor
    string internal constant NAME = "Tanasinn";
    string internal constant SYMBOL = "SINN";

    // Bools
    bool internal baseURIFrozen;
    bool public mintStarted;

    // Strings
    string public baseURI;
}
