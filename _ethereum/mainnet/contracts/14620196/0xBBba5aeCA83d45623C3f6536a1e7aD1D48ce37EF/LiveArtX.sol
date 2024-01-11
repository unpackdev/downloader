pragma solidity ^0.8.2;
// SPDX-License-Identifier: MIT

import "./ReentrancyGuardUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./StringsUpgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./MerkleProofUpgradeable.sol";
import "./AddressUpgradeable.sol";

//|_/\|_/\|_/\|_/\|_/\|_/\|_/\|_/\|_/\|_/\|_/\|_/\|_/\|_/\|_/\|_/\|_/\|_/\|_/\|_/\|_/\|_/\|_/\|_/\|_/\//
//|_/\|_/\|_/\|_/\|_/\|_/\|_/\|_/\|_/\|_/\|_/\|_/\|_/\|_/\|_/\|_/\|_/\|_/\|_/\|_/\|_/\|_/\|_/\|_/\|_/\//
//|_/\//                                                                                        //|_/\//
//|_/\//                                                                                        //|_/\//
//|_/\//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //|_/\//
//|_/\//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //|_/\//
//|_/\//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //|_/\//
//|_/\//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //|_/\//
//|_/\//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //|_/\//
//|_/\//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //|_/\//
//|_/\//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //|_/\//
//|_/\//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //|_/\//
//|_/\//    @@@@@@@@@@@@@#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@/@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //|_/\//
//|_/\//    @@@@@@@@@@@@@, @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@.  %@@@@@@@@@@@@@@@@@@@@@@@@@@@    //|_/\//
//|_/\//    @@@@@@@@@@@@@,  &@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%     /@@@@@@@@@@@@@@@@@@@@@@@@@@    //|_/\//
//|_/\//    @@@@@@@@@@@@@,   #@@@@@@@@@@@@@@@@@@@@@@@@@@@@(       .@@@@@@@@@@@@@@@@@@@@@@@@@    //|_/\//
//|_/\//    @@@@@@@@@@@@@,    /@@@@@@@@@@@@@@@@@@@@@@@@@@*          @@@@@@@@@@@@@@@@@@@@@@@@    //|_/\//
//|_/\//    @@@@@@@@@@@@@,     ,@@@@@@@@@@@@@@@@@@@@@@@@.            &@@@@@@@@@@@@@@@@@@@@@@    //|_/\//
//|_/\//    @@@@@@@@@@@@@,       &@@@@@@@@@@@@@@@@@@@@&               (@@@@@@@@@@@@@@@@@@@@@    //|_/\//
//|_/\//    @@@@@@@@@@@@@,        #@@@@@@@@@@@@@@@@@@(                 ,@@@@@@@@@@@@@@@@@@@@    //|_/\//
//|_/\//    @@@@@@@@@@@@@,         /@@@@@@@@@@@@@@@@.                    &@@@@@@@@@@@@@@@@@@    //|_/\//
//|_/\//    @@@@@@@@@@@@@,          ,@@@@@@@@@@@@@@                       %@@@@@@@@@@@@@@@@@    //|_/\//
//|_/\//    @@@@@@@@@@@@@,            @@@@@@@@@@@@                         (@@@@@@@@@@@@@@@@    //|_/\//
//|_/\//    @@@@@@@@@@@@@,             #@@@@@@@@#                           *@@@@@@@@@@@@@@@    //|_/\//
//|_/\//    @@@@@@@@@@@@@,              *@@@@@@*                              @@@@@@@@@@@@@@    //|_/\//
//|_/\//    @@@@@@@@@@@@@,               .@@@@.                                %@@@@@@@@@@@@    //|_/\//
//|_/\//    @@@@@@@@@@@@@,                 @&                                   (@@@@@@@@@@@    //|_/\//
//|_/\//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //|_/\//
//|_/\//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //|_/\//
//|_/\//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //|_/\//
//|_/\//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //|_/\//
//|_/\//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //|_/\//
//|_/\//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //|_/\//
//|_/\//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //|_/\//
//|_/\//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //|_/\//
//|_/\//    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    //|_/\//
//|_/\//                                                                                        //|_/\//
//|_/\//                                                                                        //|_/\//
//|_/\|_/\|_/\|_/\|_/\|_/\|_/\|_/\|_/\|_/\|_/\|_/\|_/\|_/\|_/\|_/\|_/\|_/\|_/\|_/\|_/\|_/\|_/\|_/\|_/\//
//|_/\|_/\|_/\|_/\|_/\|_/\|_/\|_/\|_/\|_/\|_/\|_/\|_/\|_/\|_/\|_/\|_/\|_/\|_/\|_/\|_/\|_/\|_/\|_/\|_/\//

