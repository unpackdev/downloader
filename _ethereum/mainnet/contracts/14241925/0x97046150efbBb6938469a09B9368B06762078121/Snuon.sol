// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;

import "./MerkleProofUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./StringsUpgradeable.sol";

import "./BaseContract.sol";

import "./GenerateSVG.sol";

import "./IWETH.sol";

contract Snuon is BaseContract {
    using StringsUpgradeable for uint;

    struct Seed {
        uint48 background;
        uint48 body;
        uint48 accessory;
        uint48 head;
        uint48 glasses;
    }

    mapping(uint => Seed) internal SeedRecord;

    function initialize(
        address _vault,
        address _weth,
        string memory _name,
        string memory _symbol,
        uint _salePrice,
        uint _maxPublicSaleNum
    ) initializer override public {
        super.initialize(
            _vault,
            _weth,
            _name,
            _symbol,
            _salePrice,
            _maxPublicSaleNum
        );
    } 

    function generateSeed(uint _id) internal {
        uint256 randomNum = uint256(
            keccak256(abi.encodePacked(blockhash(block.number - 1), _id))
        );

        uint256 bodyLen       = bodyCount();
        uint256 headLen       = headCount();
        uint256 glassesLen    = glassesCount();
        uint256 backgroundLen = backgroundCount();
        uint256 accessoryLen  = accessoryCount();

        SeedRecord[_id] = Seed({
            background: uint48(
                uint48(randomNum) % backgroundLen
            ),
            body: uint48(
                uint48(randomNum >> 48) % bodyLen
            ),
            accessory: uint48(
                uint48(randomNum >> 96) % accessoryLen
            ),
            head: uint48(
                uint48(randomNum >> 144) % headLen
            ),
            glasses: uint48(
                uint48(randomNum >> 192) % glassesLen
            )
        });
    }

    function whiteListMint(uint amount, bytes32[] calldata merkleProof) public whenNotPaused {
        require(merkleRoot != bytes32(0), "whiteList mint not ready.");
        address caller = _msgSender();
        bytes32 leaf = keccak256(abi.encodePacked(caller, amount));
        bool valid = MerkleProofUpgradeable.verify(merkleProof, merkleRoot, leaf);
        require(valid, "bad parameters.");
        require(!claimedMap[caller], "NFT already claimed.");

        uint index = getId();
        claimedMap[caller] = true;

        mintNFT(caller, index);
    }

    function mint() public whenNotPaused payable {
        require(msg.value >= salePrice, "Eth value incorrect.");
        require(publicSaleNum < maxPublicSaleNum, "Reach goal.");

        _safeTransferETHWithFallback(vault, msg.value);

        publicSaleNum++;
        uint index = getId();

        mintNFT(_msgSender(), index);
    }

    function mintNFT(address user, uint index) internal {
        super._mint(user, index);
        generateSeed(index);
    }

    function tokenURI(uint _tokenId) override public view returns(string memory) {
        Seed memory seed = SeedRecord[_tokenId];

        GenerateSVG.TokenURIParams memory params = GenerateSVG.TokenURIParams({
            parts: _getPartsForSeed(_tokenId),
            background: backgrounds[seed.background]
        });

        string memory image  = GenerateSVG.constructTokenURI(params, palettes);
        string memory _name  = string(abi.encodePacked('Snuon ', StringsUpgradeable.toString(_tokenId)));
        string memory desc   = string(abi.encodePacked('Snuon ', StringsUpgradeable.toString(_tokenId), ' is member of Snuon DAO'));

        return string(
            abi.encodePacked(
                '{"name":"',
                _name,
                '","description":"',
                desc,
                '","image":"',
                image,
                '"}'
            )
        );
    }

    function _getPartsForSeed(uint _id) internal view returns (bytes[] memory) {
        Seed memory seed = SeedRecord[_id];
        bytes[] memory _parts = new bytes[](4);

        _parts[0] = bodies[seed.body];
        _parts[1] = accessories[seed.accessory];
        _parts[2] = heads[seed.head];
        _parts[3] = glasses[seed.glasses];

        return _parts;
    }

    function _safeTransferETHWithFallback(address to, uint256 amount) internal {
        if (!_safeTransferETH(to, amount)) {
            IWETH(weth).deposit{ value: amount }();
            IERC20Upgradeable(weth).transfer(to, amount);
        }
    }

    function _safeTransferETH(address to, uint256 value) internal returns (bool) {
        (bool success, ) = to.call{ value: value, gas: 30_000 }(new bytes(0));
        return success;
    }

    function setMaxPublicSale(uint _num) public onlyOwner {
        maxPublicSaleNum = _num;
    }

    function setWETH(address _weth) public onlyOwner {
        weth = _weth;
    }

    function setVault(address _vault) public onlyOwner {
        vault = _vault;
    }
}
