//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./MerkleProof.sol";
import "./Counters.sol";
import "./Strings.sol";
import "./ERC721.sol";
import "./Ownable.sol";

import "./Base64.sol";

contract Faded22Drop is ERC721, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds;

    bytes32 public immutable merkleRoot;

    event NewEpicButterflyMinted(address sender, uint256 tokenId);

    constructor() ERC721("Faded22/", "FADED22") {
        merkleRoot = 0xa98508b6c6ddf2247cae7feb900351b3dc60f75955b0fb8019361d2fddbccdfc;
    }

    uint256 public claimedWithList;
    uint256 public claimedWithoutList;
    uint256 public price = 0.015 ether;
    mapping(address => bool) public whitelistClaimed;

    function makeWhiteButterfly(bytes32[] calldata _merkleProof)
        public
        payable
        virtual
    {
        uint256 newItemId = _tokenIds.current();

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));

        require(
            MerkleProof.verify(_merkleProof, merkleRoot, leaf),
            "Merkle Proof is invalid"
        );
        require(
            !whitelistClaimed[msg.sender],
            "Adress already has an Epic Butterfly"
        );
        require(claimedWithList < 75, "All slots for WhiteList are claimed");
        _mint(msg.sender, newItemId);
        claimedWithList++;

        _tokenIds.increment();

        whitelistClaimed[msg.sender] = true;
        emit NewEpicButterflyMinted(msg.sender, newItemId);
    }

    function makeButterfly() public payable virtual {
        uint256 newItemId = _tokenIds.current();

        require(msg.value >= price, "Ether value sent is not correct");
        require(claimedWithoutList < 181, "All public slots are claimed");
        _mint(msg.sender, newItemId);
        claimedWithoutList++;

        _tokenIds.increment();

        emit NewEpicButterflyMinted(msg.sender, newItemId);
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"description": "Monitoring a real change with digital butterflies, every month for a year. Butterfly origin, for community.", "external_url": "https://www.brunocerasi.it", "image": "ipfs://QmYkDA2vM3McEsNE4FmPqyEa9wDs93cZEsUEJoiAG3fbqf", "name": "Faded22/ #',
                        Strings.toString(tokenId),
                        '"}'
                    )
                )
            )
        );

        return string(abi.encodePacked("data:application/json;base64,", json));
    }
}
