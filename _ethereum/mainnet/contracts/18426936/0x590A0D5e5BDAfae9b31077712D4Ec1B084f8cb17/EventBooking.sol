// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract EventBooking {

    struct Booking {
        uint256 eventId;
        uint256 amount;
    }

    IERC20 public token;
    address public admin;
    mapping(address => Booking[]) public bookings;

    constructor(address _token) {
        token = IERC20(_token);
        admin = msg.sender;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function");
        _;
    }

    function bookEvent(uint256 _eventId, uint256 _amount) external {
        require(token.transferFrom(msg.sender, address(this), _amount), "Transfer from user failed");

        Booking memory newBooking = Booking({
            eventId: _eventId,
            amount: _amount
        });

        bookings[msg.sender].push(newBooking);
    }

    function getBookings(address _user) external view returns (Booking[] memory) {
        return bookings[_user];
    }

    function withdrawTokens() external onlyAdmin {
        uint256 contractBalance = token.balanceOf(address(this));
        require(token.transfer(admin, contractBalance), "Transfer to admin failed");
    }

    function transferOwnership(address newAdmin) external onlyAdmin {
        require(newAdmin != address(0), "New admin address cannot be zero address");
        admin = newAdmin;
    }
}