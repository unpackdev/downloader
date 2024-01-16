// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;
import "./IPriceContract.sol";

interface IBettingContract {
    event Ticket(
        address indexed _buyer,
        uint256 indexed _bracketIndex,
        uint256 _feeForPool
    );
    event Ready(uint256 _timestamp);
    event Close(
        uint256 _timestamp,
        uint256 _price,
        uint256 _reward,
        Status _status
    );

    enum Status {
        Lock,
        Open,
        End,
        Refund
    }

    struct ResultID {
        bytes32 id;
        uint256 timestamp;
    }

    function setBasic(
        address _tokenAddress,
        uint256 price,
        uint256 decimals,
        uint256 unixtime,
        uint256 _seconds
    ) external;

    function setBracketsPrice(uint256[] calldata _bracketsPrice) external;

    function start(IPriceContract _priceContract) external payable;

    function distributeReward() external;

    function buyTicket(uint256 guess_value, address _user) external;

    function getPrice(uint256 _decimals) external payable;

    function getTicket(address user) external view returns (uint256);

    function getTotalToken() external view returns (uint256);

    function getDataToCheckRefund()
        external
        view
        returns (
            bytes32,
            uint256,
            uint256
        );

    function getTicketPrice() external view returns (uint256);

    function getFee() external view returns (uint256);
}
