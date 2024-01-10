// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;

import "./AccessControlEnumerableUpgradeable.sol";
import "./ERC721Upgradeable.sol";
import "./IERC721Upgradeable.sol";
import "./ERC721Upgradeable.sol";
import "./PausableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./CountersUpgradeable.sol";

import "./Config.sol";

contract BaseContract is OwnableUpgradeable, PausableUpgradeable, ERC721Upgradeable, Config {

    using CountersUpgradeable for CountersUpgradeable.Counter;

    function initialize(
        address _vault,
        address _weth,
        string memory _name,
        string memory _symbol,
        uint _salePrice,
        uint _maxPublicSaleNum
    ) virtual initializer public {
        weth  = _weth;
        vault = _vault;
        salePrice = _salePrice;
        maxPublicSaleNum = _maxPublicSaleNum;
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        __ERC721_init(_name, _symbol);
        __Pausable_init();
        __Ownable_init();
    } 

    modifier isNotReachGoal {
        require(publicSaleNum <= 9000, "is reach goal");
        _;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function addManyColorsToPalette(uint8 paletteIndex, string[] calldata newColors) public onlyOwner {
        require(palettes[paletteIndex].length + newColors.length <= 256, 'Palettes can only hold 256 colors');
        for (uint256 i = 0; i < newColors.length; i++) {
            palettes[paletteIndex].push(newColors[i]);
        }
    }

    function addManyBackgrounds(string[] calldata _backgrounds) public onlyOwner {
        for (uint256 i = 0; i < _backgrounds.length; i++) {
            backgrounds.push(_backgrounds[i]);
        }
    }

    function addManyBodies(bytes[] calldata _bodies) public onlyOwner {
        for (uint256 i = 0; i < _bodies.length; i++) {
            bodies.push(_bodies[i]);
        }
    }

    function addManyAccessories(bytes[] calldata _accessories) public onlyOwner {
        for (uint256 i = 0; i < _accessories.length; i++) {
            accessories.push(_accessories[i]);
        }
    }

    function addManyHeads(bytes[] calldata _heads) public onlyOwner {
        for (uint256 i = 0; i < _heads.length; i++) {
            heads.push(_heads[i]);
        }
    }

    function addManyGlasses(bytes[] calldata _glasses) public onlyOwner {
        for (uint256 i = 0; i < _glasses.length; i++) {
            glasses.push(_glasses[i]);
        }
    }

    function backgroundCount() public view returns (uint256) {
        return backgrounds.length;
    }

    function bodyCount() public view returns (uint256) {
        return bodies.length;
    }

    function accessoryCount() public view returns (uint256) {
        return accessories.length;
    }

    function headCount() public view returns (uint256) {
        return heads.length;
    }

    function glassesCount() public view returns (uint256) {
        return glasses.length;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Upgradeable, AccessControlEnumerableUpgradeable) returns(bool) {
        return super.supportsInterface(interfaceId);
    }

    event MerkleRootChanged(bytes32 root);
    function setMerkleRoot(bytes32 _root) public onlyOwner {
        require(merkleRoot == bytes32(0), "Merkle root already set");
        merkleRoot = _root;

        emit MerkleRootChanged(_root);
    } 

    function getId() internal returns(uint) {
        _index.increment();
        return _index.current();
    }
}
