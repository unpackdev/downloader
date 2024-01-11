// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./Ownable.sol";
import "./SafeMath.sol";


contract StoreHash is Ownable {
    using SafeMath for uint256;

    struct Doc {
        string docURI;          // URI of the document that exist off-chain
        bytes32 docHash;        // Hash of the document
        uint256 lastModified;   // Timestamp at which document details was last modified
    }

    uint256 private docsCounter;

    mapping(uint256 => Doc) internal _documents;

    event DocHashAdded(uint256 indexed num, string docuri, bytes32 dochash);

    constructor() { }

    /**
     * @dev set a new document structure to store in the list, queueing it if others exist and incremetning documents counter
     * @param uri string for document URL
     * @param documentHash bytes32 Hash to add to list
     */
    function addNewDocument(string memory uri, bytes32 documentHash) external onlyOwner{
        _documents[docsCounter] = Doc({docURI: uri, docHash: documentHash, lastModified: block.timestamp});
        docsCounter = docsCounter.add(1); //prepare for next doc to add
        emit DocHashAdded(docsCounter, uri, documentHash);
    }

    /**
     * @dev get a hash in the _num place
     * @param _num uint256 Place of the hash to return
     * @return string name, bytes32 hash, uint256 datetime
     */
    function getDocInfos(uint256 _num) external view returns (string memory, bytes32, uint256) {
        return (_documents[_num].docURI, _documents[_num].docHash, _documents[_num].lastModified);
    }

    /**
     * @dev get the hash list length
     */
    function getDocsCount() external view returns (uint256) {
        return docsCounter;
    }

}