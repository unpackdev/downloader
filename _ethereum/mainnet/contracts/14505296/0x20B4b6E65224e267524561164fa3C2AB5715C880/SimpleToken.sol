// SPDX-License-Identifier: Unlicense
// Developed by EasyChain (easychain.tech)
//
pragma solidity ^0.8.4;

import "./console.sol";
import "./ERC721EnumerableEx.sol";
import "./ERC721Whitelisted.sol";
import "./ERC721Burnable.sol";
import "./SafeMath.sol";
import "./Context.sol";
import "./Ownable.sol";

contract SimpleToken is Context, Ownable, ERC721Whitelisted, ERC721EnumerableEx {
    using SafeMath for uint256;

    ///
    /// Fundamental constants
    ///

    /**
     * Maximum total supply
     */
    uint256 public constant MAX_TOKENS = 12000;

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
    uint256 public tokenPrice = 1 ether;

    /**
     * Is token minting enabled (can be disabled by admin)
     */
    bool public mintEnabled = true;

    /**
     * Base metadata url (can be changed by admin)
     */
    string public baseUrl = "https://mosque.sandbox-nft.ru/api/"; 

    /**
     * Randomizer nonce
     */
    uint256 internal nonce = 0;

    /**
     * Actual tokens store
     */
    uint256[MAX_TOKENS] internal indices;

    /**
     * Contract creation
     */
    constructor(address _openSeaAddress)
        ERC721Whitelisted("TheMosqueNFT", "MSQ", _openSeaAddress)
    {

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
    function _internalMint(address to) internal returns (uint256) {
        require(numTokens < MAX_TOKENS, "Token limit");

        //Get random token
        uint256 id = randomIndex();

        //Change internal token amount
        numTokens++;

        //Mint token
        _mint(to, id);
        return id;
    }

    function _doMint(uint8 _amount, address _to) internal returns (uint256) {
        uint256 result = 0;
        for (uint8 i = 0; i < _amount; i++) {
            result += tokenPrice;
            _internalMint(_to);
        }
        return result;
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

        uint256 totalPrice = _doMint(_amount, _to);
        require(msg.value >= totalPrice, "Not enought money");

        uint256 balance = msg.value.sub(totalPrice);

        // Return not used balance
        payable(msg.sender).transfer(balance);
    }

    ///
    /// Admin functions
    ///

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
        override (ERC721, ERC721Whitelisted)
        returns (bool isOperator)
    {
        return super.isApprovedForAll(_owner, _operator);
    }
}
