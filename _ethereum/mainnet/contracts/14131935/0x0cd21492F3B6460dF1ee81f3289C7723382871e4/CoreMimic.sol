
// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;


import "./ILore.sol";

import "./Combo721Base.sol";

import "./MimicMeta.sol";
import "./CoreShield.sol";


abstract contract CoreMimic is Combo721Base {
    MimicMeta cMeta;
    CoreShield cShield;
    address aGuild;

    ////
    // Mimic Data

    mapping(uint256 => address) POKED_CONTRACTS;
    mapping(uint256 => uint256) POKED_IDS;
    mapping(uint256 => uint256) MATURITIES;
    mapping(uint256 => bool) SKIP_ID_REPLACEMENT;

    ////
    // Guild Data

    uint256 guildGenesis;
    uint256 guildPrice;
    uint256 guildRate18;

    ////
    // Events

    event Poke(uint256 indexed _mimicId, address _targetContract, uint256 _targetId);
    event Rite(uint256 indexed _mimicId);
    event SkipIdReplace(uint256 indexed _mimicId, bool _trueOrFalse);

    ////
    // Init

    function init(address _guild, address _shield, address _meta) external {
        require(aGuild == address(0x0), "already initialized");

        aGuild = _guild;
        cShield = CoreShield(_shield);
        cMeta = MimicMeta(_meta);
    }

    ////
    // Mimic Lifecycle

    function maturityHash(address _targetContract, uint256 _targetId) internal pure returns (uint) {
        return uint(keccak256(abi.encodePacked("MH", _targetContract, _targetId)));
    }

    function maturityHashForMimic(uint256 _mimicId) internal view returns (uint) {
        return maturityHash(POKED_CONTRACTS[_mimicId], POKED_IDS[_mimicId]);
    }

    function _pokeShared(uint256 _mimicId, address _targetContract, uint256 _targetId) internal {
        require(_isApprovedOrOwner(msg.sender, _mimicId), "*SLAP*, not your mimic!");
        require(_targetContract != address(0x0), "that's not poking, that's pointing");
        require(_targetContract != address(this), "this would cause poor mimic to explode");
        require(_targetContract != address(cShield), "this is essence-ally a bad idea");
        uint256 mimicMatHashMimicId = MATURITIES[maturityHashForMimic(_mimicId)];
        require(mimicMatHashMimicId != _mimicId, "mature mimics won't poke");
        uint256 targetMatHashMimicId = MATURITIES[maturityHash(_targetContract, _targetId)];
        require(targetMatHashMimicId == 0x0, "mimic honor code violation");

        POKED_CONTRACTS[_mimicId] = _targetContract;
        POKED_IDS[_mimicId] = _targetId;
        emit Poke(_mimicId, _targetContract, _targetId);
    }

    function _riteShared(uint256 _mimicId) internal view returns (address pokedContract, uint256 matHash) {
        require(_isApprovedOrOwner(msg.sender, _mimicId), "*SLAP*, not your mimic!");

        pokedContract = POKED_CONTRACTS[_mimicId];
        require(pokedContract != address(0x0), "need to poke first");
        matHash = maturityHashForMimic(_mimicId);
        uint256 matHashMimicId = MATURITIES[matHash];
        require(matHashMimicId != _mimicId, "mimic is already mature");
        require(matHashMimicId == 0x0, "mimic honor code violation");
    }

    function mimic_IsAdult(uint256 _mimicId) external view returns (bool) {
        if (_exists(_mimicId) && (MATURITIES[maturityHashForMimic(_mimicId)] == _mimicId)) {
            return true;
        }

        return false;
    }

    function mimic_Poke721(uint256 _mimicId, address _pokeNftContract, uint256 _pokeNftId) external {
        (bool success, bytes memory ownerResult) = _pokeNftContract.staticcall(abi.encodeWithSignature("ownerOf(uint256)", _pokeNftId));
        require(success, "not a valid 721");
        address owner721 = abi.decode(ownerResult, (address));
        uint256 auraCount = cShield.activeCount(owner721);
        require(auraCount == 0, "blocked by active shield");

        _pokeShared(_mimicId, _pokeNftContract, _pokeNftId);
   }

    function mimic_Poke1155(uint256 _mimicId, address _pokeNftContract, uint256 _pokeNftId, address _ownerOf1155) external {
        (bool success, bytes memory countResult) = _pokeNftContract.staticcall(abi.encodeWithSignature("balanceOf(address,uint256)", _ownerOf1155, _pokeNftId));
        require(success, "not a valid 1155");
        require(abi.decode(countResult, (uint256)) > 0, "not a valid owner of the NFT");
        require(cShield.activeCount(_ownerOf1155) == 0, "blocked by active shield");

        _pokeShared(_mimicId, _pokeNftContract, _pokeNftId);
    }

    function mimic_Relax(uint256 _mimicId) external {
        require(_isApprovedOrOwner(msg.sender, _mimicId), "*SLAP*, not your mimic!");

        require(MATURITIES[maturityHashForMimic(_mimicId)] != _mimicId, "adult mimics can never relax");
        delete POKED_CONTRACTS[_mimicId];
        delete POKED_IDS[_mimicId];
        emit Poke(_mimicId, address(0x0), 0x0);
    }

    function mimic_RiteOf721(uint256 _mimicId) external {
        (address pokedContract, uint256 matHash) = _riteShared(_mimicId);

        (bool success, bytes memory ownerResult) = pokedContract.staticcall(abi.encodeWithSignature("ownerOf(uint256)", POKED_IDS[_mimicId]));
        require(success, "rite of 721 failed");

        MATURITIES[matHash] = _mimicId;

        cShield.cMimic_Mint(abi.decode(ownerResult, (address)), _mimicId);
        emit Rite(_mimicId);
    }

    function mimic_RiteOf1155(uint256 _mimicId, address _ownerOf1155) external {
        require(_ownerOf1155 != address(0x0), "nowner!");

        (address pokedContract, uint256 matHash) = _riteShared(_mimicId);

        (bool success, bytes memory ownershipCountResult) = pokedContract.staticcall(abi.encodeWithSignature("balanceOf(address,uint256)", _ownerOf1155, POKED_IDS[_mimicId]));
        require(success, "rite of 1155 failed");
        require(abi.decode(ownershipCountResult, (uint256)) > 0, "not the owner you're looking for");

        MATURITIES[matHash] = _mimicId;

        cShield.cMimic_Mint(_ownerOf1155, _mimicId);
        emit Rite(_mimicId);
    }

    function mimic_SkipIdReplacement(uint256 _mimicId, bool _trueOrFalse) external {
        require(_isApprovedOrOwner(msg.sender, _mimicId), "*SLAP*, not your mimic!");

        SKIP_ID_REPLACEMENT[_mimicId] = _trueOrFalse;

        emit SkipIdReplace(_mimicId, _trueOrFalse);
    }

    ////
    // Metadata

    function tokenURI(uint256 _mimicId) public view override returns (string memory) {
        require(msg.sender.code.length == 0, "nah!");
        require(_exists(_mimicId), "no such mimic");

        address pokedContract = POKED_CONTRACTS[_mimicId];

        // juvenile mimic that has not poked
        if (pokedContract == address(0x0)) {
            return cMeta.mimicNative(_mimicId, "");  // normal eyes
        }

        uint256 pokedId = POKED_IDS[_mimicId];

        // juvenile mimic that has poked an NFT that is another mimic's maturity NFT
        uint256 matHash = maturityHash(pokedContract, pokedId);
        uint256 matHashMimicId = MATURITIES[matHash];
        if ( (matHashMimicId != _mimicId) && (matHashMimicId != 0x0) ) {
            return cMeta.mimicNative(_mimicId, "");  // normal eyes
        }

        (bool success, bytes memory uriBytes) = pokedContract.staticcall(abi.encodeWithSignature("tokenURI(uint256)", pokedId));
        // 721
        if (success) {
            if (SKIP_ID_REPLACEMENT[_mimicId]) {
                return abi.decode(uriBytes, (string));
            }

            return uriIdReplace(abi.decode(uriBytes, (string)), pokedId);
        }

        (success, uriBytes) = pokedContract.staticcall(abi.encodeWithSignature("uri(uint256)", pokedId));
        // 1155
        if (success) {
            if (SKIP_ID_REPLACEMENT[_mimicId]) {
                return abi.decode(uriBytes, (string));
            }

            return uriIdReplace(abi.decode(uriBytes, (string)), pokedId);
        }

        // if we get here then that is bad, poor mimic is sick :(

        if (matHashMimicId == _mimicId) {
            return cMeta.mimicNative(_mimicId, "X"); // adult sick eyes (whoops)
        }

        return cMeta.mimicNative(_mimicId, "x"); // juvenile sick eyes
    }

    ////
    // Guild Mint

    function cGuild_Mint(address _owner) external {
        require(msg.sender == aGuild);
        _mint(_owner, totalSupply() + 1);
    }

    ////
    // Lore

    function lore() external view returns (string memory) {
        return ILore(aGuild).lore();
    }

    ////
    // Util

    function uriIdReplace(string memory uri, uint tokenId) internal pure returns (string memory) {
        bytes memory s = bytes(uri);
        uint sLen = s.length;
        if (sLen < 4) {
            return uri; // can't fit "{id}"
        }

        bytes memory t = uint256ToPaddedBytesHex(tokenId);
        uint sLenM3 = sLen - 3;

        bytes memory o = bytes(uri);

        uint si = 0;
        uint oi = 0;

        while (si < sLenM3) {
            if (s[si] == "{" && s[si+1] == "i" && s[si+2] == "d" && s[si+3] == "}") {
                o = bytes.concat(o, new bytes(60));
                for (uint ti = 0; ti < 64; ti++) {
                    o[oi++] = t[ti];
                }
                si += 4;
                break;
            } else {
                oi++;
                si++;
            }
        }

        while (si < sLenM3) {
            if (s[si] == "{" && s[si+1] == "i" && s[si+2] == "d" && s[si+3] == "}") {
                o = bytes.concat(o, new bytes(60));
                for (uint ti = 0; ti < 64; ti++) {
                    o[oi++] = t[ti];
                }
                si += 4;
            } else {
                o[oi++] = s[si++];
            }
        }

        while (si < sLen) {
            o[oi++] = s[si++];
        }

        return string(o);
    }

    function uint256ToPaddedBytesHex(uint256 value) internal pure returns (bytes memory) {
        bytes memory o = new bytes(64);
        uint256 mask = 0xf; // hex 15
        uint i = 63;
        while (true) {
            uint8 end = uint8(value & mask);
            if (end < 10) {
                o[i] = bytes1(end + 48);
            } else {
                o[i] = bytes1(end + 87);
            }
            value >>= 4;
            if (i == 0) {
                break;
            }
            i--;
        }
        return o;
    }

    function d() external pure returns (string memory) {
        return "Rm9yIG15IGZhdGhlciwgd2hvIG5ldmVyIGNvbXBsYWlucyBhYm91dCBteSBob25vcmFibGUgbWlzY2hpZWYu";
    }
}

