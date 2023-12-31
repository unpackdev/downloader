// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./ERC721A.sol";
import "./Ownable.sol";

contract OinariGenesis is ERC721A, Ownable {
    uint256 public immutable maxMint;
    uint256 public immutable maxSupply;
    uint256 public oinariWorth = 0.003 ether;
    string private baseTokenURI;
    bool public oinariAwake = false;

    mapping(address => uint256) public totalOinaris;

    struct OinariProvenance {
        string provenanceStageOne;
        bool provenanceStageOneLocked;
        string provenanceStageTwo;
        bool provenanceStageTwoLocked;
        string provenanceStageThree;
        bool provenanceStageThreeLocked;
    }

    OinariProvenance public oinariStages;

    constructor(
        uint256 _maxMint,
        uint256 _maxSupply
    ) ERC721A("Oinari Genesis", "OinariGenesis") {
        maxMint = _maxMint;
        maxSupply = _maxSupply;
    }

    function orderOinari() external onlyOwner {
        oinariAwake = !oinariAwake;
    }

    function mintOinari(uint256 _batchMint) external payable {
        require(oinariAwake, "Spirit not awake yet");
        require(
            totalOinaris[msg.sender] + _batchMint <= 3,
            "You exceed max claimed!"
        );
        require(_batchMint <= maxMint, "You exceed max batch mint!");
        require(totalSupply() + _batchMint <= maxSupply, "You exceed max supply!");
        require(
            msg.value == _batchMint * oinariWorth,
            "You need to mint the spirits with exact value"
        );
        totalOinaris[msg.sender] += _batchMint;
        _safeMint(msg.sender, _batchMint);
    }

    function withdraw() external onlyOwner {
        (bool succ, ) = payable(msg.sender).call{value: address(this).balance}(
            ""
        );
        require(succ, "transfer failed");
    }

    function setOinariWorth(uint256 _newWorth) external onlyOwner {
        oinariWorth = _newWorth;
    }

    function setProvenanceHash(
        string memory _spiritProvenanceHash,
        uint256 stage
    ) external onlyOwner {
        if (stage == 1) {
            require(
                !oinariStages.provenanceStageOneLocked,
                "Provenance Stage One Locked!"
            );
            oinariStages.provenanceStageOne = _spiritProvenanceHash;
            oinariStages.provenanceStageOneLocked = true;
        } else if (stage == 2) {
            require(
                !oinariStages.provenanceStageTwoLocked,
                "Provenance Stage Two Locked!"
            );
            oinariStages.provenanceStageTwo = _spiritProvenanceHash;
            oinariStages.provenanceStageTwoLocked = true;
        } else if (stage == 3) {
            require(
                !oinariStages.provenanceStageThreeLocked,
                "Provenance Stage Three Locked!"
            );
            oinariStages.provenanceStageThree = _spiritProvenanceHash;
            oinariStages.provenanceStageThreeLocked = true;
        }
    }

    function setBaseURI(string calldata _newBaseURI) external onlyOwner {
        baseTokenURI = _newBaseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
}
