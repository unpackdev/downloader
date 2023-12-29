// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./AggregatorV3Interface.sol";

interface IBatchPlanner {
    struct Plan {
        address recipient;
        uint256 amount;
        uint256 start;
        uint256 cliff;
        uint256 rate;
    }

    function batchLockingPlans(
        address locker,
        address token,
        uint256 totalAmount,
        Plan[] calldata plans,
        uint256 period,
        uint8 mintType
    ) external;
}

contract JANETokenSale is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    IERC20 public janeToken;
    AggregatorV3Interface public priceFeed;
    address public janeEscrow;
    uint256 public janePerUSD;
    address public hedgeyBatchPlanner;
    address public hedgeyVotingTokenLockUpPlan;
    uint256 public constant APR_30_2024 = 1714460400; // unix timestamp for apr 30, 2024 UTC

    constructor(
        address _janeToken,
        address _janeEscrow,
        address _priceFeed,
        uint256 _janePerUSD,
        address _owner,
        address _hedgeyBatchPlanner,
        address _hedgeyVotingTokenLockUpPlan
    ) {
        janeToken = IERC20(_janeToken);
        priceFeed = AggregatorV3Interface(_priceFeed);
        janePerUSD = _janePerUSD;
        transferOwnership(_owner);
        janeEscrow = _janeEscrow;
        hedgeyBatchPlanner = _hedgeyBatchPlanner;
        hedgeyVotingTokenLockUpPlan = _hedgeyVotingTokenLockUpPlan;
    }

    function getCurrentEthUsdPrice() public view returns (int) {
        (, int price, , , ) = priceFeed.latestRoundData();
        return price;
    }

    function buyTokens(address beneficiary) external payable nonReentrant {
        require(
            beneficiary != address(0),
            'Beneficiary address should be valid'
        );
        require(msg.value > 0, 'Ether sent should be greater than 0');

        int currentPrice = getCurrentEthUsdPrice();
        uint256 janeAmount = janePerUSD
        /* .mul(10 ** 18) */ // technically this is the math, but it cancels due to the division at the bottom
            .mul(uint256(currentPrice))
            .mul(msg.value)
            .div(10 ** 8); // this should explicitly be above the prvious line to show steps, but was moved down to improve accuracy
        /* .div(10 ** 18); */

        require(
            janeToken.allowance(janeEscrow, address(this)) >= janeAmount,
            'Token allowance is insufficient'
        );
        janeToken.safeTransferFrom(janeEscrow, address(this), janeAmount);

        require(block.timestamp < APR_30_2024, 'Lock up period is over');
        uint256 lockUpPeriod = APR_30_2024 - block.timestamp;

        // Lock the tokens using BatchPlanner's batchLockingPlans function
        IBatchPlanner.Plan[] memory plans = new IBatchPlanner.Plan[](1);
        plans[0] = IBatchPlanner.Plan({
            recipient: beneficiary,
            amount: janeAmount,
            start: block.timestamp,
            cliff: 0, // No cliff, can be adjusted
            rate: janeAmount.div(lockUpPeriod)
        });

        SafeERC20.safeIncreaseAllowance(
            janeToken,
            hedgeyBatchPlanner,
            janeAmount
        );
        IBatchPlanner(hedgeyBatchPlanner).batchLockingPlans(
            hedgeyVotingTokenLockUpPlan,
            address(janeToken),
            janeAmount,
            plans,
            1, // lock-up period is 1 second at which time plan.rate tokens are dispensed, repeating until exhausted
            5 // mintType, investor lock up is mint type 5
        );

        // Transfer Ether to the owner
        payable(owner()).transfer(msg.value);
    }

    // Called when receiving Ether
    receive() external payable {
        this.buyTokens{value: msg.value}(msg.sender);
    }

    // Fallback function
    fallback() external payable {
        this.buyTokens{value: msg.value}(msg.sender);
    }

    function setJanePerUSD(uint256 newJanePerUSD) external onlyOwner {
        require(newJanePerUSD > 0, 'Rate should be greater than zero');
        janePerUSD = newJanePerUSD;
        emit JanePerUSDChanged(newJanePerUSD);
    }

    event JanePerUSDChanged(uint256 newJanePerUSD);
}
