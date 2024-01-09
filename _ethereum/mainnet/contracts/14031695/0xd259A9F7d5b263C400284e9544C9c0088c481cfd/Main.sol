// SPDX-License-Identifier: MIT
// solhint-disable-next-line compiler-version
pragma solidity >=0.8.0;
pragma experimental ABIEncoderV2;

import "./console.sol";

interface Oracle {
    function getReportTimestampByIndex(bytes32 _queryId, uint256 _index)
        external
        view
        returns (uint256);

    function getValueByTimestamp(bytes32 _queryId, uint256 _timestamp)
        external
        view
        returns (bytes memory);

    //get last values on a request id
    function getTimestampCountById(bytes32 _queryId)
        external
        view
        returns (uint256);

    function getTimeOfLastNewValue() external view returns (uint256);

    function getCurrentReward(bytes32 _queryId)
        external
        view
        returns (uint256, uint256);

    function getTipsById(bytes32 _queryId) external view returns (uint256);

    function getTipsByUser(address _user) external view returns (uint256);

    function tipsInContract() external view returns (uint256);
}

interface Master {
    function getAddressVars(bytes32 _data) external view returns (address);

    function getUintVar(bytes32 _data) external view returns (uint256);
}

interface Governance {
    function disputeFee() external view returns (uint256);
}

/**
 * @title Tellor Lens main contract
 * @dev Aggregate and simplify calls to the Tellor oracle.
 **/
contract Main {
    Oracle public oracle;
    Master public master;
    Governance public governance;

    struct DataID {
        bytes32 id;
    }

    struct Value {
        DataID meta;
        uint256 timestamp;
        uint256 tip;
        bytes value;
    }

    constructor(
        address payable _oracle,
        address payable _master,
        address payable _governance
    ) {
        oracle = Oracle(_oracle);
        master = Master(_master);
        governance = Governance(_governance);
    }

    /**
     * @param _queryId bytes32 hash of queryId.
     * @return Returns the current reward amount.
     */
    function getCurrentReward(bytes32 _queryId)
        external
        view
        returns (uint256, uint256)
    {
        return oracle.getCurrentReward(_queryId);
    }

    /**
     * @param _queryId is the ID for which the function returns the values for.
     * @param _count is the number of last values to return.
     * @return Returns the last N values for a request ID.
     */
    function getLastValues(bytes32 _queryId, uint256 _count)
        public
        view
        returns (Value[] memory)
    {
        uint256 totalCount = oracle.getTimestampCountById(_queryId); //replaced
        if (_count > totalCount) {
            _count = totalCount;
        }
        Value[] memory values = new Value[](_count);
        for (uint256 i = 0; i < _count; i++) {
            uint256 ts = oracle.getReportTimestampByIndex( //replaced
                _queryId,
                totalCount - i - 1
            );
            bytes memory v = oracle.getValueByTimestamp(_queryId, ts); //replaced
            values[i] = Value({
                meta: DataID({id: _queryId}),
                timestamp: ts,
                value: v,
                tip: oracle.getTipsById(_queryId) //replaced
            });
        }

        return values;
    }

    /**
     * @param _count is the number of last values to return.
     * @param _queryIds is a bytes32 array of queryIds.
     * @return Returns the last N values for a specified queryIds.
     */
    function getLastValuesAll(uint256 _count, bytes32[] memory _queryIds)
        external
        view
        returns (Value[] memory)
    {
        Value[] memory values = new Value[](_count * _queryIds.length);
        uint256 pos = 0;
        for (uint256 i = 0; i < _queryIds.length; i++) {
            Value[] memory v = getLastValues(_queryIds[i], _count);
            for (uint256 ii = 0; ii < v.length; ii++) {
                values[pos] = v[ii];
                pos++;
            }
        }
        return values;
    }

    /**
     * @return Returns the contract deity that can do things at will.
     */
    function deity() external view returns (address) {
        return master.getAddressVars(keccak256("_DEITY"));
    }

    /**
     * @return Returns the contract owner address.
     */
    function owner() external view returns (address) {
        return master.getAddressVars(keccak256("_OWNER"));
    }

    /**
     * @return Returns the contract pending owner.
     */
    function pendingOwner() external view returns (address) {
        return master.getAddressVars(keccak256("_PENDING_OWNER"));
    }

    /**
     * @return Returns the contract address that executes all proxy calls.
     */
    function tellorContract() external view returns (address) {
        return master.getAddressVars(keccak256("_TELLOR_CONTRACT"));
    }

    /**
     * @param _queryId is the ID for which the function returns the total tips.
     * @return Returns the current tips for a give query ID.
     */
    function totalTip(bytes32 _queryId) public view returns (uint256) {
        return oracle.getTipsById(_queryId);
    }

    /**
     * @return Returns the last time a value was submitted by a reporter.
     */
    function timeOfLastValue() external view returns (uint256) {
        return oracle.getTimeOfLastNewValue();
    }

    /**
     * @param _user address of the user we want to find out totalTip amount.
     * @return Returns the total number of tips from a user.
     */
    function totalTipsByUser(address _user) external view returns (uint256) {
        return oracle.getTipsByUser(_user);
    }

    /**
     * @return Returns the total amount of tips in the Oracle contract.
     */
    function tipsInContract() external view returns (uint256) {
        return oracle.tipsInContract();
    }

    /**
     * @return Returns the current dispute fee amount.
     */
    function disputeFee() external view returns (uint256) {
        return governance.disputeFee();
    }

    /**
     * @return Returns a variable that tracks the stake amount required to become a reporter.
     */
    function stakeAmount() external view returns (uint256) {
        return master.getUintVar(keccak256("_STAKE_AMOUNT"));
    }

    /**
     * @return Returns the getUintVar variable named after the function name.
     * This variable tracks the number of parties currently staked.
     */
    function stakeCount() external view returns (uint256) {
        return master.getUintVar(keccak256("_STAKE_AMOUNT"));
    }
}
