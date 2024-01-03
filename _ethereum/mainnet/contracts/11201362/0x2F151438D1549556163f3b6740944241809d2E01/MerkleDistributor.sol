// SPDX-License-Identifier: MIT
pragma solidity =0.6.11;

import "./IERC20.sol";
import "./MerkleProof.sol";
import "./IMerkleDistributor.sol";

contract MerkleDistributor is IMerkleDistributor {
    address public immutable override token;
    bytes32 public immutable override merkleRoot;

    address public immutable dao;
    uint256 public immutable daoReleaseTime;

    // This is a packed array of booleans.
    mapping(uint256 => uint256) private claimedBitMap;
    address deployer;

    constructor(
        address token_,
        bytes32 merkleRoot_,
        address dao_,
        uint256 releaseTime_,
        address deployer_
    ) public {
        token = token_;
        merkleRoot = merkleRoot_;
        deployer = deployer_;

        dao = dao_;
        daoReleaseTime = releaseTime_;
    }

    function isClaimed(uint256 index) public override view returns (bool) {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWord = claimedBitMap[claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    function _setClaimed(uint256 index) private {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        claimedBitMap[claimedWordIndex] =
            claimedBitMap[claimedWordIndex] |
            (1 << claimedBitIndex);
    }

    function claim(
        uint256 index,
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof,
        uint256 tipBips
    ) external override {
        require(tipBips <= 10000);
        require(!isClaimed(index), "MerkleDistributor: Drop already claimed.");

        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(index, account, amount));
        require(
            MerkleProof.verify(merkleProof, merkleRoot, node),
            "MerkleDistributor: Invalid proof."
        );

        // Mark it claimed and send the token.
        _setClaimed(index);
        uint256 tip = account == msg.sender ? (amount * tipBips) / 10000 : 0;
        require(
            IERC20(token).transfer(account, amount - tip),
            "MerkleDistributor: Transfer failed."
        );
        if (tip > 0) require(IERC20(token).transfer(deployer, tip));

        emit Claimed(index, account, amount);
    }

    function unclaimedToDao() external {
        require(msg.sender == deployer, "!deployer");
        require(now >= daoReleaseTime, "before unclaimed release time");
        IERC20 enoki = IERC20(token);
        uint256 remainingUnclaimed = enoki.balanceOf(address(this));
        enoki.transfer(dao, remainingUnclaimed);
    }

    function collectDust(address _token, uint256 _amount) external {
        require(msg.sender == deployer, "!deployer");
        require(_token != token, "!token");
        if (_token == address(0)) {
            // token address(0) = ETH
            payable(deployer).transfer(_amount);
        } else {
            IERC20(_token).transfer(deployer, _amount);
        }
    }
}
