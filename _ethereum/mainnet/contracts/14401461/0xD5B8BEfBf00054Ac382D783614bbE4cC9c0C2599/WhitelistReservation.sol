// SPDX-License-Identifier: None

// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@&&&&&&&&&&@@@@@@@@@%(******/(%%%&@@@@@@@@@@@@@&%%%%%&&&&%&@@@@@@@@@@
// @@@@@@@@&(.            .,*%@&/.              ,(%@@@@@@&/.             .#@@@@@@@@
// @@@@@@@@@&%#*.  ./###(,    .(%(*.      ....    ./&@@@%,     ,*,.       /@@@@@@@@
// @@@@@@@@@@@@#,  .(@@@@@%,   .#@&(.   ,#@@@@&*    *%@%,   .(@@@@@%*    .(@@@@@@@@
// @@@@@@@@@@@@(.  ,#@@@@@%*   ,#@@#.   ,#@@@@@@*   ,#@#.  ./&@@@@@@&(.  .#@@@@@@@@
// @@@@@@@@@@@@#,             ,%@@@#,   ,%@@@@@@(.  ./%/   .(@@@@@@@@@&#(#@@@@@@@@@
// @@@@@@@@@@@@#,         .*#&@@@@@#.   ,%@@@@@@(.   *#*   .#@@@@@@@&/. .*%@@@@@@@@
// @@@@@@@@@@@@#,   *@@@@@@@@@@@@@@#,   ,%@@@@@&*   ./&(   .(@@@@@@@%*    /@@@@@@@@
// @@@@@@@@@@@@%,  ./@@@@@@@@@@@@@@%,   *&@@@@&*    *%@%,   ,#@@@@@%*    ,%@@@@@@@@
// @@@@@@@@@@@&(,   *%&@@@@@@@@@@@&(,   .*(/,.     *%@@@@/.   ,,,.      *&@@@@@@@@@
// @@@@@@@@@%,         /&@@@@@@@%*              .,#@@@@@@@&#*        ./%@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

pragma solidity ^0.8.9;

import "./Ownable.sol";

/**
 * @dev Whitelist reservation contract for Prisoner's Dilemma Club
 */
contract WhitelistReservation is Ownable {
    uint256 costToReserve = .2 ether;
    uint256 public constant MAX_RESERVATIONS = 2501; // comparison with less than due to gas savings
    uint256 public reservationCount = 0;
    address public withdrawalAddress;
    address[] public reservationList; // allows the whitelist to be read for inclusion in the merkle tree
    mapping(address => bool) public addressHasReserved; // allows users to check for themselves if they have a reservation

    constructor() {}

    /**
     * Standard fallback function to allow contract to receive payments
     */
    receive() external payable {}

    /**
     * @dev Withdraw all ether from this contract and send to prespecified address
     */
    function withdraw() external onlyOwner {
        require(withdrawalAddress != address(0), "Withdrawal address must be set");
        payable(withdrawalAddress).transfer(address(this).balance);
    }

    function setWithdrawalAddress(address _address) external onlyOwner {
        withdrawalAddress = _address;
    }

    /**
     * @dev Pay .2 ether to reserve a spot on the PDC presale whitelist
     */
    function reserveWhitelistSpot() external payable {
        require(msg.value == costToReserve, "Incorrect payment amount");
        require(addressHasReserved[msg.sender] == false, "Address already reserved");
        require(reservationCount + 1 < MAX_RESERVATIONS, "Reservations closed");

        reservationCount++;
        addressHasReserved[msg.sender] = true;
        reservationList.push(msg.sender);
    }
}
