// SPDX-License-Identifier: MIT
pragma solidity 0.7.4;

import "./TellorTransfer.sol";
import "./TellorGetters.sol";
import "./Utilities.sol";

/**
 * title Tellor Stake
 * @dev Contains the methods related to miners staking, unstaking, initiating disputes,
 * voting on them. Tellor.sol
 * references this library for function's logic.
 */

contract TellorStake is TellorTransfer {
    using SafeMath for uint256;
    using SafeMath for int256;

    //emitted when a new dispute is initialized
    event NewDispute(
        uint256 indexed _disputeId,
        uint256 indexed _requestId,
        uint256 _timestamp,
        address _miner
    );
    //emitted when a new vote happens
    event Voted(
        uint256 indexed _disputeID,
        bool _position,
        address indexed _voter,
        uint256 indexed _voteWeight
    );
    //emitted upon dispute tally
    event DisputeVoteTallied(
        uint256 indexed _disputeID,
        int256 _result,
        address indexed _reportedMiner,
        address _reportingParty,
        bool _active
    );
    event NewStake(address indexed _sender); //Emits upon new staker
    event StakeWithdrawn(address indexed _sender); //Emits when a staker is block.timestamp no longer staked
    event StakeWithdrawRequested(address indexed _sender); //Emits when a staker begins the 7 day withdraw period

    /*Functions*/
    /**
     * @dev This function allows stakers to request to withdraw their stake (no longer stake)
     * once they lock for withdraw(stakes.currentStatus = 2) they are locked for 7 days before they
     * can withdraw the deposit
     */
    function requestStakingWithdraw() public {
        StakeInfo storage stakes = stakerDetails[msg.sender];
        //Require that the miner is staked
        require(stakes.currentStatus == 1, "Miner is not staked");

        //Change the miner staked to locked to be withdrawStake
        stakes.currentStatus = 2;

        //Change the startDate to block.timestamp since the lock up period begins block.timestamp
        //and the miner can only withdraw 7 days later from block.timestamp(check the withdraw function)
        stakes.startDate = block.timestamp - (block.timestamp % 86400);

        //Reduce the staker count
        uints[_STAKE_COUNT] -= 1;

        //Update the minimum dispute fee that is based on the number of stakers
        updateMinDisputeFee();
        emit StakeWithdrawRequested(msg.sender);
    }

    /**
     * @dev This function allows users to withdraw their stake after a 7 day waiting
     * period from request
     */
    function withdrawStake() public {
        StakeInfo storage stakes = stakerDetails[msg.sender];
        //Require the staker has locked for withdraw(currentStatus ==2) and that 7 days have
        //passed by since they locked for withdraw
        require(
            block.timestamp - (block.timestamp % 86400) - stakes.startDate >=
                7 days,
            "7 days didn't pass"
        );
        require(
            stakes.currentStatus == 2,
            "Miner was not locked for withdrawal"
        );
        stakes.currentStatus = 0;
        emit StakeWithdrawn(msg.sender);
    }

    /**
     * @dev This function allows miners to deposit their stake.
     */
    function depositStake() public {
        newStake(msg.sender);
        updateMinDisputeFee();
    }

    /**
     * @dev This internal function is used the depositStake function to successfully stake miners.
     * The function updates their status/state and status start date so they are locked it so they can't withdraw
     * and updates the number of stakers in the system.
     */
    function newStake(address _staker) internal {
        require(
            balanceOf(_staker) >= uints[_STAKE_AMOUNT],
            "Balance is lower than stake amount"
        );
        //Ensure they can only stake if they are not currently staked or if their stake time frame has ended
        //and they are currently locked for withdraw
        require(
            stakerDetails[_staker].currentStatus == 0 ||
                stakerDetails[_staker].currentStatus == 2,
            "Miner is in the wrong state"
        );
        uints[_STAKE_COUNT] += 1;
        stakerDetails[_staker] = StakeInfo({
            currentStatus: 1, //this resets their stake start date to today
            startDate: block.timestamp - (block.timestamp % 86400)
        });
        emit NewStake(_staker);
    }

    /**
     * @dev Helps initialize a dispute by assigning it a disputeId
     * when a miner returns a false/bad value on the validate array(in Tellor.ProofOfWork) it sends the
     * invalidated value information to POS voting
     * @param _requestId being disputed
     * @param _timestamp being disputed
     * @param _minerIndex the index of the miner that submitted the value being disputed. Since each official value
     * requires 5 miners to submit a value.
     */
    function beginDispute(
        uint256 _requestId,
        uint256 _timestamp,
        uint256 _minerIndex
    ) public {
        Request storage _request = requestDetails[_requestId];
        require(_request.minedBlockNum[_timestamp] != 0, "Mined block is 0");
        require(_minerIndex < 5, "Miner index is wrong");

        //_miner is the miner being disputed. For every mined value 5 miners are saved in an array and the _minerIndex
        //provided by the party initiating the dispute
        address _miner = _request.minersByValue[_timestamp][_minerIndex];
        bytes32 _hash =
            keccak256(abi.encodePacked(_miner, _requestId, _timestamp));

        //Increase the dispute count by 1
        uint256 disputeId = uints[_DISPUTE_COUNT] + 1;
        uints[_DISPUTE_COUNT] = disputeId;

        //Ensures that a dispute is not already open for the that miner, requestId and timestamp
        uint256 hashId = disputeIdByDisputeHash[_hash];
        if (hashId != 0) {
            disputesById[disputeId].disputeUintVars[_ORIGINAL_ID] = hashId;
        } else {
            disputeIdByDisputeHash[_hash] = disputeId;
            hashId = disputeId;
        }
        uint256 origID = hashId;
        uint256 dispRounds =
            disputesById[origID].disputeUintVars[_DISPUTE_ROUNDS] + 1;
        disputesById[origID].disputeUintVars[_DISPUTE_ROUNDS] = dispRounds;
        disputesById[origID].disputeUintVars[
            keccak256(abi.encode(dispRounds))
        ] = disputeId;
        if (disputeId != origID) {
            uint256 lastID =
                disputesById[origID].disputeUintVars[
                    keccak256(abi.encode(dispRounds - 1))
                ];
            require(
                disputesById[lastID].disputeUintVars[_MIN_EXECUTION_DATE] <=
                    block.timestamp,
                "Dispute is already open"
            );
            if (disputesById[lastID].executed) {
                require(
                    block.timestamp -
                        disputesById[lastID].disputeUintVars[_TALLY_DATE] <=
                        1 days,
                    "Time for voting haven't elapsed"
                );
            }
        }
        uint256 _fee;
        if (_minerIndex == 2) {
            requestDetails[_requestId].apiUintVars[_DISPUTE_COUNT] =
                requestDetails[_requestId].apiUintVars[_DISPUTE_COUNT] +
                1;
            //update dispute fee for this case
            _fee =
                uints[_STAKE_AMOUNT] *
                requestDetails[_requestId].apiUintVars[_DISPUTE_COUNT];
        } else {
            _fee = uints[_DISPUTE_FEE] * dispRounds;
        }

        //maps the dispute to the Dispute struct
        disputesById[disputeId].hash = _hash;
        disputesById[disputeId].isPropFork = false;
        disputesById[disputeId].reportedMiner = _miner;
        disputesById[disputeId].reportingParty = msg.sender;
        disputesById[disputeId].proposedForkAddress = address(0);
        disputesById[disputeId].executed = false;
        disputesById[disputeId].disputeVotePassed = false;
        disputesById[disputeId].tally = 0;

        //Saves all the dispute variables for the disputeId
        disputesById[disputeId].disputeUintVars[_REQUEST_ID] = _requestId;
        disputesById[disputeId].disputeUintVars[_TIMESTAMP] = _timestamp;
        disputesById[disputeId].disputeUintVars[_VALUE] = _request
            .valuesByTimestamp[_timestamp][_minerIndex];
        disputesById[disputeId].disputeUintVars[_MIN_EXECUTION_DATE] =
            block.timestamp +
            2 days *
            dispRounds;
        disputesById[disputeId].disputeUintVars[_BLOCK_NUMBER] = block.number;
        disputesById[disputeId].disputeUintVars[_MINER_SLOT] = _minerIndex;
        disputesById[disputeId].disputeUintVars[_FEE] = _fee;
        _doTransfer(msg.sender, address(this), _fee);

        //Values are sorted as they come in and the official value is the median of the first five
        //So the "official value" miner is always minerIndex==2. If the official value is being
        //disputed, it sets its status to inDispute(currentStatus = 3) so that users are made aware it is under dispute
        if (_minerIndex == 2) {
            _request.inDispute[_timestamp] = true;
            _request.finalValues[_timestamp] = 0;
        }
        stakerDetails[_miner].currentStatus = 3;
        emit NewDispute(disputeId, _requestId, _timestamp, _miner);
    }

    /**
     * @dev Allows token holders to vote
     * @param _disputeId is the dispute id
     * @param _supportsDispute is the vote (true=the dispute has basis false = vote against dispute)
     */
    function vote(uint256 _disputeId, bool _supportsDispute) public {
        Dispute storage disp = disputesById[_disputeId];

        //Get the voteWeight or the balance of the user at the time/blockNumber the dispute began
        uint256 voteWeight =
            balanceOfAt(msg.sender, disp.disputeUintVars[_BLOCK_NUMBER]);

        //Require that the msg.sender has not voted
        require(disp.voted[msg.sender] != true, "Sender has already voted");

        //Require that the user had a balance >0 at time/blockNumber the dispute began
        require(voteWeight != 0, "User balance is 0");

        //ensures miners that are under dispute cannot vote
        require(
            stakerDetails[msg.sender].currentStatus != 3,
            "Miner is under dispute"
        );

        //Update user voting status to true
        disp.voted[msg.sender] = true;

        //Update the number of votes for the dispute
        disp.disputeUintVars[_NUM_OF_VOTES] += 1;

        //If the user supports the dispute increase the tally for the dispute by the voteWeight
        //otherwise decrease it
        if (_supportsDispute) {
            disp.tally = disp.tally.add(int256(voteWeight));
        } else {
            disp.tally = disp.tally.sub(int256(voteWeight));
        }

        //Let the network kblock.timestamp the user has voted on the dispute and their casted vote
        emit Voted(_disputeId, _supportsDispute, msg.sender, voteWeight);
    }

    /**
     * @dev tallies the votes and locks the stake disbursement(currentStatus = 4) if the vote passes
     * @param _disputeId is the dispute id
     */
    function tallyVotes(uint256 _disputeId) public {
        Dispute storage disp = disputesById[_disputeId];
        //Ensure this has not already been executed/tallied
        require(disp.executed == false, "Dispute has been already executed");
        require(
            block.timestamp >= disp.disputeUintVars[_MIN_EXECUTION_DATE],
            "Time for voting haven't elapsed"
        );
        require(
            disp.reportingParty != address(0),
            "reporting Party is address 0"
        );
        int256 _tally = disp.tally;
        if (_tally > 0) {
            //Set the dispute state to passed/true
            disp.disputeVotePassed = true;
        }
        //If the vote is not a proposed fork
        if (disp.isPropFork == false) {
            //Ensure the time for voting has elapsed
            StakeInfo storage stakes = stakerDetails[disp.reportedMiner];
            //If the vote for disputing a value is successful(disp.tally >0) then unstake the reported
            // miner and transfer the stakeAmount and dispute fee to the reporting party
            if (stakes.currentStatus == 3) {
                stakes.currentStatus = 4;
            }
        }
        disp.disputeUintVars[_TALLY_DATE] = block.timestamp;
        disp.executed = true;
        emit DisputeVoteTallied(
            _disputeId,
            _tally,
            disp.reportedMiner,
            disp.reportingParty,
            disp.disputeVotePassed
        );
    }

    /**
     * @dev Allows disputer to unlock the dispute fee
     * @param _disputeId to unlock fee from
     */
    function unlockDisputeFee(uint256 _disputeId) public {
        uint256 origID = disputeIdByDisputeHash[disputesById[_disputeId].hash];
        uint256 lastID =
            disputesById[origID].disputeUintVars[
                keccak256(
                    abi.encode(
                        disputesById[origID].disputeUintVars[_DISPUTE_ROUNDS]
                    )
                )
            ];
        if (lastID == 0) {
            lastID = origID;
        }
        Dispute storage disp = disputesById[origID];
        Dispute storage last = disputesById[lastID];
        //disputeRounds is increased by 1 so that the _id is not a negative number when it is the first time a dispute is initiated
        uint256 dispRounds = disp.disputeUintVars[_DISPUTE_ROUNDS];
        if (dispRounds == 0) {
            dispRounds = 1;
        }
        uint256 _id;
        require(disp.disputeUintVars[_PAID] == 0, "already paid out");
        require(
            block.timestamp - last.disputeUintVars[_TALLY_DATE] > 1 days,
            "Time for voting haven't elapsed"
        );
        StakeInfo storage stakes = stakerDetails[disp.reportedMiner];
        disp.disputeUintVars[_PAID] = 1;
        if (last.disputeVotePassed == true) {
            //Changing the currentStatus and startDate unstakes the reported miner and transfers the stakeAmount
            stakes.startDate = block.timestamp - (block.timestamp % 86400);

            //Reduce the staker count
            uints[_STAKE_COUNT] -= 1;

            //Update the minimum dispute fee that is based on the number of stakers
            updateMinDisputeFee();
            //Decreases the stakerCount since the miner's stake is being slashed
            if (stakes.currentStatus == 4) {
                stakes.currentStatus = 5;
                _doTransfer(
                    disp.reportedMiner,
                    disp.reportingParty,
                    uints[_STAKE_AMOUNT]
                );
                stakes.currentStatus = 0;
            }
            for (uint256 i = 0; i < dispRounds; i++) {
                _id = disp.disputeUintVars[
                    keccak256(abi.encode(dispRounds - i))
                ];
                if (_id == 0) {
                    _id = origID;
                }
                Dispute storage disp2 = disputesById[_id];
                //transfer fee adjusted based on number of miners if the minerIndex is not 2(official value)
                _doTransfer(
                    address(this),
                    disp2.reportingParty,
                    disp2.disputeUintVars[_FEE]
                );
            }
        } else {
            stakes.currentStatus = 1;
            TellorStorage.Request storage _request =
                requestDetails[disp.disputeUintVars[_REQUEST_ID]];
            if (disp.disputeUintVars[_MINER_SLOT] == 2) {
                //note we still don't put timestamp back into array (is this an issue? (shouldn't be))
                _request.finalValues[disp.disputeUintVars[_TIMESTAMP]] = disp
                    .disputeUintVars[_VALUE];
            }
            if (_request.inDispute[disp.disputeUintVars[_TIMESTAMP]] == true) {
                _request.inDispute[disp.disputeUintVars[_TIMESTAMP]] = false;
            }
            for (uint256 i = 0; i < dispRounds; i++) {
                _id = disp.disputeUintVars[
                    keccak256(abi.encode(dispRounds - i))
                ];
                if (_id != 0) {
                    last = disputesById[_id]; //handling if happens during an upgrade
                }
                _doTransfer(
                    address(this),
                    last.reportedMiner,
                    disputesById[_id].disputeUintVars[_FEE]
                );
            }
        }

        if (disp.disputeUintVars[_MINER_SLOT] == 2) {
            requestDetails[disp.disputeUintVars[_REQUEST_ID]].apiUintVars[
                _DISPUTE_COUNT
            ]--;
        }
    }

    /**
     * @dev This function updates the minimum dispute fee as a function of the amount
     * of staked miners
     */
    function updateMinDisputeFee() public {
        uint256 _stakeAmt = uints[_STAKE_AMOUNT];
        uint256 _trgtMiners = uints[_TARGET_MINERS];
        uints[_DISPUTE_FEE] = SafeMath.max(
            15e18,
            (_stakeAmt -
                ((_stakeAmt *
                    (SafeMath.min(_trgtMiners, uints[_STAKE_COUNT]) * 1000)) /
                    _trgtMiners) /
                1000)
        );
    }
}
