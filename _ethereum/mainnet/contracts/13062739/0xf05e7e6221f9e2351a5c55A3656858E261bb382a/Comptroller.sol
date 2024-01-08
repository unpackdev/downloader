// SPDX-License-Identifier: Unlicense
pragma solidity 0.7.3;

import "./Initializable.sol";
import "./OwnableUpgradeable.sol";
import "./SafeMath.sol";
import "./ILiquidityPool.sol";
import "./IComptroller.sol";
import "./IMarket.sol";

/// @title Comptroller Hub Contract
/// @notice Handles the different collateral markets and integrates them with the Liquidity Pool
/// @dev Upgradeable Smart Contract
contract Comptroller is Initializable, OwnableUpgradeable, IComptroller {
    using SafeMath for uint256;

    address public liquidityPool;
    /// @notice Markets registered into this Comptroller
    address[] public markets;

    uint256 constant RATIOS = 1e16;
    uint256 constant FACTOR = 1e18;

    /// @dev  Helps to perform actions meant to be executed by the Liquidity Pool itself
    modifier onlyLiquidityPool() {
        require(msg.sender == liquidityPool, "You are not allowed to perform this action");
        _;
    }

    /// @notice Upgradeable smart contract constructor
    /// @dev Initializes this comptroller
    function initialize() external initializer {
        __Ownable_init();
    }

    /// @notice Allows the owner to add a new market into the protocol
    /// @param _market (address) Market's address
    function addMarket(address _market) external override onlyOwner {
        markets.push(_market);
    }

    /// @notice Owners can set the Liquidity Pool Address
    /// @param _liquidityPool (address) Liquidity Pool's address
    function setLiquidityPool(address _liquidityPool) external override onlyOwner {
        liquidityPool = _liquidityPool;
    }

    /// @notice Anyone can know how much a borrower can borrow from the Liquidity Pool in USDC terms
    /// @dev Despite the borrower can borrow 100% of this amount, it is recommended to borrow up to 80% to avoid risk of being liquidated
    /// @param _borrower (address) Borrower's address
    /// @return capacity (uint256) How much USDC the borrower can borrow from the Liquidity Pool
    function borrowingCapacity(address _borrower) public view override returns (uint256 capacity) {
        require(_borrower != address(0));
        for (uint256 i = 0; i < markets.length; i++) {
            capacity = capacity.add(IMarket(markets[i]).borrowingLimit(_borrower));
        }
    }

    /// @notice Tells how healthy a borrow is
    /// @dev If there is no current borrow 1e18 can be understood as infinite. Healt Ratios greater or equal to 100 are good. Below 100, indicates a borrow can be liquidated
    /// @param _borrower (address) Borrower's address
    /// @return  (uint256) Health Ratio Ex 102 can be understood as 102% or 1.02
    function getHealthRatio(address _borrower) external view override returns (uint256) {
        uint256 currentBorrow = ILiquidityPool(liquidityPool).updatedBorrowBy(_borrower);
        if (currentBorrow == 0) return FACTOR;
        return borrowingCapacity(_borrower).mul(1e2).div(currentBorrow);
    }

    /// @notice Sends as much collateral as needed to a liquidator that covered a debt on behalf of a borrower
    /// @dev This algorithm decides first on more stable markets (i.e. higher collateral factors), then on more volatile markets, till the amount paid by the liquidator is covered
    /// @dev The amount sent to be covered might not be covered at all. The execution ends on either amount covered or all markets processed
    /// @dev USDC here has nothing to do with the decimals the actual USDC smart contract has. Since it's a market, always assume 18 decimals
    /// @dev This function has a high gas consumption. In any case prefer to use sendCollateralToLiquidatorWithPreference. Use this one on extreme cases.
    /// @param _liquidator (address) Liquidator's address
    /// @param _borrower (address) Borrower's address
    /// @param _amount (uint256) Amount paid by the Liquidator in USDC terms at Liquidity Pool's side
    /// @return  (bool) Indicates a successful operation
    function sendCollateralToLiquidator(
        address _liquidator,
        address _borrower,
        uint256 _amount
    ) external override onlyLiquidityPool returns (bool) {
        require(_liquidator != address(0));
        require(_borrower != address(0));
        address[] memory localMarkets = markets;
        uint256 marketsProcessed;
        while (_amount > 0 && marketsProcessed < localMarkets.length) {
            uint256 maxIndex;
            uint256 maxCollateral;
            for (uint256 i = 0; i < localMarkets.length; i++) {
                if (
                    localMarkets[i] != address(0) &&
                    IMarket(localMarkets[i]).borrowingLimit(_borrower) > 0 &&
                    IMarket(localMarkets[i]).getCollateralFactor() > maxCollateral
                ) {
                    maxCollateral = IMarket(localMarkets[i]).getCollateralFactor();
                    maxIndex = i;
                }
            }
            uint256 borrowingLimit = IMarket(localMarkets[maxIndex]).borrowingLimit(_borrower);
            uint256 collateralFactor = maxCollateral.mul(RATIOS);
            delete localMarkets[maxIndex];
            uint256 collateral = borrowingLimit.mul(FACTOR).div(collateralFactor);
            uint256 toPay = (_amount >= collateral) ? collateral : _amount;
            _amount = _amount.sub(toPay);
            IMarket(markets[maxIndex]).sendCollateralToLiquidator(_liquidator, _borrower, toPay);
            marketsProcessed = marketsProcessed.add(1);
        }
    }

    /// @notice Sends as much collateral as needed to a liquidator that covered a debt on behalf of a borrower
    /// @dev Here the Liquidator have to tell the specific order in which they want to get collateral assets
    /// @param _liquidator (address) Liquidator's address
    /// @param _borrower (address) Borrower's address
    /// @param _amount (uint256) Amount paid by the Liquidator in USDC terms at Liquidity Pool's side
    /// @param _markets (address[]) Array of markets in their specific order to send collaterals to the liquidator
    /// @return  (bool) Indicates a successful operation
    function sendCollateralToLiquidatorWithPreference(
        address _liquidator,
        address _borrower,
        uint256 _amount,
        address[] memory _markets
    ) external override onlyLiquidityPool returns (bool) {
        for (uint256 i = 0; i < _markets.length; i++) {
            if (_amount == 0) break;
            uint256 borrowingLimit = IMarket(markets[i]).borrowingLimit(_borrower);
            if (borrowingLimit == 0) continue;
            uint256 collateralFactor = IMarket(markets[i]).getCollateralFactor().mul(RATIOS);
            uint256 collateral = borrowingLimit.mul(FACTOR).div(collateralFactor);
            uint256 toPay = (_amount >= collateral) ? collateral : _amount;
            _amount = _amount.sub(toPay);
            IMarket(_markets[i]).sendCollateralToLiquidator(_liquidator, _borrower, toPay);
        }
    }

    /// @notice Get the addresses of all the markets handled by this comptroller
    /// @return (address[] memory) The array with the addresses of all the markets handled by this comptroller
    function getAllMarkets() public view returns (address[] memory) {
        return markets;
    }

    /// @notice Sets the markets of this comptroller to an empty array
    /// @dev This function is executable only by the owner of this comptroller
    function resetMarkets() external onlyOwner {
        markets = new address[](0);
    }

    /// @notice Removes a specific market address from the markets this comptroller handles
    /// @dev This function consumes as much gas as markets are in this comptroller. It creates a new empty markets array and adds all but the specified market
    /// @dev This function is executable only by the owner of this comptroller
    function removeMarket(address _market) external onlyOwner {
        address[] memory currentMarkets = markets;
        markets = new address[](0);
        for (uint256 i = 0; i < currentMarkets.length; i++) {
            if (currentMarkets[i] == _market) continue;
            markets.push(currentMarkets[i]);
        }
    }
}
