// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.4;

import "./ONFT.sol";
import "./IERC20.sol";

contract CyberFukuro is ONFT {
    uint public nextMintId;
    address public managerAddress;
    string private SECRET;

    modifier onlyMinted(uint _tokenId) {
        require(_exists(_tokenId), "This token id does not minted yet.");
        _;
    }

    modifier onlyManager() {
        require(msg.sender == managerAddress, "Only manager can call this function.");
        _;
    }

    /// @param _layerZeroEndpoint handles message transmission across chains
    constructor(address _layerZeroEndpoint, string memory secret) ONFT("Cyber Fukuro", "Fukuro", _layerZeroEndpoint) {
        nextMintId = 0;
        managerAddress = msg.sender;
        SECRET = secret;
    }

    /// @notice Mint your ONFT
    function mintFor(address to, uint64 numFukuro) external onlyManager {
        for (uint i = 0; i < numFukuro; i++) {
            uint newId = nextMintId;
            nextMintId++;
            _safeMint(to, newId);
        }
    }

    function setManagerAddress(address _managerAddress) public onlyOwner {
        managerAddress = _managerAddress;
    }

    function tokenURI(uint _tokenId) public view virtual override onlyMinted(_tokenId) returns (string memory) {
        return string(abi.encodePacked(baseTokenURI, uint2str(uint(sha256(abi.encodePacked(SECRET, _tokenId))))));
    }

    function uint2str(uint i) internal pure returns (string memory str) {
        if (i == 0) {
            return "0";
        }
        uint j = i;
        uint length;
        while (j != 0) {
            length++;
            j /= 10;
        }
        bytes memory bstr = new bytes(length);
        uint k = length;
        j = i;
        while (j != 0) {
            bstr[--k] = bytes1(uint8(48 + (j % 10)));
            j /= 10;
        }
        str = string(bstr);
        return str;
    }
}
