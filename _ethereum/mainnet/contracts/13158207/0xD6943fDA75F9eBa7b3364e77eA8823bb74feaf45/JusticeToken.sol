// contracts/JUSTICEToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20Burnable.sol";
import "./Ownable.sol";
import "./Math.sol";


interface IChubbies {
    function ownerOf(uint tokenId) external view returns (address owner);
    function tokensOfOwner(address _owner) external view returns(uint[] memory);
}

interface IBitties {
    function ownerOf(uint tokenId) external view returns (address owner);
    function tokensOfOwner(address _owner) external view returns(uint[] memory);
    function traitsForTokenId(uint _tokenId) external view returns (
        uint[] memory traits, 
        uint setModifier, 
        uint combinedCount, 
        uint powerClass, 
        uint power
    );
}


contract JusticeToken is ERC20Burnable, Ownable {
    IChubbies private chubbiesContract;
    IBitties private bittiesContract;

    mapping(uint => uint) internal lastWithdrawTimes;

    uint constant public CHUBBIE_DAILY_REWARD = 50 ether;
    uint constant internal MAX_CHUBBIES = 10000;

    uint public contractCreationTime;

    event RewardPaid(address indexed user, uint reward);

    constructor() ERC20("Justice", "JSTICE") {
        _mint(msg.sender, 1000000 ether);
        contractCreationTime = block.timestamp - 86400;
    }

    function setContracts(address _chubbiesContract, address _bittiesContract) public {
        chubbiesContract = IChubbies(_chubbiesContract);
        bittiesContract = IBitties(_bittiesContract);
    }

    // Minting Rewards

    function getChubbieReward(uint _tokenId) public view returns (uint reward) {
        uint lastWithdrawTime = Math.max(lastWithdrawTimes[_tokenId], contractCreationTime);
        reward = (block.timestamp - lastWithdrawTime) * CHUBBIE_DAILY_REWARD / 86400;
    }

    function getBittieReward(uint _tokenId) public view returns (uint reward) {
        uint lastWithdrawTime = Math.max(lastWithdrawTimes[_tokenId + MAX_CHUBBIES], contractCreationTime);
        (, , , uint powerClass, ) = bittiesContract.traitsForTokenId(_tokenId);
        reward = (block.timestamp - lastWithdrawTime) * (1 << (powerClass - 1)) * 1 ether / 86400;
    }

    function getAllReward() public view returns (uint) {
        uint chubbiesReward = 0;
        uint bittiesReward = 0;

        if (address(chubbiesContract) != address(0)) {
            uint[] memory ownedChubbies = chubbiesContract.tokensOfOwner(msg.sender);
            for (uint i = 0; i < ownedChubbies.length; i++) {
                chubbiesReward += getChubbieReward(ownedChubbies[i]);
            }
        }

        if (address(bittiesContract) != address(0)) {
            uint[] memory ownedBitties = bittiesContract.tokensOfOwner(msg.sender);
            for (uint i = 0; i < ownedBitties.length; i++) {
                bittiesReward += getBittieReward(ownedBitties[i]);
            }
        }

        return chubbiesReward + bittiesReward;
    }

    function mintChubbieReward(uint _tokenId) external {
        require(chubbiesContract.ownerOf(_tokenId) == msg.sender, "Not the correct owner");

        uint reward = getChubbieReward(_tokenId);
        _mint(msg.sender, reward);
        lastWithdrawTimes[_tokenId] = block.timestamp;
        emit RewardPaid(msg.sender, reward);
    }

    function mintBittieReward(uint _tokenId) external {
        require(bittiesContract.ownerOf(_tokenId) == msg.sender, "Not the correct owner");

        uint reward = getBittieReward(_tokenId);
        _mint(msg.sender, reward);
        lastWithdrawTimes[_tokenId + MAX_CHUBBIES] = block.timestamp;
        emit RewardPaid(msg.sender, reward);
    }

    function mintAllReward() external returns (uint reward) {
        reward = getAllReward();

        if (address(chubbiesContract) != address(0)) {
            uint[] memory ownedChubbies = chubbiesContract.tokensOfOwner(msg.sender);
            for (uint i = 0; i < ownedChubbies.length; i++) {
                lastWithdrawTimes[ownedChubbies[i]] = block.timestamp;
            }
        }
        
        if (address(bittiesContract) != address(0)) {
            uint[] memory ownedBitties = bittiesContract.tokensOfOwner(msg.sender);
            for (uint i = 0; i < ownedBitties.length; i++) {
                lastWithdrawTimes[ownedBitties[i] + MAX_CHUBBIES] = block.timestamp;
            }
        }
        
        _mint(msg.sender, reward);
        emit RewardPaid(msg.sender, reward);
    }

    function updateLastWithdrawTime(uint _tokenId) external {
        require(msg.sender == address(bittiesContract), "Must be updated from BittyBot Contract");

        lastWithdrawTimes[_tokenId + MAX_CHUBBIES] = block.timestamp;
    }
}