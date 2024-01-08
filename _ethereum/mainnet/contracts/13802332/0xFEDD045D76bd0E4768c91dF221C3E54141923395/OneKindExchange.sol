// SPDX-License-Identifier: MIT

/* 1kind.com - Exclusive NFTs
 *       .:c:.       .,::;.         .;c;.          .;cc:'           '::.           ,cc::c:c::;'.
 *     .oXWMNc      'xNWO:          ,KMX;          ;KMMWXo.        .kWWo          .OMWNXXXXXNNNKkl'
 *   .oKNXNMNc    .oXWKl.           ,KMX;          ;KMMMMWk,       .kMWo          'OMNd'....';cxXWXx'
 *  ,0N0c:OMNc  .:0WXd'             ,KMX;          ;KMMN0XWKc.     .kMWo          'OMNc         'xNW0;
 *  .::. .OMNc.,kNNk,               ,KMX;          ;KMMK:;OWNx'    .kMWo          'OMNc          .dWMO.
 *       .OMNxdXMXl.                ,KMX;          ;KMMK, .oXW0:   .kMWo          'OMNc           ,KMX:
 *       .OMMWNNWNd.                ,KMX;          ;KMMK,   ;0WNd. .kMWo          'OMNc           ,0MNc
 *       .OMWKl,oXWKc.              ,KMX;          ;KMMK;    .dNW0;'kMWo          'OMNc           cNMK,
 *       .OXd.   ,kNWk,             ,KMX;          ;KMMK;     .cKWXkKMWo          'OMNc         .cKMNl
 *       .:,      .c0WXd.           ,KMX;          ;KMMK,       'kNMMMWo          'OMNl      .':kNWKc.
 *                  .dXWKc.         ,KMX;          ;KMMK,        .lXMMWo          'OMWKkkkkkO0XWNOl.
 *                   ;dkx:.        .okd'          .dkkd.          ,dkk:          .lkkkkkkkkxdl:'.
 */

pragma solidity ^0.8.10;

import "./BidValidator.sol";
import "./LibBid.sol";
import "./SafeERC20.sol";
import "./IOneKindERC721.sol";
import "./Ownable.sol";
import "./IERC721Receiver.sol";

// @title The 1Kind Exchange contract

