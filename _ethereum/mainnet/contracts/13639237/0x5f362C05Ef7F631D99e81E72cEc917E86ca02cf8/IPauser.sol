// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.0;

import "./IMochiEngine.sol";
interface IPauser {
    event CallerChanged(address _newCaller);

    function caller() external view returns(address);
    function engine() external view returns(IMochiEngine);
    function changeCaller(address _newCaller) external;
    function pauseMint() external;
    function unpauseMint() external;
    function pause(address[] calldata _vaults) external;
    function unpause(address[] calldata _vaults) external;
}
