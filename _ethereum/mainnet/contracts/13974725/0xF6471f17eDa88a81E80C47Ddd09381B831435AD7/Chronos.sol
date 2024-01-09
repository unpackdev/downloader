// SPDX-License-Identifier: MIT
//CHRONOS IS A UTILITY TOKEN FOR THE PXQUEST ECOSYSTEM.
//$CHRONOS is NOT an investment and has NO economic value.
//It will be earned by active holding within the PXQUEST ecosystem. Each Genesis Adventurer will be eligible to claim tokens at a rate of 5 $CHRONOS per day.

pragma solidity ^0.8.0;
import "./ERC20.sol";
import "./Ownable.sol";

// Adventurer contract interface
interface iAdv {
    function walletOfOwner(address address_)
        external
        view
        returns (uint256[] memory);
}

contract Chronos is ERC20, Ownable {
    iAdv public AdvContract;

    uint256 public constant BASE_RATE = 5 ether;
    uint256 public START;
    bool rewardPaused = false;

    mapping(address => uint256) public rewards;
    mapping(address => uint256) public lastUpdate;

    mapping(uint256 => uint256) public stakedAdv;

    struct Perms {
        bool Grantee;
        bool Burner;
        bool Staker;
    }

    mapping(address => Perms) public permsMap;

    event AdvStaked(uint256 advId, uint256 util);

    constructor(address advContract) ERC20("CHRONOS", "CHR") {
        AdvContract = iAdv(advContract);
        START = block.timestamp;
    }

    //called before transfer
    function updateReward(address from, address to) external {
        require(msg.sender == address(AdvContract));
        if (from != address(0)) {
            rewards[from] += getPendingReward(from);
            lastUpdate[from] = block.timestamp;
        }
        if (to != address(0)) {
            rewards[to] += getPendingReward(to);
            lastUpdate[to] = block.timestamp;
        }
    }

    function withdrawChronos() external {
        require(!rewardPaused, "Claiming Chronos has been paused");
        uint256 calcrew = rewards[msg.sender] + getPendingReward(msg.sender);
        rewards[msg.sender] = 0;
        lastUpdate[msg.sender] = block.timestamp;
        _mint(msg.sender, calcrew);
    }

    function grantChronos(address _address, uint256 _amount) external {
        require(
            permsMap[msg.sender].Grantee,
            "Address does not have permission to distrubute tokens"
        );
        _mint(_address, _amount);
    }

    function burnUnclaimed(address user, uint256 amount) external {
        // the sender must be an 'allowedAddress' or a PXAdv
        require(
            permsMap[msg.sender].Burner || msg.sender == address(AdvContract),
            "Address does not have permission to burn"
        );
        require(user != address(0), "ERC20: burn from the zero address");
        uint256 unclaimed = rewards[user] + getPendingReward(user);
        require(
            unclaimed >= amount,
            "ERC20: burn amount exceeds unclaimed balance"
        );
        rewards[user] = unclaimed - amount;
        lastUpdate[user] = block.timestamp;
    }

    function burn(address user, uint256 amount) external {
        // the sender must be an 'allowedAddress' or a PXAdv
        require(
            permsMap[msg.sender].Burner || msg.sender == address(AdvContract),
            "Address does not have permission to burn"
        );
        _burn(user, amount);
    }

    // set stake to zero to unstake
    function stake(
        address from,
        uint256 advId,
        uint256 util
    ) external {
        require(
            permsMap[msg.sender].Staker || msg.sender == address(AdvContract),
            "Address does not have permission to stake"
        );
        rewards[from] += getPendingReward(from);
        lastUpdate[from] = block.timestamp;
        stakedAdv[advId] = util;
        emit AdvStaked(advId, util);
    }

    function viewStake(uint256 advId) external view returns (uint256) {
        return stakedAdv[advId];
    }

    function getTotalClaimable(address user) external view returns (uint256) {
        return rewards[user] + getPendingReward(user);
    }

    function getPendingReward(address user) internal view returns (uint256) {
        // return no. adv held * rate *days since last, genesis produce 2x
        uint256[] memory tokensheld = AdvContract.walletOfOwner(user);
        uint256 accum = 0;
        for (uint256 i; i < tokensheld.length; i++) {
            if (stakedAdv[tokensheld[i]] == 0) {
                if (tokensheld[i] > 5000) {
                    accum += 1;
                } else {
                    accum += 2;
                }
            }
        }

        return
            (accum *
                BASE_RATE *
                (block.timestamp -
                    (lastUpdate[user] >= START ? lastUpdate[user] : START))) /
            172800;
    }

    function setAllowedAddresses(
        address _address,
        bool _grant,
        bool _burn,
        bool _stake
    ) external onlyOwner {
        permsMap[_address].Grantee = _grant;
        permsMap[_address].Burner = _burn;
        permsMap[_address].Staker = _stake;
    }

    function viewPerms(address _address)
        external
        view
        returns (
            bool,
            bool,
            bool
        )
    {
        return (
            permsMap[_address].Grantee,
            permsMap[_address].Burner,
            permsMap[_address].Staker
        );
    }

    function toggleReward() public onlyOwner {
        rewardPaused = !rewardPaused;
    }
}
