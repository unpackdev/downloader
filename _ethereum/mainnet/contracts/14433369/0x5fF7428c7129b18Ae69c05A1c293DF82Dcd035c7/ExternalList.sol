// contracts/NFT.sol
// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "./Ownable.sol";

contract ExternalList is Ownable {
    mapping(address => bool) public list;

    address public mpcController;

    event ExternalListAdded(address[] users);

    function setMpcController(address _mpcController) public onlyOwner {
        mpcController = _mpcController;
    }

    function setList(address[] memory _users) public onlyOwner {
        for (uint256 x = 0; x < _users.length; x++) {
            list[_users[x]] = true;
        }
        emit ExternalListAdded(_users);
    }

    function isOnList(address _user) public view returns (bool) {
        return list[_user];
    }

    function updateList(address _user) public {
        require(msg.sender == mpcController, "err: caller is not MPC Controller");
        list[_user] = false;
    }
}
