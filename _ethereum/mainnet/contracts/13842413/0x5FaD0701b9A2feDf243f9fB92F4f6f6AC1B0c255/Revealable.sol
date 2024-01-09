// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./Presaleable.sol";

contract Revealable is Presaleable {
    using Strings for uint256;
    bool public isRevealable; // is the collection revealable
    bytes32 public projectURIProvenance; // hash to make sure that Project URI dosen't change
    uint256 public revealAfterTimestamp; // timestamp when the original art needs to be revealed

    /**
     * @dev set revealable details of the collection
     * @param _projectURIProvenance provenance of the collection
     * @param _revealAfterTimestamp reveal timestamp of the collection
     */
    function setRevealableDetails(
        bytes32 _projectURIProvenance,
        uint256 _revealAfterTimestamp
    ) internal {
        require(_revealAfterTimestamp >= block.timestamp, "R:001");
        if (
            _projectURIProvenance != keccak256(abi.encode(loadingURI)) &&
            _revealAfterTimestamp > 0
        ) {
            isRevealable = true;
            projectURIProvenance = _projectURIProvenance;
            _setRevealAfterTimestamp(_revealAfterTimestamp);
        } else {
            projectURI = loadingURI;
        }
    }

    /**
     * @dev set new reveal timestamp
     * @param _revealAfterTimestamp new reveal timestamp of the collection
     */
    function setRevealAfterTimestamp(uint256 _revealAfterTimestamp)
        external
        onlyOwner
    {
        require(isRevealable, "R:002");
        require(_revealAfterTimestamp >= block.timestamp, "R:003");
        _setRevealAfterTimestamp(_revealAfterTimestamp);
    }

    /**
     * @dev set new project URI
     * @param _projectURI new project URI
     */
    function setProjectURI(string memory _projectURI) external onlyOwner {
        projectURI = _projectURI;
    }

    /**
     * @dev view method to return URI of a collection
     * @param tokenId token id
     * @return token URI for the supplied token ID
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "R:004");
        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json"))
                : loadingURI;
    }

    /**
     * @dev private method to set reveal timestamp
     * @param _revealAfterTimestamp new reveal timestamp of the collection
     */
    function _setRevealAfterTimestamp(uint256 _revealAfterTimestamp) private {
        revealAfterTimestamp = _revealAfterTimestamp;
    }
}
