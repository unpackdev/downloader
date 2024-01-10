// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

import "./SafeMath.sol";
import "./ECDSA.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";

interface IArcada {
    function balanceOf(address account) external view returns (uint256);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external;
}

contract MTGGame is Ownable {
    using ECDSA for bytes32;
    using MerkleProof for bytes32[];

    IArcada public Arcada;

    address private signerAddress = 0x8fD406D0B1a95D52C0E2D85dE41e11F5FCE94373;
    address public ArcadaAddress = 0x22d811658Dc32293fbB5680EC5df85Cc2B605dC7;

    uint256 public totalChancesToWin = 100;

    bytes32 playerSnapshotRoot;
    mapping(address => uint) public playingRecords;

    event GameWon(address indexed player);
    event GameLost(address indexed player);

    constructor() {
        Arcada = IArcada(ArcadaAddress);
    }

    function getSignerAddress(uint256 seed, bytes calldata signature) private pure returns (address) {
        bytes32 messagehash =  keccak256(abi.encodePacked(seed));
        return messagehash.toEthSignedMessageHash().recover(signature);
    }

    function generateRandom(uint256 seed) private view returns (uint256) {
        return SafeMath.mod(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            block.difficulty,
                            tx.origin,
                            blockhash(block.number - 1),
                            block.timestamp,
                            seed
                        )
                    )
                ),
                5
            ) + 1;
    }

    function setPlayerSnapshotRoot(bytes32 root) external onlyOwner {
        playerSnapshotRoot = root;
    }

    function setSignerAddress(address signer) external onlyOwner {
        signerAddress = signer;
    }

    function setArcadaContract(address operator) external onlyOwner {
        Arcada = IArcada(operator);
    }

    function setTotalChancesToWin(uint number) external onlyOwner {
        totalChancesToWin = number;
    }

    function isAllowedToPlay(bytes32[] memory proof, address player, uint numberOfMaxWins) public view returns (bool) {
        return proof.verify(playerSnapshotRoot, keccak256(abi.encodePacked(player, numberOfMaxWins)));
    }

    function play(uint256 seed, bytes calldata signature, uint256 numberOfMaxWins, bytes32[] memory proof) external returns (bool) {
        require(signerAddress == getSignerAddress(seed, signature), "Invalid signature.");
        require(Arcada.balanceOf(_msgSender()) >= 400 ether, "Not enough balance.");
        require(totalChancesToWin > 0, "No more games.");
        require(isAllowedToPlay(proof, _msgSender(), numberOfMaxWins), "Not included in the game.");
        require(playingRecords[_msgSender()] < numberOfMaxWins, "Not included in the game.");

        // burn the token
        Arcada.transferFrom(
            _msgSender(),
            address(0x000000000000000000000000000000000000dEaD),
            400 ether
        );

        if (1 == generateRandom(seed)) {
            emit GameWon(_msgSender());
            playingRecords[_msgSender()]++;
            totalChancesToWin--;
            return true;
        }
        emit GameLost(_msgSender());
        return false;
    }
}