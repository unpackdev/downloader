//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./Strings.sol";
import "./ECDSA.sol";

import "./INiftyForge721.sol";
import "./NFBaseModule.sol";
import "./INFModuleTokenURI.sol";
import "./INFModuleWithRoyalties.sol";
import "./SignedAllowance.sol";

/// @title NahikosGameModule
/// @author Simon Fremaux (@dievardump)
contract NahikosGameModule is
    Ownable,
    SignedAllowance,
    NFBaseModule,
    INFModuleTokenURI,
    INFModuleWithRoyalties
{
    // this is because minting is secured with a Signature
    using Strings for uint256;
    using ECDSA for bytes32;

    // directory containing the tokens metadata
    string public baseURI;

    // contract on which this module is made to mint
    address public nftContract;

    // associates keccak256(registry, tokenId) to its type
    mapping(bytes32 => uint256) public tokenTypes;

    /// @notice constructor
    /// @param contractURI_ The contract URI (containing its metadata) - can be empty ""
    /// @param owner_ Address to whom transfer ownership (can be address(0), then owner is deployer)
    /// @param nftContract_ contract on which we mint
    /// @param baseURI_ the base URI for tokens
    constructor(
        string memory contractURI_,
        address owner_,
        address nftContract_,
        string memory baseURI_
    ) NFBaseModule(contractURI_) {
        if (address(0) != nftContract_) {
            nftContract = nftContract_;
        }

        if (address(0) != owner_) {
            transferOwnership(owner_);
        }

        baseURI = baseURI_;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override
        returns (bool)
    {
        return
            interfaceId == type(INFModuleWithRoyalties).interfaceId ||
            interfaceId == type(INFModuleTokenURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        return tokenURI(msg.sender, tokenId);
    }

    function tokenURI(address registry, uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        bytes32 key = keccak256(abi.encode(registry, tokenId));
        uint256 typeId = tokenTypes[key];

        // ensure that we actually have this tokenId
        require(typeId != 0, '!UNKNOWN_TYPE!');

        return string(abi.encodePacked(baseURI, typeId.toString()));
    }

    /// @inheritdoc	INFModuleWithRoyalties
    function royaltyInfo(uint256 tokenId)
        public
        view
        override
        returns (address, uint256)
    {
        return royaltyInfo(msg.sender, tokenId);
    }

    /// @inheritdoc	INFModuleWithRoyalties
    function royaltyInfo(address registry, uint256 tokenId)
        public
        view
        override
        returns (address, uint256)
    {
        bytes32 key = keccak256(abi.encode(registry, tokenId));
        uint256 typeId = tokenTypes[key];

        // ensure that we actually have this tokenId
        require(typeId != 0, '!UNKNOWN_TOKEN!');

        return (owner(), 500);
    }

    /// @notice Helper to know allowancesSigner address
    /// @return the allowance signer address
    function allowancesSigner() public view virtual override returns (address) {
        return owner();
    }

    /// @notice sets contract uri
    /// @param newURI the new uri
    function setContractURI(string memory newURI) external onlyOwner {
        _setContractURI(newURI);
    }

    /// @notice sets baseURI for the tokens
    /// @param newURI the new baseURI
    function setBaseURI(string memory newURI) external onlyOwner {
        baseURI = newURI;
    }

    /// @notice Setter for nfts contract
    /// @param nftContract_ the contract containing planets
    function setNFTContract(address nftContract_) external onlyOwner {
        nftContract = nftContract_;
    }

    /// @notice Claiming function
    /// @param to the minter
    /// @param typeId the type of token (this is also the nonce)
    /// @param signature the signature for the mint
    function claim(
        address to,
        uint256 typeId,
        bytes memory signature
    ) external payable {
        require(typeId != 0, '!UNKNOWN_TYPE!');

        // will validate the signature & mark this (account, nonce) used
        _useAllowance(to, typeId, signature);

        uint256 tokenId = INiftyForge721(nftContract).mint(
            to,
            '',
            address(0),
            0,
            address(0)
        );

        // now associate [nftContract][tokenId] with typeId
        bytes32 key = keccak256(abi.encode(nftContract, tokenId));
        tokenTypes[key] = typeId;
    }
}
