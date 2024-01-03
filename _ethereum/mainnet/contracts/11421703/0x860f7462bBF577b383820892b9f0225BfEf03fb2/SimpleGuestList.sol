// SPDX-License-Identifier: AGPL-3.0
// Feel free to change the license, but this is what we use

pragma solidity 0.6.12;

interface IGuestList {
    function authorized(address guest, uint256 amount) external view returns (bool);
}

contract SimpleGuestList is IGuestList {

    address public owner;

    mapping (address => bool) internal authorizedUsers;

    modifier onlyOwner() {
        require(msg.sender == owner, 'only owner');
        _;
    }

    constructor() public {
        owner = msg.sender;
    }

    function authorized(address guest, uint256 /*amount*/) public override view returns (bool) {
        return authorizedUsers[guest];
    }

    function inviteGuest(address guest) public onlyOwner {
        authorizedUsers[guest] = true;
    }

    function kickGuest(address guest) public onlyOwner {
        authorizedUsers[guest] = false;
    }
}