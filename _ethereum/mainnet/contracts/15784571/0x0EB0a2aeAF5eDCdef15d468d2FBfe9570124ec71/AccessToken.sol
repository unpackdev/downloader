// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
//   __        __    _        _   _
//   \ \      / /_ _| | _____| | | |_ __
//    \ \ /\ / / _` | |/ / _ \ | | | '_ \
//     \ V  V / (_| |   <  __/ |_| | |_) |
//      \_/\_/ \__,_|_|\_\___|\___/| .__/
//                                 |_|
//       WakeUp Labs 2022

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./DelegableTokenExtension.sol";
import "./ERC2981.sol";

import "./Whitelist.sol";

contract AccessToken is DelegableTokenExtension, ERC2981, Whitelist {
    uint256 constant MAX_TIERS = 3;

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    struct Tier {
        string tokenURI;
        uint256 maxSupply;
        uint256 price;
        uint8 maxAmount; // max amount of tokens allowed to mints in a mint tx;
        Counters.Counter supply;
    }

    mapping(uint256 => bool) public paused;
    mapping(uint256 => uint8) public tokens; // {tokenId,tierId}
    mapping(uint8 => Tier) private _tiers; // {tierId, tier}

    constructor(
        string memory name,
        string memory symbol,
        Tier[MAX_TIERS] memory tiers,
        address receiver,
        uint96 feeNumerator
    )
        DelegableTokenExtension(name, symbol)
        DelegableTokenConfiguration(true, true)
    {
        // TIER 0 --> 2
        _tiers[0] = tiers[0];
        _tiers[1] = tiers[1];
        _tiers[2] = tiers[2];

        if (receiver != address(0)) {
            _setDefaultRoyalty(receiver, feeNumerator);
        }
    }

    modifier existentTier(uint256 tierId) {
        require(tierId < MAX_TIERS, "Nonexistent tier");
        _;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        _requireMinted(tokenId);
        return _tiers[tokens[tokenId]].tokenURI;
    }

    function maxSupply(uint8 tierId) public view virtual returns (uint256) {
        return _tiers[tierId].maxSupply;
    }

    function price(uint8 tierId) public view virtual returns (uint256) {
        return _tiers[tierId].price;
    }

    function totalSupply() public view virtual returns (uint256) {
        return _tokenIdCounter.current();
    }

    function currentSupply(uint8 tierId) public view virtual returns (uint256) {
        return _tiers[tierId].supply.current();
    }

    function maxAmount(uint8 tierId) public view virtual returns (uint8) {
        return _tiers[tierId].maxAmount;
    }

    /**
     * @dev Safely mints a new Access Token with a specific tier
     * @param tierId to mint
     * @param amount of tokens 0 < amount < MAX_AMOUNT
     * Emits a {Transfer} event.
     */
    function mint(uint8 tierId, uint8 amount)
        public
        payable
        existentTier(tierId)
    {
        require(!paused[tierId], "Tier paused");
        require(amount > 0 && amount < maxAmount(tierId), "Invalid amount");
        require(
            whitelist[msg.sender] || msg.value == price(tierId) * amount,
            "Wrong value sent"
        );

        for (uint8 i = 0; i < amount; i++) {
            uint256 tokenId = _tokenIdCounter.current();
            require(
                currentSupply(tierId) < maxSupply(tierId),
                "Max supply exceeded"
            );
            _tokenIdCounter.increment();
            _tiers[tierId].supply.increment();
            tokens[tokenId] = tierId;
            whitelist[msg.sender] = false;
            _safeMint(msg.sender, tokenId);
        }
    }

    function setPrice(uint8 tierId, uint256 ntfPrice)
        external
        onlyOwner
        existentTier(tierId)
    {
        _tiers[tierId].price = ntfPrice;
    }

    function setTokenUri(uint8 tierId, string memory _tokenURI)
        external
        onlyOwner
        existentTier(tierId)
    {
        _tiers[tierId].tokenURI = _tokenURI;
    }

    function setMaxAmount(uint8 tierId, uint8 amount)
        external
        onlyOwner
        existentTier(tierId)
    {
        _tiers[tierId].maxAmount = amount;
    }

    /**
     * @dev Withdraw all the contract balance and transfer to an address.
     * @param recipient address to transfer the balance
     */
    function withdraw(address payable recipient) external onlyOwner {
        uint256 balance = address(this).balance;
        recipient.transfer(balance);
    }

    /**
     * @dev Triggers stopped state to a tier.
     * @param tierId to pause
     */
    function pause(uint8 tierId) external onlyOwner {
        paused[tierId] = true;
    }

    /**
     * @dev Returns the tier to normal state.
     * @param tierId to unpause
     */
    function unpause(uint8 tierId) external onlyOwner {
        paused[tierId] = false;
    }

    /**
     * @dev Sets the royalty information that all ids in this contract will default to.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     * The denominator with which to interpret the fee as a fraction of the sale price.
     * Defaults to 10000 so fees are expressed in basis points, but may be customized by an
     * override. (eg: feeNumerator = 150 --> roaylty = 1.5%)
     * So fee is nftPrice*(feeNumerator/feeDenominator) where feeDenominator=10.000
     */
    function setRoyalty(address receiver, uint96 feeNumerator)
        external
        onlyOwner
    {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    /**
     * @inheritdoc ERC4907Extension
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC4907Extension, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
