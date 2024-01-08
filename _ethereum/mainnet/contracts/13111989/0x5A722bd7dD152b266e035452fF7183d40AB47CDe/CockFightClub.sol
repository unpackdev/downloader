// Contract based on https://docs.openzeppelin.com/contracts/3.x/erc721
// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

contract CockFightClub is ERC721, Ownable {
    using SafeMath for uint256;

    uint256 public constant MAX_TOKENS = 6666;

    string public _PROVENANCE = "";

    uint256 public constant MAX_TOKENS_PER_PURCHASE = 10;

    uint256 private price = 60000000000000000; // 0.06 Ether

    bool public isCocksErect = false;

    mapping(uint256 => uint256) private _totalCocks;

    constructor()  ERC721("Cock Fight Club", "COCK") {}

    function setProvenanceHash(string memory _provenanceHash) public onlyOwner {
        _PROVENANCE = _provenanceHash;
    }

    function contractURI() public view returns (string memory) {
        return "https://raw.githubusercontent.com/PhreeMason/hooting-hoots/138eab10f2df47fecddb8c3d739b12dbae5af466/contractURi.json";
    }

    function reserveTokens(address _to, uint256 _reserveAmount)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < _reserveAmount; i++) {
            rubOneOut(_to);
        }
    }

    function mint(uint256 _count) public payable {
        uint256 totalSupply = totalSupply();

        require(isCocksErect, "Sale is not active");
        require(
            _count > 0 && _count < MAX_TOKENS_PER_PURCHASE + 1,
            "You can not mint less than 1 cock, and at most 10 cocks"
        );
        require(totalSupply + _count < MAX_TOKENS + 1, "All cocks are erect");
        require(
            msg.value >= price.mul(_count),
            "Ether value sent is not correct"
        );

        for (uint256 i = 0; i < _count; i++) {
            rubOneOut(msg.sender);
        }
    }

    function rubOneOut(address _to) private {
        // i hope you have lotion for this gas
        for (uint256 i = 0; i < 9999; i++) {
            uint256 randID = random(
                1,
                6666,
                uint256(uint160(address(_to))) + i
            );
            if (_totalCocks[randID] == 0) {
                _totalCocks[randID] = 1;
                _safeMint(_to, randID);
                return;
            }
        }
        revert("looks like you only had sand paper");
    }

    function random(
        uint256 from,
        uint256 to,
        uint256 salty
    ) private view returns (uint256) {
        uint256 seed = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp +
                        block.difficulty +
                        ((
                            uint256(keccak256(abi.encodePacked(block.coinbase)))
                        ) / (block.timestamp)) +
                        block.gaslimit +
                        ((uint256(keccak256(abi.encodePacked(msg.sender)))) /
                            (block.timestamp)) +
                        block.number +
                        salty
                )
            )
        );
        return seed.mod(to - from) + from;
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        _setBaseURI(_baseURI);
    }

    function flipSaleStatus() public onlyOwner {
        isCocksErect = !isCocksErect;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function tokensByOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }

    function renounceOwnership() public override onlyOwner {}
}
