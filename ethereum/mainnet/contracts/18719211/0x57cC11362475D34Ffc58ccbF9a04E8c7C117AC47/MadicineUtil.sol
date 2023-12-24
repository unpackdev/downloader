// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";
import "./SignatureChecker.sol";
import "./ECDSA.sol";

abstract contract ERC721 {
    function ownerOf(uint256 tokenId) public view virtual returns (address);
    function balanceOf(address owner) public view virtual returns (uint256);
}

abstract contract ERC20 {
    function transferFrom(address from, address to, uint256 amount) public virtual returns (bool);
    function balanceOf(address account) public view virtual returns (uint256);
}

abstract contract Madicine {
    struct MadicineInfo {
        uint16 maxSupply;
        uint16 walletLimit;
        bool prescribeAllowed;
        address prescribeCosigner;
        uint16 mintCount;
        uint16 currentStageId;
        uint16 pointerId;
        bool isReversed;
        uint80 ethCost;
        uint80 ip3Cost;
        uint56 prescribeEndTime;
    }
    struct StageInfo {
        uint56 startTime;
        uint56 endTime;
        bool mintAllowed;
        uint8 mintMethod;
        uint80 ethPrice;
		uint16 maxSupply;
        uint16 walletLimit;
        uint16 mintCount;
        bytes32 merkleRoot;
        address cosigner;
        uint80 ip3Price;
        uint16 nPerMate;
    }

    function getMadicineInfo(uint256 madicineId) external view virtual returns (MadicineInfo memory);
    function getStageInfo(uint256 madicineId, uint256 stageId) external view virtual returns (StageInfo memory);
    function totalSupply(uint256 madicineId) external view virtual returns (uint256);
    function numberMintedBy(uint256 madicineId, address addr) external view virtual returns (uint256);
    function stageMintedBy(uint256 madicineId, uint256 stageId, address addr) external view virtual returns (uint256);
    function isPrescribed(uint256 madicineId, uint256 oozId) public view virtual returns (bool);
    function canPrescribeNow(uint256 madicineId, uint256 oozId) public view virtual returns (bool);
    function mint(address to, uint256 madicineId, uint256 stageId, uint256 amount) public virtual;
    function burn(address to, uint256 madicineId, uint256 amount) public virtual;
    function prescribe(address to, uint256 madicineId, uint256 oozId) public virtual;
}

