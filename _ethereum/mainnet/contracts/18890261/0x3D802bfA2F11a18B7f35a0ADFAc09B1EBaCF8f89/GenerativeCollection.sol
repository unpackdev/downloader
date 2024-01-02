// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "./OwnableUpgradeable.sol";
import "./SafeERC20.sol";
import "./IERC20.sol";
import "./GenerativeCollectionMetadata.sol";
import "./ERC721AUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./MerkleProof.sol";

/// @title Generative Collection Contract
/// @notice This contract handles the creation and management of a generative collection.
contract GenerativeCollection is Initializable, UUPSUpgradeable, OwnableUpgradeable, ERC721AUpgradeable {
    using SafeERC20 for IERC20;

    bytes32 public constant MARKETPLACE_HASH = keccak256(abi.encodePacked("Blockframe"));

    event GenerativeCollectionMint(
        address buyer,
        address seller,
        uint256 amount,
        uint256 totalCost,
        uint256 currentTotalSupply,
        bytes32 indexed marketplaceHash
    );
    event TokenUriSet(address contractAddress, string baseURI);
    event ContractURIUpdated();

    address feeRecipient;
    string internal initialContractUri;

    GenerativeCollectionMetadata metadata;

    bytes32 public merkleRoot;

    string internal baseURI;

    /// @notice Initializes the contract with metadata and sets up the whitelist.
    /// @param _metadata Metadata related to the generative collection.
    function initialize(GenerativeCollectionMetadata memory _metadata, address _feeRecipient) initializerERC721A initializer public {
        __UUPSUpgradeable_init();
        __ERC721A_init(_metadata.name, _metadata.symbol);
        __Ownable_init();
        metadata = _metadata;
        feeRecipient = _feeRecipient;
        merkleRoot = metadata.merkleRoot;
        initialContractUri = metadata.contractURI;
        if (block.timestamp >= metadata.revealDate) {
            setBaseURI(metadata.baseUriHash, metadata.baseURI);
        }
    }

    /// @dev Modifier to ensure the function is called when the contract is in sale mode.
    modifier whenOnSale() {
        _requireSale();
        _;
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    /// @dev Checks if the contract is currently in sale mode.
    function _requireSale() internal view virtual {
        require(_isPresale() || _isPublicSale(), "Not for sale");
    }

    function _isPresale() internal view returns (bool) {
        return block.timestamp >= metadata.presaleStartTime && block.timestamp <= metadata.presaleEndTime;
    }

    function _isPublicSale() internal view returns (bool) {
        return block.timestamp >= metadata.saleStartTime && block.timestamp <= metadata.saleEndTime;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function contractURI() public view returns (string memory) {
        return initialContractUri;
    }

    function setContractURI(string memory _newContractURI) public onlyOwner {
        initialContractUri = _newContractURI;
        emit ContractURIUpdated();
    }

    /// @notice Sets the base URI for the collection.
    /// @param _baseUriHash Expected hash of the base URI.
    /// @param _baseURI The new base URI.
    function setBaseURI(bytes32 _baseUriHash, string memory _baseURI) public {
        require(_baseUriHash == metadata.baseUriHash, "Invalid hash");
        require(keccak256(abi.encode(_baseURI)) == _baseUriHash, "Hash and uri mismatch");
        baseURI = _baseURI;
        emit TokenUriSet(address(this), _baseURI);
    }

    /// @notice Reserves a certain number of NFTs.
    /// @param amount The number of NFTs to reserve.
    function reserve(uint256 amount) public onlyOwner {
        uint256 supply = totalSupply();
        require(supply + amount <= metadata.totalSupply, "Purchase would exceed max supply of NFTs");
        _safeMint(msg.sender, amount);
        address seller = owner();  
        uint256 totalCost = 0;  

        emit GenerativeCollectionMint(msg.sender, seller, amount, totalCost, supply, MARKETPLACE_HASH);
    }

    function _isWhitelisted(address user, bytes32[] memory proof) internal view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(user));
        return MerkleProof.verify(proof, merkleRoot, leaf);
    }

    /// @notice Mints a specific number of NFTs.
    /// @param numberOfTokens The number of NFTs to mint.
    function mint(uint numberOfTokens, bytes32[] calldata merkleProof) public payable whenOnSale {
        uint256 maxMint;
        uint256 pricePerMint;
        address seller = owner();  // Owner is the seller
        uint256 supply = totalSupply();  // Owner is the seller

        if (_isPresale()) {
            maxMint = metadata.presaleMaxMint;
            pricePerMint = metadata.presaleMintPrice;
            require(_isWhitelisted(msg.sender, merkleProof), "Not whitelisted");
        } else {
            maxMint = metadata.maxMint;
            pricePerMint = metadata.mintPrice;
        }

        require(numberOfTokens <= maxMint, "Minting too many.");
        require(supply + numberOfTokens <= metadata.totalSupply, "Purchase would exceed max supply of NFTs");

        uint256 totalCost = pricePerMint * numberOfTokens;
        
        uint256 feeAmount = totalCost / 50;  
        uint256 sendAmount = totalCost - feeAmount;  // 98% goes to the seller

        if (metadata.currency == address(0)) {
            require(totalCost <= msg.value, "Ether value sent is not correct");
            (bool successFee, ) = feeRecipient.call{value: feeAmount}("");
            require(successFee, "Fee transfer failed");

            (bool successSeller, ) = seller.call{value: sendAmount}("");
            require(successSeller, "Seller transfer failed");
        } else {
            IERC20(metadata.currency).safeTransferFrom(msg.sender, address(this), totalCost);
            IERC20(metadata.currency).transfer(feeRecipient, feeAmount);
            IERC20(metadata.currency).transfer(seller, sendAmount);
        }

        _safeMint(msg.sender, numberOfTokens);

        emit GenerativeCollectionMint(msg.sender, seller, numberOfTokens, totalCost, supply, MARKETPLACE_HASH);
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override(ERC721AUpgradeable) {
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }

    /// @notice Checks if the contract supports a given interface.
    /// @param interfaceId The ID of the interface.
    /// @return True if the contract supports the interface, false otherwise.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721AUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}