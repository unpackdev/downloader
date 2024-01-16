// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20Burnable.sol";
import "./Ownable.sol";
import "./ECDSA.sol";

interface iCorp {
    function ownerOf(uint256 tokenId) external view returns (address);

    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external;
}

contract CORP is ERC20Burnable, Ownable {
     uint256 public _maxSupply = 45000000 ether;
    uint256 public _initialSupply = 12500000 ether;
    iCorp public Corp;
    address corpContract;

    uint256 public constant BASE_RATE = 5 ether;
    uint256 public START;
    bool rewardPaused = false;

    uint256 TIME_RATE = 86400;

    uint256 MINT_STAKE_BONUS = 20 ether;
    //Staking

    //addressStaked
    mapping(address => uint256[]) public addressStaked;
    //tokenStakeTime
    mapping(uint256 => uint256) public tokenStakeTime;
    //tokenStaker
    mapping(uint256 => address) public tokenStaker;
    //totalStakedTime
    mapping(uint256 => uint256) public totalTokenStakedTime;

    struct UserData {
        bool firstTimeStaker;
        bool bonusActive;
        uint256 mintAndStaked;
    }

    mapping(address => UserData) public userData;

    constructor(address CorpAddress) ERC20("Corp", "CORP") {
        _mint(msg.sender, _initialSupply);
        Corp = iCorp(CorpAddress);
        corpContract = CorpAddress;
        START = block.timestamp;
    }

    //New Functionalities

    function getStakedTokens() public view returns (uint256[] memory) {
        return addressStaked[msg.sender];
    }

    function getStakedAmount(address _address) public view returns (uint256) {
        return addressStaked[_address].length;
    }

    function getStaker(uint256 tokenId) public view returns (address) {
        return tokenStaker[tokenId];
    }

    function getAllRewards(address staker) public view returns (uint256) {
        uint256 totalRewards = 0;

        uint256[] memory tokens = addressStaked[staker];
        for (uint256 i = 0; i < tokens.length; i++) {
            totalRewards += getPendingRewards(tokens[i]);
        }
        if (userData[staker].bonusActive) {
            totalRewards = totalRewards + ((totalRewards * 25000) / 100000);
        }
        if (userData[staker].mintAndStaked > 0) {
            totalRewards =
                totalRewards +
                (userData[staker].mintAndStaked * MINT_STAKE_BONUS);
        }
        return totalRewards;
    }

    function stakeByIds(uint256[] calldata tokenIds) external stakingEnabled {
        require(totalSupply() <= _maxSupply, "NO_MORE_MINTABLE_SUPPLY");
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 id = tokenIds[i];
            Corp.transferFrom(msg.sender, address(this), id);

            addressStaked[msg.sender].push(id);
            tokenStakeTime[id] = block.timestamp;
            tokenStaker[id] = msg.sender;
        }
        if (!userData[msg.sender].firstTimeStaker) {
            userData[msg.sender].firstTimeStaker = true;
            userData[msg.sender].bonusActive = true;
        }
    }

    function mintAndStake(address owner, uint256[] calldata tokenIds)
        external
        stakingEnabled
    {
        require(totalSupply() <= _maxSupply, "NO_MORE_MINTABLE_SUPPLY");
        require(msg.sender == corpContract, "NFT_CONTRACT_ONLY");
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 id = tokenIds[i];
            Corp.transferFrom(owner, address(this), id);

            addressStaked[owner].push(id);
            tokenStakeTime[id] = block.timestamp;
            tokenStaker[id] = owner;
            userData[owner].mintAndStaked += 1;
        }
        if (!userData[owner].firstTimeStaker) {
            userData[owner].firstTimeStaker = true;
            userData[owner].bonusActive = true;
        }
    }

    function unstakeByIds(uint256[] calldata tokenIds) external {
        uint256 totalRewards = 0;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 id = tokenIds[i];
            require(tokenStaker[id] == msg.sender, "NEEDS_TO_BE_OWNER");

            Corp.transferFrom(address(this), msg.sender, id);
            totalRewards += getPendingRewards(id);

            totalTokenStakedTime[id] += block.timestamp - tokenStakeTime[id];
            removeTokenIdFromArray(addressStaked[msg.sender], id);
            tokenStaker[id] = address(0);
        }
        userData[msg.sender].bonusActive = false;

        if (totalSupply() <= _maxSupply) {
            _mint(msg.sender, totalRewards);
        }
    }

    function unstakeAll() external {
        require(totalSupply() <= _maxSupply, "NO_MORE_MINTABLE_SUPPLY");
        require(getStakedAmount(msg.sender) > 0, "NO_TOKENS_STAKED");
        uint256 totalRewards = 0;

        for (uint256 i = addressStaked[msg.sender].length; i > 0; i--) {
            uint256 id = addressStaked[msg.sender][i - 1];

            Corp.transferFrom(address(this), msg.sender, id);
            totalRewards += getPendingRewards(id);

            totalTokenStakedTime[id] += block.timestamp - tokenStakeTime[id];
            addressStaked[msg.sender].pop();
            tokenStaker[id] = address(0);
        }
        userData[msg.sender].bonusActive = false;
        _mint(msg.sender, totalRewards);
    }

    function claimAll() external {
        require(totalSupply() <= _maxSupply, "NO_MORE_MINTABLE_SUPPLY");
        uint256 totalRewards = 0;

        uint256[] memory tokens = addressStaked[msg.sender];
        require(tokens.length > 0, "NO_TOKENS_STAKED");
        for (uint256 i = 0; i < tokens.length; i++) {
            uint256 id = tokens[i];

            totalRewards += getPendingRewards(id);
            tokenStakeTime[id] = block.timestamp;
        }
        if (userData[msg.sender].bonusActive) {
            totalRewards = totalRewards + ((totalRewards * 25000) / 100000);
        }
        if (userData[msg.sender].mintAndStaked > 0) {
            totalRewards =
                totalRewards +
                (userData[msg.sender].mintAndStaked * MINT_STAKE_BONUS);
            userData[msg.sender].mintAndStaked = 0;
        }
        _mint(msg.sender, totalRewards);
    }

    function removeTokenIdFromArray(uint256[] storage array, uint256 tokenId)
        internal
    {
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

    function purchaseBurn(address user, uint256 amount) external {
        require(tx.origin == user, "Only the user can purchase and burn");
        _burn(user, amount);
    }

    function getPendingRewards(uint256 tokenId) public view returns (uint256) {
        return
            ((BASE_RATE) * (block.timestamp - tokenStakeTime[tokenId])) /
            TIME_RATE;
    }

    function toggleReward() public onlyOwner {
        rewardPaused = !rewardPaused;
    }

    modifier stakingEnabled() {
        require(!rewardPaused, "NOT_LIVE");
        _;
    }
}
