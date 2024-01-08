//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC20Burnable.sol";
import "./Ownable.sol";

interface IStakingErc721 {
  function ownerOf(uint256 tokenId) external view returns (address);
  function supportsInterface(bytes4 interfaceId)
    external
    view
    returns (bool);
}

interface IMainErc721 {
  function checkBouns(address addr) external view returns (uint256);
}

contract Popmeow is ERC20Burnable, Ownable {

    uint256 private constant VIP_RATE = 34722222222222; // 3 per day
    uint256 private constant NORMAL_RATE = 11574074074074; // 1 per day
    uint256 public maxLoopSize = 200;

    uint256 public tokenCount = 1;

    // contract ID to tokenId to last staked time
    mapping(uint256 => mapping(uint256 => uint256)) private tokenStorage;
    mapping(uint256 => address) private idToContract;
    mapping(address => uint256) private whiteList;
    mapping(address => uint256) private bounsClaimedList;
    mapping(address => bool) private vipList;
    address private constant popcats = 0x5784fcf6653bE795c138E0db039d1a6410b7c88E;
    bool public stakeOpen = true;

    IMainErc721 private constant mainContract = IMainErc721(popcats);

    constructor() ERC20("Popmeow", "PMW") {
        whiteList[popcats] = tokenCount;
        idToContract[tokenCount] = popcats;
        vipList[popcats] = true;
    }

    modifier stakingActive {
        require(stakeOpen, "Staking not active");
        _;
    }

    function getBouns() view external returns (uint256) {
        uint256 bouns = mainContract.checkBouns(msg.sender);
        require(bouns > 0,"Staking: Sender not in bouns list");
        uint256 remainBouns = bouns - bounsClaimedList[msg.sender];
        require(remainBouns > 0,"Staking: No bouns remain");
        return remainBouns;
    }

    function claimBouns() external {
        uint256 bouns = mainContract.checkBouns(msg.sender);
        uint256 remainBouns = bouns - bounsClaimedList[msg.sender];
        require(remainBouns > 0,"Staking: No bouns remain");
        bounsClaimedList[msg.sender] = bouns;
        _mint(msg.sender, remainBouns);
    }

    function toggleStakingActive() external onlyOwner {
        stakeOpen = !stakeOpen;
    }

    function setVip(address contractAddr, bool status) external onlyOwner {
        vipList[contractAddr] = status;
    }

    function onVip(address contractAddr) external view returns (bool) {
        return vipList[contractAddr];
    }

    function setMaxLoopSize(uint256 size) external onlyOwner {
        require(size > 0,"loop size must greater than 0");
        maxLoopSize = size;
    }
    // return a list of bool, true means unstake
    function unstakeCheck(address contractAddr, uint256[] calldata tokenIds) external view returns (bool[] memory) {
        require(tokenIds.length <= maxLoopSize,"Staking: check stake size exceed");
        uint256 contractId = whiteList[contractAddr];
        require(contractId > 0, "Staking: contract not on whitelist");
        bool[] memory stakeResult = new bool[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if(tokenStorage[contractId][tokenIds[i]] == 0){
                stakeResult[i] = true;
            }
        }
        return stakeResult;
    }

    function getWhiteList() external view returns (address[] memory) {
        address[] memory contractList = new address[](tokenCount);
        uint256 arrIndex = 0;
        for (uint256 i = 0; i < tokenCount; i++) {
            uint256 indexOfId = i + 1;
            if(idToContract[indexOfId] != address(0)){
                contractList[arrIndex] = idToContract[indexOfId];
                arrIndex++;
            }
        }
        return contractList;
    }
    
    function addToWhitelist(address contractAddr) external onlyOwner {
        IStakingErc721 erc721 = IStakingErc721(contractAddr);
        require(erc721.supportsInterface(0x80ac58cd), "Staking: Erc721 not support");
        tokenCount ++;
        whiteList[contractAddr] = tokenCount;
        idToContract[tokenCount] = contractAddr;
    }

    // make sure to remind and withdraw all rewards in certain period of time
    function removeFromWhitelist(address contractAddr) external onlyOwner {
        uint256 tokenId = whiteList[contractAddr];
        require(tokenId > 0,"Staking: contract not on whitelist");
        idToContract[tokenId] = address(0);
        whiteList[contractAddr] = 0;
    }

    function stakeByToken(address contractAddr, uint256 tokenId) external stakingActive {
        uint256 contractId = whiteList[contractAddr];
        require(contractId > 0, "Staking: contract not on whitelist");
        IStakingErc721 erc721 = IStakingErc721(contractAddr);
        require(erc721.ownerOf(tokenId) == msg.sender, "Staking: Sender not owner");
        require(tokenStorage[contractId][tokenId] == 0,"Staking: token is already staked");
        tokenStorage[contractId][tokenId] = block.timestamp;
    }

    function claimRewardByToken(address contractAddr, uint256 tokenId) external {
        uint256 contractId = whiteList[contractAddr];
        require(contractId > 0, "Staking: contract not on whitelist");
        IStakingErc721 erc721 = IStakingErc721(contractAddr);
        require(erc721.ownerOf(tokenId) == msg.sender, "Staking: Sender not owner");
        // prevent modify unstake token
        uint256 lastStakeTime = tokenStorage[contractId][tokenId];
        require(lastStakeTime > 0,"Staking: token not stake");
        uint256 blocktime = block.timestamp;
        uint256 totalRewards = (blocktime - lastStakeTime) * (vipList[contractAddr] ? VIP_RATE : NORMAL_RATE);
        _mint(msg.sender, totalRewards);
        tokenStorage[contractId][tokenId] = blocktime;
    }

    function stakeByContract(address contractAddr, uint256[] calldata tokenIds) external stakingActive {
        require(tokenIds.length > 0,"Staking: token size must greater than 0");
        require(tokenIds.length <= maxLoopSize,"Staking: stake size exceed");
        uint256 blocktime = block.timestamp;
        uint256 contractId = whiteList[contractAddr];
        IStakingErc721 erc721 = IStakingErc721(contractAddr);
        require(contractId > 0, "Staking: contract not on whitelist");
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(erc721.ownerOf(tokenId) == msg.sender, "Staking: contain token not own");
            uint256 lastStakeTime = tokenStorage[contractId][tokenId];
            // prevent modify if token aleady staked
            require(lastStakeTime == 0,"Staking: contain staked token");
            tokenStorage[contractId][tokenId] = blocktime;
        }
    }

    function getContractStakedRewards(address contractAddr, uint256[] calldata tokenIds) external view returns (uint256[] memory) {
        require(tokenIds.length <= maxLoopSize,"Staking: search size exceed");
        uint256 contractId = whiteList[contractAddr];
        require(contractId > 0, "Staking: contract not on whitelist");
        uint256 blocktime = block.timestamp;
        uint256 rate = vipList[contractAddr] ? VIP_RATE : NORMAL_RATE;
        uint256[] memory totalRewards = new uint256[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 lastStakeTime = tokenStorage[contractId][tokenIds[i]];
            if(lastStakeTime > 0){
                totalRewards[i] = (blocktime - lastStakeTime) * rate;
            }else if(lastStakeTime == 0){
                totalRewards[i] = 0;
            }
        }
        return totalRewards;
    }

    function claimByContract(address contractAddr, uint256[] calldata tokenIds) external stakingActive {
        require(tokenIds.length > 0,"Staking: token size must greater than 0");
        require(tokenIds.length <= maxLoopSize,"Staking: claim size exceed");
        uint256 contractId = whiteList[contractAddr];
        require(contractId > 0, "Staking: contract not on whitelist");
        uint256 blocktime = block.timestamp;
        uint256 totalRewards = 0;
        IStakingErc721 erc721 = IStakingErc721(contractAddr);
        uint256 rate = vipList[contractAddr] ? VIP_RATE : NORMAL_RATE;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(erc721.ownerOf(tokenId) == msg.sender, "Staking: contain token not own");
            uint256 lastStakeTime = tokenStorage[contractId][tokenId];
            require(lastStakeTime > 0,"Staking: contain unstake token");
            tokenStorage[contractId][tokenId] = blocktime;
            totalRewards += ((blocktime - lastStakeTime) * rate);
        }
        if(totalRewards > 0){
        _mint(msg.sender, totalRewards);
        }
    }

}