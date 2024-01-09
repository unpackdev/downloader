// contracts/GameItems.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract RedEnvelope is ERC1155, Ownable {
    enum RedEnvelopeType { Ancient, Lengendary, Epic, Rare, Uncommon }

    uint256 constant public MAX_CLAIM_PER_WALLET = 5;
    uint256 constant public PRICE = 0.01 ether;
    uint256 constant public MAX_SUPPLY = 3060;
    uint256[] public maxSupply = [8, 88, 188, 888, 1888]; // total 3060

    mapping(RedEnvelopeType => uint256) public totalSupply;
    mapping(address => uint256) public totalNFTClaimed;

    string public baseURI = "https://gateway.pinata.cloud/ipfs/QmbDyXnmqvsPZ2hohuNb4mpdcPeqvLJ576ZxPSTwbL3Xux";
    string public name = "RedEnvelope"; // not part of the standard but Opensea needs it
    string public symbol = "RedEnvelope"; // no real value

    constructor() ERC1155(string(abi.encodePacked(baseURI, "{id}.json"))) {
    }

    // MANIPULATORS
    function setBaseURI(string memory _baseURI) external onlyOwner {
        _setURI(_baseURI); // not really needed as we will override function 'uri' anyway
        baseURI = _baseURI;
    }

    function preMint(address[] memory _addresses) external onlyOwner {
        for (uint256 i = 0; i < _addresses.length; ++i) {
            address to = _addresses[i];
            require(totalNFTClaimed[to] == 0, "Too many claims");
            for (uint256 j = 0; j < 2; ++j) {
                 RedEnvelopeType mintedType = mintNFT(to, j);
                totalNFTClaimed[to] += 1;
                totalSupply[mintedType] += 1;
            }
        }
    }

    function claim(uint256 _amount) external payable {
        require(totalNFTClaimed[msg.sender] + _amount <= MAX_CLAIM_PER_WALLET, "Too many claims");
        require(_amount > 0 && _amount <= MAX_CLAIM_PER_WALLET, "Wrong amount");
        if(totalNFTClaimed[msg.sender] == 0) {
            require((_amount-1)*PRICE == msg.value, "Insufficient ETH");
        }
        else {
            require(_amount*PRICE == msg.value, "Insufficient ETH");
        }

        for (uint256 i = 0; i < _amount; ++i) {
            // mint all requested amount one by one, randomly
            RedEnvelopeType mintedType = mintNFT(msg.sender, i);
            totalNFTClaimed[msg.sender] += 1;
            totalSupply[mintedType] += 1;
        }
    }

    function mintNFT(address _to, uint256 _idx) internal returns (RedEnvelopeType) {
        // mint one NFT randomly for '_to'
        // get one pseudo-random number; miners can abuse this?
        uint256 id = uint256(keccak256(
                abi.encodePacked(block.difficulty, block.timestamp, _idx, _to))) % MAX_SUPPLY;

        RedEnvelopeType[5] memory types = [
            RedEnvelopeType.Ancient,
            RedEnvelopeType.Lengendary,
            RedEnvelopeType.Epic,
            RedEnvelopeType.Rare,
            RedEnvelopeType.Uncommon
        ];
        uint256 mintedCount = 0;
        for (uint i = 0; i < types.length; ++i) {
            mintedCount += maxSupply[(uint256)(types[i])];
            // iterate through all types and mint from higher to lower rarity till supply last
            if (id < mintedCount && totalSupply[types[i]] < maxSupply[(uint256)(types[i])]) {
                _mint(_to, (uint256)(types[i]), 1, "");
                return types[i];
            }
        }
        revert("Sold out");
    }

    function withdrawTo(address _to) external onlyOwner {
        uint256 balance = address(this).balance;
        payable(_to).transfer(balance);
    }

    function uri(uint256 _id) override public view returns (string memory) {
        require(_id < 5 && _id >= 0, "Invalid ID");
        return string(abi.encodePacked(baseURI, "/", Strings.toString(_id), ".json"));
  }
}