// SPDX-License-Identifier: Unlicense
pragma solidity 0.7.3;

import "./Initializable.sol";
import "./OwnableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./IMarket.sol";
import "./IComptroller.sol";
import "./Price.sol";
import "./BlockLock.sol";

/// @title Market Asset Holder
/// @notice Registers the xAssets as collaterals put into the protocol by each borrower
/// @dev There should be as many markets as collaterals the admins want for the protocol
contract Market is Initializable, OwnableUpgradeable, BlockLock, PausableUpgradeable, IMarket {
    using SafeMath for uint256;

    address private assetPriceAddress;
    address private comptroller;
    uint256 private collateralFactor;
    uint256 private collateralCap;
    /// @notice Tells if the market is active for borrowers to collateralize their assets
    bool public marketActive;

    uint256 constant FACTOR = 1e18;
    uint256 constant PRICE_DECIMALS_CORRECTION = 1e12;
    uint256 constant RATIOS = 1e16;

    mapping(address => uint256) collaterals;

    /// @dev Allows only comptroller to perform specific functions
    modifier onlyComptroller() {
        require(msg.sender == comptroller, "You are not allowed to perform this action");
        _;
    }

    /// @notice Upgradeable smart contract constructor
    /// @dev Initializes this collateral market
    /// @param _assetPriceAddress (address) The xAsset Price address
    /// @param _collateralFactor (uint256) collateral factor for this market Ex. 35% should be entered as 35
    /// @param _collateralCap (uint256) collateral cap for this market  Ex. 120e18 must be understood as 120 xKNC or xINCH
    function initialize(
        address _assetPriceAddress,
        uint256 _collateralFactor,
        uint256 _collateralCap
    ) external initializer {
        require(_assetPriceAddress != address(0));
        __Ownable_init();
        __Pausable_init_unchained();

        assetPriceAddress = _assetPriceAddress;
        collateralFactor = _collateralFactor.mul(RATIOS);
        collateralCap = _collateralCap;
        marketActive = true;
    }

    /// @notice Returns the registered collateral factor
    /// @return  (uint256) collateral factor for this market Ex. 35 must be understood as 35%
    function getCollateralFactor() external view override returns (uint256) {
        return collateralFactor.div(RATIOS);
    }

    /// @notice Allows only owners of this market to set a new collateral factor
    /// @param _collateralFactor (uint256) collateral factor for this market Ex. 35% should be entered as 35
    function setCollateralFactor(uint256 _collateralFactor) external override onlyOwner {
        collateralFactor = _collateralFactor.mul(RATIOS);
    }

    /// @notice Returns the registered collateral cap
    /// @return  (uint256) collateral cap for this market
    function getCollateralCap() external view override returns (uint256) {
        return collateralCap;
    }

    /// @notice Allows only owners of this market to set a new collateral cap
    /// @param _collateralCap (uint256) collateral factor for this market
    function setCollateralCap(uint256 _collateralCap) external override onlyOwner {
        collateralCap = _collateralCap;
    }

    /// @notice Owner function: pause all user actions
    function pauseContract() external onlyOwner returns (bool) {
        _pause();
        return true;
    }

    /// @notice Owner function: unpause
    function unpauseContract() external onlyOwner returns (bool) {
        _unpause();
        return true;
    }

    /// @notice Borrowers can collateralize their assets using this function
    /// @dev The amount is meant to hold underlying assets tokens Ex. 120e18 must be understood as 120 xKNC or xINCH
    /// @param _amount (uint256) underlying tokens to be collateralized
    function collateralize(uint256 _amount) external override notLocked(msg.sender) whenNotPaused {
        require(marketActive, "This market is not active now, you can not perform this action");
        require(
            IERC20(Price(assetPriceAddress).underlyingAssetAddress()).balanceOf(address(this)).add(_amount) <=
                collateralCap,
            "You reached the maximum cap for this market"
        );
        lock(msg.sender);

        IERC20(Price(assetPriceAddress).underlyingAssetAddress()).transferFrom(msg.sender, address(this), _amount);
        collaterals[msg.sender] = collaterals[msg.sender].add(_amount);
    }

    /// @notice Borrowers can fetch how many underlying asset tokens they have collateralized
    /// @return  (uint256) underlying asset tokens collateralized by the borrower
    function collateral(address _borrower) public view override returns (uint256) {
        return collaterals[_borrower];
    }

    /// @notice Borrowers can know how much they can borrow in USDC terms according to the oracles prices for their collaterals
    /// @return (uint256) amount of USDC tokens that the borrower has access to
    function myBorrowingLimit(address _borrower) public view override returns (uint256) {
        return borrowingLimit(_borrower);
    }

    /// @notice Anyone can know how much a borrower can borrow in USDC terms according to the oracles prices for their collaterals
    /// @dev USDC here has nothing to do with the decimals the actual USDC smart contract has. Since it's a market, always assume 18 decimals
    /// @param _borrower (address) borrower's address
    /// @return  (uint256) amount of USDC tokens that the borrower has access to
    function borrowingLimit(address _borrower) public view override returns (uint256) {
        uint256 assetValueInUSDC = Price(assetPriceAddress).getPrice(); // Price has 12 decimals
        return
            collaterals[_borrower].mul(assetValueInUSDC).div(PRICE_DECIMALS_CORRECTION).mul(collateralFactor).div(
                FACTOR
            );
    }

    /// @notice Owners of this market can tell which comptroller is managing this market
    /// @dev Several interactions between liquidity pool and markets are handled by the comptroller
    /// @param _comptroller (address) comptroller's address
    function setComptroller(address _comptroller) external override onlyOwner {
        require(_comptroller != address(0));
        comptroller = _comptroller;
    }

    /// @notice Owners can decide wheather or not this market allows borrowers to collateralize
    /// @dev True is an active market, false is an inactive market
    /// @param _active (bool) flag indicating the market active state
    function setCollateralizationActive(bool _active) external override onlyOwner {
        marketActive = _active;
    }

    /// @notice Sends tokens from a borrower to a liquidator upon liquidation
    /// @dev This action is triggered by the comptroller
    /// @param _liquidator (address) liquidator's address
    /// @param _borrower (address) borrower's address
    /// @param _amount (uint256) amount in USDC terms to be transferred to the liquidator
    function sendCollateralToLiquidator(
        address _liquidator,
        address _borrower,
        uint256 _amount
    ) external override onlyComptroller {
        uint256 tokens = _amount.mul(PRICE_DECIMALS_CORRECTION).div(Price(assetPriceAddress).getPrice());

        collaterals[_borrower] = collaterals[_borrower].sub(tokens);
        IERC20(Price(assetPriceAddress).underlyingAssetAddress()).transfer(_liquidator, tokens);
    }

    /// @notice Borrowers can withdraw their collateral assets
    /// @dev Borrowers can only withdraw their collaterals if they have enough tokens and there is no active loan
    /// @param _amount (uint256) underlying tokens to be withdrawn
    function withdraw(uint256 _amount) external notLocked(msg.sender) whenNotPaused {
        require(collaterals[msg.sender] >= _amount, "You have not collateralized that much");
        require(
            IComptroller(comptroller).getHealthRatio(msg.sender) == FACTOR,
            "You can not withdraw your collateral while having an active loan"
        );
        lock(msg.sender);
        collaterals[msg.sender] = collaterals[msg.sender].sub(_amount);
        IERC20(Price(assetPriceAddress).underlyingAssetAddress()).transfer(msg.sender, _amount);
    }
}
