// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.13;

import "./AggregatorV3Interface.sol";

import "./ERC20Burnable.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./Strings.sol";

import "./ERC721.sol";

/**
 * @title MintSchedule
 * @author 0xMekhu
 * @dev Mint schedule struct for keeping track of price, {cadence} (mints per schedule) and how many {rounds} occur
 * @notice
 */
struct MintSchedule {
    uint256 price;
    uint256 cadence;
    uint256 rounds;
}

/**
 * @title Recipient
 * @author 0xMekhu
 * @dev Used to keep track of airdrop recipients
 * @notice
 */
struct Recipient {
    uint256 tokenId;
    uint256 timestamp;
    address recipient;
    address referrer;
}

/**
 * @title PixelPups NFT
 * @author 0xMekhu
 * @notice A communtiy driven NFT project made for $SHIB token supporters
 */
contract ShibPixelPups is ERC721, Ownable, Pausable {
    using Counters for Counters.Counter;

    /// @notice Max supply of Pixel Pups
    uint256 public constant MAX_SUPPLY = 42069;

    uint256 public constant MINT_PRICE = 6500000000000000000000000;

    /// @notice Max number of price feeds for randomization
    uint256 private constant MAX_PRICE_FEEDS = 6;

    /// @notice Track current number of mints, starts with 1
    Counters.Counter private _mintCounter;

    /// @notice Track current mint schedules as minting progresses
    Counters.Counter private _mintScheduleCounter;

    /// @notice Tracks total mint schedules. Setup as a Counter to allow for dynamic progressive games.
    Counters.Counter private _totalMintScheduleCounter;

    /// @notice Tracks current round of current mint schedule
    Counters.Counter private _roundCounter;

    /// @notice Tracks total rounds completed
    Counters.Counter private _totalRoundCounter;

    /// @notice Tracks total existing price feeds
    Counters.Counter private _totalPriceFeedCounter;

    /// @notice Token contract for burning
    ERC20Burnable private _burnToken;
    address private _burnTokenAddress;

    mapping(uint256 => AggregatorV3Interface) private _priceFeeds;
    mapping(uint256 => MintSchedule) private _mintSchedules;

    /// @notice Keep track of selected recipients for each round
    mapping(uint256 => Recipient) private _recipients;

    /// @dev Referrers can only recieve commission one time per {tokenId}
    /// @notice Keep track of {tokenId} purchases that are purchased through PupPass referrals
    mapping(uint256 => address) private _referrers;

    /// @notice Owner controlled anti-cheat nonce
    uint256 private _antiCheatNonce = 1;

    /// @notice Community controlled anti-cheat nonce
    uint256 private _communityAntiCheatNonce = 1;

    constructor(address burnTokenAddress, address[] memory priceFeeds)
        ERC721("SHIB PIXEL PUPS", "SHIBPUPS")
    {
        /// @notice 69 {cadence} * 1 {rounds} = 69
        _addMintSchedule(MINT_PRICE, 69, 1);

        /// @notice 50 {cadence} * 840 {rounds} = 42,000 + 69 = 42,069 {MAX_SUPPLY}
        _addMintSchedule(MINT_PRICE, 50, 840);

        /// @notice Start minting at 1 to reduce gas fees for first minter
        _mintCounter.increment();

        _burnTokenAddress = burnTokenAddress;
        _burnToken = ERC20Burnable(_burnTokenAddress);

        /// @dev Duplicative but prevents extra gas wasted
        require(priceFeeds.length <= MAX_PRICE_FEEDS, "Max price feeds hit");
        for (uint256 i = 0; i < priceFeeds.length; i = _unsafeIncrement(i)) {
            _addPriceFeed(priceFeeds[i]);
        }
    }

    function _addMintSchedule(
        uint256 price,
        uint256 cadence,
        uint256 rounds
    ) private onlyOwner {
        _mintSchedules[_totalMintScheduleCounter.current()] = MintSchedule(
            price,
            cadence,
            rounds
        );
        _totalMintScheduleCounter.increment();
    }

    function _addPriceFeed(address priceFeedAddress) private onlyOwner {
        require(
            _totalPriceFeedCounter.current() < MAX_PRICE_FEEDS,
            "Max price feeds hit"
        );
        _priceFeeds[_totalPriceFeedCounter.current()] = AggregatorV3Interface(
            priceFeedAddress
        );
        (, int256 price, uint256 timestamp, , ) = _priceFeeds[
            _totalPriceFeedCounter.current()
        ].latestRoundData();
        require(price != 0, "Invalid AggregatorV3 address");
        _totalPriceFeedCounter.increment();
    }

    // #region Public views
    function getRecipientTokenByRound(uint256 index)
        public
        view
        returns (uint256)
    {
        return _recipients[index].tokenId;
    }

    function getRecipientAddressByRound(uint256 index)
        public
        view
        returns (address)
    {
        return _recipients[index].recipient;
    }

    function getRecipientInfoByRound(uint256 index)
        public
        view
        returns (Recipient memory)
    {
        return _recipients[index];
    }

    function getTotalCompletedRounds() public view returns (uint256) {
        return _totalRoundCounter.current();
    }

    function getTotalSchedules() public view returns (uint256) {
        return _totalMintScheduleCounter.current();
    }

    function totalSupply() public view returns (uint256) {
        return _mintCounter.current() - 1;
    }

    function getMintsRemaining() public view returns (uint256) {
        return MAX_SUPPLY - totalSupply();
    }

    function getCurrentSchedule() public view returns (uint256) {
        return _mintScheduleCounter.current();
    }

    function getCurrentPool() public view returns (uint256) {
        return getPoolByIndex(getCurrentSchedule());
    }

    function getPoolByIndex(uint256 index) public view returns (uint256) {
        return _mintSchedules[index].cadence * _mintSchedules[index].price;
    }

    // #endregion

    // #region Public mint methods
    function mint(uint256 count, address referrer)
        external
        whenNotPaused
        returns (uint256)
    {
        return _mintTo(msg.sender, count, referrer);
    }

    function gift(
        address receiver,
        uint256 count,
        address referrer
    ) external whenNotPaused returns (uint256) {
        return _mintTo(receiver, count, referrer);
    }

    // #endregion

    function _mintTo(
        address receiver,
        uint256 count,
        address referrer
    ) internal returns (uint256) {
        require(count > 0 && count <= 5, "Count must be between 1 and 5");
        require(totalSupply() <= MAX_SUPPLY, "MAX_SUPPLY hit");
        require(totalSupply() + count <= MAX_SUPPLY, "MAX_SUPPLY exceeded");

        uint256 total = _mintSchedules[getCurrentSchedule()].price * count;
        require(_burnToken.balanceOf(msg.sender) >= total, "Invalid balance");
        require(
            _burnToken.allowance(msg.sender, address(this)) >= total,
            "Invalid allowance"
        );
        _burnToken.transferFrom(msg.sender, address(this), total);

        // Burn half
        uint256 totalBurnAmount = (total * 40) / 100;
        _burnToken.burn(totalBurnAmount);

        for (uint256 i = 0; i < count; i = _unsafeIncrement(i)) {
            _safeMint(receiver, _mintCounter.current());

            if (referrer != address(0)) {
                _referrers[_mintCounter.current()] = referrer;
            }

            // New round, select recipient
            if (
                _mintScheduleCounter.current() <
                _totalMintScheduleCounter.current() &&
                (_mintCounter.current() - _sumCompletedRounds()) %
                    _mintSchedules[_mintScheduleCounter.current()].cadence ==
                0
            ) {
                uint256 selectedTokenId = _selectTokenId(
                    _mintCounter.current()
                );
                _recipients[_totalRoundCounter.current()] = Recipient(
                    selectedTokenId,
                    block.timestamp,
                    this.ownerOf(selectedTokenId),
                    _referrers[selectedTokenId]
                );

                uint256 currentPool = getCurrentPool();

                // Delete referrer for selected tokenId
                delete _referrers[selectedTokenId];

                // New MintSchedule
                if (
                    _roundCounter.current() ==
                    _mintSchedules[_mintScheduleCounter.current()].rounds - 1
                ) {
                    _mintScheduleCounter.increment();
                    _roundCounter.reset();
                } else {
                    _roundCounter.increment();
                }

                if (
                    _recipients[_totalRoundCounter.current()].referrer !=
                    address(0)
                ) {
                    // 40% of total * 85%
                    _burnToken.transfer(
                        _recipients[_totalRoundCounter.current()].recipient,
                        ((((currentPool * 40) / 100) * 85) / 100)
                    );
                    // 40% of total * 15%
                    _burnToken.transfer(
                        _recipients[_totalRoundCounter.current()].referrer,
                        ((((currentPool * 40) / 100) * 15) / 100)
                    );
                } else {
                    // 40% of total
                    _burnToken.transfer(
                        _recipients[_totalRoundCounter.current()].recipient,
                        ((currentPool * 40) / 100)
                    );
                }

                _totalRoundCounter.increment();
            }
            _mintCounter.increment();
        }
        return
            _totalRoundCounter.current() > 0
                ? _recipients[_totalRoundCounter.current() - 1].tokenId
                : 0;
    }

    function _sumCompletedRounds() private view returns (uint256) {
        uint256 aggregateTotal;
        if (_mintScheduleCounter.current() > 0) {
            for (
                uint256 i = 0;
                i < _mintScheduleCounter.current();
                i = _unsafeIncrement(i)
            ) {
                unchecked {
                    aggregateTotal =
                        aggregateTotal +
                        (_mintSchedules[i].cadence * _mintSchedules[i].rounds);
                }
            }
        }
        return aggregateTotal;
    }

    function _selectTokenId(uint256 maxValue) private view returns (uint256) {
        return (uint256((_random() % maxValue) + 1));
    }

    function _unsafeIncrement(uint256 x) private pure returns (uint256) {
        unchecked {
            return x + 1;
        }
    }

    function _random() private view returns (uint256) {
        (, int256 priceSeed0, uint256 timestampSeed0, , ) = _priceFeeds[
            (block.timestamp + block.number + gasleft()) %
                _totalPriceFeedCounter.current()
        ].latestRoundData();

        (, int256 priceSeed1, uint256 timestampSeed1, , ) = _priceFeeds[
            (block.timestamp + uint256(priceSeed0) + block.number + gasleft()) %
                _totalPriceFeedCounter.current()
        ].latestRoundData();

        uint256 seed = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp +
                        block.difficulty +
                        ((
                            uint256(keccak256(abi.encodePacked(block.coinbase)))
                        ) / (block.timestamp)) +
                        gasleft() +
                        _mintCounter.current() +
                        ((uint256(priceSeed0) * timestampSeed1) /
                            (block.timestamp)) +
                        ((uint256(priceSeed1) * timestampSeed0) /
                            (block.timestamp)) +
                        ((uint256(priceSeed0) * _antiCheatNonce) /
                            (block.timestamp)) +
                        ((uint256(priceSeed1) * _communityAntiCheatNonce) /
                            (block.timestamp)) +
                        ((timestampSeed1 * _antiCheatNonce) /
                            (block.timestamp)) +
                        ((timestampSeed0 * _communityAntiCheatNonce) /
                            (block.timestamp)) +
                        ((uint256(keccak256(abi.encodePacked(msg.sender)))) /
                            (block.timestamp)) +
                        block.number
                )
            )
        );
        return (seed - (seed / _mintCounter.current()));
    }

    // #region Anti-cheat functionality
    function setAntiCheatNonce(uint256 nonce) external onlyOwner {
        require(totalSupply() != MAX_SUPPLY, "Max supply hit");
        require(nonce > 0, "Nonce must be greater than zero");
        _antiCheatNonce = nonce;
    }

    function setCommunityAntiCheatNonce(uint256 nonce) external {
        require(totalSupply() != MAX_SUPPLY, "Max supply hit");
        require(
            _mintCounter.current() %
                _mintSchedules[_mintScheduleCounter.current()].cadence <
                _mintSchedules[_mintScheduleCounter.current()].cadence - 10,
            "Too close to round end"
        );
        require(nonce > 0, "Nonce must be greater than zero");
        _communityAntiCheatNonce = nonce;
    }

    // #endregion

    // #region Locking functionality
    function lock() external onlyOwner {
        _pause();
    }

    function unlock() external onlyOwner {
        _unpause();
    }

    // #endregion

    // #region Withdrawal functions
    function withdraw() external onlyOwner {
        (bool success, ) = owner().call{value: address(this).balance}("");
        require(success, "Withdraw failed");
    }

    function withdrawBurnToken() external onlyOwner {
        require(
            _burnToken.balanceOf(address(this)) > 0,
            "Insufficient balance"
        );

        /// @dev Calculate the current round pool to prevent community funds inadvertantly being pulled out by owner
        uint256 reserved = totalSupply() < MAX_SUPPLY
            ? ((totalSupply() - _sumCompletedRounds()) *
                _mintSchedules[getCurrentSchedule()].price *
                80) / 100
            : 0;

        require(
            _burnToken.balanceOf(address(this)) > reserved,
            "Balance must be greater than reserved balance"
        );

        bool success = _burnToken.transfer(
            address(owner()),
            _burnToken.balanceOf(address(this)) - reserved
        );

        require(success, "Withdraw failed");
    }

    function withdrawERC20(address tokenContract) external onlyOwner {
        require(
            address(tokenContract) != address(_burnTokenAddress),
            "Cannot withdraw burn token from this method"
        );
        bool success = IERC20(tokenContract).transfer(
            address(owner()),
            IERC20(tokenContract).balanceOf(address(this))
        );
        require(success, "Withdraw failed");
    }

    // #endregion

    function baseTokenURI() public pure returns (string memory) {
        return "https://pixelpups-api.shibtoken.art/api/traits/";
    }

    function tokenURI(uint256 _tokenId)
        public
        pure
        override
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(baseTokenURI(), Strings.toString(_tokenId))
            );
    }
}
