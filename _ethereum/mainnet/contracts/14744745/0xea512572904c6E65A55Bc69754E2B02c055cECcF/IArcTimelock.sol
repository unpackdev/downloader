pragma solidity 0.8.10;

interface IArcTimelock {
    function queue(
        address[] memory targets,
        uint256[] memory values,
        string[] memory signatures,
        bytes[] memory calldatas,
        bool[] memory withDelegatecalls
    ) external;

    function getActionsSetCount() external returns (uint256);
    
    function execute(uint256) external payable;
}
