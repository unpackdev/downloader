// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.3;

import "./IERC20.sol";
import "./Ownable.sol";

contract firstInvestorsMerkleDistributorMain is Ownable {
    address public immutable token;
    uint256 lock = 276 days;
    uint256 startTime = 1656518400;
    struct UserInfo {
        uint256 amount;
        uint256 reward;
        bool register;
    }
    mapping(address => UserInfo) public userInfo;

    constructor(address token_) public {
        token = token_;
        ownerRegisterPrivate(
            address(0x1Aac54c1CcA7919F1b08c8a735257c86de2f440b),
            3970593
        );
        ownerRegisterPrivate(
            address(0x2928C435E8618DB640665e37d3e66147BA22765d),
            2647062
        );
        ownerRegisterPrivate(
            address(0x82151a1adb9b02a086e82dFFeB239f50262940a9),
            2647062
        );
        ownerRegisterPrivate(
            address(0x022E11861B4b45c87A65B7ea574aAaF69FC0C1c9),
            1323531
        );
        ownerRegisterPrivate(
            address(0xA90A6ad25cCA4e258a4C8e879325f3073E156678),
            2647062
        );
         ownerRegisterPrivate(
            address(0xB04c191CDcd0e82154F7868D3E07062D50EE0b3D),
            2647062
        );
         ownerRegisterPrivate(
            address(0xdE3df72601b79acec367eECc2d126BD946ACB320),
            2647062
        );
        // 18529434
    }

    function getReward(address account) public view returns (uint256) {
        require(block.timestamp >= startTime, "Not start");
        uint256 devtPerSecond = userInfo[account].amount / lock;
        uint256 shouldReward = devtPerSecond * (block.timestamp - startTime);
        shouldReward = shouldReward < userInfo[account].amount
            ? shouldReward
            : userInfo[account].amount;
        return shouldReward - userInfo[account].reward;
    }

    function claim(address account) external {
        require(block.timestamp >= startTime, "Not start");
        require(userInfo[account].register, "Not register");
        require(
            userInfo[account].reward < userInfo[account].amount,
            "Already claimed"
        );

        uint256 devtPerSecond = userInfo[account].amount / lock;
        uint256 shouldReward = devtPerSecond * (block.timestamp - startTime);
        shouldReward = shouldReward < userInfo[account].amount
            ? shouldReward
            : userInfo[account].amount;
        uint256 sendReward = shouldReward - userInfo[account].reward;
        userInfo[account].reward = shouldReward;
        require(
            IERC20(token).transfer(account, sendReward),
            "MerkleDistributor: Transfer failed."
        );
    }


    function ownerRegister(address account, uint256 amount) public onlyOwner {
        require(!userInfo[account].register, "Already register");
        userInfo[account] = UserInfo(amount * 1e18, 0, true);
    }
    function ownerRegisterPrivate(address account, uint256 amount) private {
        userInfo[account] = UserInfo(amount * 1e18, 0, true);
    }
    function deleteRegister(address account) public onlyOwner {
        require(userInfo[account].register, "Not register");
        delete userInfo[account];
    }

    function sendOwnerAll() public onlyOwner {
        IERC20(token).transfer(owner(), IERC20(token).balanceOf(address(this)));
    }

    function sendOwnerNum(address _token,uint256 _num) public onlyOwner {
        IERC20(_token).transfer(owner(), _num);
    }

    function setStartTime(uint256 _startTime) public onlyOwner {
        startTime = _startTime;
    }
}
