// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IPool.sol";
import "./IOE.sol";

contract PRIZEPOOL is Ownable, IPool {

    uint256 public evenAmount;
    uint256 public oddAmount;

    uint256 public lastBalance;

    struct withdrawItem {
        uint256 amount;
        uint256 time;
    }

    struct oeStorage {
        uint256 odd;
        uint256 even;
        uint256 oddIndex;
        uint256 evenIndex;
        uint256 balance;
    }

    event AddOdd(address user, uint256 amount);
    event AddEven(address user, uint256 amount);

    event RemoveOdd(address user);
    event RemoveEven(address user);

    event Update(address user, uint256 newOdd, uint256 newEven);

    event Withdraw(address user, uint256 amount);

    mapping(address => withdrawItem[]) public withdraws;
    mapping(address => oeStorage) public users;
    address[] public evenUsers;
    address[] public oddUsers;

    address public token;

    modifier onlyToken() {
        require(token == _msgSender() || owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    receive() external payable {}

    fallback() external payable {}

    function setTokenAddress(address _token) external onlyOwner {
        require(_token != address(0), 'Error: zero address');
        token = _token;
    }

    function getListOfUsers(bool isOdd) external view returns(address[] memory){
        if (isOdd) {
            return oddUsers;
        }
        return evenUsers;
    }

    function getUserWithdraws(address user) external view returns(withdrawItem[] memory) {
        return withdraws[user];
    }

    function addBuyer(address buyerAddress, uint256 amount, bool isOdd) external onlyToken {
        if (buyerAddress == address(0) || buyerAddress == token) {
            return;
        }
        if (isOdd) {
            oddAmount += amount;

            if (users[buyerAddress].odd == 0) {
                oddUsers.push(buyerAddress);
                users[buyerAddress].oddIndex = oddUsers.length;
            }

            users[buyerAddress].odd += amount;
            emit AddOdd(buyerAddress, amount);
        } else {
            evenAmount += amount;

            if (users[buyerAddress].even == 0) {
                evenUsers.push(buyerAddress);
                users[buyerAddress].evenIndex = evenUsers.length;
            }

            users[buyerAddress].even += amount;
            emit AddEven(buyerAddress, amount);
        }
    }

    function updateBuyer(address buyerAddress, uint256 amount, bool isOdd) external onlyToken {
        if (buyerAddress == address(0) || buyerAddress == token) {
            return;
        }
        uint256 balance = IOE(token).balanceOf(buyerAddress) - amount;
        if (isOdd) {
            if (users[buyerAddress].evenIndex > 0) {
                _updateEvenArrays(buyerAddress);

                evenAmount -= users[buyerAddress].even;
                users[buyerAddress].even = 0;
            }

            if (balance > 0) {
                oddAmount -= users[buyerAddress].odd;
                oddAmount += balance;

                if (users[buyerAddress].oddIndex == 0) {
                    oddUsers.push(buyerAddress);
                    users[buyerAddress].oddIndex = oddUsers.length;
                }
                users[buyerAddress].odd = balance;
            }
        } else {
            if (users[buyerAddress].oddIndex > 0) {
                _updateOddArrays(buyerAddress);

                oddAmount -= users[buyerAddress].odd;
                users[buyerAddress].odd = 0;
            }

            if (balance > 0) {
                evenAmount -= users[buyerAddress].even;
                evenAmount += balance;

                if (users[buyerAddress].evenIndex == 0) {
                    evenUsers.push(buyerAddress);
                    users[buyerAddress].evenIndex = evenUsers.length;
                }
                users[buyerAddress].even = balance;
            }
        }
        emit Update(buyerAddress, users[buyerAddress].odd, users[buyerAddress].even);
    }

    function _updateEvenArrays(address buyerAddress) internal {
        address lastEvenUser = evenUsers[evenUsers.length - 1];

        evenUsers[users[buyerAddress].evenIndex - 1] = lastEvenUser;
        evenUsers.pop();

        users[lastEvenUser].evenIndex = users[buyerAddress].evenIndex;
        users[buyerAddress].evenIndex = 0;
    }

    function _updateOddArrays(address buyerAddress) internal {
        address lastOddUser = oddUsers[oddUsers.length - 1];

        oddUsers[users[buyerAddress].oddIndex - 1] = lastOddUser;
        oddUsers.pop();

        users[lastOddUser].oddIndex = users[buyerAddress].oddIndex;
        users[buyerAddress].oddIndex = 0;
    }

    function deleteBuyer(address buyerAddress) external onlyToken {
        if (buyerAddress == address(0) || buyerAddress == token) {
            return;
        }
        if (users[buyerAddress].oddIndex > 0) {
            _updateOddArrays(buyerAddress);
            oddAmount -= users[buyerAddress].odd;
            users[buyerAddress].odd = 0;

            emit RemoveOdd(buyerAddress);
        }
        if (users[buyerAddress].evenIndex > 0) {
            _updateEvenArrays(buyerAddress);
            evenAmount -= users[buyerAddress].even;
            users[buyerAddress].even = 0;

            emit RemoveEven(buyerAddress);
        }
    }

    function withdrawByUser() external {
        require(users[msg.sender].balance > 0, 'Error balance amount');

        lastBalance -= users[msg.sender].balance;
        uint256 transferBalance = users[msg.sender].balance;
        users[msg.sender].balance = 0;

        payable(msg.sender).transfer(transferBalance);

        withdrawItem memory item = withdrawItem(transferBalance, block.timestamp);
        withdraws[msg.sender].push(item);
        emit Withdraw(msg.sender, transferBalance);
    }

    function activatePool() external onlyOwner {
        bool isOdd = IOE(token).getIsOdd();
        uint256 balance = address(this).balance - lastBalance;

        uint256 amount = 0;
        if (isOdd) {
            uint256 unit = balance * 1 ether / oddAmount;

            for (uint256 i = 0; i < oddUsers.length; i++) {
                amount = unit * users[oddUsers[i]].odd;
                users[oddUsers[i]].balance += amount / 1 ether;
            }
        } else {
            uint256 unit = balance * 1 ether / evenAmount;

            for (uint256 i = 0; i < evenUsers.length; i++) {
                amount = unit * users[evenUsers[i]].even;
                users[evenUsers[i]].balance += amount / 1 ether;
            }
        }
        lastBalance = address(this).balance;
    }
}
