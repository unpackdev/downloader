// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./ERC721Holder.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Counters.sol";
import "./Strings.sol";

contract PussyPunksV2 is ERC721, ERC721Enumerable, ERC721URIStorage, ReentrancyGuard, Ownable {
    using Counters for Counters.Counter;

    address public constant BURN_ADDRESS =
        address(0x000000000000000000000000000000000000dEaD);
    Counters.Counter private _tokenIdCounter;

    string private _uri;
    IERC721 public _nftV1; // Address of the v1 NFT contract, for burn and claim

    IERC20 public _paymentToken; // ERC20 token used to pay for NFT
    uint256 public _paymentTokenNFTPrice; // Price per NFT in ERC20 token
    address public _paymentTokenRecipient; // Address that receives the payment

    uint256 public _claimableV2PerV1Burned; // Amount of V2 NFTs claimable per V1 NFT burned
    uint256 public _maxSupply; // Maximum number of NFTs that can be minted
    uint256 public _startTime; // Timestamp when the minting starts

    constructor(
        string memory uri,
        IERC721 nftV1,
        IERC20 paymentToken,
        uint256 paymentTokenNFTPrice,
        address paymentTokenRecipient,
        uint256 claimableV2PerV1Burned,
        uint256 maxSupply,
        uint256 startTime
    ) ERC721("Pussy Financial Punks V2", "PFP-V2") {
        require(bytes(uri).length > 0, "URI must not be empty");
        require(
            address(nftV1) != address(0),
            "v1 NFT address must not be empty"
        );
        require(
            address(paymentToken) != address(0),
            "Payment token address must not be empty"
        );
        require(
            paymentTokenNFTPrice > 0,
            "Payment token NFT price must be greater than zero"
        );
        require(
            address(paymentTokenRecipient) != address(0),
            "Payment token recipient address must not be empty"
        );
        require(claimableV2PerV1Burned > 0, "Claimable V2 per V1 burned must be greater than zero");
        require(maxSupply > 0, "Maximum supply must be greater than zero");
        require(startTime > 0, "Start time must be greater than zero");

        _uri = uri;
        _nftV1 = nftV1;

        _paymentToken = paymentToken;
        _paymentTokenNFTPrice = paymentTokenNFTPrice;
        _paymentTokenRecipient = paymentTokenRecipient;

        _claimableV2PerV1Burned = claimableV2PerV1Burned;
        _maxSupply = maxSupply;
        _startTime = startTime;
    }

    function safeMint(address to) internal {
        _tokenIdCounter.increment(); //start from 1

        uint256 tokenId = _tokenIdCounter.current();
        string memory tokenIdStr = Strings.toString(tokenId);

        _safeMint(to, tokenId);
        _setTokenURI(tokenId, string(abi.encodePacked("/", tokenIdStr, ".json")));
    }

    modifier afterStartTime() {
        require(block.timestamp >= _startTime, "Minting has not started yet");
        _;
    }

    function mint(uint256 amount) external afterStartTime nonReentrant {
        require(amount > 0, "Amount must be greater than zero");
        require(
            getTotalSupply() + amount <= _maxSupply,
            "Exceeds the maximum number of NFTs"
        );
        require(
            _paymentToken.balanceOf(msg.sender) >=
                _paymentTokenNFTPrice * amount,
            "Insufficient ERC20 token balance"
        );
        require(
            _paymentToken.allowance(msg.sender, address(this)) >=
                _paymentTokenNFTPrice * amount,
            "Insufficient ERC20 token allowance"
        );

        uint256 totalPrice = _paymentTokenNFTPrice * amount;
        bool transferSuccess = _paymentToken.transferFrom(
            msg.sender,
            _paymentTokenRecipient,
            totalPrice
        );
        require(transferSuccess, "ERC20 token transfer failed");
        for (uint256 i = 0; i < amount; i++) {
            safeMint(msg.sender);
        }
    }

    function burnV1AndClaimV2(
        uint256[] memory v1TokenIds
    ) external afterStartTime nonReentrant {
        require(
            getTotalSupply() + v1TokenIds.length * _claimableV2PerV1Burned <= _maxSupply,
            "Exceeds the maximum number of NFTs"
        );

        for (uint256 i = 0; i < v1TokenIds.length; i++) {
            uint256 tokenId = v1TokenIds[i];
            address owner = _nftV1.ownerOf(tokenId);
            require(owner == msg.sender, "You do not own this v1 NFT");

            _nftV1.safeTransferFrom(msg.sender, BURN_ADDRESS, tokenId);

            // Mint configured amount of V2 NFTs per V1 NFT burned
            for (uint256 j = 0; j < _claimableV2PerV1Burned; j++) {
                safeMint(msg.sender);
            }
        }
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function _baseURI() internal view override returns (string memory) {
        return _uri;
    }

    function tokenURI(uint256 tokenId)
      public
      view
      override(ERC721, ERC721URIStorage)
      returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function getPaymentTokenNFTPrice() public view returns (uint256) {
        return _paymentTokenNFTPrice;
    }

    function getPaymentTokenRecipient() public view returns (address) {
        return _paymentTokenRecipient;
    }

    function getClaimableV2PerV1Burned() public view returns (uint256) {
        return _claimableV2PerV1Burned;
    }

    function getMaxSupply() public view returns (uint256) {
        return _maxSupply;
    }

    function getTotalSupply() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

    function getStartTime() public view returns (uint256) {
        return _startTime;
    }

    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721, ERC721Enumerable, ERC721URIStorage) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
