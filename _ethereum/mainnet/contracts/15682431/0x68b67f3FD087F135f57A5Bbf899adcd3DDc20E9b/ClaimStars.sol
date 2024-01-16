// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./IERC721.sol";
import "./IERC1155.sol";
import "./Counters.sol";

contract ClaimStars {
    using Counters for Counters.Counter;
    Counters.Counter private tokenId;

    address public constant NFTCONTRACT =
        0x5E36F2C564b16697cd6354FD9CA19E707E923a1a;

    address public constant PITBOSSCONTRACT = 
        0x8E19Be131d16Afd9c00CfFF6A8a60B098E6ab24f;
    
    bool private claimActive = true;

    mapping(address => uint256) private claims;

    IERC721 nftToken = IERC721(NFTCONTRACT);
    IERC1155 pitboss = IERC1155(PITBOSSCONTRACT);

    address private _owner;
    address private _manager;

    uint256 private initialTokenId = 2000;
    uint256 private totalTokens = 3000;

    constructor(address manager) {
        _owner = msg.sender;
        _manager = manager;
    }

    function toogleSale() public  {
        require(msg.sender == _owner, "Only the owner can toggle the claim");
        claimActive = !claimActive;
    }

    function getAmountToClaim(address account) public view returns (uint256 amount) {
        require(claimActive, "Claim is not active");
        require(tokenId.current() <= totalTokens, "Claim is over");

        uint256 token_qty = IERC1155(PITBOSSCONTRACT).balanceOf(account, 0);
        amount = 0;
        
        if (token_qty > 0) {
            amount = token_qty - claims[account]; 
        
            if (amount > 0) {
                return amount;
            }   
        }
        
        require(amount > 0, "Error: You does not have PitBoss to Claim.");
    }

    function claim() external {
        require(claimActive, "Claim is not active");
        require(tokenId.current() <= totalTokens, "Claim is over");
        
        address account = msg.sender;
        uint256 token_qty = IERC1155(PITBOSSCONTRACT).balanceOf(account, 0);
        uint256 amount = 0;
        
        if (token_qty > 0) {
            amount = token_qty - claims[account]; 
        
            if (amount > 0) {
                for (uint256 i = 0; i < amount; i++) {
                    uint256 token = initialTokenId + tokenId.current();
                    nftToken.transferFrom(_manager, account, token);
                    tokenId.increment();
                }
                claims[account] = amount;
            }   
        }
        
        require(amount > 0, "Error: You does not have PitBoss to Claim.");
    }
}
