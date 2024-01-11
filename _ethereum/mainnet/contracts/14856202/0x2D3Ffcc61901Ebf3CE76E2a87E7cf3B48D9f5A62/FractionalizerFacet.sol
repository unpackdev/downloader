// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)
pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./Ownable.sol";
import "./Base64.sol";
import "./LibAppStorage.sol";
import "./ERC721A.sol";
import "./MetadataCreator.sol";
import "./ERC721AAttributes.sol";

import "./Create2.sol";
import "./Initializable.sol";

/// @notice a fractionalized token based on erc721
contract FractionalizedToken is ERC721A, Initializable, Ownable {
    address internal _minter;
    uint256 internal _totalFractions;

    MetadataCreator.Metadata internal metadata_;
    MetadataCreator.Trait[] internal traits_;

    /// @notice initialize the token
    function initialize(
        MetadataCreator.Metadata memory _metadata,
        MetadataCreator.Trait[] memory __traits,
        address __minter,
        uint256 __totalFractions
    ) public initializer {
        metadata_ = _metadata;
        for(uint256 i = 0; i < __traits.length; i++) {
            traits_.push(__traits[i]);
        }
        // initialize the token name and symbol
        _initializeToken(_metadata.name, _metadata.symbol, _metadata.imageUrl);
        // mint the tokens to the minter
        _mint(__minter, __totalFractions, "", true);
        _totalFractions = __totalFractions;
        // transfer ownership to the sender
        transferOwnership(msg.sender);
    }

    /// @notice get the minter of this token
    function minter() public view returns (address) {
        return _minter;
    }

    /// @notice get the minter of this token
    function metadata() public view returns (MetadataCreator.Metadata memory) {
        return metadata_;
    }

    /// @notice get the total number of fractions
    function totalFractions() external view returns (uint256) {
        return _totalFractions;
    }

    function _traits(uint256 tokenID) internal view returns (MetadataCreator.Trait[] memory) {
        MetadataCreator.Trait[] memory trait = new MetadataCreator.Trait[](traits_.length + 1);
        for(uint256 i = 0; i < traits_.length; i++) {
            trait[i] = traits_[i];
        }
        trait[traits_.length].value = Strings.toString(tokenID);
        trait[traits_.length].displayType = "number";
        trait[traits_.length].key = "numbering";
        return trait;
    }

    function traits(uint256 tokenID) external view returns (MetadataCreator.Trait[] memory) {
        return _traits(tokenID);
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        MetadataCreator.Trait[] memory trait = _traits(id);
        string memory _metadata = MetadataCreator.createMetadataJSON(metadata_, trait);
        string memory json = Base64.encode(bytes(_metadata));
        return string(abi.encodePacked("data:application/json;base64,", json));
    }

    function contractURI() public view returns (string memory) {
        MetadataCreator.Trait[] memory trait = new MetadataCreator.Trait[](traits_.length);
        for(uint256 i = 0; i < traits_.length; i++) {
            trait[i] = traits_[i];
        }
        string memory _metadata = MetadataCreator.createMetadataJSON(metadata_, trait);
        string memory json = Base64.encode(bytes(_metadata));
        return string(abi.encodePacked("data:application/json;base64,", json));
    }

    function updateMetadata(MetadataCreator.Metadata memory __metadata) external onlyOwner {
        metadata_ = __metadata;
    }

    function addTrait(MetadataCreator.Trait memory trait) external onlyOwner {
        traits_.push(trait);
    }

    function updateTraits(MetadataCreator.Trait[] memory __traits) external onlyOwner {
        for(uint256 i = 0; i < __traits.length; i++) {
            traits_[i] = __traits[i];
        }
    }

    function destroyContract() external onlyOwner {
        selfdestruct(payable(msg.sender));
    }
}

/**
 * @dev Implements attributes on a token. an attribute is a value that can be modified by permissioned contracts. The attribute is also displayed on the token.
 */
contract FractionalizerFacet is Modifiers {

    event Fractionalized(
        address indexed fractionalizer,
        address indexed tokenAddress,
        uint256 indexed tokenId,
        address fractionalizedToken,
        uint256 fractionalizedQuantity
    );

    /// @notice set an attribute to a tokenid keyed by string
    function fractionalize(
        MetadataCreator.Metadata memory _metadata,
        MetadataCreator.Trait[] memory _traits,
        address tokenAddress,
        uint256 tokenId,
        uint256 fractionalizedQuantity,
        address tokenReceiver
    ) external onlyOwner returns (address _address) {

        // make a keccak256 hash of the token address and token id
        bytes32 _tokenHash = tokenHash(tokenAddress, tokenId);

        // compute the create2 address
        _address = Create2.computeAddress(_tokenHash, keccak256(type(FractionalizedToken).creationCode));

        // require this token is not already fractionalized
        require(
            s.fractionalizerStorage.fractionalizedTokens[_address].tokenAddress == address(0),
            "ERC1155: token already fractionalized"
        );

        // create the fractionalized token using create2
        _address = address(Create2.deploy(0, _tokenHash, type(FractionalizedToken).creationCode));

        // set the fractionalized token data
        s.fractionalizerStorage.fractionalizedTokens[_address] = FractionalizedTokenData(
            _metadata.symbol,
            _metadata.name,
            tokenAddress,
            tokenId,
            _address,
            fractionalizedQuantity
        );
        s.fractionalizerStorage.fractionalizedTokensList.push(_address);

        // initialize the token
        FractionalizedToken(_address).initialize(_metadata, _traits, tokenReceiver, fractionalizedQuantity);

        // transfer ownership of the token to the receiver
        FractionalizedToken(_address).transferOwnership(msg.sender);

        // send a fractionalized event
        emit Fractionalized(msg.sender, tokenAddress, tokenId, _address, fractionalizedQuantity);
    }

    /// @notice get the token hash
    function tokenHash(address tokenAddress, uint256 tokenId) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(tokenAddress, tokenId));
    }

    /// @notice get all fractionalized token addresses
    function fractionalizedTokens() public view returns (address[] memory) {
        return s.fractionalizerStorage.fractionalizedTokensList;
    }

    /// @notice get the fractionalized token data
    function fractionalizedToken(address tokenAddress)
        public
        view
        returns (FractionalizedTokenData memory)
    {
        return s.fractionalizerStorage.fractionalizedTokens[tokenAddress];
    }

    function balanceOf(address tokenAddress, uint256 tokenId) public view returns (uint256) {
        return IERC721(tokenAddress).ownerOf(tokenId) == address(0) ? 0 : 1;
    }


    function getData() external pure returns (string memory) {
        return "2";
    }
}
