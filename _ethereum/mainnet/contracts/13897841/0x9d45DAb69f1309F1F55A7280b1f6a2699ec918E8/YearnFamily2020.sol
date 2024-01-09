// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./Counters.sol";

interface BloomFilter {
    function falsePositive(uint256 _bitmap,  uint8 _hashCount, bytes32 _item) external pure returns(bool _probablyPresent);
}

contract YearnFamily2021 is ERC721, ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;
    address bloomFilterAddress = 0x9De80828ff54E961A41c3B31ca6e8eCEaDC8aEF4;
    uint256 bitmap = 134436144755219026776492379402457459703345255634037614050399006494398939524;
    uint8 constant printLimitPerAddress = 3;
    mapping(bytes32 => bool) public codeClaimed;
    mapping(address => uint8) public numberOfPrintsByAddress;
    mapping(address => bool) public addressClaimed;

    constructor() ERC721("Yearn Family #1", "yFamily 2021") {}

    function _safeMintAndIncrement(address to) internal {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }

    function claim(bytes32 code) public {
        bool alreadyClaimed = codeClaimed[code];
        bool invalidEntry = !BloomFilter(bloomFilterAddress).falsePositive(bitmap, 1, code);
        if (alreadyClaimed) {
            revert("Already claimed");            
        }
        if (invalidEntry) {
            revert("Invalid entry");
        }
        address printerAddress = msg.sender;
        _safeMintAndIncrement(printerAddress);
        addressClaimed[printerAddress] = true;
        codeClaimed[code] = true;
    }

    function print(address toAddress) public {
        address printerAddress = msg.sender;
        uint8 _numberOfPrintsByAddress = numberOfPrintsByAddress[printerAddress];
        bool addressHasNotClaimed = !addressClaimed[printerAddress];
        bool addressIsOutOfPrints = _numberOfPrintsByAddress >= printLimitPerAddress;
        if (addressHasNotClaimed) {
            revert("Only claimers can print");
        }
        if (addressIsOutOfPrints) {
            revert("Address has already printed all available prints");
        }
        numberOfPrintsByAddress[printerAddress] = _numberOfPrintsByAddress + 1;
        _safeMintAndIncrement(toAddress);
    }

    function printMultiple(address[] memory toAddresses) public {
        for (uint8 printCount = 0; printCount < toAddresses.length; printCount++
        ) {
            address toAddress = toAddresses[printCount];
            print(toAddress);
        }
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return "data:application/json;base64,eyJuYW1lIjoiWWVhcm4gRmFtaWx5IFBvcnRyYWl0IiwiZGVzY3JpcHRpb24iOiJ3aXRoIGxvdmUgPDMzIiwiaW1hZ2UiOiJodHRwczovL2dhdGV3YXkuaXBmcy5pby9pcGZzL1FtWFBLNFhpM1JaU2tucVVKY2Y1OWl5RHg1Y0F4cWljOWN6ODNWWFM3OGF3dFIifQ==";
    }
}
