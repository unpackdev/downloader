// SPDX-License-Identifier: MIT
//                                                               __  .__               
//______   ____   ____   ____   ____   ____   ________________ _/  |_|__| ____   ____  
//\____ \ /  _ \ /  _ \ / ___\_/ __ \ /    \_/ __ \_  __ \__  \\   __\  |/  _ \ /    \ 
//|  |_> >  <_> |  <_> ) /_/  >  ___/|   |  \  ___/|  | \// __ \|  | |  (  <_> )   |  \
//|   __/ \____/ \____/\___  / \___  >___|  /\___  >__|  (____  /__| |__|\____/|___|  /
//|__|                /_____/      \/     \/     \/           \/                    \/ 

pragma solidity ^0.8.2;

import "./IERC20.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./IFlush.sol";

contract PooEvolution is Ownable {
    using Counters for Counters.Counter;

    IFlush flush = IFlush(0xf07e62de6321158E1d06527919D945D73545C195);
    
    bool public isSalesActive = true;

    mapping(uint => uint8) _tokenIdToLevel;

    uint[] public prices;
    
    constructor() {
        prices = [
            100 ether,
            200 ether,
            400 ether,
            800 ether,
            1600 ether,
            3200 ether,
            6400 ether
        ];
    }

    function evolve(uint tokenId) external {
        require(levelOf(tokenId) < prices.length, "token is at max level");

        flush.transferFrom(msg.sender, address(this), nextLevelPrice(tokenId));

        _tokenIdToLevel[tokenId]++;
    }

    function nextLevelPrice(uint tokenId) public view returns (uint) {
        return prices[_tokenIdToLevel[tokenId]];
    }

    function levelOf(uint tokenId) public view returns (uint) {
        return _tokenIdToLevel[tokenId];
    }

    function toggleSales() external onlyOwner {
        isSalesActive = !isSalesActive;
    }
    
    function setPrices(uint[] memory newPrices) external onlyOwner {
        prices = newPrices;
    }

    function burnFlush() external onlyOwner {
        uint balance = flush.balanceOf(address(this));
        flush.burn(balance);
    }

    function withdrawFlush() external onlyOwner {
        uint amount = flush.balanceOf(address(this));
        flush.transfer(msg.sender, amount);
    }
}