// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./MerkleProof.sol";
import "./Ownable.sol";
import "./IERC1155.sol";

abstract contract IBlueBananaSerum is IERC1155 {
    function mint(uint256 serumType, address to) external {}
    function mintMultiple(uint256 serumType, uint256 amount, address to) external {}
}

contract BlueBananaSerumClaim is Ownable {
    IBlueBananaSerum public blueBananaSerum;

    bool public claimOpen;
    bytes32 public merkleRoot;
    mapping(address => uint256) public userToBBSClaims;    

    event ReceivedEther(address indexed sender, uint256 indexed amount);

    constructor(
        address bbs
    ) Ownable() {
        blueBananaSerum = IBlueBananaSerum(bbs);
    }

    /** === BBS Issuance === */

    function claimBBS(bytes32[] calldata proof, uint256 amount) external {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, amount));
        require(MerkleProof.verify(proof, merkleRoot, leaf), "Merkle Proof not valid");

        require(claimOpen, "Claim not opened");        
        require(userToBBSClaims[msg.sender] == 0, "BBS Already Claimed");       

        userToBBSClaims[msg.sender] = 1;
        blueBananaSerum.mintMultiple(0, amount, msg.sender);
    }

    function airdropBBS(address[] calldata recipients, uint256[] calldata amounts) external onlyOwner {
        require(claimOpen, "Claim not opened");        
        require(recipients.length > 0, "Zero recipients specified");
        require(recipients.length == amounts.length, "Lengths mismatch");

        for (uint256 i = 0; i < recipients.length; i++) {
            blueBananaSerum.mintMultiple(0, amounts[i], recipients[i]);
        }
    }

    /** === Admin only === */

    function setContracts(address bbs) external onlyOwner {
        blueBananaSerum = IBlueBananaSerum(bbs);
    }

    function setSaleStates(bool _claimOpen) external onlyOwner {
        claimOpen = _claimOpen;
    }

    function setMerkleRoot(bytes32 newRoot) external onlyOwner {
        merkleRoot = newRoot;
    }

    receive() external payable {
        emit ReceivedEther(msg.sender, msg.value);
    }

    function withdrawEth(address _to) external onlyOwner {
        require(_to != address(0), "CANNOT WITHDRAW TO ZERO ADDRESS");
        uint256 contractBalance = address(this).balance;
        require(contractBalance > 0, "NO ETHER TO WITHDRAW");
        payable(_to).transfer(contractBalance);
    }
}