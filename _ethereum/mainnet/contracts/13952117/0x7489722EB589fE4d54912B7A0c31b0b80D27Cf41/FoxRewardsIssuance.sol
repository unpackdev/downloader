// SPDX-License-Identifier: MIT
pragma solidity =0.6.11;

import "./SafeMath.sol";
import "./IERC20.sol";


contract FoxRewardsIssuance {
    using SafeMath for uint256;
    
    uint256 constant public DECIMAL_PRECISION = 1e18;
    uint256 constant public SECONDS_IN_ONE_MINUTE = 60;

    /* The issuance factor F determines the curvature of the issuance curve.
    *
    * Minutes in one year: 60*24*365 = 525600
    *
    * For 50% of remaining tokens issued each year, with minutes as time units, we have:
    *
    * F ** 525600 = 0.5
    *
    * Re-arranging:
    *
    * 525600 * ln(F) = ln(0.5)
    * F = 0.5 ** (1/525600)
    * F = 0.999998681227695000
    */
    uint256 constant public ISSUANCE_FACTOR = 999998681227695000;

    uint256 constant public rewardsSupplyCap = 1e13 * 1e18; // 10 trillion

    uint256 public totalRewardsIssued;
    uint256 public startTime;

    IERC20 public foxToken;
    address public xFOX;

    // --- Events ---
    event TotalRewardsIssuedUpdated(uint256 _totalRewardsIssued);

    // --- Modifier ---
    modifier validCaller() {
        require(msg.sender == xFOX, "FoxRewardsIssuance: caller is not xFOX");
        _;
    }

    // --- Constructor ---
    constructor (address _foxToken, address _xFOX) public {
        foxToken = IERC20(_foxToken);
        xFOX = _xFOX;
    }

    // --- Functions ---
    function initialize() external validCaller {
        require(foxToken.balanceOf(address(this)) >= rewardsSupplyCap, "FoxRewardsIssuance: insufficient rewards");
        startTime = block.timestamp;
    }

    function calculateRewards() public view returns (uint256, uint256) {
        uint256 latestTotalRewardsIssued = rewardsSupplyCap.mul(_getCumulativeIssuanceFraction()).div(DECIMAL_PRECISION);
        uint256 issuance = latestTotalRewardsIssued.sub(totalRewardsIssued);
        return (latestTotalRewardsIssued, issuance);
    }

    function issueRewards() external validCaller {
        (uint256 latestTotalRewardsIssued, uint256 issuance) = calculateRewards();

        totalRewardsIssued = latestTotalRewardsIssued;

        foxToken.transfer(msg.sender, issuance);

        emit TotalRewardsIssuedUpdated(latestTotalRewardsIssued);
    }

    function _getCumulativeIssuanceFraction() internal view returns (uint256) {
        // Get the time passed since deployment
        uint256 timePassedInMinutes = block.timestamp.sub(startTime).div(SECONDS_IN_ONE_MINUTE);

        // f^t
        uint256 power = _decPow(ISSUANCE_FACTOR, timePassedInMinutes);

        //  (1 - f^t)
        uint256 cumulativeIssuanceFraction = (uint256(DECIMAL_PRECISION).sub(power));
        assert(cumulativeIssuanceFraction <= DECIMAL_PRECISION); // must be in range [0,1]

        return cumulativeIssuanceFraction;
    }
    
    function _decPow(uint256 _base, uint256 _minutes) internal pure returns (uint256) {

        if (_minutes > 525600000) {_minutes = 525600000;}  // cap to avoid overflow

        if (_minutes == 0) {return DECIMAL_PRECISION;}

        uint256 y = DECIMAL_PRECISION;
        uint256 x = _base;
        uint256 n = _minutes;

        // Exponentiation-by-squaring
        while (n > 1) {
            if (n % 2 == 0) {
                x = _decMul(x, x);
                n = n.div(2);
            } else { // if (n % 2 != 0)
                y = _decMul(x, y);
                x = _decMul(x, x);
                n = (n.sub(1)).div(2);
            }
        }

        return _decMul(x, y);
    }

    function _decMul(uint256 x, uint256 y) internal pure returns (uint256 decProd) {
        uint256 prod_xy = x.mul(y);

        decProd = prod_xy.add(DECIMAL_PRECISION / 2).div(DECIMAL_PRECISION);
    }
}