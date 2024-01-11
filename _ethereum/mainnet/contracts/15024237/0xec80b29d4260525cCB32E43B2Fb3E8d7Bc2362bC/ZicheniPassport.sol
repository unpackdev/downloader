// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./IERC20.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./ERC721Burnable.sol";
import "./AccessControlEnumerable.sol";
import "./Counters.sol";
import "./Multicall.sol";
import "./ReentrancyGuard.sol";

import "./SignatureMint.sol";

contract ZicheniPassport is
    ERC721,
    ERC721Enumerable,
    ERC721URIStorage,
    ERC721Burnable,
    SignatureMint,
    ReentrancyGuard,
    AccessControlEnumerable,
    Multicall
{
    using Counters for Counters.Counter;

    bytes32 private constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 private constant TRANSFER_ROLE = keccak256("TRANSFER_ROLE");

    Counters.Counter private _tokenIdCounter;

    address private constant NATIVE_TOKEN = 0x0000000000000000000000000000000000000000;
    event MintedUsingSignature(uint256 tokenId);

    constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
        _setupRole(TRANSFER_ROLE, msg.sender);
        _setupRole(TRANSFER_ROLE, address(0));
    }

    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://";
    }

    function safeMint(address to, string memory uri) public onlyRole(MINTER_ROLE) {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        _mint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    /// @dev Signature minting for NFTs.
    function signatureMint(MintVoucher calldata voucher, bytes calldata signature) external payable nonReentrant {
        uint256 tokenId = _tokenIdCounter.current();
        _processVoucher(voucher, signature);
        address to = voucher.to == address(0) ? msg.sender : voucher.to;
        _processPayment(voucher);
        _mint(to, tokenId);
        _setTokenURI(tokenId, voucher.uri);
        _tokenIdCounter.increment();
        emit MintedUsingSignature(tokenId);
    }

    /// @dev Function to process payment for the signature minting.
    function _processPayment(MintVoucher calldata voucher) internal {
        uint256 price = voucher.price;
        address currency = voucher.currency;
        address paymentReceiver = voucher.paymentReceiver;

        if (price == 0) {
            return;
        }

        if (currency == NATIVE_TOKEN) {
            require(msg.value == price, "correct price not sent");

            (bool success, ) = voucher.paymentReceiver.call{ value: price }("");

            require(success, "payment receiver failed");
        } else {
            if (msg.sender == paymentReceiver) {
                return;
            }

            IERC20(voucher.currency).transferFrom(msg.sender, paymentReceiver, price);
        }
    }

    function _isValidSigner(address signer) internal view virtual override returns (bool) {
        return hasRole(MINTER_ROLE, signer);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
        if (from != address(0) && to != address(0) && !hasRole(TRANSFER_ROLE, address(0))) {
            require(hasRole(TRANSFER_ROLE, from) || hasRole(TRANSFER_ROLE, to), "only transfer role holders");
        }
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, AccessControlEnumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
