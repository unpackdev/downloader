//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.14;

import "IERC721.sol";
import "Ownable.sol";
import "IWithBalance.sol";

/// @title A Seller Contract for selling single NFTs (modified contract of Avo Labs GmbH)
/// @notice This contract can be used for selling any NFTs
contract NFTSeller is Ownable {
    address[] public whitelistedPassCollections; //Only owners of tokens from any of these collections can buy if is onlyWhitelisted
    mapping(address => mapping(uint256 => Sale)) public nftContractAuctions; // variable name is the same as in NFTAuction
    mapping(address => uint256) failedTransferCredits;
    //Each Sale is unique to each NFT (contract + id pairing).
    struct Sale {
        //map token ID to
        uint64 auctionStart; // name is the same as in NFTAuction
        uint64 auctionEnd; // name is the same as in NFTAuction
        uint128 buyNowPrice;
        address feeRecipient;
        bool onlyWhitelisted; // if true, than only owners of whitelistedPassCollections can make bids
    }

    /*╔═════════════════════════════╗
      ║           EVENTS            ║
      ╚═════════════════════════════╝*/

    event NftAuctionCreated(
        address indexed nftContractAddress,
        uint256 indexed tokenId,
        uint128 buyNowPrice,
        uint64 auctionStart,
        uint64 auctionEnd,
        address feeRecipient,
        bool onlyWhitelisted
    );

    event NFTTransferredAndSellerPaid(
        address indexed nftContractAddress,
        uint256 indexed tokenId,
        uint128 nftHighestBid,
        address nftHighestBidder
    );

    event AuctionWithdrawn(
        address indexed nftContractAddress,
        uint256 indexed tokenId
    );
    /**********************************/
    /*╔═════════════════════════════╗
      ║             END             ║
      ║            EVENTS           ║
      ╚═════════════════════════════╝*/
    /**********************************/
    /*╔═════════════════════════════╗
      ║          MODIFIERS          ║
      ╚═════════════════════════════╝*/

    modifier needWhitelistedToken(address _nftContractAddress, uint256 _tokenId) {
        if (nftContractAuctions[_nftContractAddress][_tokenId].onlyWhitelisted) {
            bool isWhitelisted;
            for (uint256 i = 0; i < whitelistedPassCollections.length; i++) {
                if(IWithBalance(whitelistedPassCollections[i]).balanceOf(msg.sender) > 0) {
                    isWhitelisted = true;
                    break;
                }
            }
            require(isWhitelisted, "Sender has no whitelisted NFTs");
        }
        _;
    }

    modifier saleOngoing(address _nftContractAddress, uint256 _tokenId) {
        require(
            _isSaleStarted(_nftContractAddress, _tokenId),
            "Sale has not started"
        );
        require(
            _isSaleOngoing(_nftContractAddress, _tokenId),
            "Sale has ended"
        );
        _;
    }

    modifier ethAmountMeetsBuyRequirements(
        address _nftContractAddress,
        uint256 _tokenId
    ) {
        require(
            msg.value >= nftContractAuctions[_nftContractAddress][_tokenId].buyNowPrice,
            "Not enough funds to buy NFT"
        );
        _;
    }

    modifier notZeroAddress(address _address) {
        require(_address != address(0), "Cannot specify 0 address");
        _;
    }

    /**********************************/
    /*╔═════════════════════════════╗
      ║             END             ║
      ║          MODIFIERS          ║
      ╚═════════════════════════════╝*/
    /**********************************/
    // constructor
    constructor(address[] memory _whitelistedPassCollectionsAddresses) {
        uint256 collectionsCount = _whitelistedPassCollectionsAddresses.length;
        for (uint256 i = 0; i < collectionsCount; i++) {
            whitelistedPassCollections.push(_whitelistedPassCollectionsAddresses[i]);
        }
    }
    /**********************************/
    /*╔══════════════════════════════╗
      ║     WHITELIST FUNCTIONS      ║
      ╚══════════════════════════════╝*/
    /*
     * Add whitelisted pass collection.
     */
    function addWhitelistedCollection(address _collectionContractAddress)
    external
    onlyOwner
    {
        whitelistedPassCollections.push(_collectionContractAddress);
    }

    /*
     * Remove whitelisted pass collection by index.
     */
    function removeWhitelistedCollection(uint256 index)
    external
    onlyOwner
    {
        whitelistedPassCollections[index] = whitelistedPassCollections[whitelistedPassCollections.length - 1];
        whitelistedPassCollections.pop();
    }
    /**********************************/
    /*╔══════════════════════════════╗
      ║             END              ║
      ║     WHITELIST FUNCTIONS      ║
      ╚══════════════════════════════╝*/
    /**********************************/
    /*╔══════════════════════════════╗
      ║     SALE CHECK FUNCTIONS     ║
      ╚══════════════════════════════╝*/
    function _isSaleStarted(address _nftContractAddress, uint256 _tokenId)
    internal
    view
    returns (bool)
    {
        return (block.timestamp >= nftContractAuctions[_nftContractAddress][_tokenId].auctionStart);
    }

    function _isSaleOngoing(address _nftContractAddress, uint256 _tokenId)
    internal
    view
    returns (bool)
    {
        uint64 auctionEndTimestamp = nftContractAuctions[_nftContractAddress][_tokenId].auctionEnd;
        //if the auctionEnd is set to 0, the sale is on-going and doesn't have specified end.
        return (auctionEndTimestamp == 0 || block.timestamp < auctionEndTimestamp);
    }

    /**********************************/
    /*╔══════════════════════════════╗
      ║             END              ║
      ║     SALE CHECK FUNCTIONS     ║
      ╚══════════════════════════════╝*/
    /**********************************/

    /*╔══════════════════════════════╗
      ║         SALE CREATION        ║
      ╚══════════════════════════════╝*/

    function createNewNftAuctions(
        address _nftContractAddress,
        uint256[] memory _tokenIds,
        uint64 _auctionStart,
        uint64 _auctionEnd,
        uint128 _buyNowPrice,
        address _feeRecipient,
        bool _onlyWhitelisted
    )
    external
    onlyOwner
    notZeroAddress(_feeRecipient)
    {
        require(_auctionEnd >= _auctionStart || _auctionEnd == 0, "Sale end must be after the start");

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            uint256 _tokenId = _tokenIds[i];

            require(
                nftContractAuctions[_nftContractAddress][_tokenId].feeRecipient == address(0),
                "Sale is already created"
            );

            Sale memory sale; // creating the sale
            sale.auctionStart = _auctionStart;
            sale.auctionEnd = _auctionEnd;
            sale.buyNowPrice = _buyNowPrice;
            sale.feeRecipient = _feeRecipient;
            sale.onlyWhitelisted = _onlyWhitelisted;

            nftContractAuctions[_nftContractAddress][_tokenId] = sale;

            // Sending the NFT to this contract
            if (IERC721(_nftContractAddress).ownerOf(_tokenId) == msg.sender) {
                IERC721(_nftContractAddress).transferFrom(
                    msg.sender,
                    address(this),
                    _tokenId
                );
            }
            require(
                IERC721(_nftContractAddress).ownerOf(_tokenId) == address(this),
                "NFT transfer failed"
            );

            emit NftAuctionCreated(
                _nftContractAddress,
                _tokenId,
                _buyNowPrice,
                _auctionStart,
                _auctionEnd,
                _feeRecipient,
                _onlyWhitelisted
            );
        }
    }

    /**********************************/
    /*╔══════════════════════════════╗
      ║             END              ║
      ║         SALE CREATION        ║
      ╚══════════════════════════════╝*/
    /**********************************/

    /*╔═════════════════════════════╗
      ║        BID FUNCTIONS        ║
      ╚═════════════════════════════╝*/

    /********************************************************************
     *                          Make bids with ETH.                     *
     ********************************************************************/

    function makeBid( // function name is the same as in NFTAuction
        address _nftContractAddress,
        uint256 _tokenId
    )
    external
    payable
    saleOngoing(_nftContractAddress, _tokenId)
    needWhitelistedToken(
        _nftContractAddress,
        _tokenId
    )
    ethAmountMeetsBuyRequirements(
        _nftContractAddress,
        _tokenId
    )
    {
        require(msg.sender == tx.origin, "Sender must be a wallet");
        address _feeRecipient = nftContractAuctions[_nftContractAddress][_tokenId].feeRecipient;
        require(_feeRecipient != address(0), "Sale does not exist");

        // attempt to send the funds to the recipient
        (bool success, ) = payable(_feeRecipient).call{ value: msg.value, gas: 20000 }("");
        // if it failed, update their credit balance so they can pull it later
        if (!success) failedTransferCredits[_feeRecipient] = failedTransferCredits[_feeRecipient] + msg.value;

        IERC721(_nftContractAddress).transferFrom(address(this), msg.sender, _tokenId);

        delete nftContractAuctions[_nftContractAddress][_tokenId];

        emit NFTTransferredAndSellerPaid(_nftContractAddress, _tokenId, uint128(msg.value), msg.sender);
    }

    /**********************************/
    /*╔══════════════════════════════╗
      ║             END              ║
      ║        BID FUNCTIONS         ║
      ╚══════════════════════════════╝*/
    /**********************************/

    /*╔══════════════════════════════╗
      ║           WITHDRAW           ║
      ╚══════════════════════════════╝*/
    function withdrawAuctions(address _nftContractAddress, uint256[] memory _tokenIds)
    external
    onlyOwner
    {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            uint256 _tokenId = _tokenIds[i];
            delete nftContractAuctions[_nftContractAddress][_tokenId];
            IERC721(_nftContractAddress).transferFrom(address(this), owner(), _tokenId);
            emit AuctionWithdrawn(_nftContractAddress, _tokenId);
        }
    }

    /*
     * If the transfer of a bid has failed, allow to reclaim amount later.
     */
    function withdrawAllFailedCreditsOf(address recipient) external {
        uint256 amount = failedTransferCredits[recipient];

        require(amount != 0, "no credits to withdraw");

        failedTransferCredits[recipient] = 0;

        (bool successfulWithdraw, ) = recipient.call{
        value: amount,
        gas: 20000
        }("");
        require(successfulWithdraw, "withdraw failed");
    }

    /**********************************/
    /*╔══════════════════════════════╗
      ║             END              ║
      ║           WITHDRAW           ║
      ╚══════════════════════════════╝*/
    /**********************************/
}
