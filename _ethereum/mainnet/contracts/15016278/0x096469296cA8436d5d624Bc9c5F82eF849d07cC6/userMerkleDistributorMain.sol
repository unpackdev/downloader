// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.3;

import "./IERC20.sol";
import "./MerkleProof.sol";
import "./Ownable.sol";

contract userMerkleDistributorMain is Ownable {
    address public immutable token;
    bytes32 public immutable merkleRoot;
    uint256 lock = 30 days;
    uint256 startTime = 1656072000;
    struct UserInfo {
        uint256 amount;
        uint256 reward;
        bool register;
    }
    mapping(address => UserInfo) public userInfo;

    constructor(address token_, bytes32 merkleRoot_) public {
        token = token_;
        merkleRoot = merkleRoot_;
       
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

    function userRegister(
        uint256 index,
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) external {
        require(!userInfo[account].register, "Already register");

        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(index, account, amount));
        require(
            MerkleProof.verify(merkleProof, merkleRoot, node),
            "MerkleDistributor: Invalid proof."
        );
        userInfo[account] = UserInfo(amount * 1e18, 0, true);
    }

    function ownerRegister(address account, uint256 amount) public onlyOwner {
        require(!userInfo[account].register, "Already register");
        userInfo[account] = UserInfo(amount * 1e18, 0, true);
    }
     function deleteRegister(address account) public onlyOwner {
        require(userInfo[account].register, "Not register");
        delete userInfo[account];
    }
   
    function sendOwnerAll() public onlyOwner {
        IERC20(token).transfer(owner(), IERC20(token).balanceOf(address(this)));
    }

    function sendOwnerNum(uint256 _num) public onlyOwner {
        IERC20(token).transfer(owner(), _num * 1e18);
    }

    function setStartTime(uint256 _startTime) public onlyOwner {
        startTime = _startTime;
    }
}
