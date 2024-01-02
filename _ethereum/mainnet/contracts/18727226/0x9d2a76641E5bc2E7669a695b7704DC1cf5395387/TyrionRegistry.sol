// SPDX-License-Identifier: GPL
pragma solidity ^0.8.9;

import "./IERC20.sol";
import "./ERC20Burnable.sol";
import "./Counters.sol";
import "./Math.sol";
import "./SafeMath.sol";
import "./ReentrancyGuard.sol";
import "./Initializable.sol";
import "./OwnableUpgradeable.sol";

struct Advertiser {
    uint256 id;
    address wallet;
    uint256 balance;
    address referrer;
}

struct Stake {
    uint256 amount;
    uint256 timestamp;
}

struct StakingPool {
    uint256 balance;
    mapping(address => Stake) stakes;
}

struct Publisher {
    uint256 id;
    address wallet;
    uint256 balance;
    address referrer;
//    StakingPool stakingPool;
}

struct Referrer {
    address wallet;
    uint256 balance;
}

contract TyrionRegistry is OwnableUpgradeable {
    using SafeMath for uint256;

    mapping(uint256 => Advertiser) public advertisers;
    mapping(uint256 => Publisher) public publishers;
    mapping(address => Referrer) public referrers;

    uint256 public nextAdvertiserId;
    uint256 public nextPublisherId;

    address public brokerAddress;

    event RegisteredAdvertiser(uint256 indexed advertiserId, address wallet, address indexed referrer);
    event RegisteredPublisher(uint256 indexed publisherId, address wallet, address indexed referrer);
    event RegisteredReferrer(address indexed referrerId);

    modifier onlyOwnerOrBroker() {
        require(owner() == _msgSender() || brokerAddress == _msgSender(), "Caller is not the owner or broker");
        _;
    }

    function initialize() public initializer {
        nextAdvertiserId = 1;
        nextPublisherId = 1;
        __Ownable_init();
    }

    function setBrokerAddress(address _brokerAddress) external onlyOwner {
        brokerAddress = _brokerAddress;
    }

    function registerAdvertiser(address advertiserWallet, address referrerId) external returns (uint256 advertiserId) {
        advertiserId = nextAdvertiserId;
        advertisers[advertiserId] = Advertiser({
            id: advertiserId,
            wallet: advertiserWallet,
            balance: 0,
            referrer: referrerId
        });

        emit RegisteredAdvertiser(advertiserId, advertiserWallet, referrerId);
        nextAdvertiserId++;
    }

    function registerPublisher(address publisherWallet, address referrerId) external returns (uint256 publisherId) {
        publisherId = nextPublisherId;
        publishers[publisherId] = Publisher({
            id: publisherId,
            wallet: publisherWallet,
            balance: 0,
            referrer: referrerId
        });

        emit RegisteredPublisher(publisherId, publisherWallet, referrerId);
        nextPublisherId++;
    }

    function registerReferrer(address referrerWallet) public {
        require(referrers[referrerWallet].wallet == address(0), "Referrer already registered");

        referrers[referrerWallet] = Referrer({
            wallet: referrerWallet, // Wallet can be changed
            balance: 0
        });

        emit RegisteredReferrer(referrerWallet);
    }

    function modifyPublisherBalance(uint256 publisherId, int256 delta) external onlyOwnerOrBroker {
        if (delta > 0) {
            publishers[publisherId].balance += uint256(delta);
        } else if (delta < 0) {
            publishers[publisherId].balance -= uint256(-delta);
        }
    }

    function modifyAdvertiserBalance(uint256 advertiserId, int256 delta) external onlyOwnerOrBroker {
        if (delta > 0) {
            advertisers[advertiserId].balance += uint256(delta);
        } else if (delta < 0) {
            advertisers[advertiserId].balance -= uint256(-delta);
        }
    }

    function modifyReferrerBalance(address referrerId, int256 delta) external onlyOwnerOrBroker {
        // If the referrer doesn't exist, let's register them
        if (referrers[referrerId].wallet == address(0))
            registerReferrer(referrerId);

        if (delta > 0) {
            referrers[referrerId].balance += uint256(delta);
        } else if (delta < 0) {
            referrers[referrerId].balance -= uint256(-delta);
        }
    }

    function getAdvertiserById(uint256 _advertiserId) external view returns (Advertiser memory) {
        return advertisers[_advertiserId];
    }

    function getPublisherById(uint256 _publisherId) external view returns (Publisher memory) {
        return publishers[_publisherId];
    }

    function getReferrerById(address _referrerId) external view returns (Referrer memory) {
        return referrers[_referrerId];
    }
}