//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.11;

import "./ERC721Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./StringsUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./SignatureCheckerUpgradeable.sol";

contract ClubHouseV1 is
    ERC721Upgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    using StringsUpgradeable for uint256;

    // type 1 counter
    uint256 public tokenCounter;

    address payable merchantWalletAddress;

    // margin value
    uint256 private margin;

    // base uri for token
    string private baseUri;

    // token uri extension
    string private baseExtension;

    // struct for minting
    struct Order {
        uint256 id;
        uint256 price;
        string dollarPrice;
        bytes32 message;
    }

    struct MintOrder {
        uint256 id;
        uint256 price;
        string dollarPrice;
        uint256 size_id;
        bytes32 message;
    }

    /**
     * @dev Emitted when new token is minted by owner.
     */
    event createdNft(
        address user,
        uint256 referenceId,
        uint256 tokenId,
        uint256 price,
        string dollar,
        uint256 sizeId
    );

    /**
     * @dev Emitted when token is purchased by user.
     */
    event purchaseNft(
        address previousOwner,
        address newOwner,
        uint256 tokenId,
        uint256 price,
        string dollar
    );

    // initialisation section

    function initialize() public initializer {
        __ERC721_init("Clubhouse Archives", "CA");
        __Ownable_init();

        baseUri = "https://s3.amazonaws.com/assets.thearchivesmint.xyz/nft-uri/";
        baseExtension = "/token-uri.json";

        margin = 10;
        merchantWalletAddress = payable(owner());

        tokenCounter = 0;
    }

    /**
     * @dev calculates the margin fee for merchant wallet
     *
     * @param _totalPrice total amount
     *
     * Requirements:
     * - only owner can update value.
     */

    function feeCalulation(uint256 _totalPrice) private view returns (uint256) {
        uint256 fee = margin * _totalPrice;
        uint256 fees = fee / 100;
        return fees;
    }

    /**
     * @dev updates the margin percentage
     *
     * @param _margin magin percentage
     *
     * Requirements:
     * - only owner can update value.
     */

    function updateMargin(uint256 _margin) external virtual onlyOwner {
        margin = _margin;
    }

    /**
     * @dev updates merchant wallet address
     *
     * @param _address magin percentage
     *
     * Requirements:
     * - only owner can update value.
     */

    function updateMerchantWallet(address _address) external virtual onlyOwner {
        merchantWalletAddress = payable(_address);
    }

    /**
     * @dev updates the token base uri and extension
     *
     * @param _baseuri base uri. (Ex. "https://abc.com/")
     * @param _extension extension uri. (Ex. ".json", "-token-uri.json", etc)
     *
     * Requirements:
     * - only owner can update value.
     */

    function upadateDefaultUri(string memory _baseuri, string memory _extension)
        external
        virtual
        onlyOwner
    {
        baseUri = _baseuri;
        baseExtension = _extension;
    }

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     *
     * @param _tokenId tokenid.
     */

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ClubHouseV1: URI query for nonexistent token"
        );
        return
            string(
                abi.encodePacked(
                    baseUri,
                    StringsUpgradeable.toString(_tokenId),
                    baseExtension
                )
            );
    }

    /**
     * @dev user can pay for cloth nft in ETH and mint new nft.
     *
     * @param _order the order details for miniting nft.
     * @param _signature the signature for verification.
     *
     * Returns
     * - boolean.
     *
     * Emits a {createdNft} event.
     */

    function mint(MintOrder calldata _order, bytes memory _signature)
        external
        payable
        virtual
        nonReentrant
    {
        require(
            SignatureCheckerUpgradeable.isValidSignatureNow(
                owner(),
                _order.message,
                _signature
            ),
            "ClubHouseV1: Not allowed to mint"
        ); // for verification
        require(_order.price == msg.value, "ClubHouseV1: Price is incorrect"); // checks the price

        tokenCounter += 1;

        _safeMint(msg.sender, tokenCounter); // minting nft
        merchantWalletAddress.transfer(msg.value); // transfering ETH to merachant wallet

        emit createdNft(
            msg.sender,
            _order.id,
            tokenCounter,
            msg.value,
            _order.dollarPrice,
            _order.size_id
        );
    }

    /**
     * @dev user can purchase the cloth nft in ETH from another user
     * who has listed on market place.
     *
     * @param _order the order details for purchasing nft.
     * @param _signature the signature for verification.
     *
     * Returns
     * - boolean.
     *
     * Emits a {purchaseNft} event.
     */

    function purchase(Order calldata _order, bytes memory _signature)
        external
        payable
        virtual
        nonReentrant
    {
        address _previousOwner = ownerOf(_order.id);

        require(
            SignatureCheckerUpgradeable.isValidSignatureNow(
                _previousOwner,
                _order.message,
                _signature
            ),
            "ClubHouseV1: Not allowed to purchase"
        ); // for verification
        require(_order.price == msg.value, "ClubHouseV1: Price is incorrect"); // checks the price

        ERC721Upgradeable(address(this)).transferFrom(
            ownerOf(_order.id),
            address(this),
            _order.id
        );
        ERC721Upgradeable(address(this)).approve(msg.sender, _order.id);
        ERC721Upgradeable(address(this)).transferFrom(
            address(this),
            msg.sender,
            _order.id
        );

        uint256 _fee = feeCalulation(msg.value);
        merchantWalletAddress.transfer(_fee);
        payable(_previousOwner).transfer(msg.value - _fee);

        emit purchaseNft(
            _previousOwner,
            msg.sender,
            _order.id,
            msg.value,
            _order.dollarPrice
        );
    }
}