contract RevaLiveArtX is
    OwnableUpgradeable,
    ERC721EnumerableUpgradeable,
    ReentrancyGuardUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeMathUpgradeable for uint256;
    using StringsUpgradeable for uint256;

    bool private tempRecursion;
    uint256 private preSeed;

    // Base URI
    string private baseURI;

    struct Member {
        uint256 id;
        uint256 level;
        uint256 createdTime;
        uint256 lockTime;
        uint256 amount;
        bool decompose;
    }

    uint256 public unLockTimestamp;

    mapping(uint256 => Member) private tokenExtend;

    mapping(address => bool) public claimed;

    // claim start time
    uint256 public claimStartTime;

    // claim end time
    uint256 public claimEndTime;

    // claim count
    mapping(uint256 => uint256) public claimCount;

    // total number of members
    uint256 public memberID;

    uint256[] public claimAmount;
    uint256[] public claimValue;
    uint256[] public levelProbability;

    uint256[] public retainMemberValue;

    IERC20Upgradeable public artToken;

    event ReceiveMember(
        address indexed owner,
        uint256 indexed tokenId,
        uint256 indexed level,
        uint256 lockTime,
        uint256 amount
    );

    event DecomposeMember(
        address indexed owner,
        uint256 indexed tokenId,
        uint256 receiveAmount,
        bool retain
    );

    event eveClaimData(uint256 indexed startTime, uint256 endTime);
    event eveUnLockTimestamp(uint256 indexed timestamp);
    event eveARTToken(address indexed art);
    event eveWithdraw(uint256 indexed amount, address indexed addr);
    event eveSeize(
        address indexed token,
        address indexed addr,
        uint256 indexed amount
    );
    event eveURIPrefix(string indexed baseURI);

    // --- Init ---
    function initialize(
        IERC20Upgradeable _artToken,
        uint256 _claimStartTime,
        uint256 _claimEndTime,
        uint256 _unLockTimestamp,
        uint256[] calldata _claimAmount,
        uint256[] calldata _claimValue,
        uint256[] calldata _levelProbability,
        uint256[] calldata _retainMemberValue
    ) external initializer {
        __Ownable_init();
        __ERC721_init(
            "Reva x LiveArt Memberships",
            "REVA.LIVEARTX.MEMBERSHIPS"
        );
        __ReentrancyGuard_init();

        preSeed = 10000;

        artToken = _artToken;

        claimStartTime = _claimStartTime;
        claimEndTime = _claimEndTime;
        unLockTimestamp = _unLockTimestamp;

        claimAmount = _claimAmount;
        claimValue = _claimValue;
        levelProbability = _levelProbability;
        retainMemberValue = _retainMemberValue;

        baseURI = "https://api.liveartx.com/v1/magic-box-reva/";

        memberID = 0;

        emit eveUnLockTimestamp(_unLockTimestamp);
    }

    function claim() external nonReentrant returns (uint256) {
        require(
            !AddressUpgradeable.isContract(msg.sender),
            "Reva x LiveArt: can't call"
        );
        require(block.timestamp >= claimStartTime, "Reva x LiveArt: not start");
        require(claimEndTime > block.timestamp, "Reva x LiveArt: end");

        address account = msg.sender;

        require(!claimed[account], "Reva x LiveArt: already claimed.");

        memberID++;

        _mint(account, memberID);

        claimed[account] = true;

        uint256 lockTime = getLockTime();

        // level
        uint256 seed = computerSeed();
        preSeed = seed % 10000;
        uint256 _base = 1000;
        uint256 levelRandom = seed % _base;
        uint256 level = getLevel(levelRandom);

        claimCount[level]++;

        Member memory member;
        member.id = memberID;
        member.level = level;
        member.createdTime = block.timestamp;
        member.lockTime = lockTime;
        member.amount = claimValue[level - 1];
        member.decompose = false;

        tokenExtend[memberID] = member;

        emit ReceiveMember(account, memberID, level, lockTime, member.amount);

        return memberID;
    }

    // _retain:
    //  true => Retain membership
    //  false => burn
    function decomposeMember(
        uint256 tokenId,
        bool _retain
    ) external nonReentrant {
        require(
            _exists(tokenId),
            "Reva x LiveArt: operator query for nonexistent token"
        );
        Member storage member = tokenExtend[tokenId];
        uint256 lockTime = member.lockTime;
        require(
            (unLockTimestamp != 0) &&
                (block.timestamp >= lockTime.add(unLockTimestamp)),
            "Reva x LiveArt: Lock"
        );
        require(!member.decompose, "Reva x LiveArt: has decompose");

        uint256 amount_ = member.amount;
        require(ownerOf(tokenId) == msg.sender, "Reva x LiveArt: not owner");

        if (_retain) {
            uint256 retainValue = retainMemberValue[member.level - 1];
            member.amount = retainValue;
            member.decompose = true;
            amount_ = amount_.sub(retainValue);
        } else {
            _burn(tokenId);
        }
        artToken.safeTransfer(msg.sender, amount_);

        emit DecomposeMember(msg.sender, tokenId, amount_, _retain);
    }

    function getLockTime() private view returns (uint256) {
        // random
        uint256 seed = computerSeed();
        uint256 _yearTime = 365;
        uint256 lockDays = seed % _yearTime;
        uint256 lockTime = lockDays.mul(1 days).add(1 days);

        return lockTime;
    }

    function getLevel(uint256 v) private returns (uint256) {
        uint256 level = 1;
        for (uint256 index = 0; index < levelProbability.length; index++) {
            if (v <= levelProbability[index]) {
                level = index + 1;
                break;
            }
        }
        tempRecursion = false;
        return getCurrentLevel(level);
    }

    function getCurrentLevel(uint256 level) private returns (uint256) {
        require(level > 0, "Reva x LiveArt: level over");
        require(level < 7, "Reva x LiveArt: have over");
        uint256 currentLevel = level;
        uint256 claimCount_ = claimCount[currentLevel];
        uint256 amount_ = claimAmount[currentLevel - 1];
        if (claimCount_ < amount_) {
            return currentLevel;
        } else {
            if (currentLevel > 1 && tempRecursion == false) {
                currentLevel--;
            } else {
                tempRecursion = true;
                currentLevel++;
            }
            return getCurrentLevel(currentLevel);
        }
    }

    function computerSeed() private view returns (uint256) {
        uint256 seed = uint256(
            keccak256(
                abi.encodePacked(
                    (block.timestamp) +
                        (block.difficulty) +
                        ((
                            uint256(keccak256(abi.encodePacked(block.coinbase)))
                        ) / (block.timestamp)) +
                        (block.gaslimit) +
                        ((uint256(keccak256(abi.encodePacked(msg.sender)))) /
                            (block.timestamp)) +
                        (block.number).add(preSeed)
                )
            )
        );
        return seed;
    }

    function setClaimData(
        uint256 _claimStartTime,
        uint256 _claimEndTime,
        uint256[] calldata _claimAmount,
        uint256[] calldata _claimValue,
        uint256[] calldata _levelProbability
    ) external onlyOwner {
        claimStartTime = _claimStartTime;
        claimEndTime = _claimEndTime;
        claimAmount = _claimAmount;
        claimValue = _claimValue;
        levelProbability = _levelProbability;
        emit eveClaimData(_claimStartTime, _claimEndTime);
    }

    function setUnLockTimestamp(uint256 _unLockTimestamp) external onlyOwner {
        unLockTimestamp = _unLockTimestamp;
        emit eveUnLockTimestamp(_unLockTimestamp);
    }

    function setRetainValue(
        uint256[] calldata _retainMemberValue
    ) external onlyOwner {
        retainMemberValue = _retainMemberValue;
    }

    function setARTToken(IERC20Upgradeable _artToken) external onlyOwner {
        artToken = _artToken;
        emit eveARTToken(address(artToken));
    }

    function withdraw(uint256 amount, address payable addr) external onlyOwner {
        addr.transfer(amount);
        emit eveWithdraw(amount, addr);
    }

    function seize(
        IERC20Upgradeable token,
        address addr,
        uint256 amount
    ) external onlyOwner {
        token.safeTransfer(addr, amount);
        emit eveSeize(address(token), addr, amount);
    }

    function setURIPrefix(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
        emit eveURIPrefix(baseURI);
    }

    function getMember(
        uint256 tokenId
    )
        external
        view
        returns (
            uint256 level,
            uint256 createdTime,
            uint256 lockTime,
            uint256 amount,
            bool decompose
        )
    {
        require(
            _exists(tokenId),
            "Reva x LiveArt: operator query for nonexistent token"
        );
        Member memory member = tokenExtend[tokenId];
        require(member.id > 0, "Reva x LiveArt: nonexistent token");

        level = member.level;
        createdTime = member.createdTime;
        lockTime = member.lockTime;
        amount = member.amount;
        decompose = member.decompose;
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        require(
            _exists(tokenId),
            "Reva x LiveArt: URI query for nonexistent token"
        );
        string memory baseURI_ = _baseURI();

        return string(abi.encodePacked(baseURI_, tokenId.toString()));
    }
}
