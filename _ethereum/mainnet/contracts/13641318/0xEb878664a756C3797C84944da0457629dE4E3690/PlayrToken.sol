//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./ERC721Whitelisted.sol";
import "./SafeMath.sol";
import "./Context.sol";
import "./Ownable.sol";

/**
 * Developed by: EasyChain (easychain.tech)
 */
contract PlayrToken is Context, ERC721Whitelisted, Ownable {
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
    uint256 public tokenPrice = 0.05 ether;

    /**
     * Is token minting enabled (can be disabled by admin)
     */
    bool public mintEnabled = true;

    /**
     * Base metadata url (can be changed by admin)
     */
    string public baseUrl = "https://nftsquidgames.com/api/getMetadata/"; // TODO: New link

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
    uint256 public dailyMaxNumTokens = 100;
    
    /**
     * Token amount already minter per day
     */
    mapping(uint256 => uint256) public dailyNumTokens;

    /**
     * Contract creation
     */
    constructor(address _whitelisted) ERC721Whitelisted("Player", "PLAYR", _whitelisted) {}

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
    function _internalMint(address to) private returns (uint256) {
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
        require (_amount <= _dailyLimitLeft(), "Daily limit exceeded");
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
        require(msg.value >= _amount * tokenPrice, "Not enought money");
        require(_to != address(0), "Cannot mint to empty");

        _ensureDailyLimit(_amount);

        uint256 balance = msg.value;

        for (uint8 i = 0; i < _amount; i++) {
            // Sub user balance
            balance = balance.sub(tokenPrice);

            // Mint token tok user
            _internalMint(_to);
        }

        // Return not used balance
        payable(msg.sender).transfer(balance);
    }

    ///
    /// Public view functions (general audience)
    ///

    /**
     * Returns daily mint limit remeaning
     */
    function dailyLimitLeft() public view returns(uint256) {
        return _dailyLimitLeft();
    }

    /**
     * Returns time left to limit rest
     */
    function timeUntilLimitRest() public view returns(uint256) {
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

        for (uint8 i = 0; i < _amount; i++) {
            // Mint token tok user
            _internalMint(_to);
        }
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
}
