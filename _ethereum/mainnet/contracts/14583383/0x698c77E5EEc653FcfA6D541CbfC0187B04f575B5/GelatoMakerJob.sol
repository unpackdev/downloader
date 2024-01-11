// SPDX-License-Identifier: UNLICENSED
//solhint-disable compiler-version
pragma solidity 0.8.11;
import "./GelatoBytes.sol";
import "./Strings.sol";

interface ISequencer {
    struct WorkableJob {
        address job;
        bool canWork;
        bytes args;
    }

    function getNextJobs(
        bytes32 network,
        uint256 startIndex,
        uint256 endIndexExcl
    ) external returns (WorkableJob[] memory);

    function numJobs() external view returns (uint256);
}

interface IJob {
    function work(bytes32 network, bytes calldata args) external;

    function workable(bytes32 network)
        external
        returns (bool canWork, bytes memory args);
}

contract GelatoMakerJob {
    using GelatoBytes for bytes;

    address public immutable pokeMe;

    constructor(address _pokeMe) {
        pokeMe = _pokeMe;
    }

    //solhint-disable code-complexity
    //solhint-disable function-max-lines
    function checker(
        address _sequencer,
        bytes32 _network,
        uint256 _startIndex,
        uint256 _endIndex
    ) external returns (bool, bytes memory) {
        ISequencer sequencer = ISequencer(_sequencer);
        uint256 numJobs = sequencer.numJobs();

        if (numJobs == 0)
            return (false, bytes("GelatoMakerJob: No jobs listed"));
        if (_startIndex >= numJobs) {
            bytes memory msg1 = bytes.concat(
                "GelatoMakerJob: Only jobs available up to index ",
                bytes(Strings.toString(numJobs - 1))
            );

            bytes memory msg2 = bytes.concat(
                ", inputted startIndex is ",
                bytes(Strings.toString(_startIndex))
            );
            return (false, bytes.concat(msg1, msg2));
        }

        uint256 endIndex = _endIndex > numJobs ? numJobs : _endIndex;

        ISequencer.WorkableJob[] memory jobs = ISequencer(_sequencer)
            .getNextJobs(_network, _startIndex, endIndex);

        uint256 numWorkable;
        for (uint256 i; i < jobs.length; i++) {
            if (jobs[i].canWork) numWorkable++;
        }

        if (numWorkable == 0)
            return (false, bytes("GelatoMakerJob: No workable jobs"));

        address[] memory tos = new address[](numWorkable);
        bytes[] memory datas = new bytes[](numWorkable);

        uint256 wIndex;
        for (uint256 i; i < jobs.length; i++) {
            if (jobs[i].canWork) {
                tos[wIndex] = jobs[i].job;
                datas[wIndex] = abi.encodeWithSelector(
                    IJob.work.selector,
                    _network,
                    jobs[i].args
                );
                wIndex++;
            }
        }

        bytes memory execPayload = abi.encodeWithSelector(
            this.doJobs.selector,
            tos,
            datas
        );

        return (true, execPayload);
    }

    function doJobs(address[] calldata _tos, bytes[] calldata _datas) external {
        require(msg.sender == pokeMe, "GelatoMakerJob: Only PokeMe");
        require(
            _tos.length == _datas.length,
            "GelatoMakerJob: Length mismatch"
        );

        for (uint256 i; i < _tos.length; i++) {
            _doJob(_tos[i], _datas[i]);
        }
    }

    function _doJob(address _to, bytes memory _data) private {
        (bool success, bytes memory returnData) = _to.call(_data);
        if (!success) returnData.revertWithError("GelatoMakerJob: ");
    }
}
