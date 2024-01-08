// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./SafeERC20.sol";
import "./IComptroller.sol";
import "./ICToken.sol";
import "./ICTokenAdmin.sol";
import "./IBurner.sol";
import "./IWeth.sol";

contract ReserveManager is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    uint public constant COOLDOWN_PERIOD = 1 days;
    address public constant ethAddress = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /**
     * @notice comptroller contract
     */
    IComptroller public immutable comptroller;

    /**
     * @notice weth contract
     */
    address public immutable wethAddress;

    /**
     * @notice usdc contract
     */
    address public immutable usdcAddress;

    /**
     * @notice the extraction ratio, scaled by 1e18
     */
    uint public ratio = 0.5e18;

    /**
     * @notice usdc burner contract
     */
    IBurner public usdcBurner;

    /**
     * @notice cToken admin to extract reserves
     */
    mapping(address => address) public cTokenAdmins;

    /**
     * @notice burner contracts to convert assets into a specific token
     */
    mapping(address => address) public burners;

    struct ReservesSnapshot {
        uint timestamp;
        uint totalReserves;
    }

    /**
     * @notice reserves snapshot that records every reserves update
     */
    mapping(address => ReservesSnapshot) public reservesSnapshot;

    /**
     * @notice return if a cToken market is blocked from reserves sharing
     */
    mapping(address => bool) public isBlocked;

    /**
     * @notice return if a cToken market should be burnt manually
     */
    mapping(address => bool) public manualBurn;

    /**
     * @notice a manual burner that reseives assets whose onchain liquidity are not deep enough
     */
    address public manualBurner;

    /**
     * @notice Emitted when reserves are dispatched
     */
    event Dispatch(
        address indexed token,
        uint indexed amount,
        address destination
    );

    /**
     * @notice Emitted when a cTokenAdmin is updated
     */
    event CTokenAdminUpdated(
        address cToken,
        address oldAdmin,
        address newAdmin
    );

    /**
     * @notice Emitted when a cToken's burner is updated
     */
    event BurnerUpdated(
        address cToken,
        address oldBurner,
        address newBurner
    );

     /**
     * @notice Emitted when a USDC burner is updated
     */
    event UsdcBurnerUpdated(
        address oldBurner,
        address newBurner
    );

    /**
     * @notice Emitted when the reserves extraction ratio is updated
     */
    event RatioUpdated(
        uint oldRatio,
        uint newRatio
    );

    /**
     * @notice Emitted when a token is seized
     */
    event TokenSeized(
        address token,
        uint amount
    );

    /**
     * @notice Emitted when a cToken market is blocked or unblocked from reserves sharing
     */
    event MarketBlocked(
        address cToken,
        bool wasBlocked,
        bool isBlocked
    );

    /**
     * @notice Emitted when a cToken market is determined to be manually burnt or not
     */
    event MarketManualBurn(
        address cToken,
        bool wasManual,
        bool isManual
    );

    /**
     * @notice Emitted when a manual burner is updated
     */
    event ManualBurnerUpdated(
        address oldManualBurner,
        address newManualBurner
    );

    constructor(
        address _owner,
        address _manualBurner,
        IComptroller _comptroller,
        IBurner _usdcBurner,
        address _wethAddress,
        address _usdcAddress
    ) {
        transferOwnership(_owner);
        manualBurner = _manualBurner;
        comptroller = _comptroller;
        usdcBurner = _usdcBurner;
        wethAddress = _wethAddress;
        usdcAddress = _usdcAddress;

        // Set default ratio to 50%.
        ratio = 0.5e18;
    }

    /**
     * @notice Get the current block timestamp
     * @return The current block timestamp
     */
    function getBlockTimestamp() public virtual view returns (uint) {
        return block.timestamp;
    }

    /**
     * @notice Execute reduce reserve and burn on multiple cTokens
     * @param cTokens The token address list
     */
    function dispatchMultiple(address[] memory cTokens) external nonReentrant {
        for (uint i = 0; i < cTokens.length; i++) {
            dispatch(cTokens[i], true);
        }
        IBurner(usdcBurner).burn(usdcAddress);
    }

    receive() external payable {}

    /* Admin functions */

    /**
     * @notice Seize the accidentally deposited tokens
     * @param token The token
     * @param amount The amount
     */
    function seize(address token, uint amount) external onlyOwner {
        if (token == ethAddress) {
            payable(owner()).transfer(amount);
        } else {
            IERC20(token).safeTransfer(owner(), amount);
        }
        emit TokenSeized(token, amount);
    }

    /**
     * @notice Block or unblock a cToken from reserves sharing
     * @param cTokens The cToken address list
     * @param blocked Block from reserves sharing or not
     */
    function setBlocked(address[] memory cTokens, bool[] memory blocked) external onlyOwner {
        require(cTokens.length == blocked.length, "invalid data");

        for (uint i = 0; i < cTokens.length; i++) {
            bool wasBlocked = isBlocked[cTokens[i]];
            isBlocked[cTokens[i]] = blocked[i];

            emit MarketBlocked(cTokens[i], wasBlocked, blocked[i]);
        }
    }

     /**
     * @notice Set the USDC burner
     * @param newUsdcBurner The USDC burner address
     */
    function setUsdcBurner(address newUsdcBurner) external onlyOwner {
        address oldUsdcBurner = address(usdcBurner);
        usdcBurner = IBurner(newUsdcBurner);

        emit UsdcBurnerUpdated(oldUsdcBurner, newUsdcBurner);
    }

    /**
     * @notice Set the admins of a list of cTokens
     * @param cTokens The cToken address list
     * @param newCTokenAdmins The admin address list
     */
    function setCTokenAdmins(address[] memory cTokens, address[] memory newCTokenAdmins) external onlyOwner {
        require(cTokens.length == newCTokenAdmins.length, "invalid data");

        for (uint i = 0; i < cTokens.length; i++) {
            require(comptroller.isMarketListed(cTokens[i]), "market not listed");
            require(ICToken(cTokens[i]).admin() == newCTokenAdmins[i], "mismatch cToken admin");

            address oldAdmin = cTokenAdmins[cTokens[i]];
            cTokenAdmins[cTokens[i]] = newCTokenAdmins[i];

            emit CTokenAdminUpdated(cTokens[i], oldAdmin, newCTokenAdmins[i]);
        }
    }

    /**
     * @notice Set the burners of a list of tokens
     * @param cTokens The cToken address list
     * @param newBurners The burner address list
     */
    function setBurners(address[] memory cTokens, address[] memory newBurners) external onlyOwner {
        require(cTokens.length == newBurners.length, "invalid data");

        for (uint i = 0; i < cTokens.length; i++) {
            address oldBurner = burners[cTokens[i]];
            burners[cTokens[i]] = newBurners[i];

            emit BurnerUpdated(cTokens[i], oldBurner, newBurners[i]);
        }
    }

    /**
     * @notice Determine a market should be burnt manually or not
     * @param cTokens The cToken address list
     * @param manual The list of markets which should be burnt manually or not
     */
    function setManualBurn(address[] memory cTokens, bool[] memory manual) external onlyOwner {
        require(cTokens.length == manual.length, "invalid data");

        for (uint i = 0; i < cTokens.length; i++) {
            bool wasManual = manualBurn[cTokens[i]];
            manualBurn[cTokens[i]] = manual[i];

            emit MarketManualBurn(cTokens[i], wasManual, manual[i]);
        }
    }

    /**
     * @notice Set new manual burner
     * @param newManualBurner The new manual burner
     */
    function setManualBurner(address newManualBurner) external onlyOwner {
        require(newManualBurner != address(0), "invalid new manual burner");

        address oldManualBurner = manualBurner;
        manualBurner = newManualBurner;

        emit ManualBurnerUpdated(oldManualBurner, newManualBurner);
    }

    /**
     * @notice Adjust the extraction ratio
     * @param newRatio The new extraction ratio
     */
    function adjustRatio(uint newRatio) external onlyOwner {
        require(newRatio <= 1e18, "invalid ratio");

        uint oldRatio = ratio;
        ratio = newRatio;
        emit RatioUpdated(oldRatio, newRatio);
    }

    /* Internal functions */

    /**
     * @notice Compare whether the two strings are the same
     * @param a The first string
     * @param b The second string
     * @return Two strings are the same or not
     */
    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    /**
     * @notice Execute reduce reserve for cToken
     * @param cToken The cToken to dispatch reduce reserve operation
     * @param batchJob indicate whether this function call is within a multiple cToken batch job
     */
    function dispatch(address cToken, bool batchJob) internal {
        require(!isBlocked[cToken], "market is blocked from reserves sharing");
        require(comptroller.isMarketListed(cToken), "market not listed");

        uint totalReserves = ICToken(cToken).totalReserves();
        ReservesSnapshot memory snapshot = reservesSnapshot[cToken];
        if (snapshot.timestamp > 0 && snapshot.totalReserves < totalReserves) {
            address cTokenAdmin = cTokenAdmins[cToken];
            require(cTokenAdmin == ICToken(cToken).admin(), "mismatch cToken admin");
            require(snapshot.timestamp + COOLDOWN_PERIOD <= getBlockTimestamp(), "still in the cooldown period");

            // Extract reserves through cTokenAdmin.
            uint reduceAmount = (totalReserves - snapshot.totalReserves) * ratio / 1e18;
            ICTokenAdmin(cTokenAdmin).extractReserves(cToken, reduceAmount);

            // After the extraction, the reserves in cToken should decrease.
            // Instead of getting reserves from cToken again, we subtract `totalReserves` with `reduceAmount` to save gas.
            totalReserves = totalReserves - reduceAmount;

            // Get the cToken underlying.
            address underlying;
            if (compareStrings(ICToken(cToken).symbol(), "crETH")) {
                IWeth(wethAddress).deposit{value: reduceAmount}();
                underlying = wethAddress;
            } else {
                underlying = ICToken(cToken).underlying();
            }

            // In case someone transfers tokens in directly, which will cause the dispatch reverted,
            // we burn all the tokens in the contract here.
            uint burnAmount = IERC20(underlying).balanceOf(address(this));

            address burner = burners[cToken];
            if (manualBurn[cToken]) {
                // Send the underlying to the manual burner.
                burner = manualBurner;
                IERC20(underlying).safeTransfer(manualBurner, burnAmount);
            } else {
                // Allow the corresponding burner to pull the assets to burn.
                require(burner != address(0), "burner not set");
                IERC20(underlying).safeIncreaseAllowance(burner, burnAmount);
                require(IBurner(burner).burn(underlying), "Burner failed to burn the underlying token");
            }

            emit Dispatch(underlying, burnAmount, burner);
        }

        // Update the reserve snapshot.
        reservesSnapshot[cToken] = ReservesSnapshot({
            timestamp: getBlockTimestamp(),
            totalReserves: totalReserves
        });

        // A standalone reduce-reserve operation followed by a final USDC burn
        if (!batchJob){
            IBurner(usdcBurner).burn(usdcAddress);
        }
    }
}
