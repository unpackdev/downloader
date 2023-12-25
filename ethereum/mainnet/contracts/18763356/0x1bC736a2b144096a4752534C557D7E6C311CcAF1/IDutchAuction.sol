// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "./Structs.sol";
import "./IMinter.sol";

/**
 * @title DutchAuction
 * @author fx(hash)
 * @notice Minter for distributing tokens at linear prices over fixed periods of time
 */
interface IDutchAuction is IMinter {
    /*//////////////////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Event emitted when the mint details for a Dutch auction are set
     * @param _token Address of the token being minted
     * @param _reserveId ID of the reserve
     * @param _reserveInfo The reserve info of the Dutch auction
     * @param _merkleRoot The merkle root allowlisted buyers
     * @param _mintPassSigner The signing account for mint passes
     * @param _auctionInfo Dutch auction information
     */
    event MintDetailsSet(
        address indexed _token,
        uint256 indexed _reserveId,
        ReserveInfo _reserveInfo,
        bytes32 _merkleRoot,
        address _mintPassSigner,
        AuctionInfo _auctionInfo
    );

    /**
     * @notice Event emitted when a purchase is made during the auction
     * @param _token Address of the token being purchased
     * @param _reserveId ID of the reserve
     * @param _buyer Address of the buyer
     * @param _to Address where the purchased tokens will be sent
     * @param _amount Amount of tokens purchased
     * @param _price Price at which the tokens were purchased
     */
    event Purchase(
        address indexed _token,
        uint256 indexed _reserveId,
        address indexed _buyer,
        address _to,
        uint256 _amount,
        uint256 _price
    );

    /**
     * @notice Event emitted when a refund is claimed by a buyer
     * @param _token Address of the token for which the refund is claimed
     * @param _reserveId ID of the reserve
     * @param _buyer Address of the buyer claiming the refund
     * @param _refundAmount Amount of refund claimed
     */
    event RefundClaimed(
        address indexed _token,
        uint256 indexed _reserveId,
        address indexed _buyer,
        uint256 _refundAmount
    );

    /**
     * @notice Event emitted when the sale proceeds are withdrawn
     * @param _token Address of the token
     * @param _reserveId ID of the reserve
     * @param _creator Address of the creator of the project
     * @param _proceeds Amount of sale proceeds withdrawn
     */
    event Withdrawn(address indexed _token, uint256 indexed _reserveId, address indexed _creator, uint256 _proceeds);

    /*//////////////////////////////////////////////////////////////////////////
                                  ERRORS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Error thrown when receiver is zero address
     */
    error AddressZero();

    /**
     * @notice Error thrown when no funds available to withdraw
     */
    error InsufficientFunds();

    /**
     * @notice Error thrown when the price is insufficient
     */
    error InsufficientPrice();

    /**
     * @notice Error thrown when the allocation amount is zero
     */
    error InvalidAllocation();

    /**
     * @notice Error thrown when the purchase amount is zero
     */
    error InvalidAmount();

    /**
     * @notice Error thrown when payment does not equal price
     */
    error InvalidPayment();

    /**
     * @notice Error thrown when the price is zero
     */
    error InvalidPrice();

    /**
     * @notice Error thrown when the passing a price curve with less than 2 points
     */
    error InvalidPriceCurve();

    /**
     * @notice Error thrown when a reserve does not exist
     */
    error InvalidReserve();

    /**
     * @notice Error thrown when the step length is not equally divisible by the auction duration
     */
    error InvalidStep();

    /**
     * @notice Error thrown when the token is address zero
     */
    error InvalidToken();

    /**
     * @notice Error thrown when buying through allowlist and no allowlist exists
     */
    error NoAllowlist();

    /**
     * @notice Error thrown when calling buy when either an allowlist or signer exists
     */
    error NoPublicMint();

    /**
     * @notice Error thrown when there is no refund available
     */
    error NoRefund();

    /**
     * @notice Error thrown when buy with a mint pass and no signing authority exists
     */
    error NoSigningAuthority();

    /**
     * @notice Error thrown if auction has not ended
     */
    error NotEnded();

    /**
     * @notice Error thrown if auction is not a refundable dutch auction
     */
    error NonRefundableDA();

    /**
     * @notice Error thrown when the auction has not started
     */
    error NotStarted();

