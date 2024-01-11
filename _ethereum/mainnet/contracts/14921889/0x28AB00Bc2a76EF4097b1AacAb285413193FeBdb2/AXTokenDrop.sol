// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.11;


import "./IERC721.sol";
import "./IERC20.sol";
import "./Ownable.sol";

contract XATokenDrop is Ownable {
    IERC721 public immutable rewardedNft;
    IERC20 public immutable rewardToken;
    uint256 public immutable tokensPerClaim;
    uint256 public immutable totalAirdropAmount;

    bool public airdropFunded = true;
    

    event Claimed(uint256 indexed tokenId, address indexed claimer);
    event WithdrawToken(address indexed sender, address indexed TokenContract, uint256 indexed Amount); 

    error NotOwner();
    error AirdropStillInProgress();
    error AlreadyRedeemed();
    error AlreadyFunded();
    error InsufficientAmount();
    error InsufficientLiquidity();

    mapping(uint256 => bool) public hasClaimed;

    constructor(
        address _rewardedNft,
        uint256 _tokensPerClaim,
        address _rewardToken,
        uint256 _totalAirdropAmount
    ) {
        rewardedNft = IERC721(_rewardedNft);
        tokensPerClaim = _tokensPerClaim;
        totalAirdropAmount = _totalAirdropAmount;
        rewardToken = IERC20(_rewardToken);
    }

    

    
    function claim(uint256 tokenId) external {
        if (hasClaimed[tokenId]) revert AlreadyRedeemed();
        if (rewardToken.balanceOf(address(this)) < tokensPerClaim) revert InsufficientLiquidity();
        if (rewardedNft.ownerOf(tokenId) != msg.sender) revert NotOwner();

        hasClaimed[tokenId] = true;
        emit Claimed(tokenId, msg.sender);

        rewardToken.transfer(msg.sender, tokensPerClaim);
    }

     function withdrawToken(address _tokenContract, uint256 _amount) public onlyOwner {
        IERC20 token = IERC20(_tokenContract);
        
        
        token.transfer(_msgSender(), _amount);

        emit WithdrawToken(_msgSender(), _tokenContract, _amount);

    }

   
}