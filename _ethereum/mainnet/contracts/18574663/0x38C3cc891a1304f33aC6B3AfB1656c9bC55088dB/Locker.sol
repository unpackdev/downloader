// SPDX-License-Identifier: UNLICENSED

import "./Ownable.sol";
import "./IERC20.sol";

pragma solidity ^0.8.19;

contract Locker is Ownable {
    uint256 fee;
    uint256 feePercentLP;
    address taxRecipient1;
    address taxRecipient2;
    Split public split;

    event NewLock(
        address lpAddress,
        address owner,
        uint256 amount,
        uint256 lockedAt,
        uint256 unlocksAt
    );

    struct Locks {
        address owner;
        address lpAddress;
        uint256 lockedAt;
        uint256 amount;
        uint256 unlocksAt;
        bool ended;
    }

    struct Split {
        uint256 split1;
        uint256 split2;
    }

    mapping(address => mapping(uint256 => Locks)) public lockers;
    mapping(address => uint256) public lockerNumber;

    receive() external payable {}

    constructor(
        address initialOwner,
        address _taxRecipient1,
        address _taxRecipient2
    ) Ownable(initialOwner) {
        fee = 0.05 ether;
        feePercentLP = 1;
        taxRecipient1 = _taxRecipient1;
        taxRecipient2 = _taxRecipient2;
        split.split1 = 50;
        split.split2 = 50;
    }

    function lock(
        address _lpAddress,
        uint256 _unlockTime,
        uint256 _amount
    ) external payable {
        require(msg.value == fee, "not enough eth sent for fee");
        require(
            _unlockTime > block.timestamp,
            "Unlock time needs to be in the future"
        );
        Locks storage locker = lockers[msg.sender][lockerNumber[msg.sender]];
        require(
            IERC20(_lpAddress).transferFrom(msg.sender, address(this), _amount)
        );

        // LP Taxes
        uint256 taxAmount = (_amount * feePercentLP) / 100;
        uint256 taxTo1 = (taxAmount * split.split1) / 100;
        uint256 taxTo2 = taxAmount - taxTo1;
        IERC20(_lpAddress).transfer(taxRecipient1, taxTo1);
        IERC20(_lpAddress).transfer(taxRecipient2, taxTo2);

        _amount = _amount - taxAmount;

        locker.amount = _amount;
        locker.lpAddress = _lpAddress;
        locker.lockedAt = block.timestamp;
        locker.owner = msg.sender;
        locker.unlocksAt = _unlockTime;

        lockerNumber[msg.sender]++;

        emit NewLock(
            _lpAddress,
            msg.sender,
            _amount,
            block.timestamp,
            _unlockTime
        );
    }

    function withdraw(uint256 _lockerNumber) external {
        Locks storage locker = lockers[msg.sender][_lockerNumber];
        require(!locker.ended, "Lock already claimed");
        require(block.timestamp >= locker.unlocksAt, "Lock has not ended");
        require(
            locker.owner == msg.sender,
            "you are not the owner of this lock"
        );
        locker.ended = true;
        require(IERC20(locker.lpAddress).transfer(locker.owner, locker.amount));
    }

    function viewLock(
        address _user,
        uint256 _lockerNumber
    ) public view returns (Locks memory) {
        return lockers[_user][_lockerNumber];
    }

    function changeFees(
        uint256 _newFee,
        uint256 _newFeePercentLP
    ) external onlyOwner {
        fee = _newFee;
        feePercentLP = _newFeePercentLP;
    }

    function changeTaxRecipient(
        address _newTaxRecipient1,
        address _newTaxRecipient2
    ) external onlyOwner {
        taxRecipient1 = _newTaxRecipient1;
        taxRecipient1 = _newTaxRecipient2;
    }

    function changeSplit(uint256 _split1, uint256 _split2) external onlyOwner {
        require(_split1 + _split2 == 100, "Please enter correct values");
        split.split1 = _split1;
        split.split2 = _split2;
    }

    function removeETH() external  {
        uint256 ethBalance = address(this).balance;
        uint256 taxTo1 = (ethBalance * split.split1) / 100;
        uint256 taxTo2 = ethBalance - taxTo1;
        (bool success1, ) = payable(taxRecipient1).call{value: taxTo1}("");
        (bool success2, ) = payable(taxRecipient2).call{value: taxTo2}("");
        require(success1 && success2);
    }
}