    /**
     * @notice Error thrown when setting both an allowlist and mint signer
     */
    error OnlyAuthorityOrAllowlist();

    /**
     * @notice Error thrown when the prices are out of order
     */
    error PricesOutOfOrder();

    /*//////////////////////////////////////////////////////////////////////////
                                  FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * @notice Mapping of token address to reserve ID to reserve information
     */
    function auctions(address, uint256) external view returns (bool, uint248);

    /**
     * @notice Purchases tokens at a linear price over fixed amount of time
     * @param _token Address of the token being purchased
     * @param _reserveId ID of the reserve
     * @param _amount Amount of tokens to purchase
     * @param _to Address receiving the purchased tokens
     */
    function buy(address _token, uint256 _reserveId, uint256 _amount, address _to) external payable;

    /**
     * @notice Purchases tokens through an allowlist at a linear price over fixed amount of time
     * @param _token Address of the token being purchased
     * @param _reserveId ID of the reserve
     * @param _to Address receiving the purchased tokens
     * @param _indexes Array of indices containing purchase info inside the BitMap
     * @param _proofs Array of merkle proofs used for verifying the purchase
     */
    function buyAllowlist(
        address _token,
        uint256 _reserveId,
        address _to,
        uint256[] calldata _indexes,
        bytes32[][] calldata _proofs
    ) external payable;

    /**
     * @notice Purchases tokens through a mint pass at a linear price over fixed amount of time
     * @param _token Address of the token being purchased
     * @param _reserveId ID of the reserve
     * @param _amount Number of tokens being purchased
     * @param _to Address receiving the purchased tokens
     * @param _index Index of puchase info inside the BitMap
     * @param _signature Array of merkle proofs used for verifying the purchase
     */
    function buyMintPass(
        address _token,
        uint256 _reserveId,
        uint256 _amount,
        address _to,
        uint256 _index,
        bytes calldata _signature
    ) external payable;

    /**
     * @notice Returns the earliest valid reserveId that can mint a token
     */
    function getFirstValidReserve(address _token) external view returns (uint256);

    /**
     * @notice Gets the latest timestamp update made to token reserves
     * @param _token Address of the token contract
     * @return Timestamp of latest update
     */
    function getLatestUpdate(address _token) external view returns (uint40);

    /**
     * @notice Gets the current auction price
     * @param _token Address of the token contract
     * @param _reserveId ID of the reserve
     * @return price Price of the token
     */
    function getPrice(address _token, uint256 _reserveId) external view returns (uint256);

    /**
     * @notice Mapping of token address to reserve ID to merkle root
     */
    function merkleRoots(address, uint256) external view returns (bytes32);

    /**
     * @notice Mapping of token address to reserve ID to number of tokens minted
     */
    function numberMinted(address _token, uint256 _reserveId) external view returns (uint256);

    /**
     * @notice Pauses all function executions where modifier is applied
     */
    function pause() external;

    /**
     * @notice Refunds an auction buyer with their rebate amount
     * @param _reserveId ID of the mint
     * @param _token Address of the token contract
     * @param _buyer Address of the buyer receiving the refund
     */
    function refund(address _token, uint256 _reserveId, address _buyer) external;

    /**
     * @notice Mapping of token address to reserve ID to refund amount
     */
    function refunds(address, uint256) external view returns (uint256);

    /**
     * @notice Mapping of token address to reserve ID to reserve information (allocation, price, max mint)
     */
    function reserves(address _token, uint256 _reserveId) external view returns (uint64, uint64, uint128);

    /**
     * @notice Mapping of token address to reserve ID to amount of sale proceeds
     */
    function saleProceeds(address _token, uint256 _reserveId) external view returns (uint256);

    /**
     * @inheritdoc IMinter
     * @dev Mint Details: struct of auction information, merkle root, and signer address
     */
    function setMintDetails(ReserveInfo calldata _reserveInfo, bytes calldata _mintDetails) external;

    /**
     * @notice Unpauses all function executions where modifier is applied
     */
    function unpause() external;

    /**
     * @notice Withdraws sale processed of primary sales to receiver
     * @param _reserveId ID of the reserve
     * @param _token Address of the token contract
     */
    function withdraw(address _token, uint256 _reserveId) external;
}