// @notice Holds the NFT tokens and delivers to winning bid owners
contract OneKindExchange is Ownable, BidValidator, IERC721Receiver {
    using SafeERC20 for IERC20;

    mapping(bytes32 => bool) public auctionBidLedger;

    // mapping of allowed addresses
    mapping(address => bool) private _admins;

    // wethAddress should be fixed
    address public wethAddress;

    // receives wETH from transactions
    address public exchangeWallet;

    //events
    event AuctionDelivered(
        bytes32 bidHash,
        address userWallet,
        address approverWallet,
        uint256 amount,
        uint256 tokenId,
        address assetContract
    );
    event ExchangeWalletSet(address walletAddress);
    event AdminAccessSet(address _admin, bool _enabled);
    event ERC721Withdrawal(
        address _contract,
        uint256 _tokenId,
        address _caller
    );

    constructor(address _wethContract, address _initialExchangeWallet) {
        wethAddress = _wethContract;
        exchangeWallet = _initialExchangeWallet;
    }

    /**
     * An Admin can accept a User Bid by calling this Function.
     * It validates if the User Bid was signed by the user and initializes
     * the exchange of assets.
     *
     * @param userBid - Struct of a 1Kind User Bid
     * @param userBidSignature - EIP712 Hash of the userBid params
     */
    function acceptBid(
        LibBid.Bid memory userBid, // 1 Kind User Order Values (amount, nft, ...)
        bytes memory userBidSignature // 1 Kind User Order Values (amount, nft, ...) SIGNED
    ) external onlyAdmin {
        validateBid(userBid, userBidSignature);
        exchangeAssets(userBid);
    }

    // @notice Mints an NFT on the ERC721 to this contract
    // @dev This contract is the owner of the minted NFTs until they get sent to bidders
    // @param tokenContractAddress Address of the NFT contract to mint
    function mintOnContract(
        address tokenContractAddress
    ) external onlyAdmin {
        IOneKindERC721(tokenContractAddress).mint(address(this));
    }

    // @notice Sets base URI on the passed NFT contract address
    // @param tokenContractAddress Address of the NFT contract
    // @param permanentBaseURI New base URI
    function setBaseURIOnContract(
        address tokenContractAddress,
        string memory permanentBaseURI
    ) external onlyAdmin {
        IOneKindERC721(tokenContractAddress).setBaseURI(permanentBaseURI);
    }

    // @notice Sets base URI on the passed NFT contract address
    // @param tokenContractAddress Address of the NFT contract
    // @param tokenId The id of the token
    // @param permanentTokenURI New base URI
    function setTokenURIOnContract(
        address tokenContractAddress,
        uint256 tokenId,
        string memory permanentTokenURI
    ) external onlyAdmin {
        IOneKindERC721(tokenContractAddress).setTokenURI(tokenId, permanentTokenURI);
    }

    /**
     * Function to actually exchange the assets.
     * Validates and checks if exchange was successul and adds
     * confirmation to out auctionBidLedger
     *
     * @param userBid - Struct of a 1Kind User Bid
     * @dev The 3 requires are added to get more readable errors in case any of them fails.
     **/
    function exchangeAssets(LibBid.Bid memory userBid) internal {
        bytes32 bidHash = LibBid.bidHash(userBid);

        require(
            !auctionBidLedger[bidHash],
            "OneKindExchange: Bid was already processed"
        );

        // Validate Balances
        require(
            IERC20(wethAddress).allowance(userBid.userWallet, address(this)) >=
                userBid.amount,
            "OneKindExchange: User has not approved enough balance on wETH Contract"
        );
        require(
            IERC20(wethAddress).balanceOf(userBid.userWallet) >= userBid.amount,
            "OneKindExchange: Insufficient Funds to fulfill Bid"
        );
        require(
            IOneKindERC721(userBid.assetContract).ownerOf(userBid.tokenId) ==
                address(this),
            "OneKindExchange: NFT is not owned by Exchange"
        );

        // First transfer wETH to Exchange Wallet
        IERC20(wethAddress).safeTransferFrom(
            userBid.userWallet,
            exchangeWallet,
            userBid.amount
        );
        // Later: Transfer Fees to different wallet

        // Then transfer NFT to User Wallet
        IOneKindERC721(userBid.assetContract).safeTransferFrom(
            address(this),
            userBid.userWallet,
            userBid.tokenId
        );

        // // If Bid was processed status is 1.
        auctionBidLedger[bidHash] = true;

        emit AuctionDelivered(
            bidHash,
            userBid.userWallet,
            msg.sender,
            userBid.amount,
            userBid.tokenId,
            userBid.assetContract
        );
    }

    // Exchange Wallet
    /**
     * Set the Exchange Wallet Address. This Address receives all wETH
     * Payments but must also be the owner of the NFTs on Sale
     *
     * @param wallet - Address of Exchange Wallet
     */
    function setExchangeWallet(address wallet) external onlyOwner {
        exchangeWallet = wallet;
        emit ExchangeWalletSet(wallet);
    }

    // ERC721 Handling
    /**
     * @param _contract - The ERC721 contract
     *  @param _tokenId The id of the token
     * @notice sends an NFT out of this contract to the exchangeWallet
     */
    function withdrawalERC721Token(address _contract, uint256 _tokenId)
        external
        onlyOwner
    {
        // Then transfer NFT to User Wallet
        IOneKindERC721(_contract).safeTransferFrom(
            address(this),
            exchangeWallet,
            _tokenId
        );

        emit ERC721Withdrawal(_contract, _tokenId, msg.sender);
    }

    // ERC721 Handling
    /**
     * Checks that ERC721 sender is allowed to send
     * @param operator - The user sending ERC721
     */
    function onERC721Received(
        address operator,
        address,
        uint256,
        bytes calldata
    ) public view returns (bytes4) {
        require(
            _admins[operator] || operator == owner() || operator == address(this),
            "OneKindExchange: Rejected ERC721 Acceptance because not sent by admin"
        );

        return this.onERC721Received.selector;
    }

    // Admin Functions
    /**
     * Set Admin Access for a Wallet Address
     * Admins are capable of accepting bids and minting tokens on 1Kind NFT Contracts
     *
     * @param admin - Address of Admin
     * @param enabled - Enable/Disable Admin Access
     */
    function setAdmin(address admin, bool enabled) external onlyOwner {
        _admins[admin] = enabled;
        emit AdminAccessSet(admin, enabled);
    }

    /**
     * Check if a Wallet is Admin Access
     *
     * @param admin - Address of Admin
     * @return If Address has Admin Access
     */
    function isAdmin(address admin) public view returns (bool) {
        return _admins[admin];
    }

    /**
     * Throws if called by any account other than the Admin.
     */
    modifier onlyAdmin() {
        require(
            _admins[msg.sender] || msg.sender == owner(),
            "OneKindExchange: Sender does not have Admin Access"
        );
        _;
    }
}
