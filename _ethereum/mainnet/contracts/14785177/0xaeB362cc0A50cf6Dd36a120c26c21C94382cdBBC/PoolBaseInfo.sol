// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./ERC20Upgradeable.sol";
import "./IPoolFactory.sol";
import "./IInterestRateModel.sol";

abstract contract PoolBaseInfo is ERC20Upgradeable {
    /// @notice Address of the pool's manager
    address public manager;

    /// @notice Pool currency token
    IERC20Upgradeable public currency;

    /// @notice PoolFactory contract
    IPoolFactory public factory;

    /// @notice InterestRateModel contract address
    IInterestRateModel public interestRateModel;

    /// @notice Reserve factor as 18-digit decimal
    uint256 public reserveFactor;

    /// @notice Insurance factor as 18-digit decimal
    uint256 public insuranceFactor;

    /// @notice Pool utilization that leads to warning state (as 18-digit decimal)
    uint256 public warningUtilization;

    /// @notice Pool utilization that leads to provisional default (as 18-digit decimal)
    uint256 public provisionalDefaultUtilization;

    /// @notice Grace period for warning state before pool goes to default (in seconds)
    uint256 public warningGracePeriod;

    /// @notice Max period for which pool can stay not active before it can be closed by governor (in seconds)
    uint256 public maxInactivePeriod;

    /// @notice Period after default to start auction after which pool can be closed by anyone (in seconds)
    uint256 public periodToStartAuction;

    enum State {
        Active,
        Warning,
        ProvisionalDefault,
        Default,
        Closed
    }

    /// @notice Indicator if debt has been claimed
    bool public debtClaimed;

    struct BorrowInfo {
        uint256 principal;
        uint256 borrows;
        uint256 reserves;
        uint256 insurance;
        uint256 lastAccrual;
        uint256 enteredProvisionalDefault;
        uint256 enteredZeroUtilization;
        State state;
    }

    /// @notice Last updated borrow info
    BorrowInfo internal _info;

    string internal _symbol;

    // EVENTS

    event Closed();

    /// @notice Event emitted when liquidity is provided to the Pool
    event Provided(
        address indexed provider,
        uint256 currencyAmount,
        uint256 tokens
    );

    /// @notice Event emitted when liquidity is redeemed from the Pool
    event Redeemed(
        address indexed redeemer,
        uint256 currencyAmount,
        uint256 tokens
    );

    /// @notice Event emitted when manager assignes liquidity
    event Borrowed(uint256 amount, address indexed receiver);

    /// @notice Event emitted when manager returns liquidity assignment
    event Repaid(uint256 amount);

    // CONSTRUCTOR

    /**
     * @notice Upgradeable contract constructor
     * @param manager_ Address of the Pool's manager
     * @param currency_ Address of the currency token
     */
    function __PoolBaseInfo_init(address manager_, IERC20Upgradeable currency_)
        internal
        onlyInitializing
    {
        require(manager_ != address(0), "AIZ");
        require(address(currency_) != address(0), "AIZ");

        manager = manager_;
        currency = currency_;
        factory = IPoolFactory(msg.sender);

        interestRateModel = IInterestRateModel(factory.interestRateModel());
        reserveFactor = factory.reserveFactor();
        insuranceFactor = factory.insuranceFactor();
        warningUtilization = factory.warningUtilization();
        provisionalDefaultUtilization = factory.provisionalDefaultUtilization();
        warningGracePeriod = factory.warningGracePeriod();
        maxInactivePeriod = factory.maxInactivePeriod();
        periodToStartAuction = factory.periodToStartAuction();

        _symbol = factory.getPoolSymbol(address(currency), address(manager));
        __ERC20_init(string(bytes.concat(bytes("Pool "), bytes(_symbol))), "");

        _info.enteredZeroUtilization = block.timestamp;
        _info.lastAccrual = block.timestamp;
    }
}
