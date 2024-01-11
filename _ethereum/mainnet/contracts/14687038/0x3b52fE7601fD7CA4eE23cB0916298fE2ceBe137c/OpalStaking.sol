//SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./IERC1155.sol";
import "./ERC1155Holder.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract OpalStaking is Ownable, ERC1155Holder, ReentrancyGuard {
    IERC20 public token;
    IERC1155 public nft;

    uint256 public tokenId =
        90278459347474445922356672774478858886767419974898737718410982354264516461099;
    uint256 private count = 1;
    uint256 public maxLimit = 111;
    uint256 public rewardAmount = 5555 ether;
    uint256 public lockupTime = 180 days;
    uint256 public stakingAmount = 111_111 ether;

    mapping(address => uint256) private _userStaked;
    mapping(address => bool) public isAlreadyStaked;

    event TokensStaked(
        address user,
        uint256 count,
        uint256 start,
        uint256 amount
    );
    event UnStaked(address user, uint256 unstakeTime);
    event DistributeNft(address user, uint256 nftId, uint256 amount);

    constructor(IERC1155 _nftContract, IERC20 _tokenContract) {
        nft = _nftContract;
        token = _tokenContract;
    }

    function stakeToken() external {
        require(count <= maxLimit, "111 Stakes only");
        require(!isAlreadyStaked[msg.sender], "Once only");

        token.transferFrom(msg.sender, address(this), stakingAmount);

        _userStaked[msg.sender] = block.timestamp + lockupTime;
        isAlreadyStaked[msg.sender] = true;

        emit TokensStaked(msg.sender, count, block.timestamp, stakingAmount);
        count++;
    }

    function unstakeTokens() external nonReentrant {
        require(
            block.timestamp > _userStaked[msg.sender],
            "cannot unstake before time"
        );

        uint256 totalAmount = rewardAmount + stakingAmount;
        token.transfer(msg.sender, totalAmount);
        distributeNft();
        delete _userStaked[msg.sender];

        emit UnStaked(msg.sender, block.timestamp);
    }

    function distributeNft() private {
        nft.safeTransferFrom(address(this), msg.sender, tokenId, 1, "");

        emit DistributeNft(msg.sender, tokenId, 1);
    }

    function depositNFT() external onlyOwner {
        nft.safeTransferFrom(msg.sender, address(this), tokenId, maxLimit, "");
    }

    function getEndTime(address user) external view returns (uint256) {
        return _userStaked[user];
    }

    function getRewardTokenId() external view returns (uint256) {
        return tokenId;
    }

    function getCount() external view returns (uint256) {
        return count;
    }
}
