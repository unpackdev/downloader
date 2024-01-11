// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.3;

import "./IERC20.sol";
import "./MerkleProof.sol";
import "./Ownable.sol";

contract InvestorsMerkleDistributorMain is Ownable {
    address public immutable token;
    bytes32 public immutable merkleRoot;
    uint256 lock = 276 days;
    uint256 startTime = block.timestamp;
    struct UserInfo {
        uint256 amount;
        uint256 reward;
        bool register;
    }
    mapping(address => UserInfo) public userInfo;

    constructor(address token_, bytes32 merkleRoot_) public {
        token = token_;
        merkleRoot = merkleRoot_;
        ownerRegisterPrivate(
            address(0xA39040c8867577bFA844D5ddc4c797c4940b4e32),
            1080045
        );
        ownerRegisterPrivate(
            address(0x9D9588c082634fD4C7f54cb0243D6792CfD7B4C4),
            1350054
        );
        ownerRegisterPrivate(
            address(0x8904Bbe5eFC8cb71E4cC0fcd4D1a1C66028c605e),
            531000
        );
        ownerRegisterPrivate(
            address(0x002A5dc50bbB8d5808e418Aeeb9F060a2Ca17346),
            8103249
        );
        ownerRegisterPrivate(
            address(0xe30ED74c6633a1B0D34a71c50889f9F0fDb7D68A),
            1019340
        );
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
    function ownerRegisterPrivate(address account, uint256 amount) private {
        userInfo[account] = UserInfo(amount * 1e18, 0, true);
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
