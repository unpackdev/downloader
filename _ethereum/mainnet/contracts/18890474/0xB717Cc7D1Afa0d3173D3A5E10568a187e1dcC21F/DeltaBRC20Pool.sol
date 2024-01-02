// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";

import "./TransferHelper.sol";
import "./IDeltaPool.sol";
import "./IDeltaPoolController.sol";

contract DeltaBRC20Pool is IDeltaPool, ReentrancyGuard, Ownable {
    bool private initialized_; // Flag of initialize data
    bytes32 public merkleRoot;

    uint256 public randomSeed;
    uint256 public constant INT_BASE = 100000;

    bool private redistributionTag;
    uint256[] public levelOfferCounts;
    uint256[] public levelShares;
    uint256 public maxLevel;

    uint256 public totalOfferFund = 0;
    uint256 public totalOfferUser = 0;
    uint256 public totalDrawUser = 0;

    address public controllAddress;

    address public targetToken;
    address public costToken;

    uint256 public oneSharePrice;
    uint256 public oneShareAmount;
    uint256 public offerStartTime;
    uint256 public offerEndTime;

    uint256 public totalShares;

    uint256 public drawTime;
    bool public isPublish;

    address public deltaNFT;
    IDeltaNFT.UnlockArgs public unlockArgs;

    mapping(address => uint256) public userStatus; // 0: init, 1: offer, 2: refund, 3: draw

    mapping(address => uint256) public userIndexs;
    mapping(address => uint256) public userLevels;
    string[] public btcAddresses;

    mapping(address => string[]) public userBTCAddress;

    event SetUnlockArgsAndRoot(IDeltaNFT.UnlockArgs unlockArgs, bytes32 root);
    event Offer(
        address indexed user,
        uint256 level,
        uint256 luckyNumber,
        uint256 oneSharePrice
    );
    event LuckySeed(uint256 luckySeed);
    event Refund(address indexed user, uint256 amount);
    event Draw(
        address indexed user,
        uint256 tokenId,
        IDeltaNFT.UnlockArgs unlockArgs
    );
    event Unlock(
        address indexed user,
        uint256 tokenId,
        uint256 newTokenId,
        uint256 amount
    );

    event SetBTCAddress(
        address indexed user,
        uint256 tokenId,
        string btcAddress
    );
    event Withdraw(address indexed user, uint256 totalOfferFund);

    modifier afterPublish() {
        require((isPublish), "afterPublish: not publish");
        _;
    }

    function initialize(
        address[5] calldata args1,
        uint256[6] calldata args2
    ) external override returns (address) {
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

        maxLevel = IDeltaPoolController(controllAddress).getMaxLevel();

        uint hasAllocShares = 0;
        for (uint i = 0; i < maxLevel - 1; i++) {
            uint shareValRate = IDeltaPoolController(controllAddress)
                .getShareAlloc(i);
            uint share = (totalShares * shareValRate) / INT_BASE;
            hasAllocShares = hasAllocShares + share;
            levelOfferCounts.push(0);
            levelShares.push(share);
        }

        levelOfferCounts.push(0);
        levelShares.push(totalShares - hasAllocShares);
        initialized_ = true;
        return address(this);
    }

    function setUnlockArgsAddRoot(
        IDeltaNFT.UnlockArgs calldata _unlockArgs,
        bytes32 _merkleRoot
    ) external override {
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
        override
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
    )
        external
        payable
        override
        nonReentrant
        returns (uint256 userLevel, uint256 userIndex)
    {
        require(
            offerStartTime <= block.timestamp &&
                block.timestamp <= offerEndTime,
            "not start or has end"
        );

        address user = msg.sender;
        require(account == user, "sender != account");
        require(userStatus[account] == 0, "has offer");
        require(userLevels[account] == 0, "has offer");

        // Verify the merkle proof.
        bytes32 node = keccak256(
            abi.encodePacked(senderIndex, account, amount)
        );
        require(
            MerkleProof.verify(merkleProof, merkleRoot, node),
            "DeltaPool: Invalid proof."
        );

        // require(amount >= 200, "The stake amount cannot be less than 1000");

        userLevel = IDeltaPoolController(controllAddress).getLevelByAmount(
            amount
        );
        require(userLevel > 0, "no power");
        if (costToken == address(0)) {
            require(msg.value == oneSharePrice, "not enough");
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

        levelOfferCounts[userLevel - 1] += 1;

        userIndex = levelOfferCounts[userLevel - 1];
        userIndexs[user] = userIndex;

        userLevels[user] = userLevel;
        userStatus[user] = 1;
        emit Offer(user, userLevel, userIndex, oneSharePrice);
    }

    function luckyrandomNum() external onlyOwner returns (uint256) {
        require(block.timestamp > offerEndTime, "Offer stage!!!");
        require(!isPublish, "has publish");
        isPublish = true;
        for (uint256 i = levelShares.length - 1; i >= 0; i--) {
            if (levelOfferCounts[i] >= levelShares[i]) {
                if (i == 0) {
                    break;
                } else {
                    continue;
                }
            } else {
                if (i > 0) {
                    uint256 beforeShare = levelShares[i];
                    levelShares[i] = levelOfferCounts[i];
                    levelShares[i - 1] += (beforeShare - levelOfferCounts[i]);
                } else {
                    uint256 beforeAllSpareShares = levelShares[0];
                    if (beforeAllSpareShares > levelOfferCounts[0]) {
                        levelShares[0] = levelOfferCounts[0];
                        uint256 allSpareShares = beforeAllSpareShares -
                            levelShares[0];
                        // once again
                        if (!redistributionTag) {
                            redistribution(allSpareShares);
                            redistributionTag = true;
                        }
                    }
                    break;
                }
            }
        }

        randomSeed = uint256(
            keccak256(
                abi.encodePacked(block.timestamp, block.gaslimit, msg.sender)
            )
        );
        emit LuckySeed(randomSeed);
        return randomSeed;
    }

    function redistribution(uint256 allSpareShares) internal {
        for (uint256 i = levelShares.length - 1; i > 0; i--) {
            if (levelOfferCounts[i] <= levelShares[i]) {
                continue;
            } else {
                uint256 beforeShare = levelShares[i];
                if (levelOfferCounts[i] - beforeShare >= allSpareShares) {
                    levelShares[i] = beforeShare + allSpareShares;
                    break;
                } else {
                    levelShares[i] = levelOfferCounts[i];
                    allSpareShares -= levelOfferCounts[i] - beforeShare;
                }
            }
        }
    }

    function isLuckyDog(
        address user
    ) public view override afterPublish returns (bool) {
        if (
            userLevels[user] == 0 ||
            userStatus[user] == 0 ||
            userStatus[user] == 2
        ) {
            return false;
        }

        if (userStatus[user] == 3) {
            return true;
        }

        // require(userLevels[user] != 0, "not offer");
        // require(userStatus[user] == 1, "not offer");
        uint256 userLevel = userLevels[user];
        uint256 offers = levelOfferCounts[userLevel - 1];
        uint256 levelShare = levelShares[userLevel - 1];
        uint256 userIndex = userIndexs[user];
        if (offers <= levelShare) {
            return true;
        } else {
            uint256 luckyNum = randomSeed % offers;
            if (luckyNum + levelShare >= offers) {
                if (userIndex > luckyNum) {
                    return true;
                } else {
                    uint256 cyclesNum = luckyNum + levelShare - offers;
                    if (userIndex <= cyclesNum) {
                        return true;
                    } else {
                        return false;
                    }
                }
            } else {
                if (
                    userIndex > luckyNum && userIndex <= luckyNum + levelShare
                ) {
                    return true;
                } else {
                    return false;
                }
            }
        }
    }

    function refund() external override afterPublish nonReentrant {
        address user = msg.sender;
        require(userLevels[user] != 0, "not offer");
        require(userStatus[user] == 1, "not offer");
        require(block.timestamp > drawTime, "not end");
        require(!isLuckyDog(user), "is lucky dog!");
        userStatus[user] = 2;
        if (costToken == address(0)) {
            payable(user).transfer(oneSharePrice);
        } else {
            TransferHelper.safeTransfer(costToken, user, oneSharePrice);
        }
        emit Refund(user, oneSharePrice);
    }

    // get nft lock token
    function draw() external override afterPublish nonReentrant {
        address user = msg.sender;
        require(userLevels[user] != 0, "not offer");
        require(userStatus[user] == 1, "not offer");
        require(block.timestamp > drawTime, "not end");
        require(isLuckyDog(user), "not lucky dog");
        userStatus[user] = 3;
        uint256 tokenId = IDeltaNFT(deltaNFT).mintNFT(
            _msgSender(),
            unlockArgs,
            IDeltaNFT.TargetArgs({
                targetToken: targetToken,
                poolAddress: address(this)
            })
        );
        emit Draw(user, tokenId, unlockArgs);
    }

    function setBTCAddress(
        uint256[] memory tokenIds,
        string memory btcAddress
    ) external nonReentrant {
        require(block.timestamp < offerEndTime + 20 days, "End!!!");
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];

            (address targetToken_, address poolAddress) = IDeltaNFT(deltaNFT)
                .getTokenTargetToken(tokenId);
            require(poolAddress == address(this), "not this pool");
            require(targetToken == targetToken_, "not this token");
            IDeltaNFT(deltaNFT).safeTransferFrom(
                msg.sender,
                address(this),
                tokenId
            );
            IDeltaNFT(deltaNFT).burnNFT(tokenId);
            btcAddresses.push(btcAddress);

            userBTCAddress[msg.sender].push(btcAddress);
            emit SetBTCAddress(msg.sender, tokenId, btcAddress);
        }
    }

    function unlockToken(
        uint256 /*tokenId*/
    ) external pure override returns (uint256 amount, uint256 _newTokenId) {
        require(false, "DeltaPool:No auth");
        return (0, 0);
    }

    // for view
    function allBTCAddrAmount() external view returns (uint256) {
        return btcAddresses.length;
    }

    // for view
    function userBTCAddrAmount(address user) external view returns (uint256) {
        return userBTCAddress[user].length;
    }

    function withdraw() external afterPublish nonReentrant onlyOwner {
        require(block.timestamp >= drawTime, "not end");

        uint256 realityShares = 0;
        for (uint i = 0; i < levelShares.length; i++) {
            realityShares += levelShares[i];
        }
        uint256 total = realityShares * oneSharePrice;
        if (costToken == address(0)) {
            payable(msg.sender).transfer(oneSharePrice);
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
