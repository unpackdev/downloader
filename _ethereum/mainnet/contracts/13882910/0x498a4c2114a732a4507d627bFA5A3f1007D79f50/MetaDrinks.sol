// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721Enumerable.sol";
import "./MetaDrinksTypes.sol";
import "./MetaDrinksSvgGenerator.sol";
import "./MetaDrinksDataGenerator.sol";
import "./MetaDrinksMetaDataGenerator.sol";

contract MetaDrinks is ERC721Enumerable, ReentrancyGuard, Ownable, MetaDrinksDataGenerator {
    // immutable configuration
    uint256 private constant TOKEN_PRICE = 0.05 ether;
    uint256 private constant MAX_TOKENS_COUNT = 7777;
    address private constant leaderAddress = 0x488eD15Ad873B34B4Ba547d00ed1b93f0fFB552C;
    address private constant engineerAddress = 0xDC745a99eaE7F20d8E8Dd9fA7e208f9A622C2B45;
    address private constant bartenderAddress = 0xa4bad3F83Ea2FC2D9A54253A007236FF8Ff8eF3A;

    // mutable configuration
    uint256 public mintStartsAtTimestamp;
    uint256 public maxTokensPerAddress;
    uint256 public maxTokensPerTransaction;
    uint256 public reservedTokensCount;

    // tokens counters
    uint256 public tokenCounter;
    mapping(address => uint256) private tokensCountPerAddress;

    // whitelist
    bool public isWhitelistActive = false;
    mapping(address => uint256) private whitelistAddressToLimit;

    constructor() ERC721("Metadrinks", "metadrinks") {
        mintStartsAtTimestamp = 0;
        maxTokensPerAddress = 20;
        maxTokensPerTransaction = 20;
        reservedTokensCount = 500;
    }

    // region ---- mutable configuration ------------------------------------------------------------
    function setMintStartsAtTimestamp(uint256 _mintStartsAtTimestamp) external onlyOwner {
        mintStartsAtTimestamp = _mintStartsAtTimestamp;
    }

    function setMaxTokens(uint256 _maxTokensPerAddress, uint256 _maxTokensPerTransaction) external onlyOwner {
        maxTokensPerAddress = _maxTokensPerAddress;
        maxTokensPerTransaction = _maxTokensPerTransaction;
    }

    function setReservedTokensCount(uint256 _reservedTokensCount) external onlyOwner {
        reservedTokensCount = _reservedTokensCount;
    }

    function setIsWhitelistActive(bool _isActive) external onlyOwner {
        isWhitelistActive = _isActive;
    }

    function updateWhitelistAddresses(address[] memory _addresses, uint256[] memory _amounts) external onlyOwner {
        for (uint i = 0; i < _addresses.length; i++) {
            whitelistAddressToLimit[_addresses[i]] = _amounts[i];
        }
    }
    // region ---- mutable configuration ------------------------------------------------------------

    // region ---- withdraw --------------------------------------------------------
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        uint256 engineerShare = (30 * balance) / 100;
        uint256 bartenderShare = (30 * balance) / 100;
        payable(engineerAddress).transfer(engineerShare);
        payable(bartenderAddress).transfer(bartenderShare);
        payable(leaderAddress).transfer(balance - engineerShare - bartenderShare);
    }

    // region ---- withdraw --------------------------------------------------------

    // region ---- mint --------------------------------------------------------
    function mint(uint256 _amount) external payable nonReentrant {
        uint256 currWhitelistAddressLimit = isWhitelistActive ? whitelistAddressToLimit[msg.sender] : 0;
        if (currWhitelistAddressLimit > 0) {
            int256 whitelistLimitDiff = int256(currWhitelistAddressLimit) - int256(_amount);
            require(whitelistLimitDiff >= 0, "Minting would exceed max supply for whitelisted address");
            whitelistAddressToLimit[msg.sender] = uint256(whitelistLimitDiff);
        } else {
            // check sale started (tested)
            require(block.timestamp >= mintStartsAtTimestamp, "Sale not started yet or paused");
        }

        // check tokens per address (tested)
        uint256 newAddressTokensCount = tokensCountPerAddress[msg.sender] + _amount;
        require(newAddressTokensCount <= maxTokensPerAddress, "Too many tokens per address");

        // check tokens per transaction (tested)
        require(_amount <= maxTokensPerTransaction, "Too many tokens per transaction");

        // check ethers value (tested)
        require(msg.value >= _amount * TOKEN_PRICE, "Wrong ether value");

        // remember new tokens count for the address
        tokensCountPerAddress[msg.sender] = newAddressTokensCount;

        // mint tokens
        mintTokensInternal(msg.sender, _amount);
    }

    function airdrop(address[] memory _addresses, uint256[] memory _amounts) external nonReentrant onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            mintTokensInternal(_addresses[i], _amounts[i]);
        }
    }

    function mintTokensInternal(address _toAddress, uint256 _amount) internal {
        // checks amount not zero (tested)
        require(_amount > 0, "Must mint at least one token");

        // checks tokens limit plus amount not reached (tested)
        require(tokenCounter + _amount + reservedTokensCount <= MAX_TOKENS_COUNT, "Minting would exceed max supply");

        // mint tokens
        for (uint256 i = 0; i < _amount; i++) {
            mintTokenInternal(_toAddress);
        }
    }

    function mintTokenInternal(address _toAddress) internal {
        // inc the counter
        tokenCounter++;

        // mint
        _safeMint(_toAddress, tokenCounter);
    }

    function tokenURI(uint256 _tokenId) override public view returns (string memory) {
        require(_exists(_tokenId), "Token not minted");
        MetaDrinksTypes.Drink memory drink = genDrink(_tokenId);
        return MetaDrinksMetaDataGenerator.genJsonTokenURI(drink, MetaDrinksSvgGenerator.genSvg(drink));
    }

    // region ---- mint --------------------------------------------------------
}
