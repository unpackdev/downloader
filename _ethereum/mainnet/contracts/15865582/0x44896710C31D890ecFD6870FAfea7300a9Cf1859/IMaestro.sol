pragma solidity ^0.8.15;

import "./IERC721.sol";

interface IMaestro is IERC721 {
    function notifyTicketStaked(
        bool _status,
        address _user,
        uint8 _tier
    ) external;
}
