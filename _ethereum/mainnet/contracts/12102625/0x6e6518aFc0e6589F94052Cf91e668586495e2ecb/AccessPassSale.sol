//SPDX-License-Identifier: Unlicense
pragma solidity ^0.6.2;

import "./SafeMath.sol";
import "./AccessControl.sol";
import "./Stars.sol";

contract AccessPassSale is AccessControl {
    using SafeMath for uint256;

    bytes32 public constant ROLE_ADMIN = keccak256("ROLE_ADMIN");
    address payable public withdrawWallet;

    Stars stars;

    struct Tier {
        uint256 numPasses;
        uint256 passPrice;
        uint256 starsPerPass;
        bool paused;
    }

    mapping(uint8 => Tier) public tiers;

    event tierSet(
        uint8 tierNumber,
        uint256 numPasses,
        uint256 passPrice,
        uint256 starsPerPass
    );
    event tierPaused(uint8 tierNumber, bool pauseStatus);
    event tierPurchased(uint8 tierNumber);

    modifier onlyAdmin {
        require(hasRole(ROLE_ADMIN, msg.sender), "Sender is not admin");
        _;
    }

    /**
     * @dev Stores the addresses of the withdraw wallet and the first admin,
     * and stores the Stars contract. Allows users with the admin role to
     * grant/revoke the admin role from other users.
     *
     * Params:
     * _withdrawWallet: the address of the wallet that will receive the excess
     * stars when tiers are reduced or removed, and receive ether when ether is
     * withdrawn
     * starsAddress: the address of the Stars contract
     * _admin: the address of the first admin
     */
    constructor(
        address payable _withdrawWallet,
        address starsAddress,
        address _admin
    ) public {
        withdrawWallet = _withdrawWallet;

        _setupRole(ROLE_ADMIN, _admin);
        _setRoleAdmin(ROLE_ADMIN, ROLE_ADMIN);

        stars = Stars(starsAddress);
    }

    /**
     * @dev Sets the withdraw wallet
     *
     * Params:
     * _withdrawWallet: the address of the withdraw wallet
     *
     * Requirements:
     * Sender is admin
     */
    function setWithdrawWallet(address payable _withdrawWallet)
        public
        onlyAdmin
    {
        withdrawWallet = _withdrawWallet;
    }

    /**
     * @dev Sets up the initial tiers to allow for the sale of 16 million Stars.
     * Transfers the required 16 million stars from the sender.
     *
     * Requirements:
     * Sender is admin
     * Sender has 16 million Stars
     * Contract is approved to transfer 16 million Stars from user
     * Tiers 1-5 contain no passes
     */
    function initTiers() public onlyAdmin {
        for (uint8 i = 0; i <= 5; i++) {
            require(tiers[i].numPasses == 0, "Tiers 1-5 are not empty");
        }
        stars.transferFrom(msg.sender, address(this), 128250000 ether);
        tiers[4] = Tier(12, 50 ether, 2000000 ether, false);
        tiers[3] = Tier(92, 25 ether, 500000 ether, false);
        tiers[2] = Tier(241, 10 ether, 100000 ether, false);
        tiers[1] = Tier(1830, 1 ether, 5000 ether, false);
        tiers[0] = Tier(25000000, 0.0003 ether, 1 ether, false);
    }

    /**
     * @dev Changes the specified tier. If the change allows for the sale of
     * more Stars than previously, the contract transfers the extra Stars
     * required from the sender. If the change allows for fewer Stars than
     * previously, the contract transfers its excess Stars to the sender.
     *
     * Params:
     * tierNumber: The number that identifies the tier to change
     * numPasses: The new number of passes to be sold in the tier
     * passPrice: The new price of a purchase from the tier
     * starsPerPass: The new number of stars that this tier grants upon purchase
     *
     * Requirements:
     * Sender is admin
     * If the change allows for the sale of more stars, the sender has the
     * required extra Stars, and the contract is approved to transfer those
     * Stars
     */
    function setTier(
        uint8 tierNumber,
        uint256 numPasses,
        uint256 passPrice,
        uint256 starsPerPass
    ) public onlyAdmin {
        Tier storage selected = tiers[tierNumber];
        uint256 newAmount = starsPerPass.mul(numPasses);
        uint256 currAmount = selected.starsPerPass.mul(selected.numPasses);

        if (newAmount > currAmount) {
            stars.transferFrom(
                msg.sender,
                address(this),
                newAmount.sub(currAmount)
            );
        } else if (newAmount < currAmount) {
            stars.transfer(msg.sender, currAmount.sub(newAmount));
        }

        tiers[tierNumber] = Tier(numPasses, passPrice, starsPerPass, false);

        emit tierSet(tierNumber, numPasses, passPrice, starsPerPass);
    }

    /**
     * @dev Sends users the appropriate number of Stars upon purchase, and
     * reduces the number of passes in the specified tier accordingly
     *
     * Params:
     * tierNumber: The number that identifies the tier to purchase from
     *
     * Requirements:
     * The transaction value is equal to the price of the specified tier
     * The tier contains more than 0 passes
     * The tier is not paused
     */
    function purchase(uint8 tierNumber) public payable {
        Tier storage purchaseTier = tiers[tierNumber];

        require(
            msg.value.mod(purchaseTier.passPrice) == 0,
            "Incorrect transaction value"
        );
        uint256 passesToBuy = msg.value.div(purchaseTier.passPrice);
        require(purchaseTier.numPasses >= passesToBuy, "Not enough passes");
        require(
            !purchaseTier.paused,
            "Purchases from this tier have been paused"
        );

        stars.transfer(msg.sender, purchaseTier.starsPerPass.mul(passesToBuy));
        purchaseTier.numPasses -= passesToBuy;

        emit tierPurchased(tierNumber);
    }

    /**
     * @dev Sets the pause status of the specified tiers
     *
     * Params:
     * tierNumbers: The list of numbers to identify the tiers to change
     * pauseStatus: The boolean value to set the pause status of specified tiers
     *
     * Requirements:
     * Sender is admin
     */
    function setTiersPauseStatus(uint8[] memory tierNumbers, bool pauseStatus)
        public
        onlyAdmin
    {
        for (uint256 i = 0; i < tierNumbers.length; i++) {
            tiers[tierNumbers[i]].paused = pauseStatus;
            emit tierPaused(tierNumbers[i], pauseStatus);
        }
    }

    /**
     * @dev Sends all the ether in the contract to the withdraw wallet
     *
     * Requirements:
     * Sender is admin
     */
    function withdrawETH() public onlyAdmin {
        withdrawWallet.transfer(address(this).balance);
    }

    /**
     * @dev Reduces the number of passes from specified tiers, and sends the
     * excess Stars the contract now has to the withdraw wallet
     *
     * Params:
     * tierNumbers: The list of numbers to identify the tiers to reduce
     * passAmounts: The number of passes to remove from each tier
     *
     * Requirements:
     * Sender is admin
     */
    function reducePassesFromTiers(
        uint8[] memory tierNumbers,
        uint256[] memory passAmounts
    ) public onlyAdmin {
        uint256 withdrawAmount = 0;

        for (uint8 i = 0; i < tierNumbers.length; i++) {
            Tier storage selected = tiers[tierNumbers[i]];
            require(passAmounts[i] <= selected.numPasses, "Not enough passes");
            withdrawAmount += passAmounts[i].mul(selected.starsPerPass);
            selected.numPasses -= passAmounts[i];
        }

        stars.transfer(withdrawWallet, withdrawAmount);
    }

    /**
     * @dev Removes all passes from specified tiers, and sends the excess Stars
     * the contract now has to the withdraw wallet
     *
     * Params:
     * tierNumbers: The list of numbers to identify the tiers to remove
     *
     * Requirements:
     * Sender is admin
     */
    function removeTiers(uint8[] memory tierNumbers) public onlyAdmin {
        uint256 amount = 0;
        for (uint8 i = 0; i < tierNumbers.length; i++) {
            amount += tiers[tierNumbers[i]].numPasses.mul(
                tiers[tierNumbers[i]].starsPerPass
            );
            tiers[tierNumbers[i]].numPasses = 0;
        }

        stars.transfer(withdrawWallet, amount);
    }
}
