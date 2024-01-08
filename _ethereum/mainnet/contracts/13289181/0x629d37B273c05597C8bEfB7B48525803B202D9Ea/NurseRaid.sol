// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

import "./Ownable.sol";
import "./INurseRaid.sol";
import "./MaidPower.sol";

contract NurseRaid is Ownable, MaidPower, INurseRaid {
    struct Raid {
        uint256 entranceFee;
        uint256 nursePart;
        uint256 maxRewardCount;
        uint256 duration;
        uint256 endBlock;
    }

    struct Challenger {
        uint256 enterBlock;
        IMaids maids;
        uint256 maidId;
    }

    struct MaidEfficacy {
        uint256 numerator;
        uint256 denominator;
    }

    Raid[] public raids;
    mapping(uint256 => mapping(address => Challenger)) public challengers;

    mapping(IMaids => bool) public override isMaidsApproved;

    IMaidCoin public immutable override maidCoin;
    IMaidCafe public override maidCafe;
    INursePart public immutable override nursePart;
    ICloneNurses public immutable override cloneNurses;
    IRNG public override rng;

    MaidEfficacy public override maidEfficacy = MaidEfficacy({numerator: 1, denominator: 1000});

    constructor(
        IMaidCoin _maidCoin,
        IMaidCafe _maidCafe,
        INursePart _nursePart,
        ICloneNurses _cloneNurses,
        IRNG _rng,
        address _sushiGirls,
        address _lingerieGirls
    ) MaidPower(_sushiGirls, _lingerieGirls) {
        maidCoin = _maidCoin;
        maidCafe = _maidCafe;
        nursePart = _nursePart;
        cloneNurses = _cloneNurses;
        rng = _rng;
    }

    function changeMaidEfficacy(uint256 _numerator, uint256 _denominator) external onlyOwner {
        maidEfficacy = MaidEfficacy({numerator: _numerator, denominator: _denominator});
        emit ChangeMaidEfficacy(_numerator, _denominator);
    }

    function setMaidCafe(IMaidCafe _maidCafe) external onlyOwner {
        maidCafe = _maidCafe;
    }

    function approveMaids(IMaids[] calldata maids) public onlyOwner {
        for (uint256 i = 0; i < maids.length; i += 1) {
            isMaidsApproved[maids[i]] = true;
        }
    }

    function disapproveMaids(IMaids[] calldata maids) public onlyOwner {
        for (uint256 i = 0; i < maids.length; i += 1) {
            isMaidsApproved[maids[i]] = false;
        }
    }

    modifier onlyApprovedMaids(IMaids maids) {
        require(address(maids) == address(0) || isMaidsApproved[maids], "NurseRaid: The maids is not approved");
        _;
    }

    function changeRNG(address addr) external onlyOwner {
        rng = IRNG(addr);
    }

    function raidCount() external view override returns (uint256) {
        return raids.length;
    }

    function create(
        uint256[] calldata entranceFees,
        uint256[] calldata _nurseParts,
        uint256[] calldata maxRewardCounts,
        uint256[] calldata durations,
        uint256[] calldata endBlocks
    ) external override onlyOwner returns (uint256 id) {
        uint256 length = entranceFees.length;
        for (uint256 i = 0; i < length; i++) {
            require(maxRewardCounts[i] < 255, "NurseRaid: Invalid number");
            {   // scope to avoid stack too deep errors
                (uint256 nursePartCount, uint256 nurseDestroyReturn, , ) = cloneNurses.nurseTypes(_nurseParts[i]);

                require(
                    entranceFees[i] >= (nurseDestroyReturn * maxRewardCounts[i]) / nursePartCount,
                    "NurseRaid: Fee should be higher"
                );
            }
            id = raids.length;
            raids.push(
                Raid({
                    entranceFee: entranceFees[i],
                    nursePart: _nurseParts[i],
                    maxRewardCount: maxRewardCounts[i],
                    duration: durations[i],
                    endBlock: endBlocks[i]
                })
            );
            emit Create(id, entranceFees[i], _nurseParts[i], maxRewardCounts[i], durations[i], endBlocks[i]);
        }
    }

    function enter(
        uint256 id,
        IMaids maids,
        uint256 maidId
    ) public override onlyApprovedMaids(maids) {
        Raid storage raid = raids[id];
        require(block.number < raid.endBlock, "NurseRaid: Raid has ended");
        require(challengers[id][msg.sender].enterBlock == 0, "NurseRaid: Raid is in progress");
        challengers[id][msg.sender] = Challenger({enterBlock: block.number, maids: maids, maidId: maidId});
        if (address(maids) != address(0)) {
            maids.transferFrom(msg.sender, address(this), maidId);
        }
        uint256 _entranceFee = raid.entranceFee;
        maidCoin.transferFrom(msg.sender, address(this), _entranceFee);
        uint256 feeToCafe = (_entranceFee * 3) / 1000;
        _feeTransfer(feeToCafe);
        maidCoin.burn(_entranceFee - feeToCafe);
        emit Enter(msg.sender, id, maids, maidId);
    }

    function enterWithPermit(
        uint256 id,
        IMaids maids,
        uint256 maidId,
        uint256 deadline,
        uint8 v1,
        bytes32 r1,
        bytes32 s1,
        uint8 v2,
        bytes32 r2,
        bytes32 s2
    ) external override {
        maidCoin.permit(msg.sender, address(this), raids[id].entranceFee, deadline, v1, r1, s1);
        if (address(maids) != address(0)) {
            maids.permit(msg.sender, maidId, deadline, v2, r2, s2);
        }
        enter(id, maids, maidId);
    }

    function enterWithPermitAll(
        uint256 id,
        IMaids maids,
        uint256 maidId,
        uint256 deadline,
        uint8 v1,
        bytes32 r1,
        bytes32 s1,
        uint8 v2,
        bytes32 r2,
        bytes32 s2
    ) external override {
        maidCoin.permit(msg.sender, address(this), type(uint256).max, deadline, v1, r1, s1);
        if (address(maids) != address(0)) {
            maids.permitAll(msg.sender, address(this), deadline, v2, r2, s2);
        }
        enter(id, maids, maidId);
    }

    function checkDone(uint256 id) public view override returns (bool) {
        Raid memory raid = raids[id];
        Challenger memory challenger = challengers[id][msg.sender];

        return _checkDone(raid.duration, challenger);
    }

    function _checkDone(uint256 duration, Challenger memory challenger) internal view returns (bool) {
        if (address(challenger.maids) == address(0)) {
            return block.number - challenger.enterBlock >= duration;
        } else {
            return
                block.number - challenger.enterBlock >=
                duration -
                    ((duration * powerOfMaids(challenger.maids, challenger.maidId) * maidEfficacy.numerator) /
                        maidEfficacy.denominator);
        }
    }

    function exit(uint256[] calldata ids) external override {
        for (uint256 i = 0; i < ids.length; i++) {
            Challenger memory challenger = challengers[ids[i]][msg.sender];
            require(challenger.enterBlock != 0, "NurseRaid: Not participating in the raid");

            Raid storage raid = raids[ids[i]];

            if (_checkDone(raid.duration, challenger)) {
                uint256 rewardCount = _randomReward(ids[i], raid.maxRewardCount, msg.sender);
                nursePart.mint(msg.sender, raid.nursePart, rewardCount);
            }

            if (address(challenger.maids) != address(0)) {
                challenger.maids.transferFrom(address(this), msg.sender, challenger.maidId);
            }

            delete challengers[ids[i]][msg.sender];
            emit Exit(msg.sender, ids[i]);
        }
    }

    function _randomReward(
        uint256 _id,
        uint256 _maxRewardCount,
        address sender
    ) internal returns (uint256 rewardCount) {
        uint256 totalNumber = 2 * (2**_maxRewardCount - 1);
        uint256 randomNumber = (rng.generateRandomNumber(_id, sender) % totalNumber) + 1;

        uint256 ceil;
        uint256 i = 0;

        while (randomNumber > ceil) {
            i += 1;
            ceil = (2**(_maxRewardCount + 1)) - (2**(_maxRewardCount + 1 - i));
        }

        rewardCount = i;
    }

    function _feeTransfer(uint256 feeToCafe) internal {
        maidCoin.transfer(address(maidCafe), feeToCafe);
    }
}
