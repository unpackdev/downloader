//SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;
pragma abicoder v2; // required to accept structs as function parameters

import "./AccessControl.sol";
import "./Ownable.sol";
import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./ECDSA.sol";
import "./draft-EIP712.sol";
import "./SafeMath.sol";

contract LooxooryNFT is ERC721URIStorage, EIP712, AccessControl, Ownable {
    using SafeMath for uint256;

    struct NFT{
        string uri;
        uint256 price;
        address creatorAddress;
        uint256 numberOfNfts;
        uint256 platformFee;
    }

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    address public marketplaceContract;
    string private constant SIGNING_DOMAIN = "LooxooryNFT-Voucher";
    string private constant SIGNATURE_VERSION = "1";

    address public minterAddress;

    uint256 public currentTokenId;
    mapping(uint256=>NFT) public nftMapping;

    event RedeemEvent(address redeemer,string ipfs,uint256 tokenId,address signer);

    constructor(address minter,address _marketplaceContract)
        ERC721("LooxooryNFT", "LAZ")
        EIP712(SIGNING_DOMAIN, SIGNATURE_VERSION)
    {
        minterAddress = minter;
        _setupRole(MINTER_ROLE, minter);

        marketplaceContract = _marketplaceContract;
    }



    struct NFTVoucher {
        string uri;
        uint256 price;
        address creatorAddress;
        uint256 numberOfNfts;
        uint256 platformFee;
        bytes signature;
    }

    function setMinterAddress(address minter) external onlyOwner {
        minterAddress = minter;
        _setupRole(MINTER_ROLE, minter);
    }

    function setMarketplaceAddress(address _marketplaceAddress) external onlyOwner {
        marketplaceContract = _marketplaceAddress;
    }

    modifier onlyMarketplace{
        require(msg.sender==marketplaceContract || msg.sender==owner(),"Unauthorized");
        _;
    }

    function redeem(address redeemer, NFTVoucher calldata voucher)
        public
        onlyMarketplace
        returns (uint256)
    {
        currentTokenId = currentTokenId.add(1);
        // make sure signature is valid and get the address of the signer
        address signer = _verify(voucher);
        
        emit RedeemEvent(redeemer,voucher.uri,currentTokenId,signer);
        // make sure that the signer is authorized to mint NFTs
        require(
            hasRole(MINTER_ROLE, signer),
            "Signature invalid or unauthorized"
        );

        // first assign the token to the signer, to establish provenance on-chain
        
        _mint(voucher.creatorAddress, currentTokenId);
        _setTokenURI(currentTokenId, voucher.uri);

        nftMapping[currentTokenId] = NFT({
            uri:voucher.uri,
            price:voucher.price,
            creatorAddress:voucher.creatorAddress,
            numberOfNfts:voucher.numberOfNfts,
            platformFee:voucher.platformFee
        });

        // transfer the token to the redeemer
        _transfer(voucher.creatorAddress, redeemer, currentTokenId);

        return currentTokenId;
    }

    function getNFT(uint256 _tokenId) public view returns(
        string memory uri,
        uint256 price,
        address creatorAddress,
        uint256 numberOfNfts,
        uint256 platformFee){
        uri = nftMapping[_tokenId].uri;
        price = nftMapping[_tokenId].price;
        creatorAddress = nftMapping[_tokenId].creatorAddress;
        numberOfNfts = nftMapping[_tokenId].numberOfNfts;
        platformFee = nftMapping[_tokenId].platformFee;
    }

    /// @notice Returns a hash of the given NFTVoucher, prepared using EIP712 typed data hashing rules.
    /// @param voucher An NFTVoucher to hash.
    function _hash(NFTVoucher calldata voucher)
        internal
        view
        returns (bytes32)
    {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "NFTVoucher(string uri,uint256 price,address creatorAddress,uint256 numberOfNfts,uint256 platformFee)"
                        ),
                        keccak256(bytes(voucher.uri)),
                        voucher.price,
                        voucher.creatorAddress,
                        voucher.numberOfNfts,
                        voucher.platformFee
                    )
                )
            );
    }

    /// @notice Returns the chain id of the current blockchain.
    /// @dev This is used to workaround an issue with ganache returning different values from the on-chain chainid() function and
    ///  the eth_chainId RPC method. See https://github.com/protocol/nft-website/issues/121 for context.
    function getChainID() external view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    /// @notice Verifies the signature for a given NFTVoucher, returning the address of the signer.
    /// @dev Will revert if the signature is invalid. Does not verify that the signer is authorized to mint NFTs.
    /// @param voucher An NFTVoucher describing an unminted NFT.
    function _verify(NFTVoucher calldata voucher)
        internal
        view
        returns (address)
    {
        bytes32 digest = _hash(voucher);
        return ECDSA.recover(digest, voucher.signature);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControl, ERC721)
        returns (bool)
    {
        return
            ERC721.supportsInterface(interfaceId) ||
            AccessControl.supportsInterface(interfaceId);
    }
}