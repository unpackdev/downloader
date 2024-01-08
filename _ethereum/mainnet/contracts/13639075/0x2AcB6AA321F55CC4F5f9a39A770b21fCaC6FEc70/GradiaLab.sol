// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./Whitelist.sol";

contract GradiaLab is ERC721, Whitelist {

    event NewStone(uint256 tokenId);
    event NewBatch(uint256 batchNumber, string BaseURI, uint256 LastStone);

    using Counters for Counters.Counter;
    using Strings for uint256;
    Counters.Counter _tokenIds;

    uint256[] public batches;
    mapping(uint256 => string) public batchURI;

    constructor() ERC721("Gradia Lab", "GRAD") {
        // Token ID and Batch Number start with 1
        _tokenIds.increment();
        batches.push(0);
    }

    function setBatchURI(uint256 batchNumber, string memory uri) external onlyWhitelisted {
        batchURI[batchNumber] = uri;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(tokenId > 0 && tokenId < _tokenIds.current(), "Token does not exist");
        for (uint256 i = 0; i < batches.length; i++) {
            if (batches[i] >= tokenId) {
                string memory base = batchURI[batches[i]];
                return string(abi.encodePacked(base, tokenId.toString(), ".json"));
            }
        }
        return "";
    }

    function batchMint(address recipient, uint256 amount, string memory batchBaseURI) public onlyWhitelisted {
        for (uint256 i = 0; i < amount; i++) {
            uint256 newId = _tokenIds.current();
            _safeMint(recipient, newId);
            _tokenIds.increment();
            emit NewStone(newId);
            if (i + 1 == amount) {
                batches.push(newId);
                batchURI[newId] = batchBaseURI;
                emit NewBatch(batches.length, batchBaseURI, newId);
            }
        }
    }

    function getSingleBatchURI(uint256 batchNumber) public view returns (string memory) {
        require(batchNumber < batches.length && batchNumber > 0, "Batch number does not exist");
        return batchURI[batches[batchNumber]];
    }

    function setSingleBatchURI(uint256 batchNumber, string memory uri) public onlyOwner {
        require(batchNumber > 0);
        require(batchNumber < batches.length);
        batchURI[batches[batchNumber]] = uri;
    }
    
    function getAllBatchURI() public view returns (string[] memory) {
        // batchNumber : batchURI : firstToken-lastToken
        string [] memory allBatches = new string [] (batches.length - 1);
        for (uint256 i = 1; i < batches.length; i++) {
            allBatches[i - 1] = string(abi.encodePacked(i.toString(), ":", batchURI[batches[i]],":",(batches[i - 1]+1).toString(),"-",batches[i].toString()));
        }
        return allBatches;
    }

    function setAllBatchURI(string [] memory batchBaseURI) public onlyOwner {
        require(batchBaseURI.length == batches.length - 1);
        for (uint256 i = 1; i < batches.length; i++) {
            batchURI[batches[i]] = batchBaseURI[i - 1];
        }
    }
}
