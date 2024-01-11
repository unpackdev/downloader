// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20Burnable.sol";
import "./Ownable.sol";
import "./ECDSA.sol";

interface iMetakages {
    function ownerOf(uint256 tokenId) external view returns (address);
        function transferFrom(address _from, address _to, uint256 _tokenId) external;
    }

contract KAGE is ERC20Burnable, Ownable {
    iMetakages public Metakages;

    uint256 public constant BASE_RATE = 1 ether;
    uint256 public START;
    bool rewardPaused = false;

    uint256 TIME_RATE = 86400;

    //Staking

    //addressStaked
    mapping(address => uint256[]) internal addressStaked;
    //tokenStakeTime
    mapping(uint256 => uint256) internal tokenStakeTime;
    //tokenStaker
    mapping(uint256 => address) internal tokenStaker;

    constructor(address MetakagesAddress) ERC20("Kage", "KAGE") {
        _mint(msg.sender, 250000 ether);
        Metakages = iMetakages(MetakagesAddress);
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

        return totalRewards;
    }

    function stakeByIds(uint256[] calldata tokenIds)
        external
        stakingEnabled
    {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 id = tokenIds[i];
            Metakages.transferFrom(msg.sender, address(this), id);

            addressStaked[msg.sender].push(id);
            tokenStakeTime[id] = block.timestamp;
            tokenStaker[id] = msg.sender;
        }
    }

    function unstakeByIds(uint256[] calldata tokenIds) external {
        uint256 totalRewards = 0;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 id = tokenIds[i];
            require(tokenStaker[id] == msg.sender, "NEEDS_TO_BE_OWNER");

            Metakages.transferFrom(address(this), msg.sender, id);
            totalRewards += getPendingRewards(id);

            removeTokenIdFromArray(addressStaked[msg.sender], id);
            tokenStaker[id] = address(0);
        }


        _mint(msg.sender, totalRewards);
    }

    function unstakeAll() external {
        require(getStakedAmount(msg.sender) > 0, "NO_TOKENS_STAKED");
        uint256 totalRewards = 0;

        for (uint256 i = addressStaked[msg.sender].length; i > 0; i--) {
            uint256 id = addressStaked[msg.sender][i - 1];

            Metakages.transferFrom(address(this), msg.sender, id);
            totalRewards += getPendingRewards(id);

            addressStaked[msg.sender].pop();
            tokenStaker[id] = address(0);
        }

        _mint(msg.sender, totalRewards);
    }

    function claimAll() external {
        uint256 totalRewards = 0;

        uint256[] memory tokens = addressStaked[msg.sender];
        require(tokens.length > 0, "NO_TOKENS_STAKED");
        for (uint256 i = 0; i < tokens.length; i++) {
            uint256 id = tokens[i];

            totalRewards += getPendingRewards(id);
            tokenStakeTime[id] = block.timestamp;
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

        modifier stakingEnabled {
        require(!rewardPaused, "NOT_LIVE");
        _;
    }
}
