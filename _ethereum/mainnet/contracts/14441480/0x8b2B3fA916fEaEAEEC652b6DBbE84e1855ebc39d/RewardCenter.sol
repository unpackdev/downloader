// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./IERC20.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";

import "./IEventCenterLeveragePosition.sol";
import "./IAccountCenter.sol";

contract RewardCenter is Ownable {


    mapping(address => bool) openAccountRewardRecord;

    mapping(address => bool) openAccountRewardWhiteList;

    mapping(uint256 => bytes32) merkelRoots;

    mapping(uint256 => uint256) rewardAmounts;

    bytes32 public accumRewardMerkelRoot;

    address public rewardToken;
    uint256 public rewardAmountPerAccoutOpen;
    uint256 public totalOpenAccountRewardReleased;
    uint256 public totalPositionRewardReleased;
    uint256 public releasedRewardRound;

    address public eventCenter;
    address public accountCenter;

    event SetEventCenter(address indexed owner, address indexed eventCenter);
    
    event SetAccountCenter(
        address indexed owner,
        address indexed accountCenter
    );

    event SetRewardToken(address indexed owner, address indexed token);

    event SetOpenAccountReward(address indexed owner, uint256 amountPerAccout);


    event ReleasePositionReward(
        address indexed owner,
        uint256 epochRound,
        bytes32 merkelRoot
    );

    event ClaimPositionReward(
        address indexed EOA,
        uint256 epochRound,
        uint256 amount
    );

    event ClaimOpenAccountReward(
        address indexed EOA,
        address indexed account,
        uint256 amount
    );

    function setEventCenter(address _eventCenter) public onlyOwner {
        require(
            _eventCenter != address(0),
            "CHFRY: EventCenter address should not be 0"
        );
        eventCenter = _eventCenter;
        emit SetEventCenter(msg.sender, eventCenter);
    }

    function setAccountCenter(address _accountCenter) public onlyOwner {
        require(
            _accountCenter != address(0),
            "CHFRY: EventCenter address should not be 0"
        );
        accountCenter = _accountCenter;
        emit SetAccountCenter(msg.sender, accountCenter);
    }

    function setRewardToken(address token) public onlyOwner {
        require(token != address(0), "CHFRY: Reward Token should not be 0");
        rewardToken = token;
        emit SetRewardToken(msg.sender, token);
    }

    function addToWhiteList(address addr) public onlyOwner {
        require(addr != address(0), "CHFRY: addr should not be 0");
        openAccountRewardWhiteList[addr] = true;
    }

    function setOpenAccountReward(uint256 _rewardAmountPerAccoutOpen)
        public
        onlyOwner
    {
        rewardAmountPerAccoutOpen = _rewardAmountPerAccoutOpen;
        emit SetOpenAccountReward(msg.sender, rewardAmountPerAccoutOpen);
    }

    function claimOpenAccountReward(address EOA, address account) public {
        require(
            openAccountRewardWhiteList[msg.sender] == true,
            "CHFRY: AccountCenter is not in white list"
        );
        require(
            openAccountRewardRecord[account] == false,
            "CHFRY: Open Accout reward already claimed"
        );
        openAccountRewardRecord[account] = true;
        require(rewardToken != address(0), "CHFRY: Reward Token not setup");
        IERC20(rewardToken).transfer(EOA, rewardAmountPerAccoutOpen);
        EventCenterLeveragePositionInterface(eventCenter)
            .emitClaimOpenAccountRewardEvent(
                EOA,
                account,
                rewardAmountPerAccoutOpen
            );
    }

    // Postition Reward
    function startNewPositionRewardEpoch(uint256 rewardAmount)
        public
        onlyOwner
    {
        require(
            EventCenterLeveragePositionInterface(eventCenter)
                .isInRewardEpoch() == false,
            "CHFRY: already in reward epoch"
        );
        EventCenterLeveragePositionInterface(eventCenter).startEpoch(
            rewardAmount
        );
    }

    function releasePositionReward(uint256 epochRound, bytes32 merkelRoot)
        public
        onlyOwner
    {
        require(merkelRoot != bytes32(0), "CHFRY: merkelRoot should not be 0");
        uint256 round = EventCenterLeveragePositionInterface(eventCenter)
            .epochRound();
        require(epochRound <= round, "CHFRY: this reward round is not start");
        if (epochRound == round) {
            require(
                EventCenterLeveragePositionInterface(eventCenter)
                    .isInRewardEpoch() == false,
                "CHFRY: this reward round is not end"
            );
        }
        merkelRoots[epochRound] = merkelRoot;
        releasedRewardRound = releasedRewardRound + 1;
        EventCenterLeveragePositionInterface(eventCenter)
            .emitReleasePositionRewardEvent(msg.sender, epochRound, merkelRoot);
    }

    function claimPositionReward(
        uint256 epochRound,
        uint256 amount,
        bytes32[] calldata proof
    ) public {
        require(
            merkelRoots[epochRound] != bytes32(0),
            "CHFRY: this round reward is not released"
        );
        bytes memory leafData = abi.encodePacked(msg.sender, amount);
        require(
            MerkleProof.verify(
                proof,
                merkelRoots[epochRound],
                keccak256(leafData)
            ) == true,
            "CHFRY: MerkleProof Fail"
        );
        IERC20(rewardToken).transfer(msg.sender, amount);
        EventCenterLeveragePositionInterface(eventCenter)
            .emitClaimPositionRewardEvent(msg.sender, epochRound, amount);
    }

    function drainRewardToken(uint256 amount, address to) public onlyOwner {
        require(
            to != address(0),
            "CHFRY: should not drain reward token to address(0)"
        );
        IERC20(rewardToken).transfer(to, amount);
    }

    function cleanRewardToken(address to) public onlyOwner {
        require(
            to != address(0),
            "CHFRY: should not drain reward token to address(0)"
        );
        IERC20(rewardToken).transfer(
            msg.sender,
            IERC20(rewardToken).balanceOf(address(this))
        );
    }

    function latestEpochRound() public view returns (uint256) {
        return EventCenterLeveragePositionInterface(eventCenter).epochRound();
    }

    function inEpoch() public view returns (bool) {
        return
            EventCenterLeveragePositionInterface(eventCenter).isInRewardEpoch();
    }
}