// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.4;

import "./ERC1155.sol";
import "./IERC2981.sol";
import "./Admin.sol";

contract UnblockMeParis is ERC1155, Admin, IERC2981 {
    // Royalty base value 10000 = 100%
    uint256 public constant ROYALTY_BASE = 10000;
    // The max amount of tokens that can be minted. Can be changed to a smaller value.
    uint256 public MAX_SUPPLY;
    // Max per Waller
    uint256 public MAX_SUPPLY_WALLET;
    // Royalty receiver
    address public ROYALTY_RECEIVER;
    // Royalty percentage with two decimals
    uint256 public ROYALTY_PERCENTAGE;
    // TokenID
    uint256 private TOKEN_ID = 0;
    // Pirce
    uint256 public PRICE;
    // The start timestamp for the sale
    uint256 public startTimestamp;
    // totalSupply
    uint256 public totalSupply;
    // wallet buy tracking
    mapping(address => uint256) walletTracking;

    constructor(
        string memory url,
        uint256 price,
        uint256 maxSupply,
        uint256 sTime,
        address royaltyReceiver,
        uint256 royaltyPercentage,
        uint256 maxWallet
    ) ERC1155(url) {
        require(royaltyReceiver != address(0), "receiver is address zero");
        require(royaltyPercentage <= ROYALTY_BASE, "royalty value too high");
        PRICE = price;
        MAX_SUPPLY = maxSupply;
        ROYALTY_RECEIVER = royaltyReceiver;
        ROYALTY_PERCENTAGE = royaltyPercentage;
        MAX_SUPPLY_WALLET = maxWallet;
        startTimestamp = sTime;
    }

    /**
     * @dev internal mint
     * @param to whom to mint
     * @param quantity Quantity
     */
    function _internalMint(address to, uint256 quantity) internal {
        require(
            totalSupply + quantity <= MAX_SUPPLY,
            "Purchase exceeds max supply"
        );
        require(
            walletTracking[to] + quantity <= MAX_SUPPLY_WALLET,
            "You can not buy that many NFTs"
        );
        walletTracking[to] += quantity;
        totalSupply += quantity;
        _mint(to, TOKEN_ID, quantity, "");
    }

    /**
     * @dev mint for user
     */
    function mint(uint256 quantity) external payable {
        require(msg.value >= PRICE, "ETH value not correct");
        require(block.timestamp >= startTimestamp, "Sale did not start yet");
        _internalMint(_msgSender(), quantity);
    }

    /**
     * @dev gift an nft
     * @param whom whom are you gift it too?
     */
    function reserve(address whom) external onlyAdmins {
        _internalMint(whom, 1);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165, ERC1155)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev Interface implementation for the NFT Royalty Standard (ERC-2981).
     * Called by marketplaces that supports the standard with the sale price to determine how much royalty is owed and
     * to whom.
     * The first parameter tokenId (the NFT asset queried for royalty information) is not used as royalties are
     * calculated equally for all tokens.
     * @param salePrice - the sale price of the NFT asset specified by `tokenId`
     * @return receiver - address of who should be sent the royalty payment
     * @return royaltyAmount - the royalty payment amount for `salePrice`
     */
    function royaltyInfo(uint256, uint256 salePrice)
        external
        view
        override
        returns (address, uint256)
    {
        return (
            ROYALTY_RECEIVER,
            (salePrice * ROYALTY_PERCENTAGE) / ROYALTY_BASE
        );
    }

    /**
     * @dev Sets the base URI for all token IDs. Only the owner can call this function.
     * @param newBaseURI The new base uri
     */
    function setBaseURI(string memory newBaseURI) external onlyAdmins {
        _setURI(newBaseURI);
    }

    /**
     * @dev Set start time sale
     * @param sTime The start time
     */
    function setStartTime(uint256 sTime) external onlyAdmins {
        startTimestamp = sTime;
    }

    /**
     * @dev Set price
     * @param price Price
     */
    function changePrice(uint256 price) external onlyAdmins {
        PRICE = price;
    }

    /**
     * @dev Cut supply. Can only make it smaller.
     * @param newSupply change max token supply.
     */
    function changeSupply(uint256 newSupply) external onlyAdmins {
        require(newSupply < MAX_SUPPLY, "New supply can only be smaller");
        MAX_SUPPLY = newSupply;
    }

    /**
     * @dev change royaltyInfo
     * @param receiver who receives the money
     * @param cut What percentage cut does the receiver get. Expressed with two decimals. For example 100 represents 1%
     */
    function changeRoyaltyInfo(address receiver, uint256 cut)
        external
        onlyOwner
    {
        require(receiver != address(0), "You can not set the receiver to 0");
        ROYALTY_RECEIVER = receiver;
        ROYALTY_PERCENTAGE = cut;
    }

    /**
     * @dev Withdraw funds
     */
    function withdraw() public onlyAdmins {
        payable(ROYALTY_RECEIVER).transfer(address(this).balance);
    }
}
