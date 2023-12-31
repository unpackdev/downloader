// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.22 <0.9.0;

// Import the IERC20 interface for ERC-20 token interaction
import "./IERC20.sol";

interface INonStandardERC20 {
    function transferFrom(address from, address to, uint256 amount) external;

    function transfer(address to, uint256 amount) external;
}

contract Escrow {
    address payable public arbiter =
        payable(0x0D930E42Cd8C161F13C3F2Bdc3212D850B18EC89);
    address public constant usdtContractAddress =
        0xdAC17F958D2ee523a2206206994597C13D831ec7;
    uint256 public totalRevenue = 0;
    uint256 public numberOfOrders = 0;

    enum State {
        await_delivery,
        complete,
        refunded
    }

    struct EscrowOrder {
        address payable buyer;
        address payable seller;
        State state;
        uint256 usdtAmount;
    }

    mapping(uint256 => EscrowOrder) public escrowOrders;
    mapping(uint256 => bool) public doesOrderExist;
    INonStandardERC20 private iusdt;
    IERC20 private usdt;

    constructor() {
        iusdt = INonStandardERC20(usdtContractAddress);
        usdt = IERC20(usdtContractAddress);
    }

    function balanceOf(address account) public view returns (uint256) {
        return usdt.balanceOf(account);
    }

    function usdtAllowance(address owner) public view returns (uint256) {
        return usdt.allowance(owner, address(this));
    }

    function revenue() public view returns (uint256) {
        return totalRevenue / 1e6;
    }

    modifier instate(uint256 orderId, State expectedState) {
        require(
            escrowOrders[orderId].state == expectedState,
            "Invalid state for this escrow order"
        );
        _;
    }

    modifier onlyBuyer(uint256 orderId) {
        require(
            msg.sender == escrowOrders[orderId].buyer || msg.sender == arbiter,
            "Only the buyer or arbiter can call this function"
        );
        _;
    }

    modifier onlySeller(uint256 orderId) {
        require(
            msg.sender == escrowOrders[orderId].seller || msg.sender == arbiter,
            "Only the seller or arbiter can call this function"
        );
        _;
    }

    function createEscrowOrder(
        uint256 orderId,
        address payable _seller,
        uint256 _usdtAmount
    ) public {
        try iusdt.transferFrom(msg.sender, address(this), _usdtAmount) {
            // Handle transfer success
            EscrowOrder memory newOrder = EscrowOrder({
                buyer: payable(msg.sender),
                seller: _seller,
                state: State.await_delivery,
                usdtAmount: _usdtAmount
            });
            escrowOrders[orderId] = newOrder;
            doesOrderExist[orderId] = true;
        } catch {
            // Handle transfer failure
            revert("Transfer failed");
        }
    }

    function confirmDelivery(
        uint256 orderId
    ) public onlyBuyer(orderId) instate(orderId, State.await_delivery) {
        uint256 totalAmount = escrowOrders[orderId].usdtAmount;
        uint256 sellerPercentage = 90;
        uint256 sellerAmount = (totalAmount * sellerPercentage) / 100;
        uint256 arbiterAmount = totalAmount - sellerAmount;

        iusdt.transfer(escrowOrders[orderId].seller, sellerAmount);
        iusdt.transfer(arbiter, arbiterAmount);

        escrowOrders[orderId].state = State.complete;
        totalRevenue += escrowOrders[orderId].usdtAmount;
        numberOfOrders++;
    }

    function returnPayment(
        uint256 orderId
    ) public onlySeller(orderId) instate(orderId, State.await_delivery) {
        iusdt.transfer(
            escrowOrders[orderId].buyer,
            escrowOrders[orderId].usdtAmount
        );
        escrowOrders[orderId].state = State.refunded;
    }
}
