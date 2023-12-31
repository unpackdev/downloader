// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./WaterCommonStorage.sol";
import "./IERC20MetadataUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./PausableUpgradeable.sol";

import "./ICustomOracle.sol";
import "./IBeanstalkUpgradeable.sol";
import "./SprinklerStorage.sol";
import "./TransferHelper.sol";
import "./EIP2535Initializable.sol";
import "./IrrigationAccessControl.sol";
import "./Constants.sol";
import "./ISprinklerUpgradeable.sol";
import "./IPriceOracleUpgradeable.sol";

contract SprinklerUpgradeable is
    EIP2535Initializable,
    IrrigationAccessControl,
    ISprinklerUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable
{
    using SprinklerStorage for SprinklerStorage.Layout;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    /// @dev errors
    error InsufficientWater();
    error InvalidSwapToken();
    error InvalidAmount();
    error ZeroWaterOut();
    error ExistingAsset();
    error NoWaterWithdraw();
    error NoSprinklerWhitelist();
    error NoWithdrawEther();

    /// @dev admin setters
    /**
     * @notice Set token decimals to calculate correct water amount
     * @param _token underlying token address
     * @param _multiplier price oracle address
     */
    function setTokenMultiplier(address _token, uint256 _multiplier) external onlyAdminRole {
        SprinklerStorage.layout().whitelistAssets[_token].tokenMultiplier = _multiplier;
    }

    /**
     * @notice add asset to whitelist
     * @param _token underlying token address
     * @param _multiplier token multiplier, if this is 0, multiplier is calculated from decimals of token
     */
    function addAssetToWhiteList(address _token, uint256 _multiplier) external onlyAdminRole {
        if (SprinklerStorage.layout().whitelistAssets[_token].tokenMultiplier != 0)
            revert ExistingAsset();

        uint256 _tokenMultiplier;
        // decimals of water is 18, and it is same as ether decimals
        if (_token == Constants.ETHER) _tokenMultiplier = 1;
        else
            _tokenMultiplier = _multiplier != 0
                ? _multiplier
                : 10 ** (Constants.WATER_DECIMALS - IERC20MetadataUpgradeable(_token).decimals());
        WhitelistAsset memory newAsset = WhitelistAsset(_tokenMultiplier, true);
        SprinklerStorage.layout().whitelistAssets[_token] = newAsset;
        SprinklerStorage.layout().allWhiteList.push(_token);
        emit AddWhiteListAsset(_token, _tokenMultiplier);
    }

    /**
     * @notice pause exchanging
     */

    function unListAsset(address _token) external onlyAdminRole {
        SprinklerStorage.layout().whitelistAssets[_token].isListed = false;
        emit UnListAsset(_token);
    }

    /**
     * @notice Exchange whitelisted asset(BEAN, BEAN:3CRV, Spot, and so on) to water
     * @param token source token address
     * @param amount source token amount
     * @return waterAmount received water amount
     */
    function exchangeTokenToWater(
        address token,
        uint256 amount
    ) external onlyListedAsset(token) nonReentrant whenNotPaused returns (uint256 waterAmount) {
        if (token == address(this) || token == Constants.ETHER) revert InvalidSwapToken();
        if (amount == 0) revert InvalidAmount();

        waterAmount = getWaterAmount(token, amount);
        if (waterAmount > sprinkleableWater()) revert InsufficientWater();
        if (waterAmount == 0) revert ZeroWaterOut();

        IERC20Upgradeable(token).safeTransferFrom(msg.sender, address(this), amount);
        transferWater(waterAmount);
        SprinklerStorage.layout().reserves[token] += amount;
        emit WaterExchanged(msg.sender, token, amount, waterAmount, false);
    }

    /**
     * @notice Exchange ETH to water
     * @return waterAmount received water amount
     */
    function exchangeETHToWater()
        external
        payable
        onlyListedAsset(Constants.ETHER)
        nonReentrant
        whenNotPaused
        returns (uint256 waterAmount)
    {
        if (msg.value == 0) revert InvalidAmount();
        waterAmount = getWaterAmount(Constants.ETHER, msg.value);
        if (waterAmount > sprinkleableWater()) revert InsufficientWater();
        if (waterAmount == 0) revert ZeroWaterOut(); // if price is 0 or tokenMultiplier is 0, amount can be 0
        transferWater(waterAmount);
        SprinklerStorage.layout().reserves[Constants.ETHER] += msg.value;
        emit WaterExchanged(msg.sender, Constants.ETHER, msg.value, waterAmount, false);
    }

    function depositWater(uint256 amount) external {
        if (amount == 0) revert InvalidAmount();
        IERC20Upgradeable(address(this)).transferFrom(msg.sender, address(this), amount);
        SprinklerStorage.layout().availableWater += amount;
        emit DepositWater(amount);
    }

    /// internal functions
    function transferWater(uint256 amount) internal {
        SprinklerStorage.layout().availableWater -= amount;
        IERC20Upgradeable(address(this)).transfer(msg.sender, amount);
    }

    /// admin functions

    /// @notice withdraw external tokens that users swapped for Water
    /// @param token token address
    /// @param to destination address
    /// @param amount token amount
    function withdrawToken(address token, address to, uint256 amount) external onlyAdminRole {
        /// @dev can't withdraw water token
        if (token == address(this)) revert NoWaterWithdraw();
        if (token == Constants.ETHER) {
            (bool success, ) = to.call{value: amount}(new bytes(0));
            if (!success) revert NoWithdrawEther();
        } else {
            IERC20Upgradeable(token).safeTransfer(to, amount);
        }
        if (SprinklerStorage.layout().whitelistAssets[token].isListed)
            SprinklerStorage.layout().reserves[token] -= amount;
        emit WithdrawToken(token, msg.sender, amount);
    }

    /// getters
    ///
    /// @notice Get amount of water to exchange whitelisted asset(BEAN, ROOT, Spot, and so on)
    /// @param _token source token address
    /// @param _amount source token amount
    /// @return waterAmount received water amount
    ///
    function getWaterAmount(
        address _token,
        uint256 _amount
    ) public view returns (uint256 waterAmount) {
        uint256 multiplier = tokenMultiplier(_token);
        uint256 tokenPrice = IPriceOracleUpgradeable(address(this)).getPrice(_token);
        uint256 waterPrice = IPriceOracleUpgradeable(address(this)).getWaterPrice();
        waterAmount = (_amount * tokenPrice * multiplier) / waterPrice;
    }

    /// @notice get whitelisted token addresses
    function getWhitelist() external view returns (address[] memory) {
        return SprinklerStorage.layout().allWhiteList;
    }

    /// @notice get token multiplier
    function tokenMultiplier(address _token) public view returns (uint256) {
        return SprinklerStorage.layout().whitelistAssets[_token].tokenMultiplier;
    }

    /// @notice get water amount available for sprinkler
    function sprinkleableWater() public view returns (uint256) {
        return SprinklerStorage.layout().availableWater;
    }

    function getReserveToken(address token) external view returns (uint256) {
        return SprinklerStorage.layout().reserves[token];
    }

    modifier onlyListedAsset(address _token) {
        if (!SprinklerStorage.layout().whitelistAssets[_token].isListed)
            revert NoSprinklerWhitelist();
        _;
    }
}
