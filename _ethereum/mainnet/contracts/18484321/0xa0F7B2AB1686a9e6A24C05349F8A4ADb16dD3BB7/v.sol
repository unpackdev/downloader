// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.20;
/**
Telegram: https://t.me/Godzillaaa007
Website:  https://Godzillaaa.org/
Twitter:  https://twitter.com/Godzillaaa007
Contract: 0x52aBb054a58677137D1ca0EB7a7cf9DdD3D683eB
**/
import "./Ownable.sol";
import "./MerkleProof.sol";

interface IERC20 {
    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);
}

contract GodzillaClaims is Ownable {
    IERC20 private token;

    struct EpochClaim {
        uint claimStart;
        uint claimEnd;
        bytes32 merkleRoot;
        uint claimableTokens;
        mapping(address => bool) userClaimed;
    }

    mapping(uint => EpochClaim) public EpochClaims;

    constructor(address tokenAddress) Ownable(msg.sender){
        token = IERC20(tokenAddress);
    }

    function hasUserClaimed(uint _claimIndex, address _user) public view returns (bool) {
        return EpochClaims[_claimIndex].userClaimed[_user];
    }

    function getEpochClaim(uint _claimIndex)
    public
    view
    returns (
        uint claimStart,
        uint claimEnd,
        bytes32 merkleRoot,
        uint claimableTokens
    )
    {
        EpochClaim storage claim = EpochClaims[_claimIndex];
        return (claim.claimStart, claim.claimEnd, claim.merkleRoot, claim.claimableTokens);
    }

    function checkProof(
        bytes32[] memory _proof,
        uint _tokens,
        bytes32 root
    ) internal view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, _tokens));
        return MerkleProof.verify(_proof, root, leaf);
    }

    function setEpochClaim(
        uint _epochIndex,
        uint _claimStart,
        uint _claimEnd,
        bytes32 _merkleRoot,
        uint _claimableTokens
    ) external onlyOwner {
        EpochClaim storage newEpochClaim = EpochClaims[_epochIndex];

        newEpochClaim.claimStart = _claimStart;
        newEpochClaim.claimEnd = _claimEnd;
        newEpochClaim.merkleRoot = _merkleRoot;
        newEpochClaim.claimableTokens = _claimableTokens;
    }

    function claimTokens(
        uint _epochIndex,
        uint _tokens,
        bytes32[] memory _proof
    ) external {
        require(token.balanceOf(address(this)) >= _tokens, "Contract tokens depleted");
        require(EpochClaims[_epochIndex].claimStart < block.timestamp, "Claim has not started");
        require(EpochClaims[_epochIndex].claimEnd > block.timestamp, "Claim has ended");
        require(!EpochClaims[_epochIndex].userClaimed[msg.sender], "User has already claimed");
        require(checkProof(_proof, _tokens, EpochClaims[_epochIndex].merkleRoot), "Invalid proof");
        EpochClaims[_epochIndex].userClaimed[msg.sender] = true;
        EpochClaims[_epochIndex].claimableTokens -= _tokens;
        token.transfer(msg.sender, _tokens);
    }
    
    function manualRemove () external onlyOwner {
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }

    function setTokenAddress(address newTokenAddress) external onlyOwner {
        require(newTokenAddress != address(0), "Invalid token address");
        token = IERC20(newTokenAddress);
    }

    function transferTokensToAddress(address recipient, uint amount) external onlyOwner {
        require(recipient != address(0), "Invalid recipient address");
        require(token.balanceOf(address(this)) >= amount, "Insufficient token balance in contract");
        token.transfer(recipient, amount);
    }
}
