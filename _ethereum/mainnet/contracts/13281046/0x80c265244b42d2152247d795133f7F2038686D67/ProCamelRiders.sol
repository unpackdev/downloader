// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";

contract ProCamelRiders is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    uint256 private _maxSupply = 3333;

    string public _provenanceHash;
    string public _baseURL;
    uint256 public launchDate;


    constructor() ERC721("ProCamelRiders", "PCRD") {}

    function mint(uint256 count) external payable {
        require(_tokenIds.current() < _maxSupply, "Can not mint more than max supply");
        require(count > 0 && count <= 12, "You can mint between 1 and 12 at once");
        require(msg.value >= count * 0.069 ether, "Insufficient payment");
        for (uint256 i = 0; i < count; i++) {
            _tokenIds.increment();
            _mint(msg.sender, _tokenIds.current());
        }

        bool success = false;
        (success,) = owner().call{value : msg.value}("");
        require(success, "Failed to send to owner");
    }

    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        _provenanceHash = provenanceHash;
    }


    function setBaseURL(string memory baseURI) public onlyOwner {
        _baseURL = baseURI;
    }


    function setMaxSupply(uint256 value) public onlyOwner {
        _maxSupply = value;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseURL;
    }
 

    function maxSupply() public view returns (uint256) {
        return _maxSupply;
    }


    function totalSupply() public view returns (uint256) {
        return _tokenIds.current();
    }
}
