// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

contract Reserve is Initializable, OwnableUpgradeable {
    using SafeERC20 for IERC20;

    // prev points to the last and next to the first entry in the list
    address constant GUARD = address(1);
    uint256 constant RESERVATION_FEE = 1000000000;

    struct Reservation {
        address prev;
        address next;
        bool bought;
    }

    IERC20 usdt;
    mapping(address => Reservation) reservations;
    uint32 numOfReservations;
    address purchaseContractAddress;
    uint256 startDate;
    uint256 endDate;

    function initialize(IERC20 _usdt, uint256 _startDate, uint256 _endDate) public initializer {
        usdt = _usdt;
        startDate = _startDate;
        endDate = _endDate;
        reservations[GUARD] = Reservation(GUARD, GUARD, false);
        OwnableUpgradeable.__Ownable_init();
    }

    modifier hasStarted {
        require(
            block.timestamp >= startDate,
            "The reservation has not yet started"
        );
        _;
    }

    modifier notEnded {
        require(
            block.timestamp <= endDate,
            "The reservation has ended"
        );
        _;
    }

    function setStartDate(uint256 _startDate) external onlyOwner {
        startDate = _startDate;
    }

    function setEndDate(uint256 _endDate) external onlyOwner {
        endDate = _endDate;
    }

    function setPurchaseContractAddress(address _purchaseContractAddress) external onlyOwner {
        purchaseContractAddress = _purchaseContractAddress;
    }

    function reserve() external hasStarted notEnded {
        Reservation storage reservation  = reservations[msg.sender];
        require(
            reservation.prev == address(0),
            "There is already a reservation for this address"
        );

        usdt.safeTransferFrom(msg.sender, address(this), RESERVATION_FEE);

        address prev = reservations[GUARD].prev;
        reservations[prev].next = msg.sender;
        reservations[GUARD].prev = msg.sender;
        reservation.prev = prev;
        reservation.next = GUARD;
        numOfReservations++;
    }

    function cancelReservation() external {
        Reservation storage reservation  = reservations[msg.sender];
        require(
            reservation.prev != address(0),
            "No reservation found for this address"
        );
        require(
            !reservation.bought,
            "An NiFTy3 has already been purchased with the reservation of this address"
        );
        reservations[reservation.prev].next = reservation.next;
        reservations[reservation.next].prev = reservation.prev;
        delete reservations[msg.sender];
        numOfReservations--;
        usdt.safeTransfer(msg.sender, RESERVATION_FEE);
    }

    function getReservations() external view returns (address[] memory) {
        address[] memory reservationAddresses = new address[](numOfReservations);
        Reservation storage current = reservations[GUARD];
        for (uint32 i = 0; i < numOfReservations; i++) {
            reservationAddresses[i] = current.next;
            current = reservations[current.next];
        }
        return reservationAddresses;
    }

    function executePurchaseStep(address reservationAddress) public {
        require(
            purchaseContractAddress != address(0),
            "The purchase contract address is not yet set"
        );
        require(
            purchaseContractAddress == msg.sender,
            "Only the purchase contract may perform the purchase step"
        );
        Reservation storage reservation = reservations[reservationAddress];
        require(
            reservation.prev != address(0),
            "No reservation found for this address"
        );
        // The purchase contract has to ensure that the reservation number is valid (off chain service + signed message)
        require(
            !reservation.bought,
            "This reservation has already been used to purchase a NiFTy3"
        );
        usdt.safeTransfer(purchaseContractAddress, RESERVATION_FEE);
        reservations[reservationAddress].bought = true;
    }

    function getReservationNumber(address reservationAddress) public view returns (uint32) {
        Reservation storage reservation = reservations[reservationAddress];
        require(
            reservation.prev != address(0),
            "No reservation found for this address"
        );
        uint32 index;
        while (reservation.prev != GUARD) {
            index++;
            reservation = reservations[reservation.prev];
        }
        return index;
    }

    function getReservationStatus(address reservationAddress) external view returns (string memory) {
        Reservation storage reservation = reservations[reservationAddress];
        require(
            reservation.prev != address(0),
            "No reservation found for this address or the reservation was cancelled"
        );
        if (reservation.bought) {
            return "This reservation was used to purchase a NiFTy3";
        } else {
            return "This reservation is open";
        }
    }
}
