// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./ERC20.sol";
import "./ABDKMathQuad.sol";
import "./IRelation.sol";

contract GuessScore is ReentrancyGuard, Ownable {
    ERC20 public token;

    address public relation;

    address public operator = 0x00A32120f8B38822a8611C81733fb4184eBE3f12;

    struct TeamStruct {
        mapping(address => mapping(bytes32 => uint256)) usersScore;
        mapping(address => uint256) usersAmount;
        mapping(address => uint256) usersRewarded;
        mapping(address => bool) userFirstDeposit;
        mapping(bytes32 => uint256) usersNumber;
        mapping(bytes32 => uint256) depositCount;
        mapping(bytes32 => uint256) scoreAmount;
        uint256 totalAmount;
        uint256 totalReward;
        address[] users;
        bool turnOn;
        bool stopDeposit;
        bool stopWithdrawal;
        bytes32 score;
    }

    mapping(bytes32 => TeamStruct) private teamsData;
    mapping(bytes32 => uint256[2]) private teamsScore;

    uint256 public amountMax = 1000 * 10**18;

    uint256 public amountMin = 10 * 10**18;

    uint256 public poolFee = 8;

    address public feeAddr;
    address public poolAddr;

    /////////////////////////////////////////////////////////////////////////////////////////////////
    //   event
    /////////////////////////////////////////////////////////////////////////////////////////////////

    event DepositEvent(
        address userAddr,
        uint256[2] teamIds,
        uint256[2] scores,
        uint256 amount
    );
    event WithdrawalEvent(
        address userAddr,
        uint256 reward,
        uint256[2] teamIds,
        uint256[2] scores,
        uint256 share
    );

    /////////////////////////////////////////////////////////////////////////////////////////////////
    //   lib
    /////////////////////////////////////////////////////////////////////////////////////////////////

    function arryToHash(uint256[2] memory _n) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_n[0], _n[1]));
    }

    modifier onlyOP() {
        require(
            msg.sender == operator || msg.sender == owner(),
            "unauthorized"
        );
        _;
    }

    function mulDiv(
        uint x,
        uint y,
        uint z
    ) private pure returns (uint) {
        if (y == 0) y = 1;
        if (z == 0) z = 1;

        return
            ABDKMathQuad.toUInt(
                ABDKMathQuad.div(
                    ABDKMathQuad.mul(
                        ABDKMathQuad.fromUInt(x),
                        ABDKMathQuad.fromUInt(y)
                    ),
                    ABDKMathQuad.fromUInt(z)
                )
            );
    }

    function addTeamUser(address userAddr, bytes32 teamId) private {
        if (!teamUserExit(userAddr, teamsData[teamId].users))
            teamsData[teamId].users.push(userAddr);
    }

    function teamUserExit(address userAddr, address[] memory users)
        private
        pure
        returns (bool)
    {
        bool ret;
        for (uint i = 0; i < users.length; i++) {
            if (users[i] == userAddr) {
                ret = true;
                break;
            }
        }
        return ret;
    }

    function getTeamUser(uint256[2] memory teamIds)
        public
        view
        returns (address[] memory)
    {
        return teamsData[arryToHash(teamIds)].users;
    }

    function getTeamUserDepoistAmount(uint256[2] memory teamIds, address user)
        public
        view
        returns (uint256)
    {
        return teamsData[arryToHash(teamIds)].usersAmount[user];
    }

    function getTeamUserscoreAmount(
        uint256[2] memory teamIds,
        address user,
        uint256[2] memory scores
    ) public view returns (uint256) {
        return
            teamsData[arryToHash(teamIds)].usersScore[user][arryToHash(scores)];
    }

    function getTeamTotalAmount(uint256[2] memory teamIds)
        public
        view
        returns (uint256)
    {
        return teamsData[arryToHash(teamIds)].totalAmount;
    }

    function getTeamTotalReward(uint256[2] memory teamIds)
        public
        view
        returns (uint256)
    {
        return teamsData[arryToHash(teamIds)].totalReward;
    }

    function getTeamTurnOn(uint256[2] memory teamIds)
        public
        view
        returns (bool)
    {
        return teamsData[arryToHash(teamIds)].turnOn;
    }

    function getTeamScore(uint256[2] memory teamIds)
        public
        view
        returns (uint256[2] memory)
    {
        return teamsScore[arryToHash(teamIds)];
    }

    /////////////////////////////////////////////////////////////////////////////////////////////////
    //   play
    /////////////////////////////////////////////////////////////////////////////////////////////////

    function deposit(
        uint256[2] memory teamIds,
        uint256 amount,
        uint256[2] memory scores,
        address referrer
    ) public nonReentrant {
        bytes32 teamId = arryToHash(teamIds);
        bytes32 score = arryToHash(scores);

        require(!teamsData[teamId].turnOn, "deposit off");

        require(!teamsData[teamId].stopDeposit, "deposit stop");

        require(amount >= amountMin, "Amount less");

        require(
            (teamsData[teamId].usersAmount[msg.sender] + amount) <= amountMax,
            "Amount limit"
        );

        uint256 fee = getUserFee(amount);
        uint256 sa = amount - fee;
        uint256 reward = fee / 2;
        fee = fee - reward;

        teamsData[teamId].usersScore[msg.sender][score] += sa;

        teamsData[teamId].totalAmount += sa;

        teamsData[teamId].usersAmount[msg.sender] += amount;

        if (!teamsData[teamId].userFirstDeposit[msg.sender]) {
            teamsData[teamId].usersNumber[score]++;
        } else {
            teamsData[teamId].userFirstDeposit[msg.sender] = true;
        }
        teamsData[teamId].depositCount[score]++;
        teamsData[teamId].scoreAmount[score] += sa;

        addTeamUser(msg.sender, teamId);

        require(
            token.transferFrom(msg.sender, feeAddr, fee),
            "transfer failed"
        );

        require(
            token.transferFrom(msg.sender, poolAddr, sa),
            "transfer failed"
        );

        // Share the Rewards
        IRelation _relation = IRelation(relation);
        address _superior = _relation.getUserSuperior(msg.sender);
        if (_superior == address(0)) {
            _superior = referrer;
            _relation.bind(msg.sender, referrer);
        }
        require(
            token.transferFrom(msg.sender, _superior, reward),
            "transfer failed reward"
        );
        //

        emit DepositEvent(msg.sender, teamIds, scores, amount);
    }

    function withdrawal(uint256[2] memory teamIds) public nonReentrant {
        bytes32 teamId = arryToHash(teamIds);
        bytes32 score = teamsData[teamId].score;

        require(!teamsData[teamId].stopWithdrawal, "withdrawal stop");

        require(
            teamsData[teamId].usersRewarded[msg.sender] == 0,
            "users is Rewarded"
        );

        require(teamsData[teamId].turnOn, "Rewards are not turned on");

        require(
            teamsData[teamId].totalReward < teamsData[teamId].totalAmount,
            "The reward is gone"
        );

        uint256 share = getTeamShare(msg.sender, teamId, score);

        uint256 reward = (teamsData[teamId].totalAmount / 10**18) * share;

        teamsData[teamId].totalReward += reward;

        teamsData[teamId].usersRewarded[msg.sender] = reward;

        require(token.transfer(msg.sender, reward), "Transfer failed");

        emit WithdrawalEvent(
            msg.sender,
            reward,
            teamIds,
            teamsScore[teamId],
            share
        );
    }

    function getTeamShare(
        address user,
        bytes32 teamId,
        bytes32 score
    ) public view returns (uint256) {
        if (teamId == 0) return 0;

        uint256 amount = teamsData[teamId].usersScore[user][score];

        uint256 total = teamsData[teamId].scoreAmount[score];

        return mulDiv(1 ether, amount, total);
    }

    function getUserFee(uint256 amount) private view returns (uint256) {
        return (amount * poolFee) / 100;
    }

    function getScoreTeamDepostitCount(
        uint256[2] memory teamIds,
        uint256[2] memory scores
    ) public view returns (uint256) {
        return teamsData[arryToHash(teamIds)].usersNumber[arryToHash(scores)];
    }

    function getScoreDepositCount(
        uint256[2] memory teamIds,
        uint256[2] memory scores
    ) public view returns (uint256) {
        return teamsData[arryToHash(teamIds)].depositCount[arryToHash(scores)];
    }

    function getTeamScoreAmount(
        uint256[2] memory teamIds,
        uint256[2] memory scores
    ) public view returns (uint256) {
        return teamsData[arryToHash(teamIds)].scoreAmount[arryToHash(scores)];
    }

    /////////////////////////////////////////////////////////////////////////////////////////////////
    //   op
    /////////////////////////////////////////////////////////////////////////////////////////////////

    function openRewards(uint256[2] memory teamIds, uint256[2] memory scores)
        public
        onlyOP
        nonReentrant
    {
        bytes32 teamId = arryToHash(teamIds);
        bytes32 score = arryToHash(scores);

        teamsScore[teamId] = scores;

        teamsData[teamId].score = score;
        teamsData[teamId].turnOn = true;
    }

    function setUserAmount(uint256 _amountMax, uint256 _amountMin)
        public
        onlyOP
        nonReentrant
    {
        amountMax = _amountMax;
        amountMin = _amountMin;
    }

    function setPoolFee(uint256 _poolFee) public onlyOP nonReentrant {
        poolFee = _poolFee;
    }

    function setStopDeposit(uint256[2] memory teamIds, bool b)
        public
        onlyOP
        nonReentrant
    {
        teamsData[arryToHash(teamIds)].stopDeposit = b;
    }

    function setStopWithdrawal(uint256[2] memory teamIds, bool b)
        public
        onlyOP
        nonReentrant
    {
        teamsData[arryToHash(teamIds)].stopWithdrawal = b;
    }

    /////////////////////////////////////////////////////////////////////////////////////////////////
    //   manager
    /////////////////////////////////////////////////////////////////////////////////////////////////

    function setOperators(address to) public onlyOwner {
        operator = to;
    }

    function setRelationAddr(address _relation) public onlyOwner {
        relation = _relation;
    }

    /////////////////////////////////////////////////////////////////////////////////////////////////
    //   Program
    /////////////////////////////////////////////////////////////////////////////////////////////////

    constructor(
        ERC20 _token,
        address _feeAddr,
        address _poolAddr,
        address _relation
    ) Ownable() {
        token = _token;
        feeAddr = _feeAddr;
        poolAddr = _poolAddr;
        relation = _relation;
    }
}
