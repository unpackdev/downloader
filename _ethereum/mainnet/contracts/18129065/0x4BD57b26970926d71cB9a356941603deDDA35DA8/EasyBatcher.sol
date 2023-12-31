// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./EasyInit.sol";
import "./EasyLibrary.sol";

abstract contract EasyBatcher is EasyInit {
    using EasyLibrary for *;
    EasyLibrary.Batch[] public batchData;

    error DateAlreadyPast();
    error BatchOutOfRange();
    error MinMaxFlipped();

    constructor(){}

    function batchExists(uint _batchID) internal virtual {
        if (_batchID >= batchData.length) {
            revert BatchOutOfRange();
        }
    }

    /**
    @notice Creates a new batch of tokens with the specified parameters and adds it to the batch data.
    @param _newBatch The Batch struct containing the configuration details for the new batch.
    @dev This function can only be called by administrators.
    */
    function createBatch(EasyLibrary.Batch calldata _newBatch) public virtual onlyAdmins {
        //create a batch and push it to EasyLibrary.Batch[] public batchData;
        batchData.push(_newBatch);
    }

    /**
    @dev Admin can set the state of an OPTION for a batch.
    @param _option The OPTION to set the state of:
    0 = Set the PAUSED state of a batch.
    1 = Set the REVEALED state.
    2 = Set the USING ROLLS state allowing Mints to pick a roll randomly within a set range.
    3 = Set the MINT IN ORDER state.     
    4 = Set the BIND on mint state. Note: Bound tokens cannot be moved once minted.
    //5 = Set the PRESALE state.
    6 = Set ROLL SWAP ALLOW state.
    @param _state The new state of the option:
    true = revealed, on
    false = hidden, off
    @param _fromBatch The batch ID to update the state for.
    */
    function setStateOf(uint _option, bool _state, uint _fromBatch) public virtual onlyAdmins {
        if(_option == 0){
            batchData[_fromBatch].bPaused = _state;
        } else if(_option == 1){
            batchData[_fromBatch].bRevealed = _state;
        } else if(_option == 2){
            batchData[_fromBatch].bRollInUse = _state;
        } else if(_option == 3){
            batchData[_fromBatch].bMintInOrder = _state;
        } else if(_option == 4){
            batchData[_fromBatch].bBindOnMint = _state;
        // } else if(_option == 5){
        //     presaleBatch[_fromBatch] = _state;
        } else if(_option == 6){
            batchData[_fromBatch].bRollSwapAllow = _state;
        }
    }

    /**
    @dev Allows an admin to set a start date for minting tokens for a specific batch.
    Tokens can only be minted after this date has passed.
    @param _batch The ID of the batch to set the mint date for.
    @param _unixDate The Unix timestamp for the start date of minting.
    @notice The Unix timestamp must be in the future, otherwise the function will revert.
    */
    function setMintDate(uint256 _batch, uint _unixDate) public virtual onlyAdmins {
        batchExists(_batch);
        if (_unixDate <= block.timestamp) {
            revert DateAlreadyPast();
        }
        batchData[_batch].bMintStartDate = _unixDate;
    }

    /**
    @dev Sets the batch range and ID of the next token to be minted.
    @param _bRangeNext uint array [start_ID, end_ID, nextIDToMint].
    @param _fromBatch uint batch ID of the batch to edit.
    Requirements:
    Only accessible by admins.
    */
    function setBatchRangeNext(uint[3] memory _bRangeNext, uint _fromBatch) external virtual onlyAdmins {
        batchData[_fromBatch].bRangeNext = _bRangeNext;
    }

    /**
    @dev Admin can set the new public or presale cost for a specific batch in WEI. The cost is denominated in wei,
    where 1 ETH = 10^18 WEI. To convert ETH to WEI and vice versa, use a tool such as https://etherscan.io/unitconverter.
    @param _isRollCost bool indicating if setting a roll or batch cost.
    @param _newCost uint256 indicating the new cost for the batch in WEI.
    @param _fromBatch uint indicating the ID of the batch to which the new cost applies.
    Note:
    This also sets the batchNextCost to the new cost so if a setCostNextOnTrigger was set it will need to be reset again.
    Requirements:
    Only accessible by admins.
    */
    function setCost(bool _isRollCost, uint256 _newCost, uint _fromBatch) public virtual onlyAdmins {
        if (!_isRollCost) {
            batchData[_fromBatch].bCost = _newCost;
            batchData[_fromBatch].bNextCost = _newCost;
        } else {
            batchData[_fromBatch].bRollCost = _newCost;
        }
    }

    /**
    @dev Sets the cost for the next mint after a specific token is minted in a batch.
    Only accessible by admins.
    */
    function setCostNextOnTrigger(uint256 _nextCost, uint _triggerPointID, uint _fromBatch) public virtual onlyAdmins {
        batchData[_fromBatch].bTriggerPoint = _triggerPointID;
        batchData[_fromBatch].bNextCost = _nextCost;
    }

    /**
    @dev Allows the contract admin to set the requirement tokens and their corresponding amounts for a specific batch ID.
    @param _batchID The ID of the batch for which the requirement tokens and amounts will be set.
    @param _requiredIDS An array of token IDs that are required to be owned in order to aquire tokens from a batch.
    @param _amounts An array of amounts indicating how many of each token ID in `_requiredIDS` are required.
    @param _tAddress is the token address for each ID specified in _requiredIDS.
    */
    function setRequirementTokens(uint _batchID, uint[] calldata _requiredIDS, uint[] calldata _amounts, address[] calldata _tAddress,  bool[] calldata _tContractType) external virtual onlyAdmins {
        batchExists(_batchID);
        batchData[_batchID].bRequirementTokens = _requiredIDS;
        batchData[_batchID].bRequirementAmounts = _amounts;
        batchData[_batchID].bRequirementAddresses = _tAddress;
        batchData[_batchID].bRequirementContractType = _tContractType;
    }

    /**
    @dev Sets the minimum and maximum values for the roll limit for a given batch _fromBatch.
    @param _min The minimum value of the roll limit (excluded).
    @param _max The maximum value of the roll limit (included).
    @param _fromBatch The ID of the batch to set the roll limit for.
    */
    function rollLimitSet(uint _min, uint _max, uint _fromBatch) external virtual onlyAdmins {
        if(_min > _max) {
            revert MinMaxFlipped();
        }
        batchData[_fromBatch].bRollRange = [_min, _max];
    }

    /**
    @dev Allows admin to set the supplies or mint limit for a batch.
    @param _isSupplies The flag is supplies or mint limit.
    @param _value The new value to set.
    @param _fromBatch The index of the batch to set the value for.
    */
    function setSuppliesOrLimit(bool _isSupplies, uint256 _value, uint256 _fromBatch) public virtual onlyAdmins {
        if(!_isSupplies) {
            batchData[_fromBatch].bLimit = _value;
        } else {
            batchData[_fromBatch].bSupply = _value;
        }
    }

    function getFixedArrayFromBatch(uint _option, uint _batchID) external view returns (string memory) {
        if (_option == 0) {
            return string(abi.encodePacked("[", Strings.toString(batchData[_batchID].bRangeNext[0]), ",", Strings.toString(batchData[_batchID].bRangeNext[1]), ",", Strings.toString(batchData[_batchID].bRangeNext[2]), "]"));
        }
        else if (_option == 1) {
            return string(abi.encodePacked("[", batchData[_batchID].bURI[0], ",", batchData[_batchID].bURI[1], "]"));
        } 
        else if (_option == 8) {
            return string(abi.encodePacked("[", Strings.toString(batchData[_batchID].bRollRange[0]), ",", Strings.toString(batchData[_batchID].bRollRange[1]), "]"));
        } 
        
        return "";
    }

    function getArrayFromBatch(uint _option, uint _batchID) external view returns (uint[] memory) {
        if (_option == 16) {
            return batchData[_batchID].bRequirementTokens;
        }
        else if (_option == 17) {
            return batchData[_batchID].bRequirementAmounts;
        }

        return new uint[](0);
    }

    function getAddressArrayFromBatch(uint _option, uint _batchID) external view returns (address[] memory) {
        if (_option == 18) {
            return batchData[_batchID].bRequirementAddresses;
        }

        return new address[](0);
    }

    function getBoolArrayFromBatch(uint _option, uint _batchID) external view returns (bool[] memory) {
        if (_option == 19) {
            return batchData[_batchID].bRequirementContractType;
        }

        return new bool[](0);
    }
}
