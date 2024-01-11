// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./draft-EIP712.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./Strings.sol";
import "./ECDSA.sol";
import "./draft-EIP712.sol";

contract FuturingClubMembership is ERC721, ERC721Enumerable, EIP712, Ownable {
    using Counters for Counters.Counter;
    
    string public constant SIGNING_DOMAIN = "FUTURINGCLUB";
    string public constant SIGNATURE_VERSION = "1";
    string internal _baseUri;
    uint256 private _mintPrice;
    bool private _claimEnabled;
    Counters.Counter private _tokenIdCounter;
    
    mapping(address => bool) private _signers;
    mapping(uint256 => bool) private _codes;

    /// @notice The FuturingClubMembershipVoucher struct describes a mintable voucher.
    /// @param code The unique voucher code to be minted.
    /// @param signature This is generated when the signer signs the voucher when it's created.
    struct FuturingClubMembershipVoucher {
        string code;
        bytes signature;
    }
    
    constructor() 
        ERC721("Futuring Club Membership", "FUTURINGCLUB")
        EIP712(SIGNING_DOMAIN, SIGNATURE_VERSION) {
        _baseUri = "https://futuring.club/token/";
        _mintPrice = 0 ether;
        _claimEnabled = true;
        _signers[msg.sender] = true;
    }

    /// @notice This mints a FuturingClubMembership.
    /// @param voucher This is the unique FuturingClubMembershipVoucher that is to be minted.
    function safeMintVoucher(FuturingClubMembershipVoucher calldata voucher) external payable {
        address signer = _verify(voucher);
        uint256 tokenId = _tokenIdCounter.current();
        
        require(_claimEnabled, 'The claiming period is over.');
        require(msg.value == _mintPrice, 'Incorrect amount of ETH sent, please check price.');
        require(_signers[signer] == true, "This voucher is invalid.");
        
        _tokenIdCounter.increment();
        _safeMint(msg.sender, tokenId);
    }

    function setMintPrice(uint256 mintPriceValue) public onlyOwner {
        require(mintPriceValue >= 0, 'Should be a positive integer');
        _mintPrice = mintPriceValue * 1000000000000000000;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseUri = baseURI;
    }

    function setClaimEnabled(bool claimEnabledValue) public onlyOwner {
        _claimEnabled = claimEnabledValue;
    }

    function setSignerEnabled(address signer, bool signerEnabled) public onlyOwner {
        _signers[signer] = signerEnabled;
    }

    /// @notice This will transfer all ETH from the smart contract to the contract owner.
    function withdraw() external onlyOwner { 
        payable(msg.sender).transfer(address(this).balance);
    }

    function mintPrice()
        public
        view
        returns (uint256)
    {
        return _mintPrice;
    }

    function claimEnabled()
        public
        view
        returns (bool)
    {
        return _claimEnabled;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        return string(abi.encodePacked(_baseUri, "metadata?id=", Strings.toString(tokenId)));
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
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

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /// @notice Verifies the signature for a given FuturingClubMembershipVoucher, returning the address of the signer.
    /// @dev Will revert if the signature is invalid. Does not verify that the signer is authorized to mint NFTs.
    /// @param voucher An FuturingClubMembershipVoucher describing an unminted NFT.
    function _verify(FuturingClubMembershipVoucher calldata voucher) private view returns (address) {
        bytes32 digest = _hash(voucher);
        return ECDSA.recover(digest, voucher.signature);
    }

    // The following functions are overrides required by Solidity.
    function _baseURI() internal view override returns (string memory) {
        return _baseUri;
    }

    /// @notice Returns a hash of the given FuturingClubMembershipVoucher, prepared using EIP712 typed data hashing rules.
    /// @param voucher An FuturingClubMembershipVoucher to hash.
    function _hash(FuturingClubMembershipVoucher calldata voucher) private view returns (bytes32) {
        return _hashTypedDataV4(keccak256(abi.encode(
            keccak256("FuturingClubMembershipVoucher(string code)"),
            keccak256(bytes(voucher.code))
        )));
    }
}