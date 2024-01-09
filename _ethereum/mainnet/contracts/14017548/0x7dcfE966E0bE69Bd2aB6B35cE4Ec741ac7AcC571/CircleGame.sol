// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./ERC1155Burnable.sol";
import "./ERC1155Supply.sol";
import "./SafeMath.sol";

/// @custom:security-contact trevormil@comcast.net
contract CircleGame is ERC1155, Ownable, ERC1155Burnable, ERC1155Supply {
    using SafeMath for uint256;
    
    //Circle Tiers: 0 = Orange, 1 = Green, 2 = Red, 3 = Blue, 4 = Purple, 5 = Pink
    //Tier Multipliers: 1x = Orange, 1.1x = Green, 1.2x = Red, 1.3x = Blue, 1.4x = Purple, 1.5x = Pink
    
    uint256 public startingMintPrice = 1000000000000000; //Mint price starts at 0.001 and addds 0.00001 every mint
    uint256 public GAME_END_TIMESTAMP; //Game ends 28 days after deployment

    bool gameHasEnded = false;
    uint256 public endingPotBalance; //total ending pot balance
    uint256 public endingClaimablePotBalance; //total ending pot balance * 90%, used in claiming formula
    uint256 public adjustedTokenTotal; //total supply of all circles when game ends, adjusted for tier multipliers

    bool ownerWithdraw = false; //makes sure that the owner can only withdraw the 10% for developers and donations once
    
    
    constructor() ERC1155("https://circlegame.s3.us-east-2.amazonaws.com/{id}.json") {
        GAME_END_TIMESTAMP = block.timestamp + 28 days; //set deadline to 28 days after deployment
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    /* Mint price starts at 0.001 ETH and goes up by 0.00001 every time one is minted. Auto upgrades tiers if >= 5 are minted */
    function mint(address account, uint256 coinId, uint256 amount)
        public
        payable
    {
        require(gameHasEnded == false, "Game has ended");
        require(coinId == 0, "ID must be 0. It will auto upgrade for you.");
        require(amount > 0, "numTokens <=0");

        //Calculate total fee for minting according to formula
        uint256 currMintPrice = (amount - 1).mul(10000000000000).div(2).add(startingMintPrice);
        require(currMintPrice <= msg.value, "ETH value sent is not enough.");

        //Update mint price
        startingMintPrice = startingMintPrice.add((amount).mul(10000000000000));

        uint256[] memory amounts = new uint[](6);

        //Auto upgrade to highest tier possible
        for (uint tier = 6; tier >= 1; tier--) {
            uint i = tier - 1;
            if (amount >= 5**i) {
                amounts[i] = amount.div(5**i);
                amount = amount.sub(amounts[i] * 5**i);
                _mint(account, i, amounts[i], "");
            }
        }
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        public
        onlyOwner
    {
        _mintBatch(to, ids, amounts, data);
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        override(ERC1155, ERC1155Supply)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    //withdraw function for developer and donation funds at end of game (10% of pot balance); locked until deadline; only able to withdraw once
    function withdraw() public onlyOwner {
        require(ownerWithdraw == false);
        require(gameHasEnded == true);

        payable(msg.sender).transfer(endingPotBalance.div(10));
        ownerWithdraw = true;
    }

    //ends the game; can be called by anyone after deadline; locks pot balance and calculates token total according to tier multipliers
    function endGame() public {
        require(block.timestamp >= GAME_END_TIMESTAMP, "Locked");
        require(gameHasEnded == false);
        

        endingPotBalance = address(this).balance;
        endingClaimablePotBalance = endingPotBalance.div(10).mul(9); //90% of the pot balance is eligible to be claimed by players
        
        //Tier Multipliers: 1x = Orange, 1.1x = Green, 1.2x = Red, 1.3x = Blue, 1.4x = Purple, 1.5x = Pink
        adjustedTokenTotal = 
            totalSupply(0) + 
            (
                totalSupply(1).mul(5).mul(11) + 
                totalSupply(2).mul(25).mul(12) + 
                totalSupply(3).mul(125).mul(13) + 
                totalSupply(4).mul(625).mul(14) + 
                totalSupply(5).mul(3125).mul(15)
            ).div(10);
        
        gameHasEnded = true;
    }


    /* Fully upgrades a player's balance to highest tiers possible. 5 of one tier = 1 of next tier */
    function upgrade() public payable {
        require(gameHasEnded == false, "Game has ended");
        
        uint256[] memory balances = new uint[](6);

        for (uint i = 0; i < 6; i++) {
            uint origBalance = balanceOf(msg.sender, i);
            balances[i] = balances[i].add(origBalance);

            if (i < 5 && balances[i] >= 5) {
                uint numNextTier = balances[i].div(5);
                balances[i + 1] = numNextTier;
                balances[i] = balances[i].sub(numNextTier.mul(5));
            }
            
            if (origBalance > balances[i]) {
                _burn(msg.sender, i, origBalance - balances[i]);
            } else if (origBalance < balances[i]) {
                _mint(msg.sender, i, balances[i] - origBalance, "");
            }
        }
    }

    /* Claim one's portion of the pot by burning their tokens. Higher the tier, more claimable %. */
    function claimStake(uint[] memory numberOfTokens) public  {
        require(gameHasEnded == true, "Game hasn't ended yet");
        require(numberOfTokens.length == 6, "numberOfTokens length must == 6");
        
        //Adjust tokens by tier multipliers, burn tokens, and payout reward
        //Tier Multipliers: 1x = Orange, 1.1x = Green, 1.2x = Red, 1.3x = Blue, 1.4x = Purple, 1.5x = Pink
        uint playerAdjustedTokens = 0;
        for (uint i = 0; i < 6; i++) {

            playerAdjustedTokens = playerAdjustedTokens.add(numberOfTokens[i].mul(5**i).mul(10 + i).div(10));
            _burn(msg.sender, i, numberOfTokens[i]);
        }
        
        uint reward = playerAdjustedTokens.mul(endingClaimablePotBalance).div(adjustedTokenTotal);
        
        /* Burn tokens and payout reward */
        payable(msg.sender).transfer(reward);
    }

    function getDetails(address account) public view returns (uint256[14] memory) {
        return [
            address(this).balance, 
            startingMintPrice, 
            account != address(0) ? balanceOf(account, 0) : 0, 
            account != address(0) ? balanceOf(account, 1) : 0,
            account != address(0) ? balanceOf(account, 2) : 0,
            account != address(0) ? balanceOf(account, 3) : 0,
            account != address(0) ? balanceOf(account, 4) : 0,
            account != address(0) ? balanceOf(account, 5) : 0,
            totalSupply(0),
            totalSupply(1),
            totalSupply(2),
            totalSupply(3),
            totalSupply(4),
            totalSupply(5)
        ];
    }

    fallback() external payable {}
    receive() external payable {}   
}