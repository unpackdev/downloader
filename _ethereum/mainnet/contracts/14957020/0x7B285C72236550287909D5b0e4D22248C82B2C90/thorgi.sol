// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol";
import "./ECDSA.sol";
import "./approving-bone.sol";
import "./approving-corgis.sol";
import "./ERC721A.sol";

contract Thorgi is ERC20Burnable, Ownable {
    bool public corgiStakingLive = false;
    bool public boneStakingLive = false;
    bool public pupStakingLive = false;
    bool public airdropLive = false;
    uint256 public _totalSupply = 100000000 * 10**18;
    uint256 public _mintableSupply = 50000000 * 10**18;
    uint256 public _initialSupply = 50000000 * 10**18;

    uint256 public constant pupRatePerDay = 11574074074074; // 1 $THORGI per day for staked pups
    uint256 public constant corgiRatePerDay = 34722222222222; // 3 $THORGI per day for staked corgis

    mapping(uint256 => uint256) internal corgTimeStaked;
    mapping(uint256 => address) internal corgiOwner;
    mapping(address => uint256[]) internal corgiTokenIds;

    mapping(uint256 => uint256) internal pupTimeStaked;
    mapping(uint256 => address) internal pupOwner;
    mapping(address => uint256[]) internal pupTokenIds;

    mapping(uint256 => uint256) internal boneTimeStaked;
    mapping(uint256 => address) internal boneOwner;
    mapping(address => uint256[]) internal boneTokenIds;

    mapping(address => bool) public claimedAirdrop;
    mapping(address => uint256) addressBlockBought;
    address signer;

    address public constant corgiAddress = 0x10F5A77Fc1324d989810823eaDa2CfE8C01716B0;
    address public constant pupAddress = 0x10F5A77Fc1324d989810823eaDa2CfE8C01716B0;
    address public constant boneAddress = 0x00f54A797d13F868b2d784D98b5B270Ff4e9aFA6;

    IERC721Enumerable private constant corgiIERC721Enumerable = IERC721Enumerable(corgiAddress);
    IERC721Enumerable private pupContract;
    IERC721Enumerable private constant boneIERC721Enumerable = IERC721Enumerable(boneAddress);
    constructor(address _signer) ERC20("Thorgi", "THORGI") {
        signer = _signer;
        _mint(msg.sender, _initialSupply);
    }

    modifier isSecured(uint8 mintType) {
        require(addressBlockBought[msg.sender] < block.timestamp, "CANNOT_TRANSACT_THE_SAME_BLOCK");
        require(tx.origin == msg.sender,"CONTRACTS_NOT_ALLOWED_TO_MINT");

        if(mintType == 1) {
            require(corgiStakingLive, "CORGI_STAKING_IS_NOT_YET_ACTIVE");
        }
        if(mintType == 2) {
            require(boneStakingLive, "BONE_STAKING_IS_NOT_YET_ACTIVE");
        }
        if(mintType == 3) {
            require(pupStakingLive, "PUP_STAKING_IS_NOT_YET_ACTIVE");
        }

        if(mintType == 4) {
            require(airdropLive, "CLAIMING_IS_NOT_YET_ACTIVE");
        }
        _;
    }

    function getStakedCorgi(address _owner) public view returns (uint256[] memory) {
        return corgiTokenIds[_owner];
    }

    function getStakedPup(address _owner) public view returns (uint256[] memory) {
        return pupTokenIds[_owner];
    }

    function getStakedBone(address _owner) public view returns (uint256[] memory) {
        return boneTokenIds[_owner];
    }

    function getTotalStakedCount(address _owner) public view returns (uint256) {
        return corgiTokenIds[_owner].length + pupTokenIds[_owner].length + boneTokenIds[_owner].length;
    }

    function getCorgiOwner(uint256 tokenId) public view returns (address) {
        return corgiOwner[tokenId];
    }
    
    function getPupOwner(uint256 tokenId) public view returns (address) {
        return pupOwner[tokenId];
    }
    
    function getBoneOwner(uint256 tokenId) public view returns (address) {
        return boneOwner[tokenId];
    }

    function toggleCorgiStaking() external onlyOwner {
        corgiStakingLive = !corgiStakingLive;
    }

    function toggleBoneStaking() external onlyOwner {
        boneStakingLive = !boneStakingLive;
    }

    function togglePupStaking() external onlyOwner {
        pupStakingLive = !pupStakingLive;
    }

    function toggleAirdrop() external onlyOwner {
        airdropLive = !airdropLive;
    }

    function removeTokenIdFromArray(uint256[] storage array, uint256 tokenId) internal {
        uint256 length = array.length;
        for (uint256 i = 0; i < length; i++) {
            if (array[i] == tokenId) {
                length--;
                if (i < length) {
                    array[i] = array[length];
                }
                array.pop();
                break;
            }
        }
    }

    function stakeCorgis(uint256[] memory tokenIds) external isSecured(1) {
        require(totalSupply() <= _totalSupply, "NO_MORE_MINTABLE_SUPPLY");
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 id = tokenIds[i];
            require(corgiIERC721Enumerable.ownerOf(id) == msg.sender && corgiOwner[id] == address(0), "TOKEN_IS_NOT_YOURS");
            corgiIERC721Enumerable.transferFrom(msg.sender, address(this), id);

            corgiTokenIds[msg.sender].push(id);
            corgTimeStaked[id] = block.timestamp;
            corgiOwner[id] = msg.sender;
        }
    }

    function stakePups(uint256[] memory tokenIds) external isSecured(3) {
        require(totalSupply() <= _totalSupply, "NO_MORE_MINTABLE_SUPPLY");
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 id = tokenIds[i];
            require(pupContract.ownerOf(id) == msg.sender && pupOwner[id] == address(0), "TOKEN_IS_NOT_YOURS");
            pupContract.transferFrom(msg.sender, address(this), id);

            pupTokenIds[msg.sender].push(id);
            pupTimeStaked[id] = block.timestamp;
            pupOwner[id] = msg.sender;
        }
    }

    function stakeBones(uint256 tokenId) external isSecured(2) {
        require(totalSupply() <= _totalSupply, "NO_MORE_MINTABLE_SUPPLY");
        require(boneTokenIds[msg.sender].length < 2, "You can only stake 1 bone");
        require(boneIERC721Enumerable.ownerOf(tokenId) == msg.sender && boneOwner[tokenId] == address(0), "TOKEN_IS_NOT_YOURS");
        boneIERC721Enumerable.transferFrom(msg.sender, address(this), tokenId);

        boneTokenIds[msg.sender].push(tokenId);
        boneTimeStaked[tokenId] = block.timestamp;
        boneOwner[tokenId] = msg.sender;
    }

    // UNSTAKE FUNCTIONS

    function unstakeCorgis(uint256[] memory tokenIds) external {
        uint256 totalRewards = 0;
        uint256[] memory stakedBone = getStakedBone(msg.sender);

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 id = tokenIds[i];
            require(corgiOwner[id] == msg.sender, "Not Owner");

            corgiIERC721Enumerable.transferFrom(address(this), msg.sender, id);
            if(stakedBone.length > 0) {
                uint256 numOfDays = ((block.timestamp - corgTimeStaked[id]) / 1 days) * 1e18;
                uint256 reward = ((block.timestamp - corgTimeStaked[id]) * corgiRatePerDay);
                uint256 multiplier = 1e18 + (numOfDays * 150 / 10000);
                totalRewards += (reward * multiplier) / 1e18;
            } else {
                totalRewards += ((block.timestamp - corgTimeStaked[id]) * corgiRatePerDay);
            }

            removeTokenIdFromArray(corgiTokenIds[msg.sender], id);
            corgiOwner[id] = address(0);
        }
        if(totalSupply() <= _totalSupply) {
            _mint(msg.sender, totalRewards);
        }
    }

    function unstakePups(uint256[] memory tokenIds) external {
        uint256 totalRewards = 0;
        uint256[] memory stakedBone = getStakedBone(msg.sender);

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 id = tokenIds[i];
            require(pupOwner[id] == msg.sender, "Not Owner");

            pupContract.transferFrom(address(this), msg.sender, id);

            if(stakedBone.length > 0) {
                uint256 numOfDays = ((block.timestamp - pupTimeStaked[id]) / 1 days) * 1e18;
                uint256 reward = ((block.timestamp - pupTimeStaked[id]) * pupRatePerDay);
                uint256 multiplier = 1e18 + (numOfDays * 150 / 10000);
                totalRewards += (reward * multiplier) / 1e18;
            } else {
                totalRewards += ((block.timestamp - pupTimeStaked[id]) * pupRatePerDay);
            }

            removeTokenIdFromArray(pupTokenIds[msg.sender], id);
            pupOwner[id] = address(0);
        }

        if(totalSupply() <= _totalSupply) {
            _mint(msg.sender, totalRewards);
        }
    }

    function unstakeBones(uint256 tokenIds) external {
        require(boneOwner[tokenIds] == msg.sender, "Not Owner");

        boneIERC721Enumerable.transferFrom(address(this), msg.sender, tokenIds);

        removeTokenIdFromArray(boneTokenIds[msg.sender], tokenIds);
        boneOwner[tokenIds] = address(0);
    }

    function unstakeAll() external {
        require(getTotalStakedCount(msg.sender) > 0, "You must have staked at least one");
        uint256 totalRewards = 0;
        uint256[] memory stakedBone = getStakedBone(msg.sender);

        for (uint256 i = corgiTokenIds[msg.sender].length; i > 0; i--) {
            uint256 tokenId = corgiTokenIds[msg.sender][i - 1];

            corgiIERC721Enumerable.transferFrom(address(this), msg.sender, tokenId);
            if(stakedBone.length > 0) {
                uint256 numOfDays = ((block.timestamp - corgTimeStaked[tokenId]) / 1 days) * 1e18;
                uint256 reward = ((block.timestamp - corgTimeStaked[tokenId]) * corgiRatePerDay);
                uint256 multiplier = 1e18 + (numOfDays * 150 / 10000);
                totalRewards += (reward * multiplier) / 1e18;
            } else {
                totalRewards += ((block.timestamp - corgTimeStaked[tokenId]) * corgiRatePerDay);
            }
            removeTokenIdFromArray(corgiTokenIds[msg.sender], tokenId);
            corgiOwner[tokenId] = address(0);
        }
        
        for (uint256 i = pupTokenIds[msg.sender].length; i > 0; i--) {
            uint256 pupTokenId = pupTokenIds[msg.sender][i - 1];

            pupContract.transferFrom(address(this), msg.sender, pupTokenId);
            if(stakedBone.length > 0) {
                uint256 numOfDays = ((block.timestamp - pupTimeStaked[pupTokenId]) / 1 days) * 1e18;
                uint256 reward = ((block.timestamp - pupTimeStaked[pupTokenId]) * corgiRatePerDay);
                uint256 multiplier = 1e18 + (numOfDays * 150 / 10000);
                totalRewards += (reward * multiplier) / 1e18;
            } else {
                totalRewards += ((block.timestamp - pupTimeStaked[pupTokenId]) * pupRatePerDay);
            }
            removeTokenIdFromArray(pupTokenIds[msg.sender], pupTokenId);
            pupOwner[pupTokenId] = address(0);
        }

        if(totalSupply() <= _totalSupply) {
            _mint(msg.sender, totalRewards);
        }
    }

    // CLAIM FUNCTIONS
    function claimFromCorgi() external {
        require(corgiTokenIds[msg.sender].length > 0, "NO_STAKED_CORGI");
        uint256 totalRewards = 0;
        uint256[] memory stakedBone = getStakedBone(msg.sender);

        uint256[] memory corgiTokens = corgiTokenIds[msg.sender];
        for (uint256 i = 0; i < corgiTokens.length; i++) {
            uint256 id = corgiTokens[i];
            require(corgiOwner[id] == msg.sender, "You are not the owner");
            if(stakedBone.length > 0) {
                uint256 numOfDays = ((block.timestamp - corgTimeStaked[id]) / 1 days) * 1e18;
                uint256 reward = ((block.timestamp - corgTimeStaked[id]) * corgiRatePerDay);
                uint256 multiplier = 1e18 + (numOfDays * 150 / 10000);
                totalRewards += (reward * multiplier) / 1e18;
            } else { 
                totalRewards += ((block.timestamp - corgTimeStaked[id]) * corgiRatePerDay);
            }
            corgTimeStaked[id] = block.timestamp;
        }

        _mint(msg.sender, totalRewards);
    }
    
    function claimFromPup() external {
        require(pupTokenIds[msg.sender].length > 0, "NO_STAKED_CORGI");
        uint256 totalRewards = 0;
        uint256[] memory stakedBone = getStakedBone(msg.sender);

        uint256[] memory pupTokens = pupTokenIds[msg.sender];
        for (uint256 i = 0; i < pupTokens.length; i++) {
            uint256 id = pupTokens[i];
            require(pupOwner[id] == msg.sender, "You are not the owner");
            if(stakedBone.length > 0) {
                uint256 numOfDays = ((block.timestamp - pupTimeStaked[id]) / 1 days) * 1e18;
                uint256 reward = ((block.timestamp - pupTimeStaked[id]) * pupRatePerDay);
                uint256 multiplier = 1e18 + (numOfDays * 150 / 10000);
                totalRewards += (reward * multiplier) / 1e18;
            } else { 
                totalRewards += ((block.timestamp - pupTimeStaked[id]) * pupRatePerDay);
            }
            pupTimeStaked[id] = block.timestamp;
        }

        _mint(msg.sender, totalRewards);
    }

    function claimAll() external {
        uint256 totalRewards = 0;
        uint256[] memory stakedBone = getStakedBone(msg.sender);

        uint256[] memory corgiTokens = corgiTokenIds[msg.sender];
        for (uint256 i = 0; i < corgiTokens.length; i++) {
            uint256 id = corgiTokens[i];
            require(corgiOwner[id] == msg.sender, "You are not the owner");
            if(stakedBone.length > 0) {
                uint256 numOfDays = ((block.timestamp - corgTimeStaked[id]) / 1 days) * 1e18;
                uint256 reward = ((block.timestamp - corgTimeStaked[id]) * corgiRatePerDay);
                uint256 multiplier = 1e18 + (numOfDays * 150 / 10000);
                totalRewards += (reward * multiplier) / 1e18;
            } else { 
                totalRewards += ((block.timestamp - corgTimeStaked[id]) * corgiRatePerDay);
            }
            corgTimeStaked[id] = block.timestamp;
        }
        
        uint256[] memory pupTokens = pupTokenIds[msg.sender];
        for (uint256 i = 0; i < pupTokens.length; i++) {
            uint256 id = pupTokens[i];
            require(pupOwner[id] == msg.sender, "You are not the owner");
            if(stakedBone.length > 0) {
                uint256 numOfDays = ((block.timestamp - pupTimeStaked[id]) / 1 days) * 1e18;
                uint256 reward = ((block.timestamp - pupTimeStaked[id]) * pupRatePerDay);
                uint256 multiplier = 1e18 + (numOfDays * 150 / 10000);
                totalRewards += (reward * multiplier) / 1e18;
            } else { 
                totalRewards += ((block.timestamp - pupTimeStaked[id]) * pupRatePerDay);
            }
            pupTimeStaked[id] = block.timestamp;
        }

        _mint(msg.sender, totalRewards);
    }

    function checkRewardsbyCorgiIds(uint256 tokenId) external view returns (uint256) {
        require(corgiOwner[tokenId] != address(0), "TOKEN_NOT_BURIED");
        uint256 totalRewards = 0;
        uint256[] memory stakedBone = getStakedBone(msg.sender);

        if(stakedBone.length > 0) {
            uint256 numOfDays = ((block.timestamp - corgTimeStaked[tokenId]) / 1 days) * 1e18;
            uint256 reward = ((block.timestamp - corgTimeStaked[tokenId]) * corgiRatePerDay);
            uint256 multiplier = 1e18 + (numOfDays * 150 / 10000);
            totalRewards += (reward * multiplier) / 1e18;
        } else { 
            totalRewards += ((block.timestamp - corgTimeStaked[tokenId]) * corgiRatePerDay);
        }

        return totalRewards;
    }

    function checkRewardsPupsIds(uint256 tokenId) external view returns (uint256) {
        require(pupOwner[tokenId] != address(0), "TOKEN_NOT_BURIED");
        uint256 totalRewards = 0;
        uint256[] memory stakedBone = getStakedBone(msg.sender);

        if(stakedBone.length > 0) {
            uint256 numOfDays = ((block.timestamp - pupTimeStaked[tokenId]) / 1 days) * 1e18;
            uint256 reward = ((block.timestamp - pupTimeStaked[tokenId]) * pupRatePerDay);
            uint256 multiplier = 1e18 + (numOfDays * 150 / 10000);
            totalRewards += (reward * multiplier) / 1e18;
        } else { 
            totalRewards += ((block.timestamp - pupTimeStaked[tokenId]) * pupRatePerDay);
        }
        return totalRewards;
    }

    function checkAllRewardsFromCorgis(address _owner) external view returns (uint256) {
        uint256 totalRewards = 0;
        uint256[] memory stakedBone = getStakedBone(_owner);
        uint256[] memory corgis = corgiTokenIds[_owner];

        for (uint256 i = 0; i < corgis.length; i++) {
            if(stakedBone.length > 0) {
                uint256 numOfDays = ((block.timestamp - corgTimeStaked[corgis[i]]) / 1 days) * 1e18;
                uint256 reward = ((block.timestamp - corgTimeStaked[corgis[i]]) * corgiRatePerDay);
                uint256 multiplier = 1e18 + (numOfDays * 150 / 10000);
                totalRewards += (reward * multiplier) / 1e18;
            } else { 
                totalRewards += ((block.timestamp - corgTimeStaked[corgis[i]]) * corgiRatePerDay);
            }
        }

        return totalRewards;
    }
    

    function checkAllRewardsFromPups(address _owner) external view returns (uint256) {
        uint256 totalRewards = 0;
        uint256[] memory stakedBone = getStakedBone(_owner);
        uint256[] memory pups = pupTokenIds[_owner];

        for (uint256 i = 0; i < pups.length; i++) {
            if(stakedBone.length > 0) {
                uint256 numOfDays = ((block.timestamp - pupTimeStaked[pups[i]]) / 1 days) * 1e18;
                uint256 reward = ((block.timestamp - pupTimeStaked[pups[i]]) * pupRatePerDay);
                uint256 multiplier = 1e18 + (numOfDays * 150 / 10000);
                totalRewards += (reward * multiplier) / 1e18;
            } else { 
                totalRewards += ((block.timestamp - pupTimeStaked[pups[i]]) * pupRatePerDay);
            }
        }

        return totalRewards;
    }

    function checkAllRewards(address _owner) external view returns (uint256) {
        uint256 totalRewards = 0;
        uint256[] memory stakedBone = getStakedBone(_owner);

        uint256[] memory corgis = corgiTokenIds[_owner];
        for (uint256 i = 0; i < corgis.length; i++) {
            if(stakedBone.length > 0) {
                uint256 numOfDays = ((block.timestamp - corgTimeStaked[corgis[i]]) / 1 days) * 1e18;
                uint256 reward = ((block.timestamp - corgTimeStaked[corgis[i]]) * corgiRatePerDay);
                uint256 multiplier = 1e18 + (numOfDays * 150 / 10000);
                totalRewards += (reward * multiplier) / 1e18;
            } else { 
                totalRewards += ((block.timestamp - corgTimeStaked[corgis[i]]) * corgiRatePerDay);
            }
        }
        
        uint256[] memory pupTokens = pupTokenIds[_owner];
        for (uint256 i = 0; i < pupTokens.length; i++) {
             if(stakedBone.length > 0) {
                uint256 numOfDays = ((block.timestamp - pupTimeStaked[pupTokens[i]]) / 1 days) * 1e18;
                uint256 reward = ((block.timestamp - pupTimeStaked[pupTokens[i]]) * pupRatePerDay);
                uint256 multiplier = 1e18 + (numOfDays * 150 / 10000);
                totalRewards += (reward * multiplier) / 1e18;
            } else { 
                totalRewards += ((block.timestamp - pupTimeStaked[pupTokens[i]]) * pupRatePerDay);
            }
        }

        return totalRewards;
    }

    // AIRDROP

    function airDrop(uint256 amount, uint64 expireTime, bytes memory sig) external isSecured(4) {
        bytes32 digest = keccak256(abi.encodePacked(msg.sender, amount, expireTime));
        require(isAuthorized(sig, digest),"NOT_ELIGIBLE_FOR_AIRDROP");
        require(amount <= _mintableSupply, "AMOUNT_SHOULD_BE_LESS_THAN_SUPPLY");
        require(totalSupply() <= _totalSupply, "NO_MORE_MINTABLE_SUPPLY");
        require(!claimedAirdrop[msg.sender], "ALREADY_CLAIMED");

        claimedAirdrop[msg.sender] = true;
        _mint(msg.sender, amount * 1e18);
    }

    function setSigner(address _signer) external onlyOwner{
        signer = _signer;
    }

    function setPupContract(address _pupContractAddress) external onlyOwner{
        pupContract = ERC721A(_pupContractAddress);
    }

    function isAuthorized(bytes memory sig, bytes32 digest) private view returns (bool) {
        return ECDSA.recover(digest, sig) == signer;
    }
}