//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";
import "./ShurikenNFT.sol";
import "./ShurikenStakingNFT.sol";
import "./ShurikenStakedNFT.sol";
import "./PassportNFT.sol";

contract CALMinter is ReentrancyGuard, Ownable {
    enum Phase {
        BeforeMint,
        WLMint
    }

    struct ProjectInfo {
        string projectName;
        uint256 stakingCount;
    }

    struct StakingInfo {
        uint256 stakingCount;
        uint256 unstakingCount;
    }

    ShurikenNFT public immutable shurikenNFT;
    ShurikenStakingNFT public immutable shurikenStakingNFT;
    ShurikenStakedNFT public immutable shurikenStakedNFT;
    PassportNFT public immutable passportNFT;

    Phase public phase = Phase.BeforeMint;
    bytes32 public merkleRoot;
    mapping(address => uint256) public shurikenMinted;

    uint256 public cardCost = 0.02 ether;
    uint256 public shurikenCost = 0.008 ether;
    uint256 public cardSupply = 3000;
    uint256 public shurikenSupply = 10000;
    uint256 public shurikenMaxMint = 10000;

    bool public stakingPaused = true;

    ProjectInfo[] public projectInfos;
    mapping(address => mapping(uint256 => StakingInfo)) stakingInfos;

    constructor(
        ShurikenNFT _shurikenNFT,
        ShurikenStakingNFT _shurikenStakingNFT,
        ShurikenStakedNFT _shurikenStakedNFT,
        PassportNFT _passportNFT
    ) {
        shurikenNFT = _shurikenNFT;
        shurikenStakingNFT = _shurikenStakingNFT;
        shurikenStakedNFT = _shurikenStakedNFT;
        passportNFT = _passportNFT;
    }

    function mint(
        bool _card,
        uint256 _shurikenAmount,
        bytes32[] calldata _merkleProof
    ) external payable nonReentrant {
        require(phase == Phase.WLMint, 'WLMint is not active.');
        require(_card || passportNFT.balanceOf(_msgSender()) == 1, 'Passport required.');
        uint256 card = _card ? cardCost : 0;
        uint256 shuriken = shurikenCost * _shurikenAmount;
        require(_card || _shurikenAmount > 0, 'Mint amount cannot be zero');
        require(
            shurikenNFT.currentIndex() + _shurikenAmount <= shurikenSupply,
            'Total supply cannot exceed shurikenSupply'
        );
        require(msg.value >= (card + shuriken), 'Not enough funds provided for mint');

        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid Merkle Proof');

        require(
            shurikenMinted[_msgSender()] + _shurikenAmount <= shurikenMaxMint,
            'Address already claimed max amount'
        );

        if (_card) {
            require(passportNFT.currentIndex() + 1 <= cardSupply, 'Total supply cannot exceed cardSupply');
            require(passportNFT.balanceOf(_msgSender()) == 0, 'Address already claimed max amount');
            passportNFT.minterMint(_msgSender(), 1);
        }

        shurikenMinted[_msgSender()] += _shurikenAmount;
        shurikenNFT.minterMint(_msgSender(), _shurikenAmount);
    }

    function stake(uint256[] calldata tokenIds, uint256 projectIdIndex) external nonReentrant {
        require(!stakingPaused, 'paused');
        require(passportNFT.balanceOf(_msgSender()) == 1);
        shurikenNFT.burnerBurn(_msgSender(), tokenIds);
        projectInfos[projectIdIndex].stakingCount += tokenIds.length;
        stakingInfos[_msgSender()][projectIdIndex].stakingCount += tokenIds.length;
        shurikenStakingNFT.minterMint(_msgSender(), tokenIds.length);
    }

    function restake(uint256[] calldata tokenIds, uint256 projectIdIndex) external nonReentrant {
        require(!stakingPaused, 'paused');
        require(tokenIds.length <= stakingInfos[_msgSender()][projectIdIndex].unstakingCount, 'amount error');
        shurikenStakedNFT.burnerBurn(_msgSender(), tokenIds);
        projectInfos[projectIdIndex].stakingCount += tokenIds.length;
        stakingInfos[_msgSender()][projectIdIndex].stakingCount += tokenIds.length;
        stakingInfos[_msgSender()][projectIdIndex].unstakingCount -= tokenIds.length;
        shurikenStakingNFT.minterMint(_msgSender(), tokenIds.length);
    }

    function unstake(uint256[] calldata tokenIds, uint256 projectIdIndex) external nonReentrant {
        require(!stakingPaused, 'paused');
        require(tokenIds.length <= stakingInfos[_msgSender()][projectIdIndex].stakingCount, 'amount error');
        shurikenStakingNFT.burnerBurn(_msgSender(), tokenIds);
        projectInfos[projectIdIndex].stakingCount -= tokenIds.length;
        stakingInfos[_msgSender()][projectIdIndex].stakingCount -= tokenIds.length;
        stakingInfos[_msgSender()][projectIdIndex].unstakingCount += tokenIds.length;
        shurikenStakedNFT.minterMint(_msgSender(), tokenIds.length);
    }

    function projectInfosLength() external view returns (uint256) {
        return projectInfos.length;
    }

    function addProjectInfo(ProjectInfo memory info) external onlyOwner {
        projectInfos.push(info);
    }

    function setProjectInfo(uint256 index, ProjectInfo memory info) external onlyOwner {
        projectInfos[index] = info;
    }

    function setPhase(Phase _newPhase) external onlyOwner {
        phase = _newPhase;
    }

    function setStakingPaused(bool _stakingPaused) external onlyOwner {
        stakingPaused = _stakingPaused;
    }

    function setCardCost(uint256 _cardCost) external onlyOwner {
        cardCost = _cardCost;
    }

    function setShurikenCost(uint256 _shurikenCost) external onlyOwner {
        shurikenCost = _shurikenCost;
    }

    function setCardSupply(uint256 _cardSupply) external onlyOwner {
        cardSupply = _cardSupply;
    }

    function setShurikenSupply(uint256 _shurikenSupply) external onlyOwner {
        shurikenSupply = _shurikenSupply;
    }

    function setShurikenMaxMint(uint256 _shurikenMaxMint) external onlyOwner {
        shurikenMaxMint = _shurikenMaxMint;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function withdraw(address payable withdrawAddress) external onlyOwner {
        (bool os, ) = withdrawAddress.call{value: address(this).balance}('');
        require(os);
    }
}
