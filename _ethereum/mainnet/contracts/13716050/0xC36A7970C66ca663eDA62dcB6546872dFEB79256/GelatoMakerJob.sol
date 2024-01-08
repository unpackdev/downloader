// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;
import "./GelatoBytes.sol";

interface IJob {
    function getNextJob(bytes32 operator)
        external
        view
        returns (
            bool canExec,
            address target,
            bytes memory execPayload
        );
}

contract GelatoMakerJob {
    using GelatoBytes for bytes;

    address public immutable pokeMe;

    constructor(address _pokeMe) {
        pokeMe = _pokeMe;
    }

    function doJob(
        address _target,
        bytes memory _execPayload,
        bool _shouldRevert
    ) external {
        require(msg.sender == pokeMe, "GelatoMakerJob: Only PokeMe");

        (bool success, bytes memory returnData) = _target.call(_execPayload);
        if (!success && _shouldRevert)
            returnData.revertWithError("GelatoMakerJob.doJob:");
    }

    function checker(
        bytes32 _network,
        address _job,
        bool _shouldRevert
    ) external view returns (bool canExec, bytes memory pokeMePayload) {
        address target;
        bytes memory execPayload;

        (canExec, target, execPayload) = IJob(_job).getNextJob(_network);

        pokeMePayload = abi.encodeWithSelector(
            this.doJob.selector,
            target,
            execPayload,
            _shouldRevert
        );
    }
}
