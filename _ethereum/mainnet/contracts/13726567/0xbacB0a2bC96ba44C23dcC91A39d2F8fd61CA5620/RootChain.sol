pragma solidity ^0.5.2;

import "./RLPReader.sol";
import "./SafeMath.sol";

import "./RootChainStorage.sol";

import "./IStakeManager.sol";
import "./IRootChain.sol";
import "./Registry.sol";


contract RootChain is RootChainStorage, IRootChain {
    using SafeMath for uint256;
    using RLPReader for bytes;
    using RLPReader for RLPReader.RLPItem;
    struct ParameterData {
        address proposer;
        uint256 start;
        uint256 end;
        bytes32 rootHash;
        bytes32 accountHash;
        uint256 _borChainID;
        uint256 epoch;
    }

    modifier onlyDepositManager() {
        require(msg.sender == registry.getDepositManagerAddress(), "UNAUTHORIZED_DEPOSIT_MANAGER_ONLY");
        _;
    }

    function submitHeaderBlock(bytes calldata data, bytes calldata sigs) external {
        revert();
    }

    function submitCheckpoint(bytes calldata data, uint[3][] calldata sigs) external {
        ParameterData memory _parameterData;
        (_parameterData.proposer, _parameterData.start, _parameterData.end, _parameterData.rootHash, _parameterData.accountHash, _parameterData._borChainID, _parameterData.epoch) = abi
            .decode(data, (address, uint256, uint256, bytes32, bytes32, uint256, uint256));
        require(CHAINID == _parameterData._borChainID, "Invalid bor chain id");

        require(_buildHeaderBlock(_parameterData.proposer, _parameterData.start, _parameterData.end, _parameterData.rootHash), "INCORRECT_HEADER_DATA");

        // check if it is better to keep it in local storage instead
        IStakeManager stakeManager = IStakeManager(registry.getStakeManagerAddress());
        uint256 _reward = stakeManager.checkSignatures(
            _parameterData.end.sub(_parameterData.start).add(1),
            _parameterData.epoch,
            /**  
                prefix 01 to data 
                01 represents positive vote on data and 00 is negative vote
                malicious validator can try to send 2/3 on negative vote so 01 is appended
             */
            keccak256(abi.encodePacked(bytes(hex"01"), data)),
            _parameterData.accountHash,
            _parameterData.proposer,
            sigs
        );

        require(_reward != 0, "Invalid checkpoint");
        emit NewHeaderBlock(_parameterData.proposer, _nextHeaderBlock, _reward, _parameterData.start, _parameterData.end, _parameterData.rootHash);
        _nextHeaderBlock = _nextHeaderBlock.add(MAX_DEPOSITS);
        _blockDepositId = 1;
    }

    function updateDepositId(uint256 numDeposits) external onlyDepositManager returns (uint256 depositId) {
        depositId = currentHeaderBlock().add(_blockDepositId);
        // deposit ids will be (_blockDepositId, _blockDepositId + 1, .... _blockDepositId + numDeposits - 1)
        _blockDepositId = _blockDepositId.add(numDeposits);
        require(
            // Since _blockDepositId is initialized to 1; only (MAX_DEPOSITS - 1) deposits per header block are allowed
            _blockDepositId <= MAX_DEPOSITS,
            "TOO_MANY_DEPOSITS"
        );
    }

    function getLastChildBlock() external view returns (uint256) {
        return headerBlocks[currentHeaderBlock()].end;
    }

    function slash() external {
        //TODO: future implementation
    }

    function currentHeaderBlock() public view returns (uint256) {
        return _nextHeaderBlock.sub(MAX_DEPOSITS);
    }

    function _buildHeaderBlock(
        address proposer,
        uint256 start,
        uint256 end,
        bytes32 rootHash
    ) private returns (bool) {
        uint256 nextChildBlock;
        /*
    The ID of the 1st header block is MAX_DEPOSITS.
    if _nextHeaderBlock == MAX_DEPOSITS, then the first header block is yet to be submitted, hence nextChildBlock = 0
    */
        if (_nextHeaderBlock > MAX_DEPOSITS) {
            nextChildBlock = headerBlocks[currentHeaderBlock()].end + 1;
        }
        if (nextChildBlock != start) {
            return false;
        }

        HeaderBlock memory headerBlock = HeaderBlock({
            root: rootHash,
            start: nextChildBlock,
            end: end,
            createdAt: now,
            proposer: proposer
        });

        headerBlocks[_nextHeaderBlock] = headerBlock;
        return true;
    }

    // Housekeeping function. @todo remove later
    function setNextHeaderBlock(uint256 _value) public onlyOwner {
        require(_value % MAX_DEPOSITS == 0, "Invalid value");
        for (uint256 i = _value; i < _nextHeaderBlock; i += MAX_DEPOSITS) {
            delete headerBlocks[i];
        }
        _nextHeaderBlock = _value;
        _blockDepositId = 1;
        emit ResetHeaderBlock(msg.sender, _nextHeaderBlock);
    }

    // Housekeeping function. @todo remove later
    function setHeimdallId(string memory _heimdallId) public onlyOwner {
        heimdallId = keccak256(abi.encodePacked(_heimdallId));
    }
}
