// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";

import "./TransferHelper.sol";
import "./IDeltaNFT.sol";

contract DeltaBRC20LuckyPool is ReentrancyGuard, Ownable {
    bool private initialized_; // Flag of initialize data
    bytes32 public merkleRoot;

    address public controllAddress;

    address public targetToken;
    address public costToken;
    address public poolAddress;

    uint256 public oneSharePrice;

    uint256 public totalOfferFund = 0;
    uint256 public totalOfferUser = 0;

    uint256 public oneShareAmount;
    uint256 public offerStartTime;
    uint256 public offerEndTime;

    uint256 public totalShares;

    uint256 public drawTime;
    address public deltaNFT;
    IDeltaNFT.UnlockArgs public unlockArgs;

    mapping(address => uint256) public userStatus; // 0: init, 1: offer, 2: refund, 3: draw

    mapping(address => bool) public whitelists;

    string[] public btcAddresses;

    event SetUnlockArgsAndRoot(IDeltaNFT.UnlockArgs unlockArgs, bytes32 root);
    event Offer(address indexed user, uint256 oneSharePrice);
    event Draw(
        address indexed user,
        uint256 tokenId,
        IDeltaNFT.UnlockArgs unlockArgs
    );
    event SetWhiteList(address indexed sender, address indexed user);
    event Withdraw(address indexed user, uint256 totalOfferFund);

    function initialize(
        address[5] calldata args1,
        uint256[6] calldata args2,
        address _poolAddress
    ) external returns (address) {
        require(!initialized_, "DeltaPool: Already initialized!");

        _transferOwnership(args1[0]);
        controllAddress = args1[1];
        targetToken = args1[2];
        costToken = args1[3];
        deltaNFT = args1[4];

        oneSharePrice = args2[0];
        oneShareAmount = args2[1];
        offerStartTime = args2[2];
        offerEndTime = args2[3];

        drawTime = args2[4];
        totalShares = args2[5];
        poolAddress = _poolAddress;
        initialized_ = true;
        return address(this);
    }

    function setUnlockArgsAddRoot(
        IDeltaNFT.UnlockArgs calldata _unlockArgs,
        bytes32 _merkleRoot
    ) external {
        require(
            msg.sender == owner() || msg.sender == controllAddress,
            "DeltaPool:No auth"
        );
        unlockArgs = _unlockArgs;
        merkleRoot = _merkleRoot;
        emit SetUnlockArgsAndRoot(_unlockArgs, _merkleRoot);
    }

    function getUnlockArgs()
        external
        view
        returns (
            uint256 firstReleaseTime,
            uint256 firstBalance,
            uint256 remainingUnlockedType,
            uint256[4] memory remainingUnlocked,
            uint256 totalBalance
        )
    {
        firstReleaseTime = unlockArgs.firstReleaseTime;
        firstBalance = unlockArgs.firstBalance;
        remainingUnlockedType = unlockArgs.remainingUnlockedType;
        remainingUnlocked = unlockArgs.remainingUnlocked;
        totalBalance = unlockArgs.totalBalance;
    }

    function subOffer(
        uint256 senderIndex,
        address account,
        uint256 amount,
        bytes32[] memory merkleProof
    ) external payable nonReentrant {
        address user = msg.sender;
        require(account == user, "sender != account");

        require(userStatus[account] == 0, "has offer");
        require(
            offerStartTime <= block.timestamp &&
                block.timestamp <= offerEndTime,
            "not start or has end"
        );

        // Verify the merkle proof.
        bytes32 node = keccak256(
            abi.encodePacked(senderIndex, account, amount)
        );
        bool isWhitelist = false;
        if (
            MerkleProof.verify(merkleProof, merkleRoot, node) ||
            whitelists[account]
        ) {
            isWhitelist = true;
        }
        require(isWhitelist, "DeltaPool: not in whitelist.");

        if (costToken == address(0)) {
            require(msg.value == oneSharePrice, "DeltaPool: value error.");
        } else {
            TransferHelper.safeTransferFrom(
                costToken,
                user,
                address(this),
                oneSharePrice
            );
        }
        totalOfferUser++;
        totalOfferFund += oneSharePrice;

        userStatus[user] = 1;

        emit Offer(user, oneSharePrice);
    }

    // for view
    function isPublish() public view returns (bool) {
        return block.timestamp > offerEndTime;
    }

    // for front
    function refund() external nonReentrant {
        require(false, "not end");
    }

    // for view
    function isLuckyDog(address user) public view returns (bool) {
        require(block.timestamp > offerEndTime, "Offer stage!!!");
        if (userStatus[user] == 0 || userStatus[user] == 2) {
            return false;
        }

        if (userStatus[user] == 3 || userStatus[user] == 1) {
            return true;
        }
        return false;
    }

    // get nft
    function draw() external nonReentrant {
        require(block.timestamp > offerEndTime, "Offer stage!!!");
        address user = msg.sender;
        require(userStatus[user] == 1, "not offer");
        require(block.timestamp > drawTime, "not end");
        require(isLuckyDog(user), "not lucky dog");
        userStatus[user] = 3;
        uint256 tokenId = IDeltaNFT(deltaNFT).mintNFT(
            _msgSender(),
            unlockArgs,
            IDeltaNFT.TargetArgs({
                targetToken: targetToken,
                poolAddress: poolAddress
            })
        );
        emit Draw(user, tokenId, unlockArgs);
    }

    function setWhiteList(address user) external nonReentrant onlyOwner {
        whitelists[user] = true;
        emit SetWhiteList(msg.sender, user);
    }

    function withdraw() external nonReentrant onlyOwner {
        uint256 total = totalShares * oneSharePrice;
        if (costToken == address(0)) {
            payable(msg.sender).transfer(total);
        } else {
            TransferHelper.safeTransfer(costToken, msg.sender, total);
        }

        emit Withdraw(msg.sender, total);
    }

    function onERC721Received(
        address /*operator*/,
        address /*from*/,
        uint256 /*tokenId*/,
        bytes memory /*data*/
    ) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
