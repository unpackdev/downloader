// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "./Ownable.sol";
import "./AccessControl.sol";
import "./MerkleProof.sol";
import "./ERC721A.sol";
import "./DefaultOperatorFilterer.sol";
import "./HamCupCrew.sol";

contract HamCupCrewMinter is Ownable {
    enum Phase {
        BeforeMint,
        PreMint1
    }
    HamCupCrew public immutable hcc;

    uint256 public maxSupply = 10000;

    Phase public phase = Phase.BeforeMint;

    mapping(Phase => mapping(address => uint256)) public minted;
    mapping(Phase => uint256) public limitedPerWL;
    mapping(Phase => bytes32) public merkleRoot;
    mapping(Phase => uint256) public prices;
    
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract.");
        _;
    }

    constructor(HamCupCrew _hcc) {
        hcc = _hcc;
        limitedPerWL[Phase.PreMint1] = 1;
        prices[Phase.PreMint1] = 0.001 ether;
    }

    // internal
    function _mintCheck(uint256 _mintAmount) internal view {
        require(phase == Phase.PreMint1, 'PreMint is not active.');
        require(msg.value >= (prices[phase] * _mintAmount), 'Not enough funds provided for mint');
        require(_mintAmount > 0, 'Mint amount cannot be zero');
        require(hcc.totalSupply() + _mintAmount <= maxSupply, 'Total supply cannot exceed maxSupply');
    }

    function _preMint(
        uint256 _mintAmount,
        uint256 _wlCount,
        bytes32[] calldata _merkleProof,
        address _receiver
    ) internal {
        _mintCheck(_mintAmount);

        bytes32 leaf = keccak256(abi.encodePacked(_receiver, _wlCount));
        require(MerkleProof.verify(_merkleProof, merkleRoot[phase], leaf), 'Invalid Merkle Proof');

        require(
            minted[phase][_receiver] + _mintAmount <= _wlCount * limitedPerWL[phase],
            'Address already claimed max amount'
        );

        minted[phase][_receiver] += _mintAmount;
        hcc.minterMint(_receiver, _mintAmount);
    }

    // public
    function preMintPie(
        uint256 _mintAmount,
        uint256 _wlCount,
        bytes32[] calldata _merkleProof,
        address _receiver
    ) public payable callerIsUser {
        _preMint(_mintAmount, _wlCount, _merkleProof, _receiver);
    }

    function preMint(
        uint256 _mintAmount,
        uint256 _wlCount,
        bytes32[] calldata _merkleProof
    ) public payable callerIsUser {
        _preMint(_mintAmount, _wlCount, _merkleProof, msg.sender);
    }

    // external (only owner)
    function setPhase(Phase _newPhase) external onlyOwner {
        phase = _newPhase;
    }

    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }

    function setLimitedPerWL(Phase _phase, uint256 _number) external onlyOwner {
        limitedPerWL[_phase] = _number;
    }

    function setMerkleRoot(Phase _phase, bytes32 _merkleRoot) external onlyOwner {
        merkleRoot[_phase] = _merkleRoot;
    }

    function setPrice(Phase _phase, uint256 _price) external onlyOwner {
        prices[_phase] = _price;
    }

    function withdraw(address to) external onlyOwner {
        (bool os, ) = payable(to).call{value: address(this).balance}('');
        require(os);
    }
}
