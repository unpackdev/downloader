
pragma solidity ^0.6.0;

import "./SafeMath.sol";

interface IHayekPlate {
    function issueAirdrop(address to, uint256 tokenId) external;
}

contract HayekPlateAirdropIssuer {
    using SafeMath for uint256;
    IHayekPlate public hayekPlatel;
    struct AirdropPool {
        uint256 aID;
        uint256 bID;
        uint256 cID;
        uint256 dID;
        uint256 eID;
        uint256 fID;
        uint256 gID;
        uint256 hID;

        uint256 aIDAmount;
        uint256 bIDAmount;
        uint256 cIDAmount;
        uint256 dIDAmount;
        uint256 eIDAmount;
        uint256 fIDAmount;
        uint256 gIDAmount;
        uint256 hIDAmount;

        uint256 allAmount;
    }

    uint256 public totolUnclaimed = 12705;

    mapping(address => AirdropPool) private airdropRemaining;
    mapping(address => bool) private airdropPoolAddr;

    constructor (IHayekPlate _hayekPlate, address[] memory airdropPools) public {
        hayekPlatel = _hayekPlate;
        for (uint256 i = 0; i < airdropPools.length; i++) {
            airdropRemaining[airdropPools[i]] = AirdropPool(
                i * 1 + 1,
                i * 20 + 20001, 
                i * 40 + 30001, 
                i * 80 + 40001, 
                i * 160 + 50001, 
                i * 320 + 60001, 
                i * 640 + 70001, 
                i * 1280+ 80001, 
                1,20,40,80,160,320,640,1280,2541);
            airdropPoolAddr[airdropPools[i]] = true;
        }
    }

    modifier isAirdropPool() {
        require(airdropPoolAddr[msg.sender], 'Not Airdrop');
        _;
    }

    function claimONEPlate(address account) public isAirdropPool {
        AirdropPool storage airdropPool = airdropRemaining[msg.sender];
        uint256 newTokenId = rand(account, airdropPool);
        hayekPlatel.issueAirdrop(account, newTokenId);
        totolUnclaimed = totolUnclaimed.sub(1);
    }

    function getTargetAirdropStatus(address _airdropPool) public view returns(uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256) {
        AirdropPool storage airdropPool = airdropRemaining[_airdropPool];
        return (airdropPool.aIDAmount, airdropPool.bIDAmount, airdropPool.cIDAmount, airdropPool.dIDAmount, airdropPool.eIDAmount, airdropPool.fIDAmount, airdropPool.gIDAmount, airdropPool.hIDAmount, airdropPool.allAmount);
    }

    function rand(address account, AirdropPool storage airdropPool) internal returns(uint256) {
        uint256 random = uint256(keccak256(abi.encode(block.difficulty, now, account, airdropPool.allAmount)));
        uint256 randomBase = random % airdropPool.allAmount;
        uint256 tokenId = 0;
        if (randomBase < airdropPool.aIDAmount) {
            tokenId = airdropPool.aID;
            airdropPool.aID = airdropPool.aID.add(1);
            airdropPool.aIDAmount = airdropPool.aIDAmount.sub(1);
        } else if (randomBase < (airdropPool.aIDAmount + airdropPool.bIDAmount)) {
            tokenId = airdropPool.bID;
            airdropPool.bID = airdropPool.bID.add(1);
            airdropPool.bIDAmount = airdropPool.bIDAmount.sub(1);
        } else if (randomBase < (airdropPool.aIDAmount + airdropPool.bIDAmount + airdropPool.cIDAmount)) {
            tokenId = airdropPool.cID;
            airdropPool.cID = airdropPool.cID.add(1);
            airdropPool.cIDAmount = airdropPool.cIDAmount.sub(1);
        } else if (randomBase < (airdropPool.aIDAmount + airdropPool.bIDAmount + airdropPool.cIDAmount + airdropPool.dIDAmount)) {
            tokenId = airdropPool.dID;
            airdropPool.dID = airdropPool.dID.add(1);
            airdropPool.dIDAmount = airdropPool.dIDAmount.sub(1);
        } else if (randomBase < (airdropPool.aIDAmount + airdropPool.bIDAmount + airdropPool.cIDAmount + airdropPool.dIDAmount + airdropPool.eIDAmount)) {
            tokenId = airdropPool.eID;
            airdropPool.eID = airdropPool.eID.add(1);
            airdropPool.eIDAmount = airdropPool.eIDAmount.sub(1);
        } else if (randomBase < (airdropPool.aIDAmount + airdropPool.bIDAmount + airdropPool.cIDAmount + airdropPool.dIDAmount + airdropPool.eIDAmount + airdropPool.fIDAmount)) {
            tokenId = airdropPool.fID;
            airdropPool.fID = airdropPool.fID.add(1);
            airdropPool.fIDAmount = airdropPool.fIDAmount.sub(1);
        } else if (randomBase < (airdropPool.aIDAmount + airdropPool.bIDAmount + airdropPool.cIDAmount + airdropPool.dIDAmount + airdropPool.eIDAmount + airdropPool.fIDAmount + airdropPool.gIDAmount)) {
            tokenId = airdropPool.gID;
            airdropPool.gID = airdropPool.gID.add(1);
            airdropPool.gIDAmount = airdropPool.gIDAmount.sub(1);
        } else if (randomBase < (airdropPool.aIDAmount + airdropPool.bIDAmount + airdropPool.cIDAmount + airdropPool.dIDAmount + airdropPool.eIDAmount + airdropPool.fIDAmount + airdropPool.gIDAmount + airdropPool.hIDAmount)) {
            tokenId = airdropPool.hID;
            airdropPool.hID = airdropPool.hID.add(1);
            airdropPool.hIDAmount = airdropPool.hIDAmount.sub(1);
        }

        airdropPool.allAmount = airdropPool.allAmount.sub(1);
        return tokenId;
    }
}