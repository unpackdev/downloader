pragma solidity 0.8.15;

import "./Ownable.sol";
import "./IERC721.sol";
import "./IERC20.sol";

interface BurnCardNFT is IERC721 {
    function incinerate(uint256 tokenId) external;
    function incinerateValue() external view returns (uint256 value);
    function owner() external view returns (address);
    function setIncinerateValue(uint256 value) external;
    function transferOwnership(address newOwner) external;
}

contract Burncinerator is Ownable {

    BurnCardNFT burnCard; // = BurnCardNFT(0x2BE0773474D93D6b9D954aD318821b8C3f751C49);
    IERC20 burnToken; // = IERC20(0xA2fe5E51729BE71261BcF42854012827BC44c044);

    uint256 public burncineratedNFTCount = 0;
    uint256 public burncineratePoolValue = 200000000 * (10**18);
    uint256 public incinerateValue = 200000000 * (10**18);
    
    uint256 public initialUnburnedCount;
    bool firstBurn;
    uint256 public accumulatedPool;


    event Burncinerate(address tokenOwner, uint256 tokenId, uint256 rewardTokens);
    event incincerateValueSet(uint256 incinerateValue);
    event BurncinceratePoolValueSet(uint256 incinerateValue);
    event unburnedCountSet(uint256 incinerateValue);

    constructor(address nft, address token, uint256 unburnedCount){
        burnCard = BurnCardNFT(nft);
        burnToken = IERC20(token);
        initialUnburnedCount = unburnedCount;
        accumulatedPool = 0;
        firstBurn = true;
    }

    // Burns by sending to 0xDEAD instead of 0x0 to save gas. Increases the reward value by 
    function burncinerate(uint256 tokenId) external {
        require(burnCard.isApprovedForAll(msg.sender, (address(this))));
        require(burnCard.ownerOf(tokenId) == msg.sender);

        if(firstBurn){
            firstBurn = false;
            burnCard.transferFrom(msg.sender, address(this), tokenId);
        } else {
            burnCard.transferFrom(msg.sender, address(0x000000000000000000000000000000000000dEaD), tokenId);
        }

        // calculate how much $BURN to send

        accumulatedPool += (burncineratePoolValue / (initialUnburnedCount - burncineratedNFTCount));
        uint256 value = incinerateValue + accumulatedPool;
        burncineratedNFTCount += 1;
        require(burnToken.transfer(msg.sender, value));
        emit Burncinerate(msg.sender, tokenId, value);
    }

    // uses the first burncard to be incinerated to transfer the tokens from the original contract to this contract. This method will save a lot of gas for users.
    function collectBurnCardTokens(uint256 tokenId) external onlyOwner {
        require(burnCard.owner() == address(this));
        require(burnCard.ownerOf(tokenId) == address(this));
        uint256 burnTokenBalance = burnToken.balanceOf(address(burnCard));
        burnCard.setIncinerateValue(burnTokenBalance);
        burnCard.incinerate(tokenId);
    }

    function rescueTokens(address token, uint256 amount) external onlyOwner {
        IERC20(token).transfer(msg.sender, amount);
    }

    function setIncinerateValue(uint256 value) external onlyOwner {
        incinerateValue = value;
        emit incincerateValueSet(incinerateValue);
    }

    function setUnburnedCount(uint256 value) external onlyOwner {
        initialUnburnedCount = value;
        emit unburnedCountSet(initialUnburnedCount);
    }

    function setBurncineratePoolValue(uint256 value) external onlyOwner {
        burncineratePoolValue = value;
        emit BurncinceratePoolValueSet(burncineratePoolValue);
    }

    function rescueBurnCard(uint256 tokenId) external onlyOwner {
        burnCard.transferFrom(address(this), owner(), tokenId);
    }

    function transferBurnCardOwnership() external onlyOwner {
        burnCard.transferOwnership(owner());
    }
    
}