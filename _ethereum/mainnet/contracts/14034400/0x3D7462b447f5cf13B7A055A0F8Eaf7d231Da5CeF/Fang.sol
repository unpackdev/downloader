// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;
import "./ERC20.sol";
import "./SafeMath.sol";
import "./ERC721.sol";
import "./Ownable.sol";

abstract contract Contract721 {
    // This doesn't have to match the real contract name. Call it what you like.
    function walletOfOwner(address _owner) public view virtual returns (uint256[] memory);
}

contract DivineWolvesFangToken is ERC20("Fang", "FANG"), Ownable {
    using SafeMath for uint256;

    address public divineWolvesERC721;
    address private contractExtension;

    uint256 public BASE_RATE = 5 ether;
    uint256 public REWARD_INTERVAL = 86400; // 24 hours
    uint256 public constant START = 1640995200;
    // 1 Jan 2022 , 00:00

    bool private rewardsPaused = false;
    mapping(uint256 => uint256) public lastUpdated;

    event RewardPaid(address indexed user, uint256 reward);

    modifier onlyExtensionContract() {
        require(msg.sender == contractExtension);
        _;
    }

    constructor(address _direwolves721Contract) {
        divineWolvesERC721 = _direwolves721Contract;
    }

    //initital minting for Launch pads | Liquidity
    function mint(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);
    }

    //utilities
    function setBaseRate(uint256 _amount) public onlyOwner {
        //wei
        BASE_RATE = _amount;
    }

    function setRewatdInterval(uint256 _interval) public onlyOwner {
        //seconds 8600 == one day
        REWARD_INTERVAL = _interval;
    }

    function toggleRewardsPause() public onlyOwner {
        rewardsPaused = !rewardsPaused;
    }

    //extending functions for breeding
    function setContractExtension(address _contractExtenstion) public onlyOwner {
        contractExtension = _contractExtenstion;
    }

    function mintFromExtentionContract(address _to, uint256 _amount) external onlyExtensionContract {
        _mint(_to, _amount);
    }

    function burnFromExtentionContract(address _to, uint256 _amount) external onlyExtensionContract {
        _burn(_to, _amount);
    }

    function getReward() public {
        require(!rewardsPaused, "Rewards are paused");
        uint256 reward = getTotalClaimable(msg.sender);
        _mint(msg.sender, reward);
        emit RewardPaid(msg.sender, reward);
        uint256[] memory wallet = Contract721(divineWolvesERC721).walletOfOwner(msg.sender);
        for (uint256 i; i < wallet.length; i++) {
            lastUpdated[wallet[i]] = block.timestamp;
        }
    }

    function getTotalClaimable(address _user) public view returns (uint256) {
        uint256 time = block.timestamp;
        //Get Wallet of owner
        uint256[] memory wallet = Contract721(divineWolvesERC721).walletOfOwner(_user);
        uint256 clamableRewards;

        for (uint256 i; i < wallet.length; i++) {
            if (lastUpdated[wallet[i]] == 0) {
                clamableRewards += BASE_RATE.mul(time.sub(START)).div(REWARD_INTERVAL);
            } else {
                clamableRewards += BASE_RATE.mul(time.sub(lastUpdated[wallet[i]])).div(REWARD_INTERVAL);
            }
        }
        return clamableRewards;
    }
}
