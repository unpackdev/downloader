//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "ERC20.sol";
import "Ownable.sol";
import "IMultiRewards.sol";
import "IERC20.sol";

/// @title FRZ token
/// @author chalex.eth - CharlieDAO
/// @notice FRZ token ERC20 contract

contract FRZtoken is ERC20, Ownable {
    uint256 private constant ONE_YEAR = 86400 * 365;
    uint256 private constant INITIAL_SUPPLY = 100000000 * (10**18);
    uint256 private constant N_YEAR_TO_INFLATE = 101;
    uint256 internal constant MAX_UINT = 2**256 - 1;

    uint256 private deployedDate;
    uint256 private nextMintingDate;
    uint256 private nYear = 1;

    address private stakingContract;

    /* --------------- Constructor --------------*/
    ///@dev mint the initial supply to the merkle tree contract
    constructor(
        address _merkleTreeAirdrop,
        address _stakingContract,
        string memory symbol
    ) public ERC20("TrueFreeze", symbol) {
        stakingContract = _stakingContract;
        _approve(address(this), stakingContract, MAX_UINT);
        _mint(_merkleTreeAirdrop, INITIAL_SUPPLY);
        deployedDate = block.timestamp;
        nextMintingDate = deployedDate;
    }

    /* --------------- External function --------------*/

    ///@dev anyone can call the mint function, it will only mint to the contract to send to the staking contract to distribute to stakers
    function mint() external {
        require(block.timestamp > nextMintingDate, "Too early for minting");
        require(nYear < N_YEAR_TO_INFLATE, "All supply have been minted");
        nextMintingDate = getMintingSchedule();
        uint256 _tokenToMint = getTokenToMint();
        nYear += 1;
        _mint(address(this), _tokenToMint);
        IMultiRewards(stakingContract).notifyRewardAmount(
            address(this),
            _tokenToMint
        );
    }

    /* --------------- View functions --------------*/

    function getNextMintingDate() public view returns (uint256) {
        return nextMintingDate;
    }

    function getMintingSchedule() internal returns (uint256) {
        return deployedDate + (ONE_YEAR * nYear);
    }

    function getTokenToMint() public view returns (uint256) {
        if (nYear < 9) {
            uint256 tokenToMint = (totalSupply() * (10 - (nYear - 1))) / 100;
            return tokenToMint;
        } else {
            uint256 tokenToMint = (totalSupply() * 2) / 100;
            return tokenToMint;
        }
    }
}
