// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./IIntegralDelay.sol";
import "./IKeep3rV1.sol";
import "./IERC20.sol";

contract IntegralDelayJob {
    address public governance;
    address public pendingGovernance;

    address public constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    IKeep3rV1 public constant KP3R = IKeep3rV1(0x1cEB5cB57C4D4E2b2433641b95Dd330A33185A44);

    address public integralDelay; // 0x8743cc30727e9E460A5E69E217893f42DFad1650
    uint256 internal constant decimals = 10000;
    uint256 internal reducedPaymentPercent;
    uint256 internal n = 10;

    constructor(address _integralDelay, uint256 _reducedPaymentPercent) {
        governance = msg.sender;
        integralDelay = _integralDelay;
        reducedPaymentPercent = _reducedPaymentPercent;
    }

    receive() external payable {}

    function setGovernance(address _governance) external {
        require(msg.sender == governance, "!G");
        pendingGovernance = _governance;
    }

    function acceptGovernance() external {
        require(msg.sender == pendingGovernance, "!pG");
        governance = pendingGovernance;
    }

    function setIntegralDelay(address _integralDelay) external {
        require(msg.sender == governance, "!G");
        integralDelay = _integralDelay;
    }

    function setReducedPaymentPercent(uint256 _reducedPaymentPercent) external {
        require(msg.sender == governance, "!G");
        reducedPaymentPercent = _reducedPaymentPercent;
    }

    function setN(uint256 _n) external {
        require(msg.sender == governance, "!G");
        n = _n;
    }

    function getRewards(address erc20) external {
        require(msg.sender == governance, "!G");
        if (erc20 == ETH) return payable(governance).transfer(address(this).balance);
        IERC20(erc20).transfer(governance, IERC20(erc20).balanceOf(address(this)));
    }

    function work() external upkeep {
        require(workable(), "!W");
        IIntegralDelay(integralDelay).execute(n);
    }

    function workForFree() external keeper {
        IIntegralDelay(integralDelay).execute(n);
    }

    function workable() public view returns (bool canWork) {
        uint256 botExecuteTime = IIntegralDelay(integralDelay).botExecuteTime();
        for (uint256 i = 0; i < n; i++) {
            uint256 lastProcessedOrderId = IIntegralDelay(integralDelay).lastProcessedOrderId();
            if (IIntegralDelay(integralDelay).isOrderCanceled(lastProcessedOrderId + 1)) {
                continue;
            }
            (Orders.OrderType orderType, uint256 validAfterTimestamp) = IIntegralDelay(integralDelay).getOrder(lastProcessedOrderId + 1);
            if (orderType == Orders.OrderType.Empty || validAfterTimestamp >= block.timestamp) {
                break;
            }
            if (block.timestamp >= validAfterTimestamp + botExecuteTime) {
                return true;
            }
        }
        return false;
    }

    modifier keeper() {
        require(KP3R.keepers(msg.sender), "!K");
        _;
    }

    modifier upkeep() {
        uint256 _gasUsed = gasleft();
        require(KP3R.keepers(msg.sender), "!K");
        _;
        uint256 _received = KP3R.KPRH().getQuoteLimit(_gasUsed - gasleft());
        uint256 _fairPayment = (_received * decimals) / reducedPaymentPercent;
        KP3R.receipt(address(KP3R), msg.sender, _fairPayment);
    }
}
