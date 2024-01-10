// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./IERC20.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";

contract CyberpunkApeLegends is ERC721Enumerable, Ownable, ReentrancyGuard {
    using Strings for uint256;

    /**
     * The baseURI for tokens
     */
    string private baseURI = "";

    /**
     * The ERC20 token contract that will be used
     * to pay to mint the token.
     */
    IERC20 public paymentToken;

    /**
     * The cost of minting
     */
    uint256 public mintCost;

    /**
     * The maximum supply for the token.
     * Will never exceed this supply.
     * @dev is mutable
     */
    uint256 public maxSupply;

    /**
     * Manual overrides for mint costs
     */
    mapping(uint256 => uint256) public mintCostOverrides;

    /**
     * Deploys the contract and mints the first token to the deployer.
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(
        uint256 _initialSupply,
        address _paymentToken,
        uint256 _mintCost,
        string memory _baseUri
    ) ERC721("Cyberpunk Ape Executives Legends", "CAEL") {
        require(_initialSupply >= 1, "Bad supply");
        require(_paymentToken != address(0), "Bad token");
        require(_mintCost > 0, "Bad cost");

        maxSupply = _initialSupply;
        paymentToken = IERC20(_paymentToken);
        mintCost = _mintCost;

        baseURI = _baseUri;

        mint(1);
    }

    // ------------------------------------------------ ADMINISTRATION LOGIC ------------------------------------------------

    /**
     * Sets the base URI for all immature tokens
     *
     * @dev be sure to terminate with a slash
     * @param uri - the target base uri (ex: 'https://google.com/')
     */
    function setBaseURI(string calldata uri) public onlyOwner {
        baseURI = uri;
    }

    function setMaxSupply(uint256 supply) public onlyOwner {
        require(supply > maxSupply, "Too small");

        maxSupply = supply;
    }

    /**
     * Sets the payment ERC20 token
     *
     * @param tokenAddress - the address of the payment token
     */
    function setPaymentToken(address tokenAddress) public onlyOwner {
        paymentToken = IERC20(tokenAddress);
    }

    /**
     * Sets the mint price
     *
     * @param _mintCost - the mint cost
     */
    function setMintPrice(uint256 _mintCost) external onlyOwner {
        mintCost = _mintCost;
    }

    /**
    * Sets overrides for the mint prices
    * @dev any prices equal to the current mint cost will not be registered as overrides.
    *
    * @param startId - the start id from which to start setting mint costs.
    * @param prices - an array of prices starting at (inclusive) the start id.
    */
    function setMintPriceOverrides(uint256 startId, uint256[] calldata prices) external onlyOwner {
        for (uint256 i; i < prices.length; i++) {
            if (prices[i] != mintCost)
                mintCostOverrides[startId + i] = prices[i];
        }
    }

    // ------------------------------------------------ URI LOGIC -------------------------------------------------

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString()))
                : "";
    }

    // ------------------------------------------------ MINT LOGIC ------------------------------------------------

    /**
     * Mints the given token id provided it is possible to.
     * transfers the required number of payment tokens from the user's wallet
     *
     * @notice This function allows minting for the set cost,
     * or free for the contract owner
     *
     * @param tokenId - the token id to mint
     */
    function mint(uint256 tokenId) public nonReentrant {
        bool isOwner = msg.sender == owner();

        if (!isOwner) {
            // transfers out token if not owner
            IERC20(paymentToken).transferFrom(
                msg.sender,
                address(this),
                priceOf(tokenId)
            );
        }

        // DISTRIBUTE THE TOKENS
        _tryMint(msg.sender, tokenId);
    }

    /**
     * Mints the given token ids provided it is possible to.
     * transfers the required number of payment tokens from the user's wallet
     *
     * @notice This function allows minting for the set cost,
     * or free for the contract owner
     *
     * @param tokenIds - the token ids to mint
     */
    function mintMany(uint256[] calldata tokenIds) public nonReentrant {
        bool isOwner = msg.sender == owner();

        uint256 price;
        for (uint256 i; i < tokenIds.length; i++) {
            price += priceOf(tokenIds[i]);

            _tryMint(msg.sender, tokenIds[i]);
        }

        if (!isOwner) {
            // transfers out token if not owner
            IERC20(paymentToken).transferFrom(
                msg.sender,
                address(this),
                price
            );
        }
    }

    /**
     * @dev mints the token after ensuring it is in the token range.
     */
    function _tryMint(address to, uint256 tokenId) internal {
        require(tokenId <= maxSupply && tokenId >= 1, "Bad id");
        _safeMint(to, tokenId);
    }

    // ------------------------------------------------ BURN LOGIC ------------------------------------------------

    /**
     * Burns the provided token id if you own it.
     * Reduces the supply by 1.
     *
     * @param tokenId - the ID of the token to be burned.
     */
    function burn(uint256 tokenId) public {
        require(ownerOf(tokenId) == msg.sender, "Not owner");

        _burn(tokenId);
    }

    // ------------------------------------------------ BALANCE STUFFS ------------------------------------------------

    /**
     * Returns the price of a given token id.
     * @dev does not check if that token has already been purchased
     */
    function priceOf(uint256 tokenId) public view returns (uint256) {
        if (mintCostOverrides[tokenId] != 0) return mintCostOverrides[tokenId];
        return mintCost;
    }

    /**
     * Gets the balance of the contract in payment tokens.
     * @return the amount held by the contract.
     */
    function balance() external view returns (uint256) {
        return paymentToken.balanceOf(address(this));
    }

    /**
     * Withdraws balance from the contract to the owner (sender).
     * @param amount - the amount to withdraw, much be <= contract balance.
     */
    function withdraw(uint256 amount) external onlyOwner {
        require(this.balance() >= amount, "Not enough");

        paymentToken.transfer(msg.sender, amount);
    }

    /**
     * Returns all of the unminted token ids as well as their prices
     * @return an array of ids and an array of prices
     */
    function unmintedTokens() external view returns (uint256[] memory, uint256[] memory) {
        uint256 numUnminted = maxSupply - totalSupply();

        uint256[] memory tokens = new uint256[](numUnminted);
        uint256[] memory prices = new uint256[](numUnminted);
        uint256 nextIndex;

        for (uint256 i = 1; i <= maxSupply; i++) {
            if (!_exists(i)) {
                tokens[nextIndex] = i;
                prices[nextIndex] = priceOf(i);
                nextIndex += 1;
            }
        }

        return (tokens, prices);
    }

    /**
     * The receive function, does nothing
     */
    receive() external payable {
        // NOTHING TO SEE HERE
    }
}
