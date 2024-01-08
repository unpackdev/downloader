// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./SafeERC20.sol";
import "./IComptroller.sol";
import "./ICToken.sol";
import "./ICTokenAdmin.sol";
import "./IBurner.sol";
import "./IWeth.sol";

contract ReserveManager is Ownable {
    using SafeERC20 for IERC20;

    uint public constant COOLDOWN_PERIOD = 1 days;

    /**
     * @notice comptroller contract
     */
    IComptroller public immutable comptroller;

    /**
     * @notice usdc burner contract
     */
    IBurner public immutable usdcBurner;

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
     * @notice Emitted when reserves are dispatched
     */
    event Dispatch(
        address indexed token,
        uint indexed amount
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
     * @notice Emitted when the reserves extraction ratio is updated
     */
    event RatioUpdated(
        uint oldRatio,
        uint newRatio
    );

    constructor(
        address _owner,
        IComptroller _comptroller,
        IBurner _usdcBurner,
        address _wethAddress,
        address _usdcAddress
    ) {
        transferOwnership(_owner);
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
     * @notice Execute reduce reserve for cToken
     * @param cToken The cToken to dispatch reduce reserve operation
     * @param batchJob indicate whether this function call is within a multiple cToken batch job
     */
    function dispatch(address cToken, bool batchJob) external {
        require(comptroller.isMarketListed(cToken), "market not listed");

        uint totalReserves = ICToken(cToken).totalReserves();
        ReservesSnapshot memory snapshot = reservesSnapshot[cToken];
        if (snapshot.timestamp > 0 && snapshot.totalReserves < totalReserves) {
            address cTokenAdmin = cTokenAdmins[cToken];
            address burner = burners[cToken];
            require(cTokenAdmin == ICToken(cToken).admin(), "mismatch cToken admin");
            require(burner != address(0), "burner not set");
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
            IERC20(underlying).approve(burner, burnAmount);
            require(IBurner(burner).burn(underlying), "Burner failed to burn the underlying token");

            emit Dispatch(underlying, burnAmount);
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

    /**
     * @notice Execute reduce reserve and burn on multiple cTokens
     * @param cTokens The token address list
     */
    function dispatchMultiple(address[] memory cTokens) external {
        for (uint i = 0; i < cTokens.length; i++) {
            this.dispatch(cTokens[i], true);
        }
        IBurner(usdcBurner).burn(usdcAddress);
    }

    receive() external payable {}

    /* Admin functions */

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
     * @param tokens The token address list
     * @param newBurners The burner address list
     */
    function setBurners(address[] memory tokens, address[] memory newBurners) external onlyOwner {
        require(tokens.length == newBurners.length, "invalid data");

        for (uint i = 0; i < tokens.length; i++) {
            address oldBurner = burners[tokens[i]];
            burners[tokens[i]] = newBurners[i];

            emit BurnerUpdated(tokens[i], oldBurner, newBurners[i]);
        }
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
    function compareStrings(string memory a, string memory b) private pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }
}
