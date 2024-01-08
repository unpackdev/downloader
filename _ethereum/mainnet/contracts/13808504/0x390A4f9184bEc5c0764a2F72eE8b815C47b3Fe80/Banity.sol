//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./ERC721URIStorage.sol";
import "./draft-EIP712.sol";
import "./AccessControl.sol";
import "./ECDSA.sol";
import "./Counters.sol";

contract Banity is ERC721Enumerable, ERC721Burnable, ERC721URIStorage, EIP712, AccessControl {
    using Counters for Counters.Counter;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    uint16 public constant HARDCAP = 1001;
    Counters.Counter public tokensMinted;

    mapping(uint256 => bool) internal tokenIdsMinted;
    mapping(string => bool) internal tokenURIsMinted;

    constructor() ERC721("Banity", "BNFT") EIP712("Banity", "1.0.0") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
    }

    /// @notice Represents an un-minted NFT, which has not yet been recorded into the blockchain. A signed voucher can be redeemed for a real NFT using the redeem function.
    struct NFTVoucher {
        uint256 tokenId;
        string tokenURI;
        bytes signature;
    }

    function redeem(address to, NFTVoucher calldata voucher) external returns (uint256) {
        address signer = _verify(voucher);

        require(hasRole(MINTER_ROLE, signer), "Signature invalid or unauthorized");

        _safeMint(to, voucher.tokenId);
        _setTokenURI(voucher.tokenId, voucher.tokenURI);

        return voucher.tokenId;
    }

    function mint(
        address to,
        uint256 tokenId,
        string memory _tokenURI
    ) public virtual onlyRole(MINTER_ROLE) {
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, _tokenURI);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC721Enumerable, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _baseURI() internal view virtual override(ERC721) returns (string memory) {
        return "ipfs://"; 
    }

    function _mint(address to, uint256 tokenId) internal virtual override(ERC721) {
        require(tokenIdsMinted[tokenId] == false, "TokenId has already been minted once");
        require(tokensMinted.current() < HARDCAP, "Hardcap of tokens is reached");

        super._mint(to, tokenId);
        tokenIdsMinted[tokenId] = true;
        tokensMinted.increment();
    }

    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual override(ERC721URIStorage) {
        require(tokenURIsMinted[_tokenURI] == false, "TokenURI has already been minted once");

        super._setTokenURI(tokenId, _tokenURI);
        tokenURIsMinted[_tokenURI] = true;
    }

    function _verify(NFTVoucher calldata voucher) internal view returns (address) {
        bytes32 digest = _hash(voucher);
        return ECDSA.recover(digest, voucher.signature);
    }

    function _hash(NFTVoucher calldata voucher) internal view returns (bytes32) {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256("NFTVoucher(uint256 tokenId,string tokenURI)"),
                        voucher.tokenId,
                        keccak256(bytes(voucher.tokenURI))
                    )
                )
            );
    }

    function _burn(uint256 tokenId) internal virtual override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable) {
        return super._beforeTokenTransfer(from, to, tokenId);
    }
}
