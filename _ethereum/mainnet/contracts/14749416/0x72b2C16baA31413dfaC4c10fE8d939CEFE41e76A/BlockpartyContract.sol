//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./AccessControl.sol";

import "./Ownable.sol";

import "./ERC721.sol";
import "./ECDSA.sol";
import "./ERC165.sol";
import "./draft-EIP712.sol";
import "./ERC721URIStorage.sol";
import "./SignatureChecker.sol";

import "./Counters.sol";

import "./console.sol";

contract BlockpartyContract is ERC165, ERC721URIStorage, EIP712, AccessControl, Ownable {
    bytes4 private constant INTERFACE_ID_ERC2981 = 0x2a55205a;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    string private constant SIGNING_DOMAIN = "BP-Voucher";
    string private constant SIGNATURE_VERSION = "1";
    
    using ECDSA for bytes32;
    using Counters for Counters.Counter;

    mapping (address => uint8) creatorFee;
    mapping (uint256 => address) tokenCreators;
    mapping (string => uint256) soldAssets;

    Counters.Counter private tokenIdentityGenerator;

    constructor()
        ERC721("Blockparty Platform", "BPPL") 
        EIP712(SIGNING_DOMAIN, SIGNATURE_VERSION) {
    }

    /// @notice Represents an un-minted NFT, 
    ///  which has not yet been recorded into 
    ///  the blockchain. A signed voucher can 
    ///  be redeemed for a real NFT using the 
    ///  redeem function.
    struct Voucher {
        /// @notice The asset identification GUID generated
        /// by the backend system managing the collection assets.
        string assetId;

        /// @notice The minimum price (in wei) that the 
        /// NFT creator is willing to accept for the 
        /// initial sale of this NFT.
        uint256 price;

        /// @notice The address of the NFT creator
        /// selling the NFT.
        address from;

        /// @notice The address of the NFT buyer
        /// acquiring the NFT.
        address to;

        /// @notice The metadata URI to associate with 
        /// this token.
        string uri;

        /// @notice the EIP-712 signature of all other 
        /// fields in the Voucher struct. For a 
        /// voucher to be valid, it must be signed 
        /// by an account with the MINTER_ROLE.
        bytes signature;
    }

    /// @notice Called with the sale price to determine how much royalty is owed and to whom.
    /// @param tokenId - the NFT asset queried for royalty information
    /// @param salePrice - the sale price of the NFT asset specified by tokenId
    /// @return receiver - address of who should be sent the royalty payment
    /// @return royaltyAmount - the royalty payment amount for salePrice
    function royaltyInfo(
        uint256 tokenId,
        uint256 salePrice) 
        external view returns (
            address receiver, 
            uint256 royaltyAmount) {
        address creator = tokenCreators[tokenId];
        require(creator != address(0), "No creator found for this token ID");
        return (creator, (salePrice * 5) / 100);
    }

    event itemSold(
        uint256 tokenId, 
        string assetId,
        address from, 
        address to, 
        uint256 soldPrice,
        string tokenUri);

    /// @notice Redeems an Voucher for an actual NFT, creating it in the process.
    function redeem(
        uint8 platformFee, 
        Voucher calldata voucher) public payable returns (uint256) {
        // make sure signature is valid and get the address of the creator
        uint256 tokenId = tokenIdentityGenerator.current();

        // make sure the fees aren't lower than 5 percent
        require(platformFee >= 5, "Platform fee can't be lower than 5 percent");

        // verifies the voucher signature        
        require(_verify(voucher), "Signature is invalid");

        // preventing transactions that attempt to mint for free
        require(msg.value >= 0.011 ether, "Insufficient funds: minimum is 0.011");
        
        // make sure that the buyer is paying enough to cover the buyer's cost
        require(msg.value >= voucher.price, "Insufficient funds to redeem");

        // make sure an asset can't be sold twice
        require(soldAssets[voucher.assetId] == 0, "Item is sold");

        // first assign the token to the creator, to establish provenance on-chain
        _safeMint(voucher.from, tokenId);
        _setTokenURI(tokenId, voucher.uri);

        // transfer the token to the buyer
        _transfer(voucher.from, voucher.to, tokenId);
        tokenIdentityGenerator.increment();

        uint256 cut = (msg.value * platformFee) / 100;

        payable(owner()).transfer(cut);
        payable(voucher.from).transfer(msg.value - cut);

        // includes the creator on the royalties creator catalog
        tokenCreators[tokenId] = voucher.from;

        // Adds the asset information to the 'sold assets' catalog
        soldAssets[voucher.assetId] = tokenId;

        emit itemSold(
            tokenId, 
            voucher.assetId,
            voucher.from, 
            voucher.to, 
            voucher.price,
            voucher.uri);

        // the ID of the newly delivered token
        return tokenId;
    }
    
    /// @notice Checks if it implements the interface defined by `interfaceId`.
    /// @param interfaceId The interface identification that will be verified.
    function supportsInterface(bytes4 interfaceId) 
        public view virtual override (AccessControl, ERC165, ERC721) 
        returns (bool) {
        return ERC721.supportsInterface(interfaceId) 
            || ERC165.supportsInterface(interfaceId)
            || AccessControl.supportsInterface(interfaceId);
    }

    /// @notice Verifies the signature for a given Voucher, returning the verification result (bool).
    /// @dev Will revert if the signature is invalid. Does not verify that the creator is authorized to mint NFTs.
    /// @param voucher An Voucher describing an unminted NFT.
    function _verify(Voucher calldata voucher) internal view returns (bool) {
        bytes32 digest = _hash(voucher);
        console.log("FROM: ", voucher.from);
        console.log("TO: ", voucher.to);
        console.log("OWNER: ", owner());
        return SignatureChecker.isValidSignatureNow(owner(), digest, voucher.signature);
    }

    /// @notice Returns a hash of the given Voucher, prepared using EIP712 typed data hashing rules.
    /// @param voucher An Voucher to hash.
    function _hash(Voucher calldata voucher) internal view returns (bytes32) {
        return _hashTypedDataV4(keccak256(abi.encode(
            keccak256("Voucher(string assetId,uint256 price,address from,address to,string uri)"),
            keccak256(bytes(voucher.assetId)),
            voucher.price,
            voucher.from,
            voucher.to,
            keccak256(bytes(voucher.uri))
        )));
    }
}