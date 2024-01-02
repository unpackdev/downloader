// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IPaddysPass {

    struct Token {
        uint256 tokenId;
        uint256 totalSupply;
        uint256 maxSupply;
        uint256 publicPrice;
        uint256 publicStart;
        uint256 publicMaxMint;
    }

    error SoldOut();
    error InvalidSignature();
    error AmountExceedsMintLimit();
    error PublicMintNotLive();
    error ContractMintNotAllowed();
    error InsufficientBalance();
    error ZeroBalance();
    error TransferFailed();

    event MetadataUriChanged(string metadataUri);
    event TokenDataChanged(uint256 tokenId, uint256 totalSupply, uint256 maxSupply, uint256 publicPrice, uint256 publicStart, uint256 publicMaxMint);
    event StakingContractChanged(address staking);
    event RegistryContractChanged(address registry);
    event SignerAddressChanged(address signer);
    event BalanceWithdrawn(address owner, uint256 contractBalance);

}