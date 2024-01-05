// SPDX-License-Identifier: MIT

pragma solidity >=0.4.25 <0.7.0;
/** OpenZeppelin Dependencies Upgradeable */
// import "./Initializable.sol";
import "./SafeMathUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./ERC20Upgradeable.sol";
/** OpenZepplin non-upgradeable Swap Token (hex3t) */
import "./IERC20.sol";
/** Local Interfaces */
import "./Auction.sol";

contract AuctionRestorable is Auction {
    function init(
        uint256 _stepTimestamp,
        address _mainTokenAddress,
        address _stakingAddress,
        address payable _uniswapAddress,
        address payable _recipientAddress,
        address _nativeSwapAddress,
        address _auctionV1Address
    ) external onlyMigrator {
        require(!init_, 'Init is active');
        init_ = true;
        /** Roles */
        _setupRole(CALLER_ROLE, _nativeSwapAddress);
        _setupRole(CALLER_ROLE, _stakingAddress);

        // Timer
        if (start == 0) {
            start = now;
        }

        stepTimestamp = _stepTimestamp;

        // Options
        options = Options({
            autoStakeDays: 14,
            referrerPercent: 20,
            referredPercent: 10,
            referralsOn: true,
            discountPercent: 20,
            premiumPercent: 0
        });

        // Addresses
        auctionV1 = IAuctionV1(_auctionV1Address);
        addresses = Addresses({
            mainToken: _mainTokenAddress,
            staking: _stakingAddress,
            uniswap: _uniswapAddress,
            recipient: _recipientAddress
        });
    }

    /** Setter methods for contract migration */
    function setNormalVariables(uint256 _lastAuctionEventId, uint256 _start)
        external
        onlyMigrator
    {
        start = _start;
        lastAuctionEventId = _lastAuctionEventId;
        lastAuctionEventIdV1 = _lastAuctionEventId;
    }

    /** TESTING ONLY */
    function setLastSessionId(uint256 _lastSessionId) external onlyMigrator {
        lastAuctionEventIdV1 = _lastSessionId.sub(1);
        lastAuctionEventId = _lastSessionId;
    }

    function setReservesOf(
        uint256[] calldata sessionIds,
        uint256[] calldata eths,
        uint256[] calldata tokens,
        uint256[] calldata uniswapLastPrices,
        uint256[] calldata uniswapMiddlePrices
    ) external onlyMigrator {
        for (uint256 i = 0; i < sessionIds.length; i = i.add(1)) {
            reservesOf[sessionIds[i]] = AuctionReserves({
                eth: eths[i],
                token: tokens[i],
                uniswapLastPrice: uniswapLastPrices[i],
                uniswapMiddlePrice: uniswapMiddlePrices[i]
            });
        }
    }

    function setAuctionsOf(
        address[] calldata _userAddresses,
        uint256[] calldata _sessionPerAddressCounts,
        uint256[] calldata _sessionIds
    ) external onlyMigrator {
        uint256 sessionIdIdx = 0;
        for (uint256 i = 0; i < _userAddresses.length; i = i + 1) {
            address userAddress = _userAddresses[i];
            uint256 sessionCount = _sessionPerAddressCounts[i];
            uint256[] memory sessionIds = new uint256[](sessionCount);
            for (uint256 j = 0; j < sessionCount; j = j + 1) {
                sessionIds[j] = _sessionIds[sessionIdIdx];
                sessionIdIdx = sessionIdIdx + 1;
            }
            auctionsOf[userAddress] = sessionIds;
        }
    }

    function setAuctionBidOf(
        uint256 sessionId,
        address[] calldata userAddresses,
        uint256[] calldata eths,
        address[] calldata refs
    ) external onlyMigrator {
        for (uint256 i = 0; i < userAddresses.length; i = i.add(1)) {
            auctionBidOf[sessionId][userAddresses[i]] = UserBid({
                eth: eths[i],
                ref: refs[i],
                withdrawn: false
            });
        }
    }

    function setExistAuctionsOf(
        uint256 sessionId,
        address[] calldata userAddresses,
        bool[] calldata exists
    ) external onlyMigrator {
        for (uint256 i = 0; i < userAddresses.length; i = i.add(1)) {
            existAuctionsOf[sessionId][userAddresses[i]] = exists[i];
        }
    }
}
