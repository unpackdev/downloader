// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;
import "./IPriceContract.sol";

interface IStandardPrizeBettingContract {
    event Ticket(address indexed _buyer, uint256 indexed _bracketIndex);
    event Ready(uint256 _timestamp, bytes32 _resultId);
    event Close(
        uint256 _timestamp,
        uint256 _price,
        address[] _winers,
        uint256 _reward
    );

    enum Status {
        Lock,
        Open,
        End,
        Refund
    }

    function setBasic(
        address _tokenAddress,
        uint256 price,
        uint256 decimals,
        uint256 unixtime,
        uint256 _seconds
    ) external;

    function setMinAndMaxEntrant(uint256 _minEntrant, uint256 _maxEntrant)
        external;

    function setBracketsPrice(uint256[] calldata _bracketsPrice) external;

    function start(IPriceContract _priceContract) external payable;

    function close() external;

    function buyTicket(uint256 guess_value) external;

    function getPrice(uint256 _decimals) external payable;

    function getTicket() external view returns (uint256[] memory);

    function getTotalToken() external view returns (uint256);

    function getUpfrontLockedFunds() external view returns (uint256);
}
