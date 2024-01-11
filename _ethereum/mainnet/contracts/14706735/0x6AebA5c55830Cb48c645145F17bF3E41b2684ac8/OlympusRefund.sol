// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "./Ownable.sol";
import "./IERC721.sol";
import "./IERC20.sol";
import "./MerkleProof.sol";

contract OlympiaRefund is Ownable {
    // mainnet
    address payable public tokenReciever = payable(0x940913C25A23FB6e2778Ec4b29110DC9f3F54fb0);
    IERC721 public constant nftContract = IERC721(0xeB652a847e5961D1F7FA53699693eC13C008b57B);


    uint256 public ethRecieved;
    bool public isRefundActive;
    bool public skipMerkleCheck;
    bytes32 public merkleRoot;

    modifier whitelisted(bytes32[] calldata merkleProof) {
        if (!skipMerkleCheck) {
            bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
            require(MerkleProof.verify(merkleProof, merkleRoot, leaf), "not whitelisted");
        }
        _;
    }

    function claimRefund(bytes32[] calldata merkleProof, uint256[] calldata nftIds) whitelisted(merkleProof) external {
        require (isRefundActive, "!active");
        uint256 total = nftIds.length * 0.01 ether;
        require(ethRecieved >= total, "noEth");
        ethRecieved -= total;
        for (uint8 i = 0; i < nftIds.length; i++) {
            require(msg.sender == nftContract.ownerOf(nftIds[i]), "!owner");
            nftContract.transferFrom(msg.sender, tokenReciever, nftIds[i]);
        }
        payable(msg.sender).transfer(total);
    }

    function withdrawAllEth() external {
        require(
            (msg.sender == owner() || msg.sender == tokenReciever),
            "!owner"
        );
        tokenReciever.transfer(ethRecieved);
        ethRecieved = 0;
    }

    receive() external payable {
        ethRecieved += msg.value;
    }

    fallback() external payable {
        ethRecieved += msg.value;
    }

    function inCaseTokensGetStuck(address _token) external onlyOwner {
        uint256 amount = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transfer(msg.sender, amount);
    }

    function setIsRefundActive(bool _isRefundActive) external onlyOwner {
        isRefundActive = _isRefundActive;
    }

    function setSkipMerkleCheck(bool _skipMerkleCheck) external onlyOwner {
        skipMerkleCheck = _skipMerkleCheck;
    }

    function setTokenReciever(address payable _tokenReciever) external onlyOwner {
        tokenReciever = _tokenReciever;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }
}