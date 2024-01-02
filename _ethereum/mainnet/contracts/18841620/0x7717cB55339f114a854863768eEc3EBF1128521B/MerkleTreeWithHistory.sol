// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IHasher {
  function MiMCSponge(uint256 in_xL, uint256 in_xR) external pure returns (uint256 xL, uint256 xR);
}

contract MerkleTreeWithHistory {
    uint32 public levels;
    uint256 public constant FIELD_SIZE = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
    // the following variables are made public for easier testing and debugging and
    // are not supposed to be accessed in regular code

    // filledSubtrees and roots could be bytes32[size], but using mappings makes it cheaper because
    // it removes index range check on every interaction
    mapping(uint256 => bytes32) public filledSubtrees;
    mapping(uint256 => bytes32) public roots;
    uint32 public constant ROOT_HISTORY_SIZE = 30;
    uint32 public currentRootIndex = 0;
    uint32 public nextIndex = 0;
    IHasher public immutable hasher;

    constructor(uint32 _levels, IHasher _hasher) {
        require(_levels > 0, "_levels should be greater than zero");
        require(_levels < 32, "_levels should be less than 32");
        levels = _levels;
        hasher = _hasher;

        for (uint32 i = 0; i < _levels; i++) {
            filledSubtrees[i] = zeros(i);
        }

        roots[0] = zeros(_levels - 1);
    }

    /**
        @dev Hash 2 tree leaves, returns MiMC(_left, _right)
    */
    function hashLeftRight(
        IHasher _hasher,
        bytes32 _left,
        bytes32 _right
    ) public pure returns (bytes32) {
        require(uint256(_left) < FIELD_SIZE, "_left should be inside the field");
        require(uint256(_right) < FIELD_SIZE, "_right should be inside the field");
        uint256 R = uint256(_left);
        uint256 C = 0;
        (R, C) = _hasher.MiMCSponge(R, C);
        R = addmod(R, uint256(_right), FIELD_SIZE);
        (R, C) = _hasher.MiMCSponge(R, C);
        return bytes32(R);
    }

    function dualMux(uint256 a, uint256 b, bool c) private pure returns (uint256, uint256) {
        if (c) {
            return (b, a);
        }
        return (a, b);
    }

    function verify(bytes32 _root, bytes32 _leaf, uint256[] calldata pathElements, bool[] calldata pathIndices) public view returns (bool) {
        bytes32[] memory hashers = new bytes32[](levels);
        for (uint256 i = 0; i < levels; i++) {
            (uint256 a, uint256 b) = dualMux(i == 0 ? uint256(_leaf) : uint256(hashers[i - 1]), pathElements[i], pathIndices[i]);
            hashers[i] = hashLeftRight(hasher, bytes32(a), bytes32(b));
        }
        return _root == hashers[levels - 1];
    }

    function _insert(bytes32 _leaf) internal returns (uint32 index) {
        uint32 _nextIndex = nextIndex;
        require(_nextIndex != uint32(2)**levels, "Merkle tree is full. No more leaves can be added");
        uint32 currentIndex = _nextIndex;
        bytes32 currentLevelHash = _leaf;
        bytes32 left;
        bytes32 right;

        for (uint32 i = 0; i < levels; i++) {
            if (currentIndex % 2 == 0) {
                left = currentLevelHash;
                right = zeros(i);
                filledSubtrees[i] = currentLevelHash;
            } else {
                left = filledSubtrees[i];
                right = currentLevelHash;
            }
            currentLevelHash = hashLeftRight(hasher, left, right);
            currentIndex /= 2;
        }

        uint32 newRootIndex = (currentRootIndex + 1) % ROOT_HISTORY_SIZE;
        currentRootIndex = newRootIndex;
        roots[newRootIndex] = currentLevelHash;
        nextIndex = _nextIndex + 1;
        return _nextIndex;
    }

    /**
        @dev Whether the root is present in the root history
    */
    function isKnownRoot(bytes32 _root) public view returns (bool) {
        if (_root == 0) {
        return false;
        }
        uint32 _currentRootIndex = currentRootIndex;
        uint32 i = _currentRootIndex;
        do {
        if (_root == roots[i]) {
            return true;
        }
        if (i == 0) {
            i = ROOT_HISTORY_SIZE;
        }
        i--;
        } while (i != _currentRootIndex);
        return false;
    }

    /**
        @dev Returns the last root
    */
    function getLastRoot() public view returns (bytes32) {
        return roots[currentRootIndex];
    }

    /**
        @dev provides Zero (Empty) elements for a MerkleTree. Up to 32 levels
    */
    function zeros(uint256 i) public pure returns (bytes32) {   
        if (i == 0) return bytes32(uint256(21663839004416932945382355908790599225266501822907911457504978515578255421292));
        else if (i == 1) return bytes32(uint256(16923532097304556005972200564242292693309333953544141029519619077135960040221));
        else if (i == 2) return bytes32(uint256(7833458610320835472520144237082236871909694928684820466656733259024982655488));
        else if (i == 3) return bytes32(uint256(14506027710748750947258687001455876266559341618222612722926156490737302846427));
        else if (i == 4) return bytes32(uint256(4766583705360062980279572762279781527342845808161105063909171241304075622345));
        else if (i == 5) return bytes32(uint256(16640205414190175414380077665118269450294358858897019640557533278896634808665));
        else if (i == 6) return bytes32(uint256(13024477302430254842915163302704885770955784224100349847438808884122720088412));
        else if (i == 7) return bytes32(uint256(11345696205391376769769683860277269518617256738724086786512014734609753488820));
        else if (i == 8) return bytes32(uint256(17235543131546745471991808272245772046758360534180976603221801364506032471936));
        else if (i == 9) return bytes32(uint256(155962837046691114236524362966874066300454611955781275944230309195800494087));
        else if (i == 10) return bytes32(uint256(14030416097908897320437553787826300082392928432242046897689557706485311282736));
        else if (i == 11) return bytes32(uint256(12626316503845421241020584259526236205728737442715389902276517188414400172517));
        else if (i == 12) return bytes32(uint256(6729873933803351171051407921027021443029157982378522227479748669930764447503));
        else if (i == 13) return bytes32(uint256(12963910739953248305308691828220784129233893953613908022664851984069510335421));
        else if (i == 14) return bytes32(uint256(8697310796973811813791996651816817650608143394255750603240183429036696711432));
        else if (i == 15) return bytes32(uint256(9001816533475173848300051969191408053495003693097546138634479732228054209462));
        else if (i == 16) return bytes32(uint256(13882856022500117449912597249521445907860641470008251408376408693167665584212));
        else if (i == 17) return bytes32(uint256(6167697920744083294431071781953545901493956884412099107903554924846764168938));
        else if (i == 18) return bytes32(uint256(16572499860108808790864031418434474032816278079272694833180094335573354127261));
        else if (i == 19) return bytes32(uint256(11544818037702067293688063426012553693851444915243122674915303779243865603077));
        else if (i == 20) return bytes32(uint256(18926336163373752588529320804722226672465218465546337267825102089394393880276));
        else if (i == 21) return bytes32(uint256(11644142961923297861823153318467410719458235936926864848600378646368500787559));
        else if (i == 22) return bytes32(uint256(14452740608498941570269709581566908438169321105015301708099056566809891976275));
        else if (i == 23) return bytes32(uint256(7578744943370928628486790984031172450284789077258575411544517949960795417672));
        else if (i == 24) return bytes32(uint256(5265560722662711931897489036950489198497887581819190855722292641626977795281));
        else if (i == 25) return bytes32(uint256(731223578478205522266734242762040379509084610212963055574289967577626707020));
        else if (i == 26) return bytes32(uint256(20461032451716111710758703191059719329157552073475405257510123004109059116697));
        else if (i == 27) return bytes32(uint256(21109115181850306325376985763042479104020288670074922684065722930361593295700));
        else if (i == 28) return bytes32(uint256(81188535419966333443828411879788371791911419113311601242851320922268145565));
        else if (i == 29) return bytes32(uint256(7369375930008366466575793949976062119589129382075515225587339510228573090855));
        else if (i == 30) return bytes32(uint256(14128481056524536957498216347562587505734220138697483515041882766627531681467));
        else if (i == 31) return bytes32(uint256(20117374654854068065360091929240690644953205021847304657748312176352011708876));
        else revert("Index out of bounds");
    }
}
