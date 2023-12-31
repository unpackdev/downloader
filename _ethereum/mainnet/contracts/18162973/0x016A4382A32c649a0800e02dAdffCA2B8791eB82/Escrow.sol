// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.22 <0.9.0;

// Import the IERC20 interface for ERC-20 token interaction
import "./ERC20.sol";

contract Escrow {
    // Declaring the state variables
    address payable public arbiter =
        payable(0x0D930E42Cd8C161F13C3F2Bdc3212D850B18EC89);
    address public constant usdtContractAddress =
        0xdAC17F958D2ee523a2206206994597C13D831ec7;
    uint totalRevenue = 0;
    uint public numberOfOrders = 0;

    // Defining a enumerator 'State'
    enum State {
        awate_payment,
        awate_delivery,
        complete
    }

    struct EscrowOrder {
        address payable buyer;
        address payable seller;
        State state;
        uint256 usdtAmount;
    }

    mapping(uint256 => EscrowOrder) public escrowOrders;
    IERC20 private usdt;

    // Defining a constructor
    constructor() {
        usdt = IERC20(usdtContractAddress);
    }

    function balanceOf(address account) public view returns (uint256) {
        return usdt.balanceOf(account);
    }

    function usdtAllowance(address owner) public view returns (uint256) {
        return usdt.allowance(owner, address(this));
    }

    // Defining function modifier 'instate'
    modifier instate(uint256 orderId, State expectedState) {
        require(
            escrowOrders[orderId].state == expectedState,
            "Invalid state for this escrow order"
        );
        _;
    }

    // Defining function modifier 'onlyBuyer'
    modifier onlyBuyer(uint256 orderId) {
        require(
            msg.sender == escrowOrders[orderId].buyer || msg.sender == arbiter,
            "Only the buyer or arbiter can call this function"
        );
        _;
    }

    // Defining function modifier 'onlySeller'
    modifier onlySeller(uint256 orderId) {
        require(
            msg.sender == escrowOrders[orderId].seller || msg.sender == arbiter,
            "Only the seller or arbiter can call this function"
        );
        _;
    }

    function revenue() public view returns (uint) {
        return totalRevenue / 1e6;
    }

    // Function to create a new escrow order
    function createEscrowOrder(
        uint256 orderId,
        address payable _seller,
        uint256 _usdtAmount
    ) public {
        // Check if the specified orderId is available
        require(
            escrowOrders[orderId].state == State(0),
            "Order with the specified ID already exists"
        );

        // Transfer USDT from the buyer to this contract (assuming the buyer has already approved this contract)
        usdt.transferFrom(msg.sender, address(this), _usdtAmount);

        EscrowOrder memory newOrder = EscrowOrder({
            buyer: payable(msg.sender),
            seller: _seller,
            state: State.awate_delivery,
            usdtAmount: _usdtAmount
        });
        escrowOrders[orderId] = newOrder;
    }

    // Function to confirm payment
    function confirmPayment(
        uint256 orderId
    ) public onlyBuyer(orderId) instate(orderId, State.awate_delivery) {
        escrowOrders[orderId].state = State.awate_delivery;
    }

    // Function to confirm delivery
    function confirmDelivery(
        uint256 orderId
    ) public onlyBuyer(orderId) instate(orderId, State.awate_delivery) {
        uint256 totalAmount = escrowOrders[orderId].usdtAmount;
        uint256 sellerAmount = (totalAmount * 90) / 100;
        uint256 arbiterAmount = totalAmount - sellerAmount;

        // Transfer USDT to the seller and the arbiter (assuming they have already approved this contract)
        usdt.transfer(escrowOrders[orderId].seller, sellerAmount);
        usdt.transfer(arbiter, arbiterAmount);
        escrowOrders[orderId].state = State.complete;

        totalRevenue += escrowOrders[orderId].usdtAmount;
        numberOfOrders++;
    }

    // Function to return payment
    function returnPayment(
        uint256 orderId
    ) public onlySeller(orderId) instate(orderId, State.awate_delivery) {
        usdt.transfer(
            escrowOrders[orderId].buyer,
            escrowOrders[orderId].usdtAmount
        );
    }
}
