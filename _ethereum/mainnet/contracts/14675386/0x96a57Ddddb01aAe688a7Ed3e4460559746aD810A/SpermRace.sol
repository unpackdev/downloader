// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./IERC721.sol";
import "./ECDSA.sol";
import "./Ownable.sol";

contract SpermRace is Ownable {
    using ECDSA for bytes32;

    uint internal immutable MAX_INT = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    IERC721 spermGameContract;

    mapping(uint => uint) public eggTokenIdToSpermTokenIdBet;
    mapping(uint => bool) public uniqueTokenIds;

    bool inProgress;
    bool enforceRaceEntrySignature;

    uint public constant TOTAL_EGGS = 1778;
    uint public constant TOTAL_SUPPLY = 8888;

    uint public maxParticipantsInRace = 4000;
    uint public numOfFertilizationSpermTokens = 2;
    uint public raceEntryFee = 0 ether;
    uint public bettingFee = 0 ether;

    uint[] public tokenIdParticipants;
    uint[] public raceRandomNumbers;
    uint[] public participantsInRound;
    uint[] public fertilizedTokenIds = new uint[]((TOTAL_EGGS / 256) + 1);

    address private operatorAddress;

    constructor(address _spermGameContractAddress) {
        spermGameContract = IERC721(_spermGameContractAddress);
        operatorAddress = msg.sender;
        inProgress = false;
        enforceRaceEntrySignature = false;
    }

    function enterRace(uint[] calldata tokenIds, bytes[] calldata signatures) external payable enforceMaxParticipantsInRace(tokenIds.length) enforceSignatureEntry(tokenIds, signatures) {
        require(inProgress, "Sperm race is not in progress");
        require(msg.value >= raceEntryFee, "Insufficient fee supplied to enter race");
        for (uint i = 0; i < tokenIds.length; i++) {
            require((tokenIds[i] % 5) != 0, "One of the supplied tokenIds is not a sperm");
            require(spermGameContract.ownerOf(tokenIds[i]) == msg.sender, "Not the owner of one or more of the supplied tokenIds");

            tokenIdParticipants.push(tokenIds[i]);
        }
    }

    function fertilize(uint eggTokenId, uint[] calldata spermTokenIds, bytes[] memory signatures) external {
        require(!inProgress, "Sperm race is ongoing");

        require((eggTokenId % 5) == 0, "Supplied eggTokenId is not an egg");
        require(spermGameContract.ownerOf(eggTokenId) == msg.sender, "Not the owner of the egg");
        require(spermTokenIds.length == numOfFertilizationSpermTokens, "Must bring along the correct number of sperms");
        require(spermTokenIds.length == signatures.length, "Each sperm requires a signatures");
        require(!isFertilized(eggTokenId), "Egg tokenId is already fertilized");

        setFertilized(eggTokenId);

        for (uint i = 0; i < spermTokenIds.length; i++) {
            require((spermTokenIds[i] % 5) != 0, "One or more of the supplied spermTokenIds is not a sperm");
            isTokenInFallopianPool(spermTokenIds[i], signatures[i]);
            require(!isFertilized(spermTokenIds[i]), "One of the spermTokenIds has already fertilized an egg");
            setFertilized(spermTokenIds[i]);
        }
    }

    function bet(uint eggTokenId, uint spermTokenId) external payable {
        require(!inProgress || (raceRandomNumbers.length == 0), "Race is already in progress");
        require(msg.value >= bettingFee, "Insufficient fee to place bet");
        require(spermGameContract.ownerOf(eggTokenId) == msg.sender, "Not the owner of the egg");
        require((eggTokenId % 5) == 0, "Supplied eggTokenId is not an egg");
        require((spermTokenId % 5) != 0, "Supplied spermTokenId is not a sperm");

        eggTokenIdToSpermTokenIdBet[eggTokenId] = spermTokenId;
    }

    function calculateTraitsFromTokenId(uint tokenId) public pure returns (uint) {
        if ((tokenId == 409) || (tokenId == 1386) || (tokenId == 1499) || (tokenId == 1556) || (tokenId == 1971) || (tokenId == 2561) || (tokenId == 3896) || (tokenId == 4719) || (tokenId == 6044) || (tokenId == 6861) || (tokenId == 8348) || (tokenId == 8493)) {
            return 12;
        }

        uint magicNumber = 69420;
        uint iq = (uint(keccak256(abi.encodePacked(tokenId, magicNumber, "IQ"))) % 4) + 1;
        uint speed = (uint(keccak256(abi.encodePacked(tokenId, magicNumber, "Speed"))) % 4) + 1;
        uint strength = (uint(keccak256(abi.encodePacked(tokenId, magicNumber, "Strength"))) % 4) + 1;

        return iq + speed + strength;
    }

    function progressRace(uint num) external onlyOwner {
        require(inProgress, "Races must be in progress to progress");
        uint randomNumber = random(tokenIdParticipants.length);
        for (uint i = 0; i < num; i++) {
            randomNumber >>= 8;
            raceRandomNumbers.push(randomNumber);
            participantsInRound.push(tokenIdParticipants.length);
        }
    }

    function toggleRace() external onlyOwner {
        inProgress = !inProgress;
    }

    function setOperatorAddress(address _address) external onlyOwner {
        operatorAddress = _address;
    }

    function resetRace() external onlyOwner {
        require(!inProgress, "Sperm race is ongoing");

        delete tokenIdParticipants;
        delete raceRandomNumbers;
        delete participantsInRound;
        fertilizedTokenIds = new uint[]((TOTAL_EGGS / 256) + 1);
    }

    function leaderboard(uint index) external view returns (uint[] memory, uint[] memory) {
        uint[] memory leaders = new uint[](participantsInRound[index]);
        uint[] memory progress = new uint[](participantsInRound[index]);
        uint[] memory tokenRaceTraits = new uint[](8888);

        // copy over all the tokenIdParticipants into the leader array
        // calculate all the battle traits one time
        for (uint i = 0; i < participantsInRound[index]; i++) {
            leaders[i] = tokenIdParticipants[i];
            tokenRaceTraits[tokenIdParticipants[i]] = calculateTraitsFromTokenId(tokenIdParticipants[i]);
        }

        // Fisher-Yates shuffle
        for (uint k = 0; k < participantsInRound[index]; k++) {
            uint randomIndex = raceRandomNumbers[index] % (participantsInRound[index] - k);
            uint randomValA = leaders[randomIndex];
            uint randomValB = progress[randomIndex];

            leaders[randomIndex] = leaders[k];
            leaders[k] = randomValA;

            progress[randomIndex] = progress[k];
            progress[k] = randomValB;
        }

        for (uint j = 0; j < participantsInRound[index]; j = j + 2) {
            // You are a winner if you're the edge case in a odd number of tokenIdParticipants
            if (j == (participantsInRound[index] - 1)) {
                progress[j]++;
            } else {
                uint scoreA = tokenRaceTraits[leaders[j]];
                uint scoreB = tokenRaceTraits[leaders[j+1]];

                if ((raceRandomNumbers[index] % (scoreA + scoreB)) < scoreA) {
                    progress[j]++;
                } else {
                   progress[j+1]++;
                }
            }
        }

       return (leaders, progress);
    }

    function setMaxParticipantsInRace(uint _maxParticipants) external onlyOwner {
        maxParticipantsInRace = _maxParticipants;
    }

    function setNumOfFertilizationSpermTokens(uint _numOfTokens) external onlyOwner {
        numOfFertilizationSpermTokens = _numOfTokens;
    }

    function setRaceEntryFee(uint _entryFee) external onlyOwner {
        raceEntryFee = _entryFee;
    }

    function setBettingFee(uint _bettingFee) external onlyOwner {
        bettingFee = _bettingFee;
    }

    function setEnforceRaceEntrySignature (bool _enableSignature) external onlyOwner {
        enforceRaceEntrySignature = _enableSignature;
    }

    function getTokenIdParticipants() external view returns (uint[] memory) {
        return tokenIdParticipants;
    }

    function random(uint seed) internal view returns (uint) {
        return uint(keccak256(abi.encodePacked(tx.origin, blockhash(block.number - 1), block.timestamp, seed)));
    }

    function isValidSignature(bytes32 hash, bytes memory signature) internal view returns (bool isValid) {
        bytes32 signedHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
        return signedHash.recover(signature) == operatorAddress;
    }

    function isTokenInFallopianPool(uint tokenId, bytes memory signature) internal view {
        bytes32 msgHash = keccak256(abi.encodePacked(tokenId));
        require(isValidSignature(msgHash, signature), "Invalid signature");
    }

    function isFertilized(uint tokenId) public view returns (bool) {
        uint[] memory bitMapList = fertilizedTokenIds;
        uint partitionIndex = tokenId / 256;
        uint partition = bitMapList[partitionIndex];
        if (partition == MAX_INT) {
            return true;
        }
        uint bitIndex = tokenId % 256;
        uint bit = partition & (1 << bitIndex);
        return (bit != 0);
    }

    function setFertilized(uint tokenId) internal {
        uint[] storage bitMapList = fertilizedTokenIds;
        uint partitionIndex = tokenId / 256;
        uint partition = bitMapList[partitionIndex];
        uint bitIndex = tokenId % 256;
        bitMapList[partitionIndex] = partition | (1 << bitIndex);
    }

    function numOfRounds() external view returns (uint) {
        return raceRandomNumbers.length;
    }

    function numOfParticipants() external view returns (uint) {
        return tokenIdParticipants.length;
    }

    modifier enforceMaxParticipantsInRace(uint num) {
        require((tokenIdParticipants.length + num) <= maxParticipantsInRace, "Race participants has reached the maximum allowed");
        _;
    }

    modifier enforceSignatureEntry(uint[] calldata tokenIds, bytes[] calldata signatures) {
        if (enforceRaceEntrySignature) {
            require(tokenIds.length == signatures.length, "Number of signatures must match number of tokenIds");
            for (uint i = 0; i < tokenIds.length; i++) {
                bytes32 msgHash = keccak256(abi.encodePacked(tokenIds[i]));
                require(isValidSignature(msgHash, signatures[i]), "Invalid signature");
            }
        }
        _;
    }
}