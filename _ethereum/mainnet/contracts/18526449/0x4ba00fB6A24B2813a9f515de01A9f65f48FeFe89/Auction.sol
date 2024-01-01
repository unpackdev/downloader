// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "./ERC1155Supply.sol";
import "./ERC1155Burnable.sol";
import "./ERC2981.sol";
import "./MerkleProof.sol";
import "./Strings.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./DefaultOperatorFilterer.sol";

/// @title adidas x Crazyfast Bugatti Auction
contract AdidasCrazyfastBugatti is
    ERC1155Supply,
    ERC1155Burnable,
    ERC2981,
    DefaultOperatorFilterer,
    Ownable,
    Pausable,
    ReentrancyGuard
{
    using Strings for uint256;

    struct Bid {
        /// @dev Actual ETH amount
        uint128 value;
        /// @dev Calculated bid value including boost, if applied
        uint128 bidAmount;
        /// @dev Address of the bidder
        address bidder;
        /// @dev Shoe size
        uint8 size;
        /// @dev Whether the bid has been refunded
        bool isRefunded;
    }

    struct Size {
        uint8 supply;
        Bid[] topBids;
    }

    /// @notice Percentage amount of boosted allow-list bids
    uint256 public immutable ALLOWLIST_BOOST;

    /// @notice Auction starting price for all items
    uint256 public startingPrice;

    /// @notice Minimum bid increment above previous bid
    uint256 public constant MINIMUM_INCREMENT = 0.01 ether;

    /// @notice Initialize the bid count for bids
    uint96 public bidCount;

    /// @notice Initialize the bid count for bid top-ups
    uint96 public topUpCount;

    /// @notice Unix timestamp for auction start
    uint256 public auctionStart;

    /// @notice Unix timestamp for auction end
    uint256 public auctionEnd;

    /// @notice Merkle root for allow-list wallet addresses
    bytes32 public merkleRoot;

    /// @notice Mintpass token name
    string public name;

    /// @notice Mintpass token symbol
    string public symbol;

    mapping(uint256 => mapping(address => Bid[])) public bids;
    mapping(uint256 => mapping(address => uint256)) private bidderToTopBidIndex;
    mapping(uint256 => Size) public shoeSize;

    event BidPlaced(
        address indexed bidder,
        uint8 indexed size,
        uint256 deposit,
        uint128 bidValue,
        bool indexed topUp
    );

    event BidRefunded(
        uint8 indexed size,
        address indexed outbidBy,
        uint128 outbidAmount,
        address indexed refundBidder,
        uint128 calculatedBidAmount,
        uint128 refund
    );

    constructor(
        uint8[] memory _sizes,
        uint8[] memory _supply,
        uint256 _auctionStart,
        uint256 _auctionEnd,
        uint256 _allowList,
        uint256 _startingPrice,
        uint96 _value,
        address _recipient,
        bytes32 _merkleRoot,
        string memory _baseUri,
        string memory _name,
        string memory _symbol
    ) ERC1155(_baseUri) {
        _setDefaultRoyalty(_recipient, _value);
        auctionStart = _auctionStart;
        auctionEnd = _auctionEnd;
        ALLOWLIST_BOOST = _allowList;
        startingPrice = _startingPrice;
        merkleRoot = _merkleRoot;
        name = _name;
        symbol = _symbol;
        require(_sizes.length == _supply.length, "Mismatch between sizes and supply amounts");
        unchecked {
            for (uint i = 0; i < _sizes.length; i++) {
                require(_supply[i] > 0, "Supply cannot be zero");
                shoeSize[_sizes[i]].supply = _supply[i];
            }
        }
    }

    /// @notice Handle new bids and top-up bids
    /// @param size The shoe size
    /// @param merkleProof If user is in the allowlist, the merkle proof
    function handleBid(
        uint8 size,
        bytes32[] calldata merkleProof
    ) public payable nonReentrant whenNotPaused {
        Size storage shoe = shoeSize[size];
        require(
            block.timestamp >= auctionStart && block.timestamp <= auctionEnd && shoe.supply > 0,
            "Invalid bid conditions"
        );

        bool isAllowListed = (merkleProof.length > 0) && verifyAllowList(merkleProof, msg.sender);
        uint128 bidIncrement = isAllowListed
            ? uint128((msg.value * ALLOWLIST_BOOST) / 100)
            : uint128(msg.value);
        uint256 index = bidderToTopBidIndex[size][msg.sender];
        Bid[] storage userBids = bids[size][msg.sender];

        if (index > 0) {
            require(
                msg.value >= MINIMUM_INCREMENT,
                "You must top up your bid by at least 0.01 ETH"
            );
            unchecked {
                Bid storage existingTopBid = shoe.topBids[index - 1];
                existingTopBid.value += uint128(msg.value);
                existingTopBid.bidAmount += bidIncrement;
                userBids[userBids.length - 1] = existingTopBid;
                topUpCount++;
                emit BidPlaced(
                    existingTopBid.bidder,
                    size,
                    msg.value,
                    existingTopBid.bidAmount,
                    true
                );
            }
            return;
        }

        Bid memory newBid = Bid({
            value: uint128(msg.value),
            bidAmount: bidIncrement,
            bidder: msg.sender,
            size: size,
            isRefunded: false
        });

        uint256 currentTopBidsCount = shoe.topBids.length;

        if (currentTopBidsCount >= shoe.supply) {
            Bid memory lowestBid = shoe.topBids[0];
            unchecked {
                for (uint256 i = 1; i < currentTopBidsCount; i++) {
                    if (shoe.topBids[i].bidAmount < lowestBid.bidAmount) {
                        lowestBid = shoe.topBids[i];
                    }
                }
            }
            require(
                msg.value >= lowestBid.bidAmount + MINIMUM_INCREMENT,
                "Bid must be at least 0.01 ETH higher than the current minimum bid"
            );

            uint256 lowestBidIndex = bidderToTopBidIndex[size][lowestBid.bidder] - 1;
            Bid[] storage userToRefundBids = bids[size][lowestBid.bidder];
            uint256 lastBidIndex = userToRefundBids.length - 1;

            userToRefundBids[lastBidIndex].isRefunded = true;
            bidderToTopBidIndex[size][lowestBid.bidder] = 0;
            bidderToTopBidIndex[size][msg.sender] = lowestBidIndex + 1;
            shoe.topBids[lowestBidIndex] = newBid;
            lowestBid.bidder.call{value: lowestBid.value}("");

            emit BidRefunded(
                size,
                newBid.bidder,
                newBid.value,
                lowestBid.bidder,
                lowestBid.bidAmount,
                lowestBid.value
            );
        } else {
            require(
                msg.value >= startingPrice,
                "Bid must be equal to or greater than the starting price"
            );
            shoe.topBids.push(newBid);
            bidderToTopBidIndex[size][msg.sender] = currentTopBidsCount + 1;
        }

        userBids.push(newBid);
        unchecked {
            bidCount++;
        }

        emit BidPlaced(newBid.bidder, size, msg.value, newBid.bidAmount, false);
    }

    /// @notice Gets all winning/top bids for a given shoe size
    /// @param size The shoe size
    /// @return An array of Bids
    function getTopBids(uint8 size) public view returns (Bid[] memory) {
        return shoeSize[size].topBids;
    }

    /// @notice Simulator function to return the minimum amount of ETH needed for a new bid
    /// @param sizes The array of sizes to get prices for
    /// @return An array of prices by size
    function getMinimumPrices(uint8[] memory sizes) public view returns (uint256[] memory) {
        unchecked {
            uint256[] memory prices = new uint256[](sizes.length);
            for (uint256 i = 0; i < sizes.length; i++) {
                Size memory shoe = shoeSize[sizes[i]];
                require(shoe.supply > 0, "Invalid shoe size");
                Bid[] memory topBids = shoe.topBids;
                if (topBids.length == 0 || topBids.length < shoe.supply) {
                    prices[i] = startingPrice;
                } else {
                    uint256 lowestBidAmount = topBids[0].bidAmount;
                    for (uint256 j = 1; j < topBids.length; j++) {
                        lowestBidAmount = (topBids[j].bidAmount < lowestBidAmount)
                            ? topBids[j].bidAmount
                            : lowestBidAmount;
                    }
                    prices[i] = lowestBidAmount + MINIMUM_INCREMENT;
                }
            }
            return prices;
        }
    }

    /// @notice Gets all bids placed by a specific address for a range of shoe sizes
    /// @param sizes The shoe sizes
    /// @param bidder The address of the bidder
    /// @return An array of arrays of bids where each element corresponds to a bid
    function getBidsByBidder(
        address bidder,
        uint8[] calldata sizes
    ) public view returns (Bid[] memory) {
        unchecked {
            uint256 totalBids = 0;

            for (uint256 i = 0; i < sizes.length; i++) {
                totalBids += bids[sizes[i]][bidder].length;
            }

            Bid[] memory allBids = new Bid[](totalBids);
            uint256 index = 0;

            for (uint256 i = 0; i < sizes.length; i++) {
                Bid[] memory currentBids = bids[sizes[i]][bidder];
                for (uint256 j = 0; j < currentBids.length; j++) {
                    allBids[index] = currentBids[j];
                    index++;
                }
            }
            return allBids;
        }
    }

    /// @notice Gets all the winning/top bidders' addresses for all sizes
    /// @param sizes An array of all shoe sizes to check
    /// @return An array of arrays of addresses where each element corresponds to top bid addresses for a size
    function getWinningBidders(uint8[] calldata sizes) public view returns (address[][] memory) {
        unchecked {
            address[][] memory winningBidders = new address[][](sizes.length);

            for (uint256 i = 0; i < sizes.length; i++) {
                uint8 currentSize = sizes[i];
                Bid[] memory topBids = shoeSize[currentSize].topBids;
                winningBidders[i] = new address[](topBids.length);

                for (uint256 j = 0; j < topBids.length; j++) {
                    winningBidders[i][j] = topBids[j].bidder;
                }
            }
            return winningBidders;
        }
    }

    /// @notice Verifies if a user is in the allowlist by checking the merkle proof
    /// @param proof The merkle proof provided by the user
    /// @param user The address of the user
    /// @return A boolean indicating whether the user is in the allowlist
    function verifyAllowList(bytes32[] calldata proof, address user) public view returns (bool) {
        bytes32 node = keccak256(abi.encodePacked(user));
        return MerkleProof.verifyCalldata(proof, merkleRoot, node);
    }

    /// @notice Sets the merkle root for the allowlist
    /// @param _merkleRoot The new merkle root
    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    /// @notice Sets the auction start and end times
    /// @param start The start time for the auction in unix epoch seconds
    /// @param end The end time for the auction in unix epoch seconds
    function setAuctionTimes(uint256 start, uint256 end) public onlyOwner {
        require(start < end, "Auction end time must be after start time");
        auctionStart = start;
        auctionEnd = end;
    }

    ///  @notice Set the auction starting price for all shoe sizes
    ///  @param newStartingPrice The new starting price
    function setStartingPrice(uint256 newStartingPrice) public onlyOwner {
        startingPrice = newStartingPrice;
    }

    /// @notice Pauses the contract, blocking all state-changing operations
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Unpauses the contract, allowing state-changing operations
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @notice Release funds to owner after auction ends
    function releaseFunds() public onlyOwner {
        (bool success, ) = owner().call{value: address(this).balance}("");
        require(success, "Failed to release funds");
    }

    /// @notice Mint mintpasses for auction winners
    /// @param recipients The addresses to receive the tokens
    /// @param amounts The amounts of tokens to mint
    /// @param tokenIds The IDs of the tokens to mint
    function mintBatch(
        address[] calldata recipients,
        uint256[] calldata amounts,
        uint256[] calldata tokenIds
    ) public onlyOwner {
        require(recipients.length == tokenIds.length, "Mismatched data");
        unchecked {
            for (uint256 i = 0; i < recipients.length; i++) {
                _mint(recipients[i], tokenIds[i], amounts[i], "");
            }
        }
    }

    /// @notice Token metadata URI
    /// @param id The tokenId
    function uri(uint256 id) public view override returns (string memory) {
        return string(abi.encodePacked(super.uri(id), Strings.toString(id)));
    }

    /// @notice Sets the base URI for the token's metadata
    /// @param baseUri The new base URI
    function setURI(string calldata baseUri) external onlyOwner {
        _setURI(baseUri);
    }

    /// @notice Sets the name and symbol for the token's metadata
    /// @param newName The new token name
    /// @param newSymbol The new token symbol
    function setNameAndSymbol(
        string calldata newName,
        string calldata newSymbol
    ) external onlyOwner {
        name = newName;
        symbol = newSymbol;
    }

    /// @notice Sets the default royalty for the token
    /// @param receiver The receiver of the royalty fees
    /// @param feeNumerator The value of the royalty fees
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override onlyAllowedOperatorApproval(operator) whenNotPaused {
        super.setApprovalForAll(operator, approved);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override onlyAllowedOperator(from) {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override(ERC1155, ERC1155Supply) whenNotPaused {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC1155, ERC2981) returns (bool) {
        return ERC1155.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }
}
