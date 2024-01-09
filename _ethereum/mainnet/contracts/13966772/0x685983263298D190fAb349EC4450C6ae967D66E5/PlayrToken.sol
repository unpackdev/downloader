// SPDX-License-Identifier: Unlicense
// Developed by EasyChain (easychain.tech)
//
pragma solidity ^0.8.4;

import "./ERC721Whitelisted.sol";
import "./ERC721EnumerableEx.sol";
import "./ERC721StagedSale.sol";
import "./ERC721Discounted.sol";
import "./SafeMath.sol";
import "./Context.sol";
import "./Ownable.sol";

contract PlayrToken is Context, ERC721Whitelisted, ERC721EnumerableEx, ERC721StagedSale, ERC721Discounted {
    using SafeMath for uint256;

    ///
    /// Fundamental constants
    ///

    /**
     * Maximum total supply
     */
    uint256 public constant MAX_TOKENS = 10000;

    /**
     * Day duration
     */
    uint256 public constant DAY_DURATION = 86400;

    ///
    /// State variables
    ///

    /**
     * Current amount minted
     */
    uint256 public numTokens = 0;

    /**
     * Token price
     */
    uint256 public tokenPrice = 0.06 ether;

    /**
     * Is token minting enabled (can be disabled by admin)
     */
    bool public mintEnabled = true;

    /**
     * Base metadata url (can be changed by admin)
     */
    string public baseUrl = "https://sandbox-nft.ru/squid/"; 

    /**
     * Randomizer nonce
     */
    uint256 internal nonce = 0;

    /**
     * Actual tokens store
     */
    uint256[MAX_TOKENS] internal indices;

    /**
     * Maxumum amount of token to mint daily
     */
    uint256 public dailyMaxNumTokens = MAX_TOKENS;

    /**
     * Token amount already minter per day
     */
    mapping(uint256 => uint256) public dailyNumTokens;

    /**
     * Amount of tokens minted by user
     */
    mapping(address => uint256) public mintedTokens;

    /**
     * Contract creation
     */
    constructor(address _whitelisted)
        ERC721Whitelisted("Player", "PLAYR", _whitelisted)
        ERC721StagedSale(MAX_TOKENS)
    {
        {
            uint256[] memory stages = new uint256[](6);
            uint256[] memory prices = new uint256[](6);

            stages[0] = 456;
            stages[1] = 1144;
            stages[2] = 1400;
            stages[3] = 7000;
            stages[4] = 0;
            stages[5] = 0;

            prices[0] = 30;
            prices[1] = 50;
            prices[2] = 70;
            prices[3] = 100;
            prices[4] = 100;
            prices[5] = 100;

            updateStagesData(stages, prices);
            open(0);
        }
    }

    ///
    /// Internal function
    ///

    /**
     * Returns metadata base url
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseUrl;
    }

    /**
     * Get random index
     */
    function randomIndex() internal returns (uint256) {
        uint256 totalSize = MAX_TOKENS - numTokens;
        uint256 index = uint256(
            keccak256(
                abi.encodePacked(
                    nonce,
                    msg.sender,
                    block.difficulty,
                    block.timestamp
                )
            )
        ) % totalSize;
        uint256 value = 0;
        if (indices[index] != 0) {
            value = indices[index];
        } else {
            value = index;
        }

        // Move last value to selected position
        if (indices[totalSize - 1] == 0) {
            // Array position not initialized, so use position
            indices[index] = totalSize - 1;
        } else {
            // Array position holds a value so use that
            indices[index] = indices[totalSize - 1];
        }
        nonce++;
        // Don't allow a zero index, start counting at 1
        return value.add(1);
    }

    /**
     * Mint one token internal
     */
    function _internalMint(address to) override internal returns (uint256) {
        require(numTokens < MAX_TOKENS, "Token limit");

        //Get random token
        uint256 id = randomIndex();

        //Change internal token amount
        numTokens++;

        //Mint token
        _mint(to, id);
        return id;
    }

    /**
     * Returns current day id
     */
    function _currentDayId() internal view returns (uint256) {
        return block.timestamp / DAY_DURATION;
    }

    /**
     * Returns amount of token left to mint this day
     */
    function _dailyLimitLeft() internal view returns (uint256) {
        return dailyMaxNumTokens - dailyNumTokens[_currentDayId()];
    }

    /**
     * Ensures that daily mint amount not exceeded
     */
    function _ensureDailyLimit(uint8 _amount) internal {
        require(_amount <= _dailyLimitLeft(), "Daily limit exceeded");
        dailyNumTokens[_currentDayId()] += _amount;
    }

    ///
    /// Public functions (general audience)
    ///

    /**
     * Mint selected amount of tokens
     */
    function mint(address _to, uint8 _amount) public payable {
        require(mintEnabled, "Minting disabled");
        require(_amount <= 20, "Maximum 20 tokens per mint");
        require(_to != address(0), "Cannot mint to empty");

        _ensureDailyLimit(_amount);

        mintedTokens[_to] += _amount;

        uint256 amountAdjustedPrice = getDiscountedPrice(_amount, tokenPrice);
        uint256 totalPrice = _mintStaged(_amount, amountAdjustedPrice, _to);
        require(msg.value >= totalPrice, "Not enought money");

        uint256 balance = msg.value.sub(totalPrice);

        // Return not used balance
        payable(msg.sender).transfer(balance);
    }

    ///
    /// Public view functions (general audience)
    ///

    /**
     * Returns daily mint limit remeaning
     */
    function dailyLimitLeft() public view returns (uint256) {
        return _dailyLimitLeft();
    }

    /**
     * Returns time left to limit rest
     */
    function timeUntilLimitRest() public view returns (uint256) {
        return (_currentDayId() + 1) * DAY_DURATION - block.timestamp;
    }

    ///
    /// Admin functions
    ///

    /**
     * Mint selected amount of tokens to a given address by owner (airdrop)
     */
    function airdrop(address _to, uint8 _amount) public onlyOwner {
        require(mintEnabled, "Minting disabled");
        require(_amount <= 20, "Maximum 20 tokens per mint");
        require(_to != address(0), "Cannot mint to empty");
        
        mintedTokens[msg.sender] += _amount;

        _mintStaged(_amount, 0, _to);
    }

    /**
     * Claim ether
     */
    function claimOwner(uint256 _amount) public onlyOwner {
        payable(msg.sender).transfer(_amount);
    }

    /**
     * Enable or disable Minting
     */
    function setMintingStatus(bool _status) public onlyOwner {
        mintEnabled = _status;
    }

    /**
     * Update base url
     */
    function setBaseUrl(string memory _baseUrl) public onlyOwner {
        baseUrl = _baseUrl;
    }

    /**
     * Allow owner to change token sale price
     */
    function setTokenPrice(uint256 _tokenPrice) public onlyOwner {
        tokenPrice = _tokenPrice;
    }

    /**
     * Allow owner to change daily mint limit
     */
    function setDailyMaxNumTokens(uint256 _dailyMaxNumTokens) public onlyOwner {
        dailyMaxNumTokens = _dailyMaxNumTokens;
    }

    ///
    /// Fallback function
    ///

    /**
     * Fallback to mint
     */
    fallback() external payable {
        mint(msg.sender, 1);
    }

    /**
     * Fallback to mint
     */
    receive() external payable {
        mint(msg.sender, 1);
    }

    ///
    /// Overrides
    ///

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function isApprovedForAll(address _owner, address _operator)
        public
        view
        override(ERC721, ERC721Whitelisted)
        returns (bool isOperator)
    {
        return super.isApprovedForAll(_owner, _operator);
    }
}
