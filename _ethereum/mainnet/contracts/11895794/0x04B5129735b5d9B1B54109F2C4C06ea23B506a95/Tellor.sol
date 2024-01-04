// SPDX-License-Identifier: MIT
pragma solidity 0.7.4;

import "./TellorStake.sol";
import "./TellorGetters.sol";
import "./Utilities.sol";
import "./ITellor.sol";
import "./SafeMath.sol";

/**
 * @title Tellor Oracle System
 * @dev Oracle contract where miners can submit the proof of work along with the value.
 */
contract Tellor is TellorStake {
    using SafeMath for uint256;

    event TipAdded(
        address indexed _sender,
        uint256 indexed _requestId,
        uint256 _tip,
        uint256 _totalTips
    );
    //emits when a new challenge is created (either on mined block or when a new request is pushed forward on waiting system)
    event NewChallenge(
        bytes32 indexed _currentChallenge,
        uint256[5] _currentRequestId,
        uint256 _difficulty,
        uint256 _totalTips
    );
    //Emits upon a successful Mine, indicates the blockTime at point of the mine and the value mined
    event NewValue(
        uint256[5] _requestId,
        uint256 _time,
        uint256[5] _value,
        uint256 _totalTips,
        bytes32 indexed _currentChallenge
    );
    //Emits upon each mine (5 total) and shows the miner, nonce, and value submitted
    event NonceSubmitted(
        address indexed _miner,
        string _nonce,
        uint256[5] _requestId,
        uint256[5] _value,
        bytes32 indexed _currentChallenge,
        uint256 _slot
    );

    /**
     * @dev This is an internal function used by the function migrate  that helps to
     *  swap old trb tokens for new ones based on the user's old Tellor balance
     * @param _user is the msg.sender address of the user to migrate the balance from
     */
    function _migrate(address _user) internal {
        require(!migrated[_user], "alredy migrated");
        _doMint(_user, ITellor(addresses[_OLD_TELLOR]).balanceOf(_user));
        migrated[_user] = true;
    }

    /**
     * @dev This function allows users to swap old trb tokens for new ones based
     * on the user's old Tellor balance
     */
    function migrate() external {
        _migrate(msg.sender);
    }

    /**
     * @dev  allows for the deity to update the TellorStake contract address
     * @param _tGetters the address of the new Tellor Contract
     */
    function changeTellorGetters(address _tGetters) external {
        require(msg.sender == addresses[_DEITY]);
        addresses[_TELLOR_GETTERS] = _tGetters;
    }

    /**
     * @dev This function allows miners to submit their mining solution and data requested
     * @param _nonce is the mining solution
     * @param _requestIds iare the 5 request ids being mined
     * @param _values are the 5 values correspoding to the 5 request ids
     */
    function submitMiningSolution(
        string calldata _nonce,
        uint256[5] calldata _requestIds,
        uint256[5] calldata _values
    ) external {
        bytes32 _hashMsgSender = keccak256(abi.encode(msg.sender));
        require(
            uints[_hashMsgSender] == 0 ||
                block.timestamp - uints[_hashMsgSender] > 15 minutes,
            "Miner can only win rewards once per 15 min"
        );
        if (uints[_SLOT_PROGRESS] != 4) {
            _verifyNonce(_nonce);
        }
        uints[_hashMsgSender] = block.timestamp;
        _submitMiningSolution(_nonce, _requestIds, _values);
    }

    /**
     * @dev This is an internal function used by submitMiningSolution to  allows miners to submit
     * their mining solution and data requested. It checks the miner is staked, has not
     * won in the las 15 min, and checks they are submitting all the correct requestids
     * @param _nonce is the mining solution
     * @param _requestIds iare the 5 request ids being mined
     * @param _values are the 5 values correspoding to the 5 request ids
     */
    function _submitMiningSolution(
        string memory _nonce,
        uint256[5] memory _requestIds,
        uint256[5] memory _values
    ) internal {
        //Verifying Miner Eligibility
        bytes32 _hashMsgSender = keccak256(abi.encode(msg.sender));
        require(
            stakerDetails[msg.sender].currentStatus == 1,
            "Miner status is not staker"
        );

        require(
            _requestIds[0] == currentMiners[0].value,
            "Request ID is wrong"
        );
        require(
            _requestIds[1] == currentMiners[1].value,
            "Request ID is wrong"
        );
        require(
            _requestIds[2] == currentMiners[2].value,
            "Request ID is wrong"
        );
        require(
            _requestIds[3] == currentMiners[3].value,
            "Request ID is wrong"
        );
        require(
            _requestIds[4] == currentMiners[4].value,
            "Request ID is wrong"
        );
        uints[_hashMsgSender] = block.timestamp;

        bytes32 _currChallenge = bytesVars[_CURRENT_CHALLENGE];
        uint256 _slotP = uints[_SLOT_PROGRESS];
        //Checking and updating Miner Status
        require(
            minersByChallenge[_currChallenge][msg.sender] == false,
            "Miner already submitted the value"
        );
        //Update the miner status to true once they submit a value so they don't submit more than once
        minersByChallenge[_currChallenge][msg.sender] = true;
        //Updating Request
        Request storage _tblock = requestDetails[uints[_T_BLOCK]];
        //Assigning directly is cheaper than using a for loop
        _tblock.valuesByTimestamp[0][_slotP] = _values[0];
        _tblock.valuesByTimestamp[1][_slotP] = _values[1];
        _tblock.valuesByTimestamp[2][_slotP] = _values[2];
        _tblock.valuesByTimestamp[3][_slotP] = _values[3];
        _tblock.valuesByTimestamp[4][_slotP] = _values[4];
        _tblock.minersByValue[0][_slotP] = msg.sender;
        _tblock.minersByValue[1][_slotP] = msg.sender;
        _tblock.minersByValue[2][_slotP] = msg.sender;
        _tblock.minersByValue[3][_slotP] = msg.sender;
        _tblock.minersByValue[4][_slotP] = msg.sender;

        if (_slotP + 1 == 4) {
            _adjustDifficulty();
        }

        if (_slotP + 1 == 5) {
            //slotProgress has been incremented, but we're using the variable on stack to save gas
            _newBlock(_nonce, _requestIds);
            uints[_SLOT_PROGRESS] = 0;
        } else {
            uints[_SLOT_PROGRESS]++;
        }
        emit NonceSubmitted(
            msg.sender,
            _nonce,
            _requestIds,
            _values,
            _currChallenge,
            _slotP
        );
    }

    /**
     * @dev This is an internal function used by submitMiningSolution to allows miners to submit
     * their mining solution and data requested. It checks the miner has submitted a
     * valid nonce or allows any solution if 15 minutes or more have passed since last
     *  mine values
     * @param _nonce is the mining solution
     */
    function _verifyNonce(string memory _nonce) internal view {
        require(
            uint256(
                sha256(
                    abi.encodePacked(
                        ripemd160(
                            abi.encodePacked(
                                keccak256(
                                    abi.encodePacked(
                                        bytesVars[_CURRENT_CHALLENGE],
                                        msg.sender,
                                        _nonce
                                    )
                                )
                            )
                        )
                    )
                )
            ) %
                uints[_DIFFICULTY] ==
                0 ||
                block.timestamp - uints[_TIME_OF_LAST_NEW_VALUE] >= 15 minutes,
            "Incorrect nonce for current challenge"
        );
    }

    /**
     * @dev This is an internal function used by submitMiningSolution and adjusts the difficulty
     * based on the the difference between the target time and how long it took to solve
     * the previous challenge otherwise it sets it to 1
     */
    function _adjustDifficulty() internal {
        // If the difference between the timeTarget and how long it takes to solve the challenge this updates the challenge
        //difficulty up or down by the difference between the target time and how long it took to solve the previous challenge
        //otherwise it sets it to 1
        uint256 timeDiff = block.timestamp - uints[_TIME_OF_LAST_NEW_VALUE];
        int256 _change = int256(SafeMath.min(1200, timeDiff));
        int256 _diff = int256(uints[_DIFFICULTY]);
        _change = (_diff * (int256(uints[_TIME_TARGET]) - _change)) / 4000;
        if (_change == 0) {
            _change = 1;
        }
        uints[_DIFFICULTY] = uint256(SafeMath.max(_diff + _change, 1));
    }

    /**
     * @dev This is an internal function used by submitMiningSolution to
     * calculate and pay rewards to miners
     * @param miners are the 5 miners to reward
     * @param _previousTime is the previous mine time based on the 4th entry
     */
    function _payReward(address[5] memory miners, uint256 _previousTime)
        internal
    {
        //_timeDiff is how many seconds passed since last block
        uint256 _timeDiff = block.timestamp - _previousTime;
        uint256 reward = (_timeDiff * uints[_CURRENT_REWARD]) / 300;
        uint256 _tip = uints[_CURRENT_TOTAL_TIPS] / 10;
        uint256 _devShare = reward / 2;

        _doMint(miners[0], reward + _tip);
        _doMint(miners[1], reward + _tip);
        _doMint(miners[2], reward + _tip);
        _doMint(miners[3], reward + _tip);
        _doMint(miners[4], reward + _tip);

        _doMint(addresses[_OWNER], _devShare);
        uints[_CURRENT_TOTAL_TIPS] = 0;
    }

    /**
     * @dev This is an internal function called by submitMiningSolution and adjusts the difficulty,
     * sorts and stores the first 5 values received, pays the miners, the dev share and
     * assigns a new challenge
     * @param _nonce or solution for the PoW  for the requestId
     * @param _requestIds for the current request being mined
     */
    function _newBlock(string memory _nonce, uint256[5] memory _requestIds)
        internal
    {
        Request storage _tblock = requestDetails[uints[_T_BLOCK]];
        bytes32 _currChallenge = bytesVars[_CURRENT_CHALLENGE];
        uint256 _previousTime = uints[_TIME_OF_LAST_NEW_VALUE];
        uint256 _timeOfLastNewValueVar = block.timestamp;
        uints[_TIME_OF_LAST_NEW_VALUE] = _timeOfLastNewValueVar;
        //this loop sorts the values and stores the median as the official value
        uint256[5] memory a;
        uint256[5] memory b;
        for (uint256 k = 0; k < 5; k++) {
            for (uint256 i = 1; i < 5; i++) {
                uint256 temp = _tblock.valuesByTimestamp[k][i];
                address temp2 = _tblock.minersByValue[k][i];
                uint256 j = i;
                while (j > 0 && temp < _tblock.valuesByTimestamp[k][j - 1]) {
                    _tblock.valuesByTimestamp[k][j] = _tblock.valuesByTimestamp[
                        k
                    ][j - 1];
                    _tblock.minersByValue[k][j] = _tblock.minersByValue[k][
                        j - 1
                    ];
                    j--;
                }
                if (j < i) {
                    _tblock.valuesByTimestamp[k][j] = temp;
                    _tblock.minersByValue[k][j] = temp2;
                }
            }
            Request storage _request = requestDetails[_requestIds[k]];
            //Save the official(finalValue), timestamp of it, 5 miners and their submitted values for it, and its block number
            a = _tblock.valuesByTimestamp[k];
            _request.finalValues[_timeOfLastNewValueVar] = a[2];
            b[k] = a[2];
            _request.minersByValue[_timeOfLastNewValueVar] = _tblock
                .minersByValue[k];
            _request.valuesByTimestamp[_timeOfLastNewValueVar] = _tblock
                .valuesByTimestamp[k];
            delete _tblock.minersByValue[k];
            delete _tblock.valuesByTimestamp[k];
            _request.requestTimestamps.push(_timeOfLastNewValueVar);
            _request.minedBlockNum[_timeOfLastNewValueVar] = block.number;
            _request.apiUintVars[_TOTAL_TIP] = 0;
        }
        emit NewValue(
            _requestIds,
            _timeOfLastNewValueVar,
            b,
            uints[_CURRENT_TOTAL_TIPS],
            _currChallenge
        );
        //add timeOfLastValue to the newValueTimestamps array
        newValueTimestamps.push(_timeOfLastNewValueVar);
        address[5] memory miners =
            requestDetails[_requestIds[0]].minersByValue[
                _timeOfLastNewValueVar
            ];
        //pay Miners Rewards
        _payReward(miners, _previousTime);
        uints[_T_BLOCK]++;
        uint256[5] memory _topId = _getTopRequestIDs();
        for (uint256 i = 0; i < 5; i++) {
            currentMiners[i].value = _topId[i];
            requestQ[
                requestDetails[_topId[i]].apiUintVars[_REQUEST_Q_POSITION]
            ] = 0;
            uints[_CURRENT_TOTAL_TIPS] += requestDetails[_topId[i]].apiUintVars[
                _TOTAL_TIP
            ];
        }
        //Issue the the next challenge
        _currChallenge = keccak256(
            abi.encode(_nonce, _currChallenge, blockhash(block.number - 1))
        );
        bytesVars[_CURRENT_CHALLENGE] = _currChallenge; // Save hash for next proof
        emit NewChallenge(
            _currChallenge,
            _topId,
            uints[_DIFFICULTY],
            uints[_CURRENT_TOTAL_TIPS]
        );
    }

    /**
     * @dev Add tip to Request value from oracle
     * @param _requestId being requested to be mined
     * @param _tip amount the requester is willing to pay to be get on queue. Miners
     * mine the onDeckQueryHash, or the api with the highest payout pool
     */
    function addTip(uint256 _requestId, uint256 _tip) external {
        require(_requestId != 0, "RequestId is 0");
        require(_tip != 0, "Tip should be greater than 0");
        uint256 _count = uints[_REQUEST_COUNT] + 1;
        if (_requestId == _count) {
            uints[_REQUEST_COUNT] = _count;
        } else {
            require(_requestId < _count, "RequestId is not less than count");
        }
        _doBurn(msg.sender, _tip);
        //Update the information for the request that should be mined next based on the tip submitted
        updateOnDeck(_requestId, _tip);
        emit TipAdded(
            msg.sender,
            _requestId,
            _tip,
            requestDetails[_requestId].apiUintVars[_TOTAL_TIP]
        );
    }

    /**
     * @dev This function updates the requestQ when addTip are ran
     * @param _requestId being requested
     * @param _tip is the tip to add
     */
    function updateOnDeck(uint256 _requestId, uint256 _tip) internal {
        Request storage _request = requestDetails[_requestId];
        _request.apiUintVars[_TOTAL_TIP] = _request.apiUintVars[_TOTAL_TIP].add(
            _tip
        );
        if (
            currentMiners[0].value == _requestId ||
            currentMiners[1].value == _requestId ||
            currentMiners[2].value == _requestId ||
            currentMiners[3].value == _requestId ||
            currentMiners[4].value == _requestId
        ) {
            uints[_CURRENT_TOTAL_TIPS] += _tip;
        } else {
            //if the request is not part of the requestQ[51] array
            //then add to the requestQ[51] only if the _payout/tip is greater than the minimum(tip) in the requestQ[51] array
            if (_request.apiUintVars[_REQUEST_Q_POSITION] == 0) {
                uint256 _min;
                uint256 _index;
                (_min, _index) = _getMin(requestQ);
                //we have to zero out the oldOne
                //if the _payout is greater than the current minimum payout in the requestQ[51] or if the minimum is zero
                //then add it to the requestQ array and map its index information to the requestId and the apiUintVars
                if (_request.apiUintVars[_TOTAL_TIP] > _min || _min == 0) {
                    requestQ[_index] = _request.apiUintVars[_TOTAL_TIP];
                    requestDetails[requestIdByRequestQIndex[_index]]
                        .apiUintVars[_REQUEST_Q_POSITION] = 0;
                    requestIdByRequestQIndex[_index] = _requestId;
                    _request.apiUintVars[_REQUEST_Q_POSITION] = _index;
                }
                // else if the requestId is part of the requestQ[51] then update the tip for it
            } else {
                requestQ[_request.apiUintVars[_REQUEST_Q_POSITION]] += _tip;
            }
        }
    }

    /**
     * @dev This is an internal function called by updateOnDeck that gets the min value
     * @param data is an array [51] to determine the min from
     * @return min the min value and it's index  in the data array
     */
    function _getMin(uint256[51] memory data)
        internal
        pure
        returns (uint256 min, uint256 minIndex)
    {
        minIndex = data.length - 1;
        min = data[minIndex];
        for (uint256 i = data.length - 2; i > 0; i--) {
            if (data[i] < min) {
                min = data[i];
                minIndex = i;
            }
        }
    }

    /**
     * @dev This is an internal function called by updateOnDeck that gets the top 5 values
     * @param data is an array [51] to determine the top 5 values from
     * @return max the top 5 values and their index values in the data array
     */
    function _getMax5(uint256[51] memory data)
        internal
        pure
        returns (uint256[5] memory max, uint256[5] memory maxIndex)
    {
        uint256 min5 = data[1];
        uint256 minI = 0;
        for (uint256 j = 0; j < 5; j++) {
            max[j] = data[j + 1]; //max[0]=data[1]
            maxIndex[j] = j + 1; //maxIndex[0]= 1
            if (max[j] < min5) {
                min5 = max[j];
                minI = j;
            }
        }
        for (uint256 i = 6; i < data.length; i++) {
            if (data[i] > min5) {
                max[minI] = data[i];
                maxIndex[minI] = i;
                min5 = data[i];
                for (uint256 j = 0; j < 5; j++) {
                    if (max[j] < min5) {
                        min5 = max[j];
                        minI = j;
                    }
                }
            }
        }
    }

    /**
     * @dev Getter function for the top 5 requests with highest payouts.
     * This function is used within the newBlock function
     * @return _requestIds the top 5 requests ids based on tips or the last 5 requests ids mined
     */
    function _getTopRequestIDs()
        internal
        view
        returns (uint256[5] memory _requestIds)
    {
        uint256[5] memory _max;
        uint256[5] memory _index;
        (_max, _index) = _getMax5(requestQ);
        for (uint256 i = 0; i < 5; i++) {
            if (_max[i] != 0) {
                _requestIds[i] = requestIdByRequestQIndex[_index[i]];
            } else {
                _requestIds[i] = currentMiners[4 - i].value;
            }
        }
    }

    /**
     * @dev This is an internal function called within the fallback function to help delegate calls.
     * This functions helps delegate calls to the TellorGetters
     * contract.
     */
    function _delegate(address implementation)
        internal
        virtual
        returns (bool succ, bytes memory ret)
    {
        (succ, ret) = implementation.delegatecall(msg.data);
    }

    /**
     * @dev The tellor logic does not fit in one contract so it has been split into two:
     * Tellor and TellorGetters This functions helps delegate calls to the TellorGetters
     * contract.
     */
    fallback() external payable {
        address addr = addresses[_TELLOR_GETTERS];
        (bool result, ) = _delegate(addr);
        assembly {
            returndatacopy(0, 0, returndatasize())

            switch result
                // delegatecall returns 0 on error.
                case 0 {
                    revert(0, returndatasize())
                }
                default {
                    return(0, returndatasize())
                }
        }
    }
}
