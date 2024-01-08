// +------+.      +------+       +------+       +------+      .+------+
// |`.    | `.    |\     |\      |      |      /|     /|    .' |    .'|
// |  `+--+---+   | +----+-+     +------+     +-+----+ |   +---+--+'  |
// |   |  |   |   | |    | |     |      |     | |    | |   |   |  |   |
// +---+--+.  |   +-+----+ |     +------+     | +----+-+   |  .+--+---+
//  `. |    `.|    \|     \|     |      |     |/     |/    |.'    | .'
//    `+------+     +------+     +------+     +------+     +------+'
//
//    .+------+     +------+     +------+     +------+     +------+.
//  .' |    .'|    /|     /|     |      |     |\     |\    |`.    | `.
// +---+--+'  |   +-+----+ |     +------+     | +----+-+   |  `+--+---+
// |   |  |   |   | |    | |     |      |     | |    | |   |   |  |   |
// |  ,+--+---+   | +----+-+     +------+     +-+----+ |   +---+--+   |
// |.'    | .'    |/     |/      |      |      \|     \|    `. |   `. |
// +------+'      +------+       +------+       +------+      `+------+
//
//    .+------+     +------+     +------+     +------+     +------+.
//  .' |      |    /|      |     |      |     |      |\    |      | `.
// +   |      |   + |      |     +      +     |      | +   |      |   +
// |   |      |   | |      |     |      |     |      | |   |      |   |
// |  .+------+   | +------+     +------+     +------+ |   +------+.  |
// |.'      .'    |/      /      |      |      \      \|    `.      `.|
// +------+'      +------+       +------+       +------+      `+------+
//
// Spacetime Rodeo
//
// psychedelic internet aquarium
// https://spacetime.rodeo
// https://twitter.com/spacetimerodeo
//
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./ERC721PresetMinterPauserAutoId.sol";

contract SpacetimeRodeo is ERC721PresetMinterPauserAutoId, Ownable {
    using SafeMath for uint256;
    uint256 public cap = 256;
    uint256 public price = 0.1 ether;
    uint256 public constant MAX_ENTITIES = 10000;

    constructor()
        ERC721PresetMinterPauserAutoId(
            "Spacetime Rodeo",
            "ENTITIES",
            "https://spacetime.rodeo/api/"
        )
    {}

    function synthesize(uint256 numEntities) public payable {
        require(
            totalSupply() < MAX_ENTITIES,
            "all energy has been converted to matter"
        );
        require(
            numEntities > 0 && numEntities <= 8,
            "only 8 entities may be synthesized per tx"
        );
        require(totalSupply().add(numEntities) <= cap, "try again later");
        require(
            totalSupply().add(numEntities) <= MAX_ENTITIES,
            "too many entities"
        );
        require(
            msg.value >= price.mul(numEntities),
            "not enough energy for nucleosynthesis"
        );

        for (uint256 i = 0; i < numEntities; i++) {
            uint256 mintIndex = totalSupply();
            _safeMint(msg.sender, mintIndex);
        }
    }

    function tokensOfOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        }

        uint256[] memory result = new uint256[](tokenCount);
        uint256 index;
        for (index = 0; index < tokenCount; index++) {
            result[index] = tokenOfOwnerByIndex(_owner, index);
        }
        return result;
    }

    function setPrice(uint256 _newPrice) public onlyOwner {
        price = _newPrice;
    }

    function setCap(uint256 _newCap) public onlyOwner {
        require(_newCap <= MAX_ENTITIES, "cap cannot exceed max");
        require(_newCap >= totalSupply(), "cap cannot be less than supply");
        cap = _newCap;
    }

    function reserve(uint256 _numEntities) public onlyOwner {
        uint256 currentSupply = totalSupply();
        require(currentSupply.add(_numEntities) <= 64, "too many reserved");
        uint256 i;
        for (i = 0; i < _numEntities; i++) {
            _safeMint(owner(), currentSupply + i);
        }
    }

    function withdraw(uint256 _amount) public onlyOwner {
        require(payable(owner()).send(_amount));
    }

    function withdrawAll() public payable onlyOwner {
        require(payable(owner()).send(address(this).balance));
    }

    function forwardERC20s(IERC20 _token, uint256 _amount) public onlyOwner {
        _token.transfer(owner(), _amount);
    }

    // TODO solidity does not support fixed point math yet
    // pragma abicoder v2;
    // using SafeMath for uint8;
    // struct SpacetimeEntity {
    //     uint256 id;
    //     bytes32 hash;
    //     fixed gamma;
    //     fixed delta;
    //     fixed theta;
    //     fixed lambda;
    //     fixed phi;
    // }
    // function entityFromIndex(uint256 index)
    //     external
    //     view
    //     returns (SpacetimeEntity memory)
    // {
    //     require(index >= 0 && index < MAX_ENTITIES, "invalid entity index");
    //     SpacetimeEntity memory entity;
    //     bytes32 indexHash = keccak256(abi.encodePacked(index));
    //     entity.id = index;
    //     entity.hash = indexHash;
    //     entity.gamma = floor(fixed(uint8(indexHash[0])) * fixed(8 / 256));
    //     entity.delta = ceil(fixed(uint8(indexHash[1])) * fixed(8 / 256));
    //     entity.theta = ceil(fixed(uint8(indexHash[2])) * fixed(32 / 256));
    //     entity.lambda = floor(fixed(uint8(indexHash[3])) * fixed(8 / 256));
    //     entity.phi = fixed(unit8(indexHash[4]));
    //     return entity;
    // }
}
