// SPDX-License-Identifier: MIT

pragma solidity >=0.4.25 <0.7.0;

/** OpenZeppelin Dependencies */
// import "./Initializable.sol";
import "./SafeMathUpgradeable.sol";

/** Local Interfaces */
import "./IAuctionManager.sol";
import "./IAuction.sol";
import "./IToken.sol";
import "./IBPD.sol";

import "./Manageable.sol";

/**
Auction MANAGER should mint up to 250bln axion and most
Auction MANAGER should send 50bln to BPD over 5years
Auction MANAGER should send up to 200bln to auction
*/

contract AuctionManager is IAuctionManager, Initializable, Manageable {
    using SafeMathUpgradeable for uint256;

    /** Events */
    event SentToAuction (
        uint256 indexed auctionId,
        uint256 indexed amount
    );
    event SentToBPD (
        uint256 indexed amount
    );

    /** Structs */
    struct Addresses {
        address axion;
        address auction;
        address bpd;
    }
    /** Constants */
    uint256 public constant MAX_MINT = 250000000000;

    /** Variables */
    uint256 public mintedBPD;
    uint256 public mintedAuction;
    Addresses public addresses;

    /** Inits */
    function initialize(
        address _manager,
        address _axion,
        address _auction,
        address _bpd
    ) public initializer {
        _setupRole(MANAGER_ROLE, _manager);
        _setupRole(DEFAULT_ADMIN_ROLE, _manager);
        addresses.axion = _axion;
        addresses.bpd = _bpd;
        addresses.auction = _auction;
        mintedBPD = 0;
        mintedAuction = 0;
    }

    /** Main public manager functions */
    function sendToAuction(
        uint256 daysInFuture, 
        uint256 amount
    ) external onlyManager {
        _sendToAuction(daysInFuture, amount);
    }

    function sendToAuctions(
        uint256[] calldata daysInFuture,
        uint256[] calldata amounts
    ) external onlyManager {
        require(daysInFuture.length == amounts.length, "AUCTION MANAGER: Array lengths must be equal");

        for(uint256 i = 0; i < daysInFuture.length; i++) {
            _sendToAuction(daysInFuture[i], amounts[i]);
        }
    }

    function _sendToAuction(
        uint256 daysInFuture, 
        uint256 amount
    ) private {
        mintedAuction = mintedAuction.add(amount);
        require(mintedAuction.add(mintedBPD) <= MAX_MINT, "AUCTION MANAGER: Max mint has been reached");

        /** Mint the tokens send to Auction */
        uint256 actualAmount = amount.mul(1e18);
        IToken(addresses.axion).mint(addresses.auction, actualAmount);
        uint256 auctionId = IAuction(addresses.auction).addReservesToAuction(daysInFuture, actualAmount);

        emit SentToAuction(auctionId, amount);
    }

    /** Main public manager functions */
    function sendToBPD(uint256 amount) external onlyManager {
        mintedBPD = mintedBPD.add(amount);
        require(mintedBPD.add(mintedAuction) <= MAX_MINT, "AUCTION MANAGER: Max mint has been reached");

        /** Mint the tokens send to BPD */
        uint256 actualAmount = amount.mul(1e18);
        IToken(addresses.axion).mint(addresses.bpd, actualAmount);
        IBPD(addresses.bpd).callIncomeTokensTrigger(actualAmount);

        emit SentToBPD(amount);
    }
}