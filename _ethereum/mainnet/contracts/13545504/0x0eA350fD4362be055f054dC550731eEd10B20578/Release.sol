// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./Governed.sol";
import "./OwnerBalanceContributor.sol";
import "./Macabris.sol";
import "./Bank.sol";

/**
 * @title Macabris token initial randomised sale contract
 */
contract Release is Governed, OwnerBalanceContributor {

    // Represents a sale of a token
    struct Sale {
        address buyer;
        uint price;
        uint fee;
        uint blockNumber;
    }

    // Macabris NFT contract
    Macabris public macabris;

    // Bank contract
    Bank public bank;

    // Price of a single token
    uint public price;

    // Total available tokens
    uint256 public immutable tokensTotal;

    // Total sold tokens
    uint256 public tokensSold;

    // Total revealed tokens
    uint256 public tokensRevealed;

    // Owner fee in bps
    uint256 public ownerFee;

    // Automatic price increase amount
    uint public priceIncreaseAmount;

    // Number of sales that trigger automatic price increase
    uint256 public priceIncreaseFrequency;

    // Sales mapped by sale ID
    mapping(uint256 => Sale) private sales;

    // Revealed token IDs, mapped by sale ID (only valid until the tokensRevealed-1)
    mapping(uint256 => uint256) private reveals;

    /**
     * @dev Emitted when a token is sold through the `buy` method
     * @param saleId Sale ID
     * @param buyer Buyer address
     * @param blockNumber Block number of the buy transaction
     * @param price Price in wei
     */
    event Buy(uint256 indexed saleId, address indexed buyer, uint blockNumber, uint price);

    /**
     * @dev Emitted when a token is revealed through the `reveal` method
     * @param saleId Sale ID
     * @param tokenId Revealed token ID
     * @param price Price in wei
     */
    event Reveal(uint256 indexed saleId, uint256 indexed tokenId, uint price);

    /**
     * @param _tokensTotal Total number of tokens that can be realeased
     * @param _price Price of a new token in wei
     * @param governanceAddress Address of the Governance contract
     * @param ownerBalanceAddress Address of the OwnerBalance contract
     *
     * Requirements:
     * - There should be less total tokens than the max value of uint256
     * - Governance contract must be deployed at the given address
     * - OwnerBalance contract must be deployed at the given address
     */
    constructor(
        uint256 _tokensTotal,
        uint _price,
        address governanceAddress,
        address ownerBalanceAddress
    ) Governed(governanceAddress) OwnerBalanceContributor(ownerBalanceAddress) {

        // Since the token IDs start with 1, the full uint256 range is not supported.
        require(_tokensTotal < type(uint256).max, "Max token count must be less than max int256 value");

        tokensTotal = _tokensTotal;
        price = _price;
    }

    /**
     * @dev Sets Macabris NFT contract address
     * @param macabrisAddress Address of Macabris NFT contract
     *
     * Requirements:
     * - the caller must have the bootstrap permission
     * - Macabris contract must be deployed at the given address
     */
    function setMacabrisAddress(address macabrisAddress) external canBootstrap(msg.sender) {
        macabris = Macabris(macabrisAddress);
    }

    /**
     * @dev Sets Bank contract address
     * @param bankAddress Address of the Bank contract
     *
     * Requirements:
     * - the caller must have the bootstrap permission
     * - Bank contract must be deployed at the given address
     */
    function setBankAddress(address bankAddress) external canBootstrap(msg.sender) {
        bank = Bank(bankAddress);
    }

    /**
     * @dev Sets price for the new tokens
     * @param _price Price in wei
     *
     * Requirements:
     * - the caller must have the configure permission
     * - price must be bigger than the current price
     */
    function setPrice(uint _price) external canConfigure(msg.sender) {
        require(_price > price, "Price can only be increased up");
        price = _price;
    }

    /**
     * @dev Sets automatic price increase amount
     * @param amount Amount in wei
     *
     * Requirements:
     * - the caller must have the configure permission
     */
    function setPriceIncreaseAmount(uint amount) external canConfigure(msg.sender) {
        priceIncreaseAmount = amount;
    }

    /**
     * @dev Sets the number of sales that trigger automatic price increase
     * @param frequency Number of sales, zero to disable automatic price increases
     *
     * Requirements:
     * - the caller must have the configure permission
     */
    function setPriceIncreaseFrequency(uint frequency) external canConfigure(msg.sender) {
        priceIncreaseFrequency = frequency;
    }

    /**
     * @dev Sets owner fee
     * @param _ownerFee Owner fee in bps
     *
     * Requirements:
     * - the caller must have the configure permission
     * - owner fee should divide 10000 without a remainder
     */
    function setOwnerFee(uint256 _ownerFee) external canConfigure(msg.sender) {

        if (_ownerFee > 0) {
            require(10000 % _ownerFee == 0, "Owner fee amount must divide 10000 without a remainder");
        }

        ownerFee = _ownerFee;
    }

    /**
     * @dev Buys a random token, to be revealed later
     *
     * Requirements:
     * - Current amount of tokens sold must be lower than max token count
     * - `msg.value` must exactly match the `price` property
     *
     * Emits {Buy} event
     */
    function buy() external payable {
        require(tokensSold < tokensTotal, "Tokens are sold out");
        require(msg.value == price, "Transaction value does not match token price");

        uint fee = _calculateFeeAmount(price, ownerFee);
        uint saleId = tokensSold;

        sales[saleId] = Sale({
            buyer: msg.sender,
            price: price,
            fee: fee,
            blockNumber: block.number
        });
        tokensSold++;

        // Do automatic price increase for the future token sales
        if (priceIncreaseFrequency > 0 && tokensSold % priceIncreaseFrequency == 0) {
            price += priceIncreaseAmount;
        }

        _transferToOwnerBalance(fee);

        emit Buy(saleId, msg.sender, block.number, sales[saleId].price);
    }

    /**
     * @dev Reveals the token ID for the oldest unrevealed sale
     *
     * Uses reversed Fisher-Yates-Durstenfeld-Knuth shuffle algorithm to assign tokens:
     * https://en.wikipedia.org/wiki/Fisher%E2%80%93Yates_shuffle
     *
     * Uses hash of the buy transaction block, which isn't known during the buy transaction, as a
     * source of randomness.
     *
     * This method should be periodically called by a background process to reveal any new sales.
     * This way the UX of the buy process is better, because the user only needs to issue one buy
     * transaction to buy a token. However, the method can be called by anyone, to make sure the
     * contract is functional even if said background process dies for some reason.
     *
     * Requirements:
     * - There must be unrevealed sales
     * - Sale can't be revealed in the same block as the buy transaction
     *
     * Emits {Reveal} event
     */
    function reveal() external {
        require(tokensRevealed < tokensSold, "All sales have been already revealed");
        uint saleId = tokensRevealed;
        Sale storage sale = sales[saleId];

        // Miners can influence block hash to some degree, but the reward for a valid block is much
        // higher than the value of a change of the revealed token to a different random token.
        require(
            block.number > sale.blockNumber,
            "Token can't be reavealed in the same block as the buy transaction"
        );

        // Normally, the reveal method should be called by a background process shortly after the
        // sale occured. If that doesn't happen for some reason, and 256 blocks are mined after the
        // sale has happenned, block hash of the sale transaction won't be available anymore.
        //
        // Using the block hash of the last block as a fallback source of randomness, but it opens
        // up the possibility to revert the reveal transaction and try again, only spending the gas
        // costs on each try.
        bytes32 blockHash = blockhash(sale.blockNumber);
        blockHash = blockHash == 0 ? blockhash(block.number - 1) : blockHash;

        // If only the block hash is used as the source of randomness, then all the sales of the same
        // block would reveal tokens sequentially, with one token gaps in between. Hashing block hash
        // and the total number of revealed tokens to make the reveals spread out randomly even for
        // the sales in the same block.
        uint256 tokensHidden = tokensTotal - tokensRevealed;
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(blockHash, tokensRevealed)));
        uint256 tokenOffset = tokensRevealed + (randomNumber > 0 ? randomNumber % tokensHidden : 0);

        // The reaveals mapping represents all the possible tokens, but is initiated with zeros
        // during the contract construction. A zero value in the mapping represents a token with
        // an ID matching the index plus one.
        uint256 revealedTokenId = reveals[tokenOffset];
        revealedTokenId = revealedTokenId == 0 ? tokenOffset + 1 : revealedTokenId;

        uint256 currentTokenId = reveals[tokensRevealed];
        currentTokenId = currentTokenId == 0 ? tokensRevealed + 1 : currentTokenId;

        // Switching token ID in the current reveal index with the revealed token ID, keeping all
        // the revealed tokens in the [0, tokensRevealed - 1] range, and the remaining ones in the
        // [tokensRevealed, tokensTotal - 1] range.
        reveals[saleId] = revealedTokenId;
        reveals[tokenOffset] = currentTokenId;

        tokensRevealed++;

        macabris.onRelease(revealedTokenId, sale.buyer);
        bank.deposit{value: sale.price - sale.fee}();

        emit Reveal(saleId, revealedTokenId, sale.price);
    }

    /**
     * @dev Calculates fee amount based on given price and fee in bps
     * @param _price Price base for calculation
     * @param fee Fee in basis points
     * @return Fee amount in wei
     */
    function _calculateFeeAmount(uint _price, uint fee) private pure returns (uint) {

        // Fee might be zero, avoiding division by zero
        if (fee == 0) {
            return 0;
        }

        // Only using division to make sure there is no overflow of the return value.
        // This is the reason why fee must divide 10000 without a remainder, otherwise
        // because of integer division fee won't be accurate.
        return _price / (10000 / fee);
    }

    /**
     * @dev Returns revealed token ID for the given sale
     * @param saleId Sale ID, could be retrieved from the Sale event emitted in the `buy` method
     * @return Revealed token ID
     *
     * Requirements:
     * - Sale must be previously revealed using the `reveal` method
     */
    function getRevealedTokenId(uint256 saleId) external view returns (uint256) {
        require(saleId < tokensRevealed, "Sale does not exist or is not yet revealed");
        return reveals[saleId];
    }
}