contract MadicineUtil is Ownable, ReentrancyGuard {
    using ECDSA for bytes32;
    
    // Mint methods
    uint8 constant OWNER = 0;
    uint8 constant PUBLIC = 1;
    uint8 constant MATES = 2;
    uint8 constant CHECKMATE = 3;

    mapping(uint256 => uint16[][]) private _requiredMadicine;
    mapping(uint256 => mapping(uint256 => uint16[])) private _mergeMadicineIds;
    mapping(uint256 => mapping(uint256 => uint16[])) private _mergeMadicineCounts;
    mapping(uint256 => mapping(uint256 => bool[10000])) private _checkMate;

    Madicine public Mad_icine;
    ERC721 public OOZ;
    ERC20 public IP3;
    address public IP3recipientAddr;
    uint256 public timestampExpirySeconds;

    constructor() {
        Mad_icine = Madicine(0x81B636Cbc85e674b1A4Ca08e80B6eedFFa009C83);
        OOZ = ERC721(0x0A69FDBaF055f92b8CC16a4ddb2DdE8aBe876927);
        IP3 = ERC20(0x01C3f4a1EbccbC37cD3D4763B540e880E60302c9);
        IP3recipientAddr = owner();
        timestampExpirySeconds = 120;
    }

    function setIP3recipientAddr(address addr) external onlyOwner {
        IP3recipientAddr = addr;
    }

    function setTimestampExpirySeconds(uint256 expirySeconds) external onlyOwner {
        timestampExpirySeconds = expirySeconds;
    }

    function addRequiredMadicine(uint256 madicineId, uint16[][] memory requiredMadicine) external onlyOwner {
        require(Mad_icine.getMadicineInfo(madicineId).mintCount == Mad_icine.totalSupply(madicineId), "Prescribe already started");

        _requiredMadicine[madicineId] = requiredMadicine;
    }

    function addMergeMadicine(uint256 madicineId, uint256 stageId, uint16[] calldata mergeMadicineIds, uint16[] calldata mergeMadicineCounts) external onlyOwner {
        require(Mad_icine.getStageInfo(madicineId, stageId).mintCount == 0, "Stage has already started");
        require(mergeMadicineIds.length == mergeMadicineCounts.length, "Array length not matching");

        _mergeMadicineIds[madicineId][stageId] = mergeMadicineIds;
        _mergeMadicineCounts[madicineId][stageId] = mergeMadicineCounts;
    }

    function _prescribe(uint256 madicineId, uint256 oozId, bytes calldata signature, uint256 timestamp) internal returns (uint256) {
        require(Mad_icine.canPrescribeNow(madicineId, oozId), "Cannot prescribe madicine to OOZ");
        require(OOZ.ownerOf(oozId) == msg.sender, "Does not own corresponding OOZ");
        
        if (_requiredMadicine[madicineId].length > 0) {
            bool found;
            for (uint256 i = 0; i < _requiredMadicine[madicineId].length; i++) {
                for (uint256 j = 0; j < _requiredMadicine[madicineId][i].length; j++) {
                    if (Mad_icine.isPrescribed(_requiredMadicine[madicineId][i][j], oozId)) {
                        found = true;
                    }
                }
                require(found, "Required madicine not prescribed");
                found = false;
            }
            delete found;
        }

        if (Mad_icine.getMadicineInfo(madicineId).prescribeCosigner != address(0)) {
            require(SignatureChecker.isValidSignatureNow(Mad_icine.getMadicineInfo(madicineId).prescribeCosigner, keccak256(abi.encodePacked(madicineId, oozId, msg.sender, timestamp)).toEthSignedMessageHash(), signature), "Invalid signature");
            require(timestamp + timestampExpirySeconds >= block.timestamp, "Timestamp expired");
        }

        if (Mad_icine.getMadicineInfo(madicineId).ip3Cost > 0) {
            require(IP3.balanceOf(msg.sender) >= Mad_icine.getMadicineInfo(madicineId).ip3Cost, "Not enough IP3");

            IP3.transferFrom(msg.sender, IP3recipientAddr, Mad_icine.getMadicineInfo(madicineId).ip3Cost);
        }

        Mad_icine.prescribe(msg.sender, madicineId, oozId);

        return Mad_icine.getMadicineInfo(madicineId).ethCost;
    }

    function prescribe(uint256 madicineId, uint256 oozId, bytes calldata signature, uint256 timestamp) external payable nonReentrant {
        require(msg.value >= Mad_icine.getMadicineInfo(madicineId).ethCost, "Not enough ETH");

        _prescribe(madicineId, oozId, signature, timestamp);
    }

    function prescribeBatch(uint256[] calldata madicineIds, uint256[] calldata oozIds, bytes[] calldata signatures, uint256[] calldata timestamps) external payable nonReentrant {
        require(madicineIds.length == oozIds.length && oozIds.length == signatures.length && signatures.length == timestamps.length, "Array length not matching");

        uint256 ethRequired = 0;
        for (uint256 i = 0; i < madicineIds.length; i++) {
            ethRequired += _prescribe(madicineIds[i], oozIds[i], signatures[i], timestamps[i]);
        }

        require(msg.value >= ethRequired, "Not enough ETH");

        delete ethRequired;
    }

    function _mint(uint256 madicineId, uint256 stageId, uint256 amount, uint256 proofAmount, bytes32[] calldata proof, bytes calldata signature, uint256 timestamp) internal returns (uint256) {
        require(Mad_icine.getStageInfo(madicineId, stageId).mintAllowed && Mad_icine.getStageInfo(madicineId, stageId).startTime <= block.timestamp, "Mint is not allowed");
        require(Mad_icine.getStageInfo(madicineId, stageId).endTime == 0 || block.timestamp <= Mad_icine.getStageInfo(madicineId, stageId).endTime, "Stage has ended");
        require(amount + Mad_icine.getMadicineInfo(madicineId).mintCount <= Mad_icine.getMadicineInfo(madicineId).maxSupply, "Exceeds maximum madicine supply");
        require(amount + Mad_icine.getStageInfo(madicineId, stageId).mintCount <= Mad_icine.getStageInfo(madicineId, stageId).maxSupply, "Exceeds maximum stage supply");
        require(Mad_icine.getMadicineInfo(madicineId).walletLimit == 0 || amount + Mad_icine.numberMintedBy(madicineId, msg.sender) <= Mad_icine.getMadicineInfo(madicineId).walletLimit, "Exceeds madicine wallet limit");
        require(Mad_icine.getStageInfo(madicineId, stageId).walletLimit == 0 || amount + Mad_icine.stageMintedBy(madicineId, stageId, msg.sender) <= Mad_icine.getStageInfo(madicineId, stageId).walletLimit, "Exceeds stage wallet limit");
        require(Mad_icine.getStageInfo(madicineId, stageId).mintMethod == PUBLIC || Mad_icine.getStageInfo(madicineId, stageId).mintMethod == MATES, "Stage mint method not matching");

        if (Mad_icine.getStageInfo(madicineId, stageId).merkleRoot != 0) {
            require(MerkleProof.processProof(proof, keccak256(abi.encodePacked(msg.sender, proofAmount))) == Mad_icine.getStageInfo(madicineId, stageId).merkleRoot, "Invalid proof");
            require(amount + Mad_icine.stageMintedBy(madicineId, stageId, msg.sender) <= proofAmount, "Exceeds whitelist limit");
        }

        if (Mad_icine.getStageInfo(madicineId, stageId).cosigner != address(0)) {
            require(isValidCosign(madicineId, stageId, msg.sender, amount, timestamp, signature), "Invalid signature");
            require(timestamp + timestampExpirySeconds >= block.timestamp, "Timestamp expired");
        }

        if (Mad_icine.getStageInfo(madicineId, stageId).mintMethod == MATES) {
            require(OOZ.balanceOf(msg.sender) > 0, "Does not own OOZ");
        }

        if (_mergeMadicineIds[madicineId][stageId].length > 0) {
            for (uint256 i = 0; i < _mergeMadicineIds[madicineId][stageId].length; i++) {
                uint256 id = _mergeMadicineIds[madicineId][stageId][i];
                uint256 total = _mergeMadicineCounts[madicineId][stageId][i] * amount;
                Mad_icine.burn(msg.sender, id, total);
                delete id;
                delete total;
            }
        }

        if (Mad_icine.getStageInfo(madicineId, stageId).ip3Price > 0) {
            require(IP3.balanceOf(msg.sender) >= Mad_icine.getStageInfo(madicineId, stageId).ip3Price * amount, "Not enough IP3");

            uint256 ip3Total = Mad_icine.getStageInfo(madicineId, stageId).ip3Price * amount;
            IP3.transferFrom(msg.sender, IP3recipientAddr, ip3Total);
            delete ip3Total;
        }
        
        Mad_icine.mint(msg.sender, madicineId, stageId, amount);

        return Mad_icine.getStageInfo(madicineId, stageId).ethPrice * amount;
    }

    function mint(uint256 madicineId, uint256 stageId, uint256 amount, uint256 proofAmount, bytes32[] calldata proof, bytes calldata signature, uint256 timestamp) external payable nonReentrant {
        require(msg.value >= Mad_icine.getStageInfo(madicineId, stageId).ethPrice * amount, "Not enough ETH");

        _mint(madicineId, stageId, amount, proofAmount, proof, signature, timestamp);
    }

    function mintBatch(uint256[] calldata madicineIds, uint256[] calldata stageIds, uint256[][2] calldata amounts, bytes32[][] calldata proofs, bytes[] calldata signatures, uint256[] calldata timestamps) external payable nonReentrant {
        require(madicineIds.length == stageIds.length && stageIds.length == amounts[0].length && amounts[0].length == amounts[1].length && amounts[1].length == proofs.length && proofs.length == signatures.length && signatures.length == timestamps.length, "Array length not matching");

        uint256 ethRequired = 0;
        for (uint256 i = 0; i < madicineIds.length; i++) {
            ethRequired += _mint(madicineIds[i], stageIds[i], amounts[0][i], amounts[1][i], proofs[i], signatures[i], timestamps[i]);   
        }

        require(msg.value >= ethRequired, "Not enough ETH");

        delete ethRequired;
    }

    function mintCheckMate(uint256 madicineId, uint256 stageId, uint256[] calldata oozIds, bytes32[][] calldata proofs, bytes[] calldata signatures, uint256[] calldata timestamps) external payable nonReentrant {
        require(Mad_icine.getStageInfo(madicineId, stageId).mintAllowed && Mad_icine.getStageInfo(madicineId, stageId).startTime <= block.timestamp, "Mint is not allowed");
        require(Mad_icine.getStageInfo(madicineId, stageId).endTime == 0 || block.timestamp <= Mad_icine.getStageInfo(madicineId, stageId).endTime, "Stage has ended");
        require(Mad_icine.getStageInfo(madicineId, stageId).mintMethod == CHECKMATE, "Stage mint method not matching");
        require(Mad_icine.getStageInfo(madicineId, stageId).nPerMate > 0, "N per mate not initialized");
        require(oozIds.length == proofs.length && proofs.length == signatures.length && signatures.length == timestamps.length, "Array length not matching");
        require(msg.value >= Mad_icine.getStageInfo(madicineId, stageId).ethPrice * oozIds.length, "Not enough ETH");

        uint256 mintAmount = oozIds.length * Mad_icine.getStageInfo(madicineId, stageId).nPerMate;

        require(mintAmount + Mad_icine.getMadicineInfo(madicineId).mintCount <= Mad_icine.getMadicineInfo(madicineId).maxSupply, "Exceeds maximum madicine supply");
        require(mintAmount + Mad_icine.getStageInfo(madicineId, stageId).mintCount <= Mad_icine.getStageInfo(madicineId, stageId).maxSupply, "Exceeds maximum stage supply");
        require(Mad_icine.getMadicineInfo(madicineId).walletLimit == 0 || mintAmount + Mad_icine.numberMintedBy(madicineId, msg.sender) <= Mad_icine.getMadicineInfo(madicineId).walletLimit, "Exceeds madicine wallet limit");
        require(Mad_icine.getStageInfo(madicineId, stageId).walletLimit == 0 || mintAmount + Mad_icine.stageMintedBy(madicineId, stageId, msg.sender) <= Mad_icine.getStageInfo(madicineId, stageId).walletLimit, "Exceeds stage wallet limit");

        for (uint256 i = 0; i < oozIds.length; i++) {
            require(oozIds[i] > 0 && oozIds[i] < 10000, "OOZ ID does not exist");
            require(OOZ.ownerOf(oozIds[i]) == msg.sender, "Does not own corresponding OOZ");
            require(!_checkMate[madicineId][stageId][oozIds[i]], "Already minted using this OOZ");
            
            if (Mad_icine.getStageInfo(madicineId, stageId).merkleRoot != 0) {
                require(MerkleProof.processProof(proofs[i], keccak256(abi.encodePacked(oozIds[i]))) == Mad_icine.getStageInfo(madicineId, stageId).merkleRoot, "Invalid proof");
            }

            if (Mad_icine.getStageInfo(madicineId, stageId).cosigner != address(0)) {
                require(SignatureChecker.isValidSignatureNow(Mad_icine.getStageInfo(madicineId, stageId).cosigner, keccak256(abi.encodePacked(madicineId, stageId, msg.sender, oozIds[i], timestamps[i])).toEthSignedMessageHash(), signatures[i]), "Invalid signature");
                require(timestamps[i] + timestampExpirySeconds >= block.timestamp, "Timestamp expired");
            }

            _checkMate[madicineId][stageId][oozIds[i]] = true;
        }

        if (_mergeMadicineIds[madicineId][stageId].length > 0) {
            for (uint256 i = 0; i < _mergeMadicineIds[madicineId][stageId].length; i++) {
                uint256 total = _mergeMadicineCounts[madicineId][stageId][i] * mintAmount;
                uint256 id =_mergeMadicineIds[madicineId][stageId][i];
                Mad_icine.burn(msg.sender, id, total);
                delete id;
                delete total;
            }
        }

        if (Mad_icine.getStageInfo(madicineId, stageId).ip3Price > 0) {
            require(IP3.balanceOf(msg.sender) >= Mad_icine.getStageInfo(madicineId, stageId).ip3Price * oozIds.length, "Not enough IP3");

            uint256 ip3Total = Mad_icine.getStageInfo(madicineId, stageId).ip3Price * oozIds.length;
            IP3.transferFrom(msg.sender, IP3recipientAddr, ip3Total);
            delete ip3Total;
        }

        Mad_icine.mint(msg.sender, madicineId, stageId, mintAmount);

        delete mintAmount;
    }

    function isValidCosign(uint256 madicineId, uint256 stageId, address addr, uint256 amount, uint256 timestamp, bytes calldata signature) internal view returns (bool) {
        bytes32 hash = keccak256(abi.encodePacked(madicineId, stageId, addr, amount, timestamp, Mad_icine.stageMintedBy(madicineId, stageId, addr)));
        hash = hash.toEthSignedMessageHash();
        if (SignatureChecker.isValidSignatureNow(Mad_icine.getStageInfo(madicineId, stageId).cosigner, hash, signature)) {
            delete hash;
            return true;
        } else {
            delete hash;
            return false;
        }
    }

    // Basic withdrawal of funds function in order to transfer ETH out of the smart contract
    function withdrawFunds() public onlyOwner {
		payable(msg.sender).transfer(address(this).balance);
	}
}