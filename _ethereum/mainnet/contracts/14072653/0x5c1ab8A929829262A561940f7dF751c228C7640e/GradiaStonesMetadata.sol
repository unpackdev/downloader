// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "./Strings.sol";
import "./Ownable.sol";
import "./IGradiaStonesMetadata.sol";
import "./IGradiaStones.sol";

contract GradiaStonesMetadata is IGradiaStonesMetadata, Ownable {
    using Strings for uint256;

    event NewBatch(uint256 batchNumber, string baseURI, uint256 lastStone);

    uint256[] public lastTokenOfBatch;
    uint256 public lastId;
    mapping(uint256 => string) public batchURI;
    address public mainContract;

    modifier onlyWhitelisted() {
        require(mainContract != address(0x0), "Main contract not set");
        require(IGradiaStones(mainContract).isWhitelisted(msg.sender), "You're not permitted to perform this action.");
        _;
    }

    constructor() {
        lastTokenOfBatch.push(0);
    }

    function getMetadata(uint256 tokenId) external view override returns (string memory) {
        for (uint256 i = 0; i < lastTokenOfBatch.length; i++) {
            if (lastTokenOfBatch[i] >= tokenId) {
                string memory base = batchURI[lastTokenOfBatch[i]];
                return string(abi.encodePacked(base, tokenId.toString()));
            }
        }
        return "";
    }

    function setMainContract(address _address) external onlyOwner {
        mainContract = _address;
    }

    function getSingleBatchURI(uint256 batchNumber) external view returns (string memory) {
        require(batchNumber < lastTokenOfBatch.length && batchNumber > 0, "Batch number does not exist");
        return batchURI[lastTokenOfBatch[batchNumber]];
    }

    function setSingleBatchURI(uint256 batchNumber, string memory uri) external onlyWhitelisted {
        require(batchNumber > 0);
        require(batchNumber < lastTokenOfBatch.length);
        batchURI[lastTokenOfBatch[batchNumber]] = uri;
    }
    
    function getAllBatchURI() external view returns (string[] memory) {
        // batchNumber : batchURI : firstToken-lastToken
        string [] memory allBatches = new string [] (lastTokenOfBatch.length - 1);
        for (uint256 i = 1; i < lastTokenOfBatch.length; i++) {
            allBatches[i - 1] = string(abi.encodePacked(i.toString(), ":", batchURI[lastTokenOfBatch[i]],":",(lastTokenOfBatch[i - 1]+1).toString(),"-",lastTokenOfBatch[i].toString()));
        }
        return allBatches;
    }

    function setAllBatchURI(string [] calldata batchBaseURI) external onlyWhitelisted {
        require(batchBaseURI.length == lastTokenOfBatch.length - 1);
        for (uint256 i = 1; i < lastTokenOfBatch.length; i++) {
            batchURI[lastTokenOfBatch[i]] = batchBaseURI[i - 1];
        }
    }

    function createBatch(uint256 amount, string calldata batchBaseURI) external onlyWhitelisted {
        lastId += amount;
        lastTokenOfBatch.push(lastId);
        batchURI[lastId] = batchBaseURI;
        emit NewBatch(lastTokenOfBatch.length, batchBaseURI, lastId);
    }
}
