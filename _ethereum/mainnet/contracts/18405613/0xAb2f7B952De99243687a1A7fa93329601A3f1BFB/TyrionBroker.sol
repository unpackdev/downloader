// SPDX-License-Identifier: GPL
pragma solidity ^0.8.9;

import "./IERC20.sol";
import "./ERC20Burnable.sol";
import "./Counters.sol";
import "./Math.sol";
import "./ReentrancyGuard.sol";
import "./Initializable.sol";
import "./TransparentUpgradeableProxy.sol";
import "./OwnableUpgradeable.sol";
import "./TyrionRegistry.sol";
import "./Tyrion.sol";


contract TyrionBroker is OwnableUpgradeable {
    uint256 public advertiserPercentage;
    uint256 public burnPercentage;
    uint256 public referrerDepositPercentage;
    uint256 public publisherReferrerPercentage;
    uint256 public percentDivisor;

    address public treasuryWallet;
    Tyrion public tyrionToken;
    TyrionRegistry public registry;

    event Deposited(uint256 indexed advertiserId, uint256 amount);
    event WithdrawnPublisher(uint256 indexed publisherId, uint256 amount);
    event WithdrawnReferrer(uint256 indexed referrerId, uint256 amount);

    function initialize(address payable _tyrionTokenAddress, address _registryAddress) public initializer {
        advertiserPercentage = 700;
        burnPercentage = 20;
        referrerDepositPercentage = 25;
        publisherReferrerPercentage = 25;
        percentDivisor = 1000;

        treasuryWallet = msg.sender;
        tyrionToken = Tyrion(_tyrionTokenAddress);
        registry = TyrionRegistry(_registryAddress);

        __Ownable_init();
    }

    // TODO: Temporary fallback for migrations, to be removed in later versions
    function withdrawAllTokens() external onlyOwner {
        uint256 balance = tyrionToken.balanceOf(address(this));
        tyrionToken.transfer(msg.sender, balance);
    }

    function depositTokens(uint256 advertiserId, uint256 amount) external {
        require(tyrionToken.transferFrom(msg.sender, address(this), amount), "Transfer failed");

        uint256 advertiserAmount = (amount * advertiserPercentage) / percentDivisor;
        uint256 burnAmount = (amount * burnPercentage) / percentDivisor;
        uint256 referrerAmount = (amount * referrerDepositPercentage) / percentDivisor;
        // Reserves to be spent on referrer who referred the publisher who will display ads later on
        uint256 reservesAmount = (advertiserAmount * publisherReferrerPercentage) / percentDivisor;
        uint256 treasuryAmount = amount - advertiserAmount - burnAmount - referrerAmount - reservesAmount;

        tyrionToken.burn(burnAmount);
        tyrionToken.transfer(treasuryWallet, treasuryAmount);

        Advertiser memory advertiser = registry.getAdvertiserById(advertiserId);
        if (advertiser.referrer != 0) {
            registry.modifyReferrerBalance(advertiser.referrer, int256(referrerAmount));
        }

        registry.modifyAdvertiserBalance(advertiserId, int256(advertiserAmount));

        emit Deposited(advertiserId, amount);
    }

    // This function can be called from the server-side to credit publishers
    function creditPublisher(uint256 advertiserId, uint256 publisherId, uint256 amount) external onlyOwner {
        // Ensure the server's address is authorized
        Advertiser memory advertiser = registry.getAdvertiserById(advertiserId);

        require(amount <= advertiser.balance, "Insufficient balance in advertiser account");

        registry.modifyAdvertiserBalance(advertiserId, -int256(amount));
        registry.modifyPublisherBalance(publisherId, int256(amount));
    }

    function publisherWithdraw(uint256 publisherId, uint256 amount) external {
        Publisher memory publisher = registry.getPublisherById(publisherId);
        require(publisher.wallet == msg.sender, "Unauthorized");
        require(publisher.balance >= amount, "Insufficient balance");

        registry.modifyPublisherBalance(publisherId, -int256(amount));

        tyrionToken.transfer(publisher.wallet, amount);
        // Assuming each referrer has a unique ID and is mapped to their ID
        if (publisher.referrer != 0) {
            int256 referrerAmount = int256((amount * publisherReferrerPercentage) / percentDivisor);
            registry.modifyReferrerBalance(publisher.referrer, referrerAmount);
        }

        emit WithdrawnPublisher(publisherId, amount);
    }

    function referrerWithdraw(uint256 referrerId) external {
        Referrer memory referrer = registry.getReferrerById(referrerId);
        require(referrer.wallet == msg.sender, "Unauthorized");
        require(referrer.balance > 0, "No balance to withdraw");

        uint256 amount = referrer.balance;
        registry.modifyReferrerBalance(referrerId, -int256(amount));

        tyrionToken.transfer(referrer.wallet, amount);

        emit WithdrawnReferrer(referrerId, amount);
    }

    function setTreasuryWallet(address _treasuryWallet) external onlyOwner {
        treasuryWallet = _treasuryWallet;
    }

    function setPercentages(
        uint256 _advertiserPercentage,
        uint256 _burnPercentage,
        uint256 _referrerDepositPercentage,
        uint256 _publisherReferrerPercentage
    ) external onlyOwner {
        advertiserPercentage = _advertiserPercentage;
        burnPercentage = _burnPercentage;
        referrerDepositPercentage = _referrerDepositPercentage;
        publisherReferrerPercentage = _publisherReferrerPercentage;
    }
}
