pragma solidity 0.8.6;

interface IDocument {
    function getAllDocuments()
        external
        view
        returns (string[] memory);

    function getDocument(string calldata _name)
        external
        view
        returns (string memory, uint256);
}
