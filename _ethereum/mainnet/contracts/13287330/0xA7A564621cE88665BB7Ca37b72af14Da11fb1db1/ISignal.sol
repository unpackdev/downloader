pragma solidity 0.8.0;

interface ISignal {
    function registerSignal(
        string memory,
        string memory,
        string[] memory
    ) external returns (string memory);

    function withdrawSignal(string memory) external;

    function submitSignal(
        string memory,
        string[] memory,
        int256[] memory,
        bytes calldata
    ) external;

    function updateSignal(string memory) external;

    function getSignal(string memory) external view returns (int256[] memory);

    function getSignalSymbols(string memory)
        external
        view
        returns (string[] memory);
}
