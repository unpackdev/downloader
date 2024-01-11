// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

/**
 * WEDREAM ESCROW CONTRACT
 * Learn more about this Project on https://auction.wedream.world/
 */

import "./IERC721Receiver.sol";
import "./IERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./BidValidator.sol";
import "./LibBid.sol";


contract WedreamEscrow is BidValidator, IERC721Receiver, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter public tokenRegistryId;

    uint256 public withdrawalLockedUntil;
    uint256 public auctionStartsAt;
    uint256 public auctionEndsAt;
    uint256 public escrowSharePercentage;

    mapping(uint256 => TokenRegistryEntry) public tokenRegistry;
    mapping(address => uint256[]) public tokenIdsByAddress;
    mapping(address => uint256) public tokenCountByAddress;

    struct TokenRegistryEntry {
        address tokenContract;
        uint256 tokenIdentifier;
        address tokenOwner;
        uint256 minimumPrice;
    }

    // Events
    event TokenWithdrawal(
        uint256 tokenRegistryId,
        address tokenContract,
        uint256 tokenIdentifier,
        address withdrawalInitiator,
        address withdrawalReceiver
    );

    event MinmumPriceChange(
        uint256 tokenRegistryId,
        uint256 oldMiniumPrice,
        uint256 newMiniumPrice,
        address priceChanger
    );

    event FulfillBid(
        uint256 tokenRegistryId,
        address tokenContract,
        uint256 tokenIdentifier,
        address tokenReceiver,
        uint256 minimumPrice,
        uint256 paidAmount
    );

    constructor() public {
        ESCROW_WALLET = 0x901E0FDaf9326A7B962793d2518aB4cC6E4FeF04;
        escrowSharePercentage = 250;
    }

    /**
     * @dev See {IERC721Receiver-onERC721Received}. Also registers token in our TokenRegistry.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address, // operator not required
        address tokenOwnerAddress,
        uint256 tokenIdentifier,
        bytes memory
    ) public virtual override returns (bytes4) {
        tokenRegistryId.increment();
        tokenRegistry[tokenRegistryId.current()] = TokenRegistryEntry(
            msg.sender,
            tokenIdentifier,
            tokenOwnerAddress,
            0
        );
        tokenIdsByAddress[tokenOwnerAddress].push(tokenRegistryId.current());
        tokenCountByAddress[tokenOwnerAddress]++;
        return this.onERC721Received.selector;
    }

    /**
     * @dev Function withdrawal a specific token from the registry.
     * Requirements:
     * - Token must be owned by this contract.
     * - Token was owned by msg.sender before.
     * - It is allowed to withdrawal tokens at this moment.
     *
     * @param _tokenRegistryId Id in the token registry
     * @param _tokenContract ERC721 Contract Address
     * @param _tokenIdentifier Identifier of token on the contract
     */
    function withdrawalToken(
        uint256 _tokenRegistryId,
        address _tokenContract,
        uint256 _tokenIdentifier
    ) public virtual {
        require(
            tokenRegistry[_tokenRegistryId].tokenOwner == msg.sender,
            "WedreamEscrow: Invalid Sender"
        );

        require(
            tokenRegistry[_tokenRegistryId].tokenIdentifier ==
                _tokenIdentifier &&
                tokenRegistry[_tokenRegistryId].tokenContract == _tokenContract,
            "WedreamEscrow: Invalid Registry Entry"
        );

        require(
            (block.timestamp < auctionStartsAt ||
                withdrawalLockedUntil < block.timestamp),
            "WedreamEscrow: Withdrawal currently not allowed"
        );

        transferToken(
            tokenRegistry[_tokenRegistryId].tokenContract,
            tokenRegistry[_tokenRegistryId].tokenIdentifier,
            tokenRegistry[_tokenRegistryId].tokenOwner
        );

        emit TokenWithdrawal(
            _tokenRegistryId,
            tokenRegistry[_tokenRegistryId].tokenContract,
            tokenRegistry[_tokenRegistryId].tokenIdentifier,
            msg.sender,
            tokenRegistry[_tokenRegistryId].tokenOwner
        );

        delete tokenRegistry[_tokenRegistryId];
    }

    /**
     * @dev Function to set the token on sale and add a minimum price. Tokens
     * with minimum Price 0 are not allowed to be sold.
     *
     * Requirements:
     * - `msg.sender` needs to be owner of token in our registry
     * - Withdrawals are allowed / Auction is not running
     *
     * @param _tokenRegistryId Id in the token registry
     * @param _tokenContract ERC721 Contract Address
     * @param _tokenIdentifier Identifier of token on the contract
     * @param minimumPrice New minimum price in wei
     */
    function setMinimumPrice(
        uint256 _tokenRegistryId,
        address _tokenContract,
        uint256 _tokenIdentifier,
        uint256 minimumPrice
    ) external {
        require(
            tokenRegistry[_tokenRegistryId].tokenOwner == msg.sender,
            "WedreamEscrow: Invalid Sender"
        );
        require(
            tokenRegistry[_tokenRegistryId].tokenIdentifier ==
                _tokenIdentifier &&
                tokenRegistry[_tokenRegistryId].tokenContract == _tokenContract,
            "WedreamEscrow: Invalid Registry Entry"
        );
        require(
            (block.timestamp < auctionStartsAt ||
                withdrawalLockedUntil < block.timestamp),
            "WedreamEscrow: Minimum Price Change is currently not allowed"
        );

        uint256 oldPrice = tokenRegistry[_tokenRegistryId].minimumPrice;
        tokenRegistry[_tokenRegistryId].minimumPrice = minimumPrice;

        emit MinmumPriceChange(
            _tokenRegistryId,
            oldPrice,
            minimumPrice,
            msg.sender
        );
    }

    /**
     * @dev Function to set the token on sale and add a minimum price. Tokens
     * with minimum Price 0 are not allowed to be sold. This is a Emergency Function.
     *
     * Requirements:
     * - `msg.sender` needs to admin of contract
     *
     * @param _tokenRegistryId Id in the token registry
     * @param _tokenContract ERC721 Contract Address
     * @param _tokenIdentifier Identifier of token on the contract
     * @param minimumPrice New minimum price in wei
     */
    function adminSetMinimumPrice(
        uint256 _tokenRegistryId,
        address _tokenContract,
        uint256 _tokenIdentifier,
        uint256 minimumPrice
    ) external onlyOwner {
        require(
            tokenRegistry[_tokenRegistryId].tokenIdentifier ==
                _tokenIdentifier &&
                tokenRegistry[_tokenRegistryId].tokenContract == _tokenContract,
            "WedreamEscrow: Invalid Registry Entry"
        );

        uint256 oldPrice = tokenRegistry[_tokenRegistryId].minimumPrice;
        tokenRegistry[_tokenRegistryId].minimumPrice = minimumPrice;

        emit MinmumPriceChange(
            _tokenRegistryId,
            oldPrice,
            minimumPrice,
            msg.sender
        );
    }

    /**
     * @dev Function to change the Auction Period and withdrawal Locking
     * Requirements:
     * - `msg.sender` needs to admin of contract
     * - Dates must be in right order _auctionStartsAt < _auctionEndsAt < _withdrawalLockedUntil
     *
     * @param _auctionStartsAt Timestamp when auction starts (no minimum price changes, no withdrawals)
     * @param _auctionEndsAt Timestamp when auction ends (earlierst when the bids can be fulfilled)
     * @param _withdrawalLockedUntil Timestamp until when previous token owner withdrawal and minimum price changes are not possible
     */
    function adminChangePeriods(
        uint256 _auctionStartsAt,
        uint256 _auctionEndsAt,
        uint256 _withdrawalLockedUntil
    ) external onlyOwner {
        require(
            (_auctionStartsAt < _auctionEndsAt && _auctionEndsAt < _withdrawalLockedUntil),
            "WedreamEscrow: Invalid dates order"
        );
        auctionStartsAt = _auctionStartsAt;
        auctionEndsAt = _auctionEndsAt;
        withdrawalLockedUntil = _withdrawalLockedUntil;
    }

    /**
     * @dev Function to change the escrow share percentage
     *
     * Requirements:
     * - `msg.sender` needs to admin of contract
     * - _escrowSharePercentage can't be more than 10000 (=100%)
     * @param _escrowSharePercentage basis points of share that is sent to the contract owner, default: 250 (=2.5%)
     */
    function adminChangeEscrowSharePercentage(
        uint256 _escrowSharePercentage
    ) external onlyOwner {
        require(
            (_escrowSharePercentage <= 10000),
            "WedreamEscrow: Invalid share percentage (> 10000)"
        );
        escrowSharePercentage = _escrowSharePercentage;
    }

    /**
     * @dev ESCROW_WALLET is used to verify bids integrity. With this function the owner can change it.
     *
     * Requirements:
     * - `msg.sender` needs to admin of contract
     *
     * @param _escrow_wallet Public Address of Signer Wallet
     */
    function adminChangeEscrowWallet(
        address _escrow_wallet
    ) external onlyOwner {
        ESCROW_WALLET = _escrow_wallet;
    }

    /**
     * @dev Withrawal all Funds sent to the contract to Owner.
     * Should never happen but just in case...
     *
     * Requirements:
     * - `msg.sender` needs to be Owner and payable
     */
    function adminWithdrawalEth() external onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

    /**
     * @dev Emergency Admin function to withdrawal a specific token from the registry.
     * Requirements:
     * - Token must be owned by this contract.
     * - msg.sender is owner.
     *
     * @param _tokenRegistryId Id in the token registry.
     * @param _tokenContract ERC721 Contract Address
     * @param _tokenIdentifier Identifier of token on the contract
     */
    function adminWithdrawalToken(
        uint256 _tokenRegistryId,
        address _tokenContract,
        uint256 _tokenIdentifier
    ) public virtual onlyOwner {
        require(
            tokenRegistry[_tokenRegistryId].tokenIdentifier ==
                _tokenIdentifier &&
                tokenRegistry[_tokenRegistryId].tokenContract == _tokenContract,
            "WedreamEscrow: Invalid Registry Entry"
        );

        transferToken(
            tokenRegistry[_tokenRegistryId].tokenContract,
            tokenRegistry[_tokenRegistryId].tokenIdentifier,
            tokenRegistry[_tokenRegistryId].tokenOwner
        );

        emit TokenWithdrawal(
            _tokenRegistryId,
            tokenRegistry[_tokenRegistryId].tokenContract,
            tokenRegistry[_tokenRegistryId].tokenIdentifier,
            msg.sender,
            tokenRegistry[_tokenRegistryId].tokenOwner
        );

        delete tokenRegistry[_tokenRegistryId];
    }

    /**
     * @dev Function for auction winner to fulfill the bid. Token is exchanged with ETH minus {escrowSharePercentage} fee
     * Requirements:
     * - minimumPrice needs to be more than 0
     * - ETH send must match the bid value
     * - transaction needs to be sent by the bidder wallet
     * - TokenContract and TokenIdentifier has to match our TokenRegistryEntry
     * - Auction must have ended
     *
     * @param acceptedBidSignature id in the token registry signed by ESCROW_WALLET
     * @param bidData Struct of Bid
     */
    function fulfillBid(
        bytes memory acceptedBidSignature,
        LibBid.Bid memory bidData
    ) public payable {

        require(
            tokenRegistry[bidData.tokenRegistryId].minimumPrice > 0,
            "WedreamEscrow: Token is not on Sale"
        );
        require(
            msg.value >= tokenRegistry[bidData.tokenRegistryId].minimumPrice,
            "WedreamEscrow: Reserve Price not met"
        );
        require(
            msg.value == bidData.amount,
            "WedreamEscrow: Amount send does not match bid"
        );
        require(
            msg.sender == bidData.winnerWallet,
            "WedreamEscrow: Wrong Wallet"
        );
        require(
            tokenRegistry[bidData.tokenRegistryId].tokenContract ==
                bidData.tokenContract,
            "WedreamEscrow: Mismatch of Token Data (Contract)"
        );
        require(
            tokenRegistry[bidData.tokenRegistryId].tokenIdentifier ==
                bidData.tokenIdentifier,
            "WedreamEscrow: Mismatch of Token Data (Identifier)"
        );

        require(
            (auctionEndsAt < block.timestamp),
            "WedreamEscrow: Auction still running"
        );

        validateBid(bidData, acceptedBidSignature);

        uint256 totalReceived = msg.value;
        uint256 escrowPayout = (totalReceived * escrowSharePercentage) / 10000;
        uint256 ownerPayout = totalReceived - escrowPayout;
        payable(owner()).transfer(escrowPayout);
        payable(tokenRegistry[bidData.tokenRegistryId].tokenOwner).transfer(ownerPayout);


        transferToken(
            tokenRegistry[bidData.tokenRegistryId].tokenContract,
            tokenRegistry[bidData.tokenRegistryId].tokenIdentifier,
            msg.sender
        );

        emit FulfillBid(
            bidData.tokenRegistryId,
            tokenRegistry[bidData.tokenRegistryId].tokenContract,
            tokenRegistry[bidData.tokenRegistryId].tokenIdentifier,
            msg.sender,
            tokenRegistry[bidData.tokenRegistryId].minimumPrice,
            msg.value
        );

        delete tokenRegistry[bidData.tokenRegistryId];
    }

    /**
     * @dev Function to send a Token owned by this contract to an address
     * Requirements:
     * - Token must be owned by this contract.
     *
     * @param tokenContractAddress ERC721 Contract Address
     * @param tokenIdentifier Identifier on the token contract
     * @param tokenReceiver Receiver of the NFT
     */
    function transferToken(
        address tokenContractAddress,
        uint256 tokenIdentifier,
        address tokenReceiver
    ) private {
        require(
            IERC721(tokenContractAddress).ownerOf(tokenIdentifier) ==
                address(this),
            "WedreamEscrow: NFT is not owned by Escrow Contract"
        );

        IERC721(tokenContractAddress).safeTransferFrom(
            address(this),
            tokenReceiver,
            tokenIdentifier
        );
    }
}