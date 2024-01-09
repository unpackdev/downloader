pragma solidity 0.8.6;

import "IDocument.sol";

contract DocumentHelper {
    struct Document {
        string name;
        string data;
    }

    function getDocuments(address _contract)
        public
        view
        returns (Document[] memory)
    {
        IDocument document = IDocument(_contract);
        string[] memory documentNames = document.getAllDocuments();
        uint256 documentCount = documentNames.length;

        Document[] memory documents = new Document[](documentCount);

        for (uint256 i = 0; i < documentCount; i++) {
            string memory documentName = documentNames[i];
            (documents[i].data, ) = document.getDocument(documentName);
            documents[i].name = documentName;
        }
        return documents;
    }
}
