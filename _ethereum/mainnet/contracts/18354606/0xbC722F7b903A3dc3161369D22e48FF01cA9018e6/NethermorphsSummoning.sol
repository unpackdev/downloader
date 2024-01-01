// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./MerkleProof.sol";
import "./IERC721.sol";
import "./INethermorphs.sol";
import "./Pausable.sol";

contract NethermorphsSummoning is Ownable, Pausable {
    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    uint public maxRegularSupply;
    uint public maxRareSupply;

    INethermorphs public nethermorphsContract;
    IERC721 public totemsContract;

    mapping(bytes32 => bool) private _merkleRoots;

    constructor(
        address nethermorphsContractAddress,
        address totemsContractAddress,
        uint _maxRegularSupply,
        uint _maxRareSupply
    ) {
        nethermorphsContract = INethermorphs(nethermorphsContractAddress);
        totemsContract = IERC721(totemsContractAddress);
        maxRegularSupply = _maxRegularSupply;
        maxRareSupply = _maxRareSupply;
    }

    function mint(
        uint regularQty,
        uint rareQty,
        uint[][] calldata totemsToBurnForRegulars,
        uint[][] calldata totemsToBurnForRares,
        bytes32 merkleRoot,
        bytes32[] calldata merkleProof
    ) external whenNotPaused {
        require(regularQty == totemsToBurnForRegulars.length, "NethermorphsSummoning: Invalid regularQty");
        require(rareQty == totemsToBurnForRares.length, "NethermorphsSummoning: Invalid rareQty");
        require(nethermorphsContract.regularsMinted() + regularQty <= maxRegularSupply, "NethermorphsSummoning: Max regular supply exceeded");
        require(nethermorphsContract.raresMinted() + rareQty <= maxRareSupply, "NethermorphsSummoning: Max rare supply exceeded");

        require(_merkleRoots[merkleRoot], "NethermorphsSummoning: Invalid merkle root");
        require(merkleProof.length > 0, "NethermorphsSummoning: Invalid merkle proof");

        bytes32 leaf = _createLeaf(msg.sender, regularQty, rareQty, totemsToBurnForRegulars, totemsToBurnForRares);
        require(MerkleProof.verify(merkleProof, merkleRoot, leaf), "NethermorphsSummoning: Unable to verify merkle proof");

        if (regularQty > 0) {
            for (uint i = 0; i < regularQty; i++) {
                for (uint j = 0; j < totemsToBurnForRegulars[i].length; j++) {
                    totemsContract.transferFrom(msg.sender, BURN_ADDRESS, totemsToBurnForRegulars[i][j]);
                }
            }
        }

        if (rareQty > 0) {
            for (uint i = 0; i < rareQty; i++) {
                for (uint j = 0; j < totemsToBurnForRares[i].length; j++) {
                    totemsContract.transferFrom(msg.sender, BURN_ADDRESS, totemsToBurnForRares[i][j]);
                }
            }
        }

        nethermorphsContract.mint(msg.sender, regularQty, rareQty);
    }

    function setNethermorphsContract(address _nethermorphsContract) public onlyOwner {
        nethermorphsContract = INethermorphs(_nethermorphsContract);
    }

    function setTotemsContract(address _totemsContract) public onlyOwner {
        totemsContract = IERC721(_totemsContract);
    }

    function setMaxRegularSupply(uint _maxRegularSupply) public onlyOwner {
        maxRegularSupply = _maxRegularSupply;
    }

    function setMaxRareSupply(uint _maxRareSupply) public onlyOwner {
        maxRareSupply = _maxRareSupply;
    }

    function setMerkleRoot(bytes32 merkleRoot, bool value) public onlyOwner {
        _merkleRoots[merkleRoot] = value;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _createLeaf(
        address sender,
        uint regularsQty,
        uint raresQty,
        uint[][] calldata totemsToBurnForRegulars,
        uint[][] calldata totemsToBurnForRares
    ) private pure returns (bytes32) {
        bytes memory totemsToBurnForRegularsBytes;
        bytes memory totemsToBurnForRaresBytes;
        for (uint i = 0; i < totemsToBurnForRegulars.length; i++) {
            totemsToBurnForRegularsBytes = abi.encodePacked(totemsToBurnForRegularsBytes, totemsToBurnForRegulars[i]);
        }
        for (uint i = 0; i < totemsToBurnForRares.length; i++) {
            totemsToBurnForRaresBytes = abi.encodePacked(totemsToBurnForRaresBytes, totemsToBurnForRares[i]);
        }
        return keccak256(abi.encodePacked(sender, regularsQty, raresQty, totemsToBurnForRegularsBytes, totemsToBurnForRaresBytes));
    }
}
