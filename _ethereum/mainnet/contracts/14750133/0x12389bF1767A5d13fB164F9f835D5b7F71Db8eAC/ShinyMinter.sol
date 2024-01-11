// SPDX-License-Identifier: GPL-3.0

/// @title The Shiny Club Minter

/*********************************
 * ･ﾟ･ﾟ✧.・･ﾟshiny.club・✫・゜･ﾟ✧ *
 *********************************/

pragma solidity ^0.8.9;

import "./PausableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./IERC20.sol";
import "./IShinyMinter.sol";
import "./IShinySeeder.sol";
import "./IShinyToken.sol";
import "./IWETH.sol";


contract ShinyMinter is IShinyMinter, PausableUpgradeable, ReentrancyGuardUpgradeable, OwnableUpgradeable {
    // The ShinyClub ERC721 token contract
    IShinyToken public shinys;

    // Address of the ShinyDAO
    address public shinyDAO;

    // Where to send ETH used to purchse Shinies
    address public purchasePriceRecipient;

    // The address of the WETH contract
    address public weth;

    // The minimum price accepted for purchase
    uint256 public minimumPrice;

    // The total amount (in ETH) ever spent on Shinies
    uint256 public totalPurchasedAmount;

    // The cost (in wei) to reconfigure a Shiny
    uint256 public reconfigureCost;

    uint256 public constant CREATOR_PROCEEDS_LIMIT = 4206900000000000000000; // 4206.9 ETH

    /**
     * @notice Require that the sender is the purchasePriceRecipient.
     */
    modifier onlyShinyDAO() {
        require(_msgSender() == shinyDAO, 'ShinyMinter: Sender is not shinyDAO');
        _;
    }

    /**
     * @notice Require that the sender is the purchasePriceRecipient.
     */
    modifier onlyPurchasePriceRecipient() {
        require(_msgSender() == purchasePriceRecipient, 'ShinyMinter: Sender is not purchasePriceRecipient');
        _;
    }

    /**
     * @notice Initialize the minter and base contracts,
     * populate configuration values, and pause the contract.
     * @dev This function can only be called once.
     */
    function initialize(
        IShinyToken _shinys,
        address _shinyDAO,
        address _weth,
        uint256 _minimumPrice,
        uint256 _reconfigureCost,
        address _purchasePriceRecipient
    ) external initializer {
        __Pausable_init();
        __ReentrancyGuard_init();
        __Ownable_init();

        _pause();

        shinys = _shinys;
        shinyDAO = _shinyDAO;
        weth = _weth;
        minimumPrice = _minimumPrice;
        purchasePriceRecipient = _purchasePriceRecipient;
        reconfigureCost = _reconfigureCost;
        totalPurchasedAmount = 0;
    }

    function mint() external payable override whenNotPaused nonReentrant {
        // And amount is great than min amount
        require(msg.value >= minimumPrice, 'ShinyMinter: Must send at least minimumPrice');

        // Determine shiny chance?
        uint16 shinyChanceBasisPoints = 0;
        if (msg.value >= totalPurchasedAmount) {
            // Is gaurauntee Shiny
            shinyChanceBasisPoints = 10_000;
        } else {
            // Calc shiny chance and mint non-shiny
            // Eventually this will overflow...
            // ...but we'll all be long dead by then.
            shinyChanceBasisPoints = uint16((msg.value - minimumPrice) * 10_000 / (totalPurchasedAmount - minimumPrice));
        }
        // Update total amount spent & minimumAmount
        totalPurchasedAmount += msg.value;
        minimumPrice = totalPurchasedAmount / 10_000;

        // Mint via ShinyToken.sol
        uint256 tokenId = shinys.mint(_msgSender(), shinyChanceBasisPoints);

        address receiver = purchasePriceRecipient;
        // Send funds to ShinyDAO after limit is reached.
        if (totalPurchasedAmount > CREATOR_PROCEEDS_LIMIT) {
            receiver = shinyDAO;
        }
        _safeTransferETHWithFallback(receiver, msg.value);

        emit ShinyMinted(tokenId, _msgSender(), msg.value, shinyChanceBasisPoints);
    }

    /**
     * @notice Reconfigure a Shiny.
     * @dev This function can only be called by the shiny owner when the
     * contract is unpaused.
     */
    function reconfigureShiny(uint256 tokenId, IShinySeeder.Seed calldata newSeed) external payable override whenNotPaused returns (IShinySeeder.Seed memory) {
        require(shinys.ownerOf(tokenId) == _msgSender(), 'ShinyMinter: Caller is not token owner');
        require(msg.value == reconfigureCost, 'ShinyMinter: insufficinet reconfigure fee');

        _safeTransferETHWithFallback(shinyDAO, msg.value);
        return shinys.reconfigureShiny(tokenId, _msgSender(), newSeed);
    }

    /**
     * @notice Pause the Shiny Minter.
     * @dev This function can only be called by the owner when the
     * contract is unpaused.
     */
    function pause() external override onlyOwner {
        _pause();
    }

    /**
     * @notice Unpause the Shiny Minter.
     * @dev This function can only be called by the owner when the
     * contract is paused.
     */
    function unpause() external override onlyOwner {
        _unpause();
    }

    /**
     * @notice Update the reconfigureCost.
     * @dev This function can only be called by the ShinyDAO.
     */
    function updateReconfigureCost(uint256 newReconfigureCost) external override onlyShinyDAO {
        reconfigureCost = newReconfigureCost;
    }

    /**
     * @notice Update the purchasePriceRecipient.
     * @dev This function can only be called by the purchasePriceRecipient.
     */
    function updateShinyDAO(address newShinyDAO) external override onlyOwner {
        shinyDAO = newShinyDAO;
    }

    /**
     * @notice Update the purchasePriceRecipient.
     * @dev This function can only be called by the purchasePriceRecipient.
     */
    function updatePurchasePriceRecipient(address newRecipient) external override onlyPurchasePriceRecipient {
        purchasePriceRecipient = newRecipient;
    }

    /**
     * @notice Transfer ETH. If the ETH transfer fails, wrap the ETH and try send it as WETH.
     */
    function _safeTransferETHWithFallback(address to, uint256 amount) internal {
        if (!_safeTransferETH(to, amount)) {
            IWETH(weth).deposit{ value: amount }();
            IERC20(weth).transfer(to, amount);
        }
    }

    /**
     * @notice Transfer ETH and return the success status.
     * @dev This function only forwards 30,000 gas to the callee.
     */
    function _safeTransferETH(address to, uint256 value) internal returns (bool) {
        (bool success, ) = to.call{ value: value, gas: 30_000 }(new bytes(0));
        return success;
    }
}