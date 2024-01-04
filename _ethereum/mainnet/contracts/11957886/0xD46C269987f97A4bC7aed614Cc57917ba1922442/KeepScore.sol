pragma solidity ^0.6.0;

import "./AccessControl.sol";

// proof of concept for keeping score based on different contracts that can add to it with right role
contract KeepScore is AccessControl {
    bytes32 public constant SCORER_ROLE = keccak256("SCORER_ROLE");
    mapping(address => uint256) public score;

    constructor() public {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(SCORER_ROLE, _msgSender());
    }

    function add(uint256 _points, address _user) external {
        require(hasRole(SCORER_ROLE, _msgSender()), "Must have scorer role");
        score[_user] += _points;
    }
}
