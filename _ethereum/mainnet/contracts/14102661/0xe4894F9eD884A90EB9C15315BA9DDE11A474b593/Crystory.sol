//Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721](https://docs.openzeppelin.com/contracts/3.x/erc721)
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import "./Ownable.sol";
//import "./ERC721PresetMinterPauserAutoId.sol";
import "./ERC721CustomPreset.sol";
import "./ECDSA.sol";
import "./draft-EIP712.sol";

contract Crystory is ERC721CustomPreset, Ownable, EIP712 {

    string private constant SIGNING_DOMAIN = "Crystory";
    string private constant SIGNATURE_VERSION = "1";

    mapping (address => uint256) pendingWithdrawals;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    event Mint(address indexed redeemer, uint256 indexed tokenId, string name, string century, string category, string birthdate, uint256 rare, string uri);

    struct CrystoryNFT {
        uint256 tokenId;
        string name; // name of figure
        string century; // century
        string category; // category
        string birthdate; // birthdate
        uint256 rare;
        uint256 minPrice;
        string uri;
        bytes signature;
    }

    constructor() 
        ERC721CustomPreset("Crystory", "CRY", "ipfs://")
        EIP712(SIGNING_DOMAIN, SIGNATURE_VERSION) {
    }

    /// @notice Redeems an crystoryNFT for an actual NFT, creating it in the process.
    /// @param redeemer The address of the account which will receive the NFT upon success.
    /// @param crystoryNFT A signed crystoryNFT that describes the NFT to be redeemed.
    function redeem(address redeemer, CrystoryNFT calldata crystoryNFT) public payable returns (uint256) {
        // make sure signature is valid and get the address of the signer
        address signer = _verify(crystoryNFT);

        // make sure that the signer is authorized to mint NFTs
        require(hasRole(MINTER_ROLE, signer), "Signature invalid");

        // make sure that the redeemer is paying enough to cover the buyer's cost
        require(msg.value >= crystoryNFT.minPrice, "Insufficient funds");

        // first assign the token to the signer, to establish provenance on-chain
        _mint(signer, crystoryNFT.tokenId);
        _setTokenURI(crystoryNFT.tokenId, crystoryNFT.uri);

        // transfer the token to the redeemer
        _transfer(signer, redeemer, crystoryNFT.tokenId);

        emit Mint(redeemer, crystoryNFT.tokenId, crystoryNFT.name, crystoryNFT.century, crystoryNFT.category, crystoryNFT.birthdate, crystoryNFT.rare, crystoryNFT.uri);

        // record payment to signer's withdrawal balance
        pendingWithdrawals[signer] += msg.value;

        return crystoryNFT.tokenId;
    }

    /// @notice Transfers all pending withdrawal balance to the caller. Reverts if the caller is not an authorized minter.
    function withdraw() public {
        require(hasRole(MINTER_ROLE, msg.sender), "Not allowed");
        
        // IMPORTANT: casting msg.sender to a payable address is only safe if ALL members of the minter role are payable addresses.
        address payable receiver = payable(msg.sender);

        uint amount = pendingWithdrawals[receiver];
        // zero account before transfer to prevent re-entrancy attack
        pendingWithdrawals[receiver] = 0;
        receiver.transfer(amount);
    }

    /// @notice Retuns the amount of Ether available to the caller to withdraw.
    function availableToWithdraw() public view returns (uint256) {
        return pendingWithdrawals[msg.sender];
    }

    /// @notice Returns a hash of the given crystoryNFT, prepared using EIP712 typed data hashing rules.
    /// @param crystoryNFT An NFTVoucher to hash.
    function _hash(CrystoryNFT calldata crystoryNFT) internal view returns (bytes32) {
        return _hashTypedDataV4(keccak256(abi.encode(
        keccak256("CrystoryNFT(uint256 tokenId,string name,string century,string category,string birthdate,uint256 rare,uint256 minPrice,string uri)"),
        crystoryNFT.tokenId,
        keccak256(bytes(crystoryNFT.name)),
        keccak256(bytes(crystoryNFT.century)),
        keccak256(bytes(crystoryNFT.category)),
        keccak256(bytes(crystoryNFT.birthdate)),
        crystoryNFT.rare,
        crystoryNFT.minPrice,
        keccak256(bytes(crystoryNFT.uri))
        )));
    }

    /// @notice Returns the chain id of the current blockchain.
    /// @dev This is used to workaround an issue with ganache returning different values from the on-chain chainid() function and
    ///  the eth_chainId RPC method. See https://github.com/protocol/nft-website/issues/121 for context.
    function getChainID() external view returns (uint256) {
        return block.chainid;
    }

    /// @notice Verifies the signature for a given NFTVoucher, returning the address of the signer.
    /// @dev Will revert if the signature is invalid. Does not verify that the signer is authorized to mint NFTs.
    /// @param crystoryNFT An NFTVoucher describing an unminted NFT.
    function _verify(CrystoryNFT calldata crystoryNFT) internal view returns (address) {
        bytes32 digest = _hash(crystoryNFT);
        return ECDSA.recover(digest, crystoryNFT.signature);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override (ERC721CustomPreset) returns (bool) {
        return ERC721CustomPreset.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

}
