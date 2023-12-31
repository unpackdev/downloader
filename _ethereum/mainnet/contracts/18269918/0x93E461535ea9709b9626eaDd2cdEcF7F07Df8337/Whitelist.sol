// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./OwnableUpgradeable.sol";
import "./IERC20.sol";

contract Whitelist is OwnableUpgradeable {
    address public treasury;
    IERC20 public token;

    uint256 public base_price;
    uint256 public price_increment;
    uint64 public ticket_capacity;
    uint64 public current_stage;
    uint64 public total_tickets;
    uint64 public tickets_sold_in_stage;

    mapping(address => uint64) public tickets;
    mapping(address => uint256) public referrals;

    event TicketPurchased(
        address indexed buyer,
        uint64 ticketId,
        address referrer
    );

    event ReferralFeePaid(
        address indexed referrer,
        uint256 amount
    );

    function initialize(
        IERC20 _token,
        uint256 _base_price,
        uint256 _price_increment,
        uint64 _ticket_capacity,
        address _treasury,
        uint8 _referrer_fee
    ) public initializer {
        __Ownable_init();

        current_stage = 1;
        total_tickets = 0;
        tickets_sold_in_stage = 0;

        token = _token;
        base_price = _base_price;
        price_increment = _price_increment;
        ticket_capacity = _ticket_capacity;
        treasury = _treasury;
        referrer_fee = _referrer_fee;
    }

    function purchase_ticket(uint64 _n) external {
        _purchase_ticket(_n, address(0));
    }

    function purchase_ticket_ref(uint64 _n, address _referrer) external {
        require(
            tickets[_referrer] != 0,
            "Referrer hasn't purchased a ticket yet"
        );
        _purchase_ticket(_n, _referrer);
    }

    function _purchase_ticket(uint64 _n, address _referrer) internal {
        require(_n == total_tickets + 1, "Invalid ticket number");
        require(
            tickets_sold_in_stage < ticket_capacity,
            "Ticket capacity exceeded"
        );

        uint256 ticketPrice = base_price +
            uint256(tickets_sold_in_stage) *
            price_increment;

        total_tickets++;
        tickets_sold_in_stage++;
        tickets[msg.sender] = _n;

        if (_referrer != address(0)) {
            uint256 referrer_reward = 0;

            if (referrer_fee > 0) {
                referrer_reward = (ticketPrice * referrer_fee) / 100;
                require(
                    token.transferFrom(msg.sender, _referrer, referrer_reward),
                    "Referral fee transfer failed"
                );

                emit ReferralFeePaid(_referrer, referrer_reward);
            }
        
            require(token.transferFrom(msg.sender, treasury, ticketPrice - referrer_reward), "Treasury transfer failed");

            referrals[_referrer]++;
        } else {
            require(token.transferFrom(msg.sender, treasury, ticketPrice), "Treasury transfer failed");
        }

        emit TicketPurchased(msg.sender, _n, _referrer);
    }

    function next_stage(
        uint256 _base_price,
        uint256 _price_increment,
        uint64 _ticket_capacity,
        uint8 _referrer_fee
    ) external onlyOwner {
        require(
            tickets_sold_in_stage == ticket_capacity,
            "Not all tickets sold in the current stage"
        );

        current_stage++;
        base_price = _base_price;
        price_increment = _price_increment;
        ticket_capacity = _ticket_capacity;
        referrer_fee = _referrer_fee;
        tickets_sold_in_stage = 0;

        emit NextStage(
            _base_price,
            _price_increment,
            _ticket_capacity,
            _referrer_fee
        );
    }

    function current_price() external view returns (uint64 _n, uint256 price) {
        _n = total_tickets + 1;
        price = base_price + uint256(tickets_sold_in_stage) * price_increment;
    }

    function stage()
        external
        view
        returns (
            uint64 _stage,
            uint256 _base_price,
            uint256 _price_increment,
            uint64 _ticket_capacity,
            uint8 _referrer_fee
        )
    {
        _stage = current_stage;
        _base_price = base_price;
        _price_increment = price_increment;
        _ticket_capacity = ticket_capacity;
        _referrer_fee = referrer_fee;
    }

    function ticket_stats() external view returns (uint64 total, uint64 left) {
        total = total_tickets;
        left = ticket_capacity - tickets_sold_in_stage;
    }

    function counter_ref(
        address _referer
    ) external view returns (uint256 count) {
        count = referrals[_referer];
    }

    function verify(address _target) external view returns (bool hasTicket) {
        hasTicket = tickets[_target] != 0;
    }

    function check_ticket(
        address _target
    ) external view returns (uint64 ticketId) {
        ticketId = tickets[_target];
    }

    uint8 public referrer_fee;

    event NextStage(
        uint256 base_price,
        uint256 price_increment,
        uint64 ticket_capacity,
        uint8 referrer_fee
    );
}
