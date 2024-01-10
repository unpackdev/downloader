// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.12;

// import "./console.sol"; // for testing only

import "./Counters.sol";
import "./IERC721.sol";
import "./ReentrancyGuard.sol";

import "./Ownable.sol";
import "./Pausable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

contract Marketplace is ReentrancyGuard, Ownable, Pausable {
    using Counters for Counters.Counter;
    using SafeERC20 for IERC20;

    struct MarketItem {
        uint256 itemId;
        address nftContract;
        uint256 tokenId;
        address payable seller;
        uint256 price;
    }

    event MarketItemCreated(uint256 indexed itemId, address indexed nftContract, uint256 indexed tokenId, address seller, address owner, uint256 price);
    event MarketSaleCreated(uint256 indexed itemId, address indexed nftContract, uint256 indexed tokenId, address seller, address owner, uint256 price);
    event MarketItemCancelled(uint256 indexed itemId, address indexed nftContract, uint256 indexed tokenId, address seller);
    event SetSaleEnabled(bool saleEnabled);
    event SetNftPerAddressLimit(uint256 limit);
    event SetOnlyWhitelisted(bool onlyWhitelisted);
    event DisburseFee(address indexed feeCollector, uint256 amount);
    event SetFeeCollector(address indexed feeCollector);
    event WhitelistUsers();
    event DeleteWhitelistUsers();
    event ResetAddressMintedBalance(address indexed user);
    event SafePullETH(address indexed user, uint256 balance);
    event SafePullERC20(address indexed user, uint256 balance);
    event Pause();
    event Unpause();

    Counters.Counter private itemIds;
    Counters.Counter private itemsSold;

    address[] public whitelistedAddresses;

    uint256 public nftPerAddressLimit = 2;
    address payable feeCollector;
    bool public onlyWhitelisted = true;
    bool public saleEnabled = true;

    mapping(uint256 => MarketItem) private idToMarketItem;
    mapping(address => uint256) public addressMintedBalance;

    // ======= STORAGE DECLARATION END ============

    constructor(address payable _feeCollector) {
        feeCollector = _feeCollector;
    }

    function toUint48(uint256 value) internal pure returns (uint48) {
        require(value <= type(uint48).max, "SafeCast: value doesn't fit in 48 bits");
        return uint48(value);
    }

    function getFeeCollector() external view returns (address) {
        return feeCollector;
    }

    /**
     * @dev Set saleEnabled state
     * @param _state: new state
     */
    function setSaleEnabled(bool _state) public onlyOwner {
        saleEnabled = _state;
        emit SetSaleEnabled(_state);
    }

    /**
     * @dev Getter function for saleEnabled state
     */
    function getSaleState() external view returns (bool) {
        return saleEnabled;
    }

    /**
     * @dev get number of items ever been on sale
     */
    function getItemIds() external view returns (uint48) {
        return toUint48(itemIds.current());
    }

    /**
     * @dev get number of items currently on sale
     */
    function getItemsForSaleAmount() external view returns (uint48) {
        return toUint48(itemIds.current() - itemsSold.current());
    }

    /**
     * @dev Set nftPerAddress limit
     * @param _limit: new limit
     */
    function setNftPerAddressLimit(uint256 _limit) public onlyOwner {
        nftPerAddressLimit = _limit;
        emit SetNftPerAddressLimit(_limit);
    }

    /**
     * @dev Set whitelisted state
     * @param _state: new state
     */
    function setOnlyWhitelisted(bool _state) public onlyOwner {
        onlyWhitelisted = _state;
        emit SetOnlyWhitelisted(_state);
    }

    /**
     * @dev Getter function for whitelisting enabled state
     */
    function getWhitelistState() external view returns (bool) {
        return onlyWhitelisted;
    }

    /**
     * @dev Getter function for whitelist
     */
    function getWhitelist() external view returns (address[] memory) {
        return whitelistedAddresses;
    }

    /**
     * @dev Getter function for checking if an address is whitelisted
     * @param _user: the user address to verify
     */
    function isWhiteListed(address _user) public view returns (bool) {
        for (uint256 i = 0; i < whitelistedAddresses.length; i++) {
            if (whitelistedAddresses[i] == _user) {
                return true;
            }
        }
        return false;
    }

    /**
     * @dev Creates a new list of whitelisted user addresses
     * @param _users: array of users to whitelist
     * ["", "", "", "", ""]
     */
    function whitelistUsers(address[] calldata _users) public onlyOwner {
        delete whitelistedAddresses;
        whitelistedAddresses = _users;
        emit WhitelistUsers();
    }

    /**
     * @dev Deletes the whitelist users
     */
    function deleteWhitelistUsers() public onlyOwner {
        delete whitelistedAddresses;
        emit DeleteWhitelistUsers();
    }

    /**
     * @dev reset amount of NFTs a user has bought in the past
     */
    function resetAddressMintedBalance(address _user) external onlyOwner {
        delete addressMintedBalance[_user];
        emit ResetAddressMintedBalance(_user);
    }

    /**
     * @dev Getter function for idToMarketItem
     * @param marketItemId: id
     */
    function getMarketItem(uint256 marketItemId) external view returns (MarketItem memory) {
        return idToMarketItem[marketItemId];
    }

    /**
     * @dev Creates new market item. Marketplace should be already approved to transfer {tokenId}
     * @param nftContract: nftContract address
     * @param tokenId: tokenId
     * @param price: price
     */
    function createMarketItem(
        address nftContract,
        uint256 tokenId,
        uint256 price
    ) external nonReentrant whenNotPaused {
        require(price > 0, "Price must be at least 1 wei");

        uint256 itemId = itemIds.current();
        idToMarketItem[itemId] = MarketItem(itemId, nftContract, tokenId, payable(msg.sender), price);

        itemIds.increment();
        IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);
        emit MarketItemCreated(itemId, nftContract, tokenId, msg.sender, address(0), price);
    }

    /**
     * @dev Cancels an existing NFT marketlisting
     * @param itemId: itemId
     */
    function cancelMarketItem(uint256 itemId) external nonReentrant whenNotPaused {
        MarketItem memory item = idToMarketItem[itemId];
        require(item.seller != address(0), "market listing does not exist");
        require(item.seller == address(msg.sender), "not seller of this item");
        delete (idToMarketItem[itemId]);
        itemIds.decrement();
        IERC721(item.nftContract).safeTransferFrom(address(this), msg.sender, item.tokenId);
        emit MarketItemCancelled(itemId, item.nftContract, item.tokenId, msg.sender);
    }

    /**
     * @dev Creates market sale
     * @param nftContract: nftContract address
     * @param itemId: tokenId
     * @param to: the address to send nft
     */
    function createMarketSale(
        address nftContract,
        uint256 itemId,
        address to
    ) external payable nonReentrant whenNotPaused {
        require(saleEnabled, "sale is currently disabled");

        if (onlyWhitelisted) {
            require(isWhiteListed(msg.sender), "user is not whitelisted");
            require(addressMintedBalance[msg.sender] < nftPerAddressLimit, "max NFT per address exceeded");
            addressMintedBalance[msg.sender]++;
        }

        uint256 price = idToMarketItem[itemId].price;
        uint256 tokenId = idToMarketItem[itemId].tokenId;
        require(msg.value == price, "Value sent does not match price");

        // seller could be contract. So recommended to use call here
        (bool sent, ) = idToMarketItem[itemId].seller.call{value: msg.value}("");
        require(sent, "Failed to send Ether"); // TODO : ignore failure to prevent DDOS attack ??? (MRM-01)

        idToMarketItem[itemId].seller = payable(address(0));
        itemsSold.increment();
        IERC721(nftContract).safeTransferFrom(address(this), to, tokenId);
        emit MarketItemCreated(itemId, nftContract, tokenId, idToMarketItem[itemId].seller, to, price);
    }

    /**
     * @dev Disburses the fee collected to feeCollector address. Owner function
     * @param amount: Fee amount to withdraw
     */
    function disburseFee(uint256 amount) external onlyOwner whenNotPaused {
        require(feeCollector != address(0), "No fee collector");
        require(amount <= address(this).balance, "Not enough fee amount");

        (bool sent, ) = feeCollector.call{value: amount}("");
        require(sent, "Failed to send Ether");

        emit DisburseFee(feeCollector, amount);
    }

    /**
     * @dev Sets new fee collector address. Owner function
     * @param _feeCollector: new address
     */
    function setFeeCollector(address payable _feeCollector) external onlyOwner whenNotPaused {
        require(_feeCollector != payable(0), "Invalid fee collector address");
        feeCollector = _feeCollector;
        emit SetFeeCollector(_feeCollector);
    }

    /**
     * @dev Returns market items which are currently for sale
     */
    function fetchMarketItems() external view returns (MarketItem[] memory) {
        // return _fetchNFTsFor(address(0));
        uint256 totalItemCount = itemIds.current();
        uint256 itemCount;
        uint256 currentIndex;

        // determine number of for-sale items
        itemCount = totalItemCount - itemsSold.current();

        // allocate and fill return array
        MarketItem[] memory items = new MarketItem[](itemCount);
        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i].seller != address(0)) {
                items[currentIndex++] = idToMarketItem[i];
            }
        }

        return items;
    }

    /**
     * @dev Returns market items for msg.sender
     */
    function fetchMyNFTs() external view returns (MarketItem[] memory) {
        // return _fetchNFTsFor(msg.sender);
        uint256 totalItemCount = itemIds.current();
        uint256 itemCount;
        uint256 currentIndex;

        // count how many items msg.sender has for sale
        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i].seller == msg.sender) {
                itemCount++;
            }
        }

        // allocate and fill return array
        MarketItem[] memory items = new MarketItem[](itemCount);
        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i].seller == msg.sender) {
                items[currentIndex++] = idToMarketItem[i];
            }
        }

        return items;
    }

    /**
     * @notice Emergency functions - use with extreme care !
     */

    /**
     * @dev allows to recover ETH
     */
    function safePullETH() external onlyOwner whenPaused {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
        emit SafePullETH(msg.sender, balance);
    }

    /**
     * @dev allows to recover ERC20 tokens which were (accidently) sent to this contract
     */
    function safePullERC20(address erc20) external onlyOwner {
        uint256 balance = IERC20(erc20).balanceOf(address(this));
        IERC20(erc20).safeTransfer(msg.sender, balance);
        emit SafePullERC20(msg.sender, balance);
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function pause() external onlyOwner {
        _pause();
        emit Pause();
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() external onlyOwner {
        _unpause();
        emit Unpause();
    }
}
