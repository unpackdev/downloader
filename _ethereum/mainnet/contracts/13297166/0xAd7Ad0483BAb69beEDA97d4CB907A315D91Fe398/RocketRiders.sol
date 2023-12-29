// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract RocketRiders is Ownable, ERC721Enumerable {
    using Strings for uint256;

    string public baseURI;
    uint256 public cost = 0.07 ether;
    uint256 public constant maxSupply = 9950;
    uint256 public maxMintAmount = 10;
    bool public paused = true;

    uint256 internal once = 5;
    uint256 public constant maxTraits = 6;
    uint16[][maxTraits] internal tp;
    uint16[maxTraits][maxSupply] internal rocketRiderGenome;

    address internal a1;
    address internal a2;
    address internal a3;
    address internal a4;
    address internal a5;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI,
        address _a1,
        address _a2,
        address _a3,
        address _a4,
        address _a5
    ) ERC721(_name, _symbol) {
        setBaseURI(_initBaseURI);
        a1 = _a1;
        a2 = _a2;
        a3 = _a3;
        a4 = _a4;
        a5 = _a5;
        tp[0] = [
            1,
            1,
            1,
            1,
            1,
            1,
            1,
            1,
            2,
            2,
            2,
            2,
            2,
            2,
            2,
            2,
            2,
            2,
            3,
            3,
            3,
            3,
            3,
            3,
            3,
            3,
            3,
            4,
            4,
            4,
            4,
            4,
            4,
            4,
            4,
            4,
            4,
            5,
            5,
            5,
            5,
            5,
            5,
            5,
            5,
            5,
            5,
            5,
            5,
            5,
            5,
            5,
            6,
            6,
            6,
            6,
            6,
            6,
            7,
            7,
            7,
            7,
            7,
            7,
            7,
            7,
            7,
            7,
            7,
            7,
            7,
            7,
            7,
            7,
            7,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            9,
            9,
            9,
            9,
            9,
            9,
            9,
            9,
            9,
            10,
            10,
            10,
            10,
            10,
            11
        ];
        tp[1] = [
            1,
            1,
            1,
            1,
            1,
            1,
            1,
            1,
            1,
            1,
            1,
            1,
            2,
            2,
            2,
            2,
            2,
            2,
            2,
            2,
            2,
            2,
            2,
            2,
            2,
            2,
            2,
            3,
            3,
            3,
            3,
            3,
            4,
            4,
            4,
            4,
            4,
            4,
            4,
            4,
            4,
            4,
            4,
            4,
            4,
            4,
            4,
            5,
            5,
            5,
            5,
            5,
            5,
            5,
            5,
            5,
            5,
            5,
            5,
            5,
            5,
            5,
            5,
            5,
            5,
            5,
            5,
            6,
            7,
            7,
            7,
            7,
            7,
            7,
            7,
            7,
            7,
            7,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            9,
            9
        ];
        tp[2] = [
            1,
            2,
            2,
            2,
            2,
            2,
            2,
            2,
            2,
            2,
            2,
            3,
            3,
            3,
            3,
            3,
            3,
            3,
            3,
            3,
            3,
            4,
            4,
            4,
            4,
            4,
            4,
            5,
            5,
            5,
            5,
            5,
            5,
            5,
            6,
            6,
            6,
            6,
            6,
            7,
            7,
            7,
            7,
            7,
            7,
            7,
            8,
            8,
            8,
            8,
            9,
            9,
            10,
            11,
            12,
            12,
            12,
            12,
            12,
            12,
            13,
            13,
            13,
            13,
            13,
            14,
            15,
            16,
            16,
            16,
            16,
            16,
            16,
            16,
            16,
            16,
            16,
            16,
            17,
            18,
            19,
            20,
            20,
            21,
            21,
            22,
            22,
            22,
            22,
            22,
            22,
            22,
            22,
            22,
            22,
            22,
            22,
            23,
            23,
            24
        ];
        tp[3] = [
            1,
            2,
            2,
            3,
            4,
            5,
            5,
            5,
            5,
            5,
            5,
            5,
            5,
            6,
            6,
            6,
            6,
            6,
            6,
            6,
            7,
            7,
            7,
            8,
            8,
            9,
            9,
            9,
            9,
            9,
            10,
            10,
            10,
            10,
            10,
            10,
            11,
            12,
            12,
            12,
            12,
            12,
            12,
            12,
            13,
            13,
            13,
            14,
            14,
            14,
            14,
            14,
            14,
            14,
            14,
            15,
            15,
            15,
            15,
            15,
            16,
            16,
            16,
            16,
            16,
            17,
            17,
            17,
            17,
            18,
            19,
            19,
            19,
            19,
            19,
            19,
            20,
            20,
            20,
            20,
            20,
            21,
            21,
            21,
            22,
            23,
            23,
            23,
            23,
            23,
            23,
            23,
            24,
            24,
            25,
            26,
            27,
            28,
            28,
            29
        ];
        tp[4] = [
            1,
            1,
            1,
            2,
            2,
            2,
            2,
            3,
            4,
            5,
            5,
            5,
            5,
            5,
            5,
            5,
            5,
            5,
            6,
            6,
            6,
            6,
            6,
            6,
            6,
            7,
            7,
            7,
            7,
            7,
            7,
            7,
            7,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            8,
            9,
            9,
            9,
            9,
            9,
            9,
            9,
            10,
            10,
            10,
            11,
            12,
            13,
            13,
            13,
            13,
            13,
            13,
            13,
            13,
            13,
            14,
            14,
            14,
            14,
            14,
            14,
            14,
            14,
            15,
            15,
            15,
            15,
            15,
            15,
            15,
            16,
            17,
            17,
            17,
            17,
            17,
            17,
            17,
            17,
            17,
            18,
            18,
            18,
            18,
            18,
            18,
            18,
            18,
            19,
            20,
            21,
            22,
            23
        ];
        tp[5] = [
            1,
            1,
            1,
            1,
            1,
            2,
            2,
            2,
            2,
            2,
            3,
            3,
            3,
            4,
            4,
            4,
            5,
            5,
            6,
            6,
            7,
            7,
            7,
            7,
            7,
            7,
            8,
            8,
            9,
            9,
            9,
            9,
            9,
            9,
            9,
            10,
            10,
            10,
            10,
            10,
            11,
            11,
            11,
            11,
            12,
            12,
            12,
            13,
            13,
            14,
            14,
            15,
            15,
            15,
            15,
            15,
            16,
            16,
            16,
            16,
            16,
            17,
            17,
            17,
            17,
            17,
            18,
            19,
            19,
            20,
            21,
            21,
            21,
            21,
            21,
            22,
            22,
            22,
            22,
            22,
            23,
            23,
            23,
            23,
            23,
            23,
            23,
            23,
            23,
            23,
            23,
            23,
            23,
            23,
            23,
            23,
            23,
            23,
            23,
            23
        ];
    }

    function mint(address _to, uint256 _mintAmount) public payable {
        uint256 supply = totalSupply();

        if (msg.sender != owner()) {
            require(supply + _mintAmount <= maxSupply);
            require(!paused);
            require(_mintAmount > 0 && _mintAmount <= maxMintAmount);
            require(msg.value >= cost * _mintAmount);
        }

        uint256 randomNumber = uint256(
            keccak256(
                abi.encodePacked(once, block.difficulty, block.timestamp, _to)
            )
        );

        for (uint256 i = 1; i <= _mintAmount; i++) {
            configureRider(randomNumber, supply + i);
            _safeMint(_to, supply + i);
        }
    }

    function configureRider(uint256 randomNumber, uint256 id) internal {
        for (uint8 i = 0; i < maxTraits; i++) {
            once++;
            rocketRiderGenome[id][i] = createDNA(i, randomNumber);
        }
    }

    function createDNA(uint8 traitType, uint256 randomNumber)
        internal
        view
        returns (uint16)
    {
        uint16 i = uint16(
            uint256(keccak256(abi.encodePacked(once, randomNumber++))) %
                tp[traitType].length
        );
        uint16 result = tp[traitType][i];

        return result;
    }

    function getRiderDNA(uint256 tokenId)
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: DNA query for nonexistent token"
        );

        return (
            rocketRiderGenome[tokenId][0],
            rocketRiderGenome[tokenId][1],
            rocketRiderGenome[tokenId][2],
            rocketRiderGenome[tokenId][3],
            rocketRiderGenome[tokenId][4],
            rocketRiderGenome[tokenId][5]
        );
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        return
            bytes(_baseURI()).length > 0
                ? string(abi.encodePacked(_baseURI(), tokenId.toString()))
                : "";
    }

    function setMaxMintAmount(uint256 _maxMintAmount) public onlyOwner {
        maxMintAmount = _maxMintAmount;
    }

    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    function withdraw() public payable onlyOwner {
        uint256 amount = address(this).balance;

        require(payable(a1).send((amount * 350) / 1000));
        require(payable(a2).send((amount * 275) / 1000));
        require(payable(a3).send((amount * 150) / 1000));
        require(payable(a4).send((amount * 150) / 1000));
        require(payable(a5).send((amount * 75) / 1000));
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}
