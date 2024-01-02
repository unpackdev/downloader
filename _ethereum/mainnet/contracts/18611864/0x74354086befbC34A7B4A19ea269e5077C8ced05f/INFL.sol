// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Iinfl.sol";
import "./IOE.sol";

contract INFL is Ownable, Iinfl {

    struct infl {
        uint256 balance;
        uint256 totalIncome;
        uint256 totalWithdraw;
        uint256 percent;
    }

    mapping(address => infl) public users;
    address[] public activeUsers;
    uint256 public totalShare;

    address public token;

    receive() external payable {}

    fallback() external payable {}

    function _getInfl(address _infl) internal view returns(address, uint256) {
        address zInfl = address(0);
        for (uint256 i = 0; i < activeUsers.length; ++i) {
            if (activeUsers[i] == _infl) {
                return (activeUsers[i], i);
            }
        }
        return (zInfl, 0);
    }

    function setTokenAddress(address _token) external onlyOwner {
        require(_token != address(0), 'Error: zero address');
        token = _token;
    }

    function addInfl(address _infl, uint256 _percent) external onlyOwner {
        (address rInfl,) = _getInfl(_infl);

        if (rInfl == address(0)) {
            activeUsers.push(_infl);
        }
        if (users[_infl].percent > 0) {
            totalShare -= users[_infl].percent;
        }

        users[_infl].percent = _percent;
        totalShare += users[_infl].percent;
    }

    function deleteInfl(address _infl) external onlyOwner {
        (address rInfl, uint256 index) = _getInfl(_infl);
        require(rInfl != address(0), 'Error: user is not exist');

        address lastUser = activeUsers[activeUsers.length - 1];

        totalShare -= users[rInfl].percent;

        activeUsers[index] = lastUser;
        activeUsers.pop();
    }

    function emergencyWithdraw() external onlyOwner {
        uint256 balance = address(this).balance;

        payable(owner()).transfer(balance);
    }

    function inflWithdraw() external {
        uint256 balance = users[msg.sender].balance;
        users[msg.sender].balance = 0;
        users[msg.sender].totalWithdraw += balance;

        payable(msg.sender).transfer(balance);
    }

    function addPayment() external payable {
        uint256 amount = msg.value;
        uint256 chunk = amount / totalShare;

        for (uint256 i = 0; i < activeUsers.length; ++i) {
            users[activeUsers[i]].balance += chunk * users[activeUsers[i]].percent;
            users[activeUsers[i]].totalIncome += chunk * users[activeUsers[i]].percent;
        }
    }
}
