// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./IERC20Metadata.sol";
import "./IERC721.sol";

contract GALStaking is IERC20Metadata {

    struct StakeInfo {
        uint256 tokenId;
        uint256 unlockTime;
        address owner;
    }

    IERC721 public immutable GAL;
    uint256 public constant MULTIPLIER = 1e12;
    uint256 public lockDuration = 7 days;

    uint256 accRPS;
    uint256 lastETHBalance;

    // Info of each user that stakes tokens.
    mapping(uint256 => StakeInfo) private _receipt;
    mapping(address => uint256) private _debt;
    mapping(address => uint256[]) private _stakedListOf;

    constructor(IERC721 _GAL) {
        GAL = _GAL;
    }

    function name() external pure override returns (string memory) {
        return "GAL DP";
    }

    function symbol() external pure override returns (string memory) {
        return "GALDP";
    }

    function decimals() external pure override returns (uint8) {
        return 0;
    }

    function totalSupply() public view override returns (uint256) {
        return GAL.balanceOf(address(this));
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _stakedListOf[account].length;
    }

    function transfer(address, uint256) public pure override returns (bool) {
        revert("Not allowed");
    }

    function allowance(address, address) public pure override returns (uint256) {
        revert("Not allowed");
    }

    function approve(address, uint256) public pure override returns (bool) {
        revert("Not allowed");
    }

    function transferFrom(address, address, uint256) public pure override returns (bool) {
        revert("Not allowed");
    }

    function stakedListOf(address account) external view returns (uint256[] memory) {
        return _stakedListOf[account];
    }

    function getStakeInfo(uint256 tokenId) external view returns (uint256, uint256, address) {
        return (
            _receipt[tokenId].tokenId,
            _receipt[tokenId].unlockTime,
            _receipt[tokenId].owner
        );
    }

    // View function to see pending ETH rewards
    function pendingETHRewards(address account) external view returns (uint256) {
        uint256 currentRPS = accRPS;
        uint256 stakedGALCount = totalSupply();
        uint256 stakedCount = balanceOf(account);

        if(stakedCount == 0) {
            return 0;
        }

        if (stakedGALCount != 0) {
            uint256 ETHSupply = address(this).balance;
            uint256 ETHReward = ETHSupply - lastETHBalance;
            currentRPS += (ETHReward * MULTIPLIER) / stakedGALCount;
        }
        return ((stakedCount * currentRPS) / MULTIPLIER) - _debt[account];
    }

    function deposit(uint256[] calldata tokenIds) external {
        _deposit(tokenIds, msg.sender);
    }

    function withdraw(uint256[] calldata tokenIds) external {
        _withdraw(tokenIds, msg.sender);
    }

    // Deposit A GAL token for staking.
    function _deposit(uint256[] calldata tokenIds, address holder) internal {
        _refreshRewards();

        uint256 pending;
        uint256 stakedCount = balanceOf(holder);
        if(stakedCount > 0) {
            pending = ((stakedCount * accRPS) / MULTIPLIER) - _debt[holder];
        }

        for(uint256 i = 0; i < tokenIds.length; i++) {
            _receipt[tokenIds[i]] = StakeInfo(tokenIds[i], block.timestamp + lockDuration, holder);
            _stakedListOf[holder].push(tokenIds[i]);
        }
        _debt[holder] = ((stakedCount + tokenIds.length) * accRPS) / MULTIPLIER;    

        if(pending > 0) {
            _sendRewards(holder, pending);
        }

        for(uint256 i = 0; i < tokenIds.length; i++) {
            GAL.transferFrom(holder, address(this), tokenIds[i]);
        }

        emit Transfer(address(0), msg.sender, tokenIds.length);
    }

    // Withdraw staked GAL + ETH rewards.
    function _withdraw(uint256[] calldata tokenIds, address holder) internal {
        _refreshRewards();

        uint256 stakedCount = balanceOf(holder);
        uint256 pending = ((stakedCount * accRPS) / MULTIPLIER) - _debt[holder];
        _debt[holder] += pending;

        for(uint256 i = 0; i < tokenIds.length; i++) {
            StakeInfo memory stakeInfo = _receipt[tokenIds[i]];
            require(stakeInfo.owner == holder, "GALStaking: Unauthorized");
            require(block.timestamp >= stakeInfo.unlockTime, "GALStaking: Too early");
            delete _receipt[tokenIds[i]];

            // delete from the list of NFTs for holder
            uint256[] memory listOfNFTs = _stakedListOf[holder];
            uint256 length = listOfNFTs.length;
            for (uint256 j = 0; j < length; j++) {
                if (listOfNFTs[j] == tokenIds[i]) {
                    _stakedListOf[holder][j] = listOfNFTs[length - 1];
                    _stakedListOf[holder].pop();
                    break;
                }
            }
            GAL.transferFrom(address(this), holder, tokenIds[i]);
        }

        if(pending > 0) {
            _sendRewards(holder, pending);
        }
        emit Transfer(msg.sender, address(0), tokenIds.length);
    }

    // Update reward variables
    function _refreshRewards() internal {
        uint256 ETHSupply = address(this).balance;
        uint256 ETHReward = ETHSupply - lastETHBalance;
        if(ETHReward == 0) {
            return;
        }

        uint256 stakedGALCount = totalSupply();
        if (stakedGALCount == 0) {
            return;
        }

        accRPS += (ETHReward * MULTIPLIER) / stakedGALCount;
        lastETHBalance = ETHSupply;
    }

    function _sendRewards(address _to, uint256 _amount) internal {
        uint256 ETHBal = address(this).balance;
        if (_amount > ETHBal) {
            lastETHBalance = 0;
            (bool success, ) = _to.call{ value : ETHBal }("");
            require(success, "Transfer failed.");
        } else {
            lastETHBalance = ETHBal - _amount;
            (bool success, ) = _to.call{ value : _amount }("");
            require(success, "Transfer failed.");
        }
    }

    receive() external payable {}
}
