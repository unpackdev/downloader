// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./MerkleProofLib.sol";
import "./SafeTransferLib.sol";
import "./ERC2981.sol";

/// @title Absolution NFT Contract
/// @dev A contract for minting "Absolution" NFTs with private and public sales.
contract Absolution is ERC721A, ERC2981, Ownable {
    string private baseURI = "";
    string public contractURI = "";

    uint256 public maxSupply = 333;
    uint256 public privatePrice = 0.069 ether;
    uint256 public publicPrice = 0.1 ether;
    uint256 public privateSaleStartTime;
    uint256 public privateSaleEndTime;

    bytes32 public immutable PROVENANCE;
    bytes32 public merkleRoot;
    address public immutable contractCreator;

    error ExceedsMaximumSupply();
    error PrivateSaleNotStarted();
    error PublicSaleNotStarted();
    error PrivateSaleEnded();
    error InvalidPaymentAmount();
    error AddressNotWhitelisted();

    event MerkleRootUpdated(bytes32 newMerkleRoot);

    /// @dev This event emits when the metadata of a range of tokens is changed.
    /// So that the third-party platforms such as NFT market could
    /// timely update the images and related attributes of the NFTs.
    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);

    /// @notice Creates an instance of the Absolution NFT contract.
    /// @param privateStartTime_ Timestamp for private sale start.
    /// @param privateEndTime_ Timestamp for private sale end.
    /// @param provenance_ provenance hash for verifying asset authenticity.
    /// @param merkleRoot_ Merkle root for whitelist verification.
    constructor(
        uint256 privateStartTime_,
        uint256 privateEndTime_,
        bytes32 provenance_,
        bytes32 merkleRoot_,
        uint96 royaltyBps_,
        string memory baseURI_,
        string memory contractURI_
    ) ERC721A("Absolution", "ABS") {
        PROVENANCE = provenance_;
        privateSaleStartTime = privateStartTime_;
        privateSaleEndTime = privateEndTime_;
        merkleRoot = merkleRoot_;
        _initializeOwner(msg.sender);
        _setDefaultRoyalty(msg.sender, royaltyBps_);
        contractCreator = msg.sender;
        baseURI = baseURI_;
        contractURI = contractURI_;
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721A, ERC2981) returns (bool) {
        // Supports the following `interfaceId`s:
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        // - IERC2981: 0x2a55205a
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }

    modifier checkMaxSupply(uint256 amount) {
        uint256 supply = totalSupply();
        if (supply + amount > maxSupply) {
            revert ExceedsMaximumSupply();
        }
        _;
    }

    /// @notice Mint tokens during the private sale.
    /// @param recipient Address to mint tokens to.
    /// @param amount Amount of tokens to mint.
    /// @param proof Merkle proof for whitelist verification.
    function privateMint(
        address recipient,
        uint256 amount,
        bytes32[] calldata proof
    ) public payable checkMaxSupply(amount) {
        address to = recipient;

        // Verify that the sale is active
        if (block.timestamp < privateSaleStartTime) {
            revert PrivateSaleNotStarted();
        }
        if (block.timestamp > privateSaleEndTime) {
            revert PrivateSaleEnded();
        }

        // Verify that the payment is sufficient
        if (amount * privatePrice != msg.value) {
            revert InvalidPaymentAmount();
        }

        // Verify that the sender is whitelisted
        bool verified = MerkleProofLib.verifyCalldata(
            proof,
            merkleRoot,
            keccak256(abi.encodePacked(to))
        );
        if (!verified) {
            revert AddressNotWhitelisted();
        }

        _mint(to, amount);
    }

    /// @notice Mint tokens during the public sale.
    /// @param amount Amount of tokens to mint.
    function publicMint(
        address recipient,
        uint256 amount
    ) public payable checkMaxSupply(amount) {
        address to = recipient;

        // Verify that the sale is active
        if (block.timestamp < privateSaleEndTime) {
            revert PublicSaleNotStarted();
        }

        // Verify that the payment is sufficient
        if (amount * publicPrice != msg.value) {
            revert InvalidPaymentAmount();
        }

        _mint(to, amount);
    }

    //////////////////////////
    ///  Token methods      //
    //////////////////////////

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    /// @notice Get the URI for a specific token ID.
    /// @param tokenId ID of the token to fetch the URI for.
    /// @return String representing the token URI.
    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory base = _baseURI();
        return string(abi.encodePacked(base, _toString(tokenId)));
    }

    /// @notice Get the base URI for all tokens.
    /// @return String representing the base URI.
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    //////////////////////////
    ///  Owner only methods //
    //////////////////////////

    /// @notice Reserve a specified amount of tokens for an address.
    /// @param to Address to reserve tokens for.
    /// @param amount Number of tokens to reserve.
    function reserve(
        address to,
        uint256 amount
    ) public onlyOwner checkMaxSupply(amount) {
        _mint(to, amount);
    }

    /// @notice Set the royalty for the contract.
    /// @param recipient Address to receive royalties.
    /// @param royaltyBps Basis points for royalty.
    function setRoyalty(address recipient, uint96 royaltyBps) public onlyOwner {
        _setDefaultRoyalty(recipient, royaltyBps);
    }

    /// @notice Set the start and end times for the private sale.
    /// @param _startTime Timestamp for private sale start.
    /// @param _endTime Timestamp for private sale end.
    function setPrivateSaleTime(
        uint256 _startTime,
        uint256 _endTime
    ) public onlyOwner {
        privateSaleStartTime = _startTime;
        privateSaleEndTime = _endTime;
    }

    /// @notice Set the price for the private sale.
    /// @param _newPrice New price for the private sale.
    function setPrivatePrice(uint256 _newPrice) public onlyOwner {
        privatePrice = _newPrice;
    }

    /// @notice Set the price for the public sale.
    /// @param _newPrice New price for the public sale.
    function setPublicPrice(uint256 _newPrice) public onlyOwner {
        publicPrice = _newPrice;
    }

    /// @notice Set a new base URI for token metadata.
    /// @param _newBaseURI The new base URI.
    function setBaseURI(string calldata _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
        emit BatchMetadataUpdate(_startTokenId(), type(uint256).max);
    }

    /// @notice Set a new contract URI for OpenSea.
    /// @param _newContractURI The new contract URI.
    function setContractURI(string calldata _newContractURI) public onlyOwner {
        contractURI = _newContractURI;
    }

    /// @notice Update the Merkle root for whitelist verification.
    /// @param _newMerkleRoot The new Merkle root.
    function setMerkleRoot(bytes32 _newMerkleRoot) public onlyOwner {
        merkleRoot = _newMerkleRoot;
        emit MerkleRootUpdated(_newMerkleRoot);
    }

    /// @notice Lock the maximum supply of tokens.
    function lockSupply() public onlyOwner {
        maxSupply = totalSupply();
    }

    /// @notice Withdraw all Ether stored in the contract.
    function withdraw() public onlyOwner {
        SafeTransferLib.forceSafeTransferAllETH(contractCreator);
    }
}
