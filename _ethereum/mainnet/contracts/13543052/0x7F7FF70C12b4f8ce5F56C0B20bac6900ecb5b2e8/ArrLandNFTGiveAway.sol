// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;


import "./Ownable.sol";
import "./SafeMath.sol";


interface IArrLandNFT {

    function spawn_pirate(address _to, uint256 generation, uint256 pirate_type) external returns (uint256);

    function sendGiveAway(address _to, uint256 _tokenCount, uint256 _generation) external;

    function reserveTokens(uint256 tokenCount) external;
}


contract ArrlandGiveAway is Ownable{

    using SafeMath for uint256;

    mapping(address => uint256) public giveawaylist;
    

    address arrlandNFT;

    event giveawayClaimed(address to, uint256 numberOfTokens);

    constructor (address _arrlandNFT) {
        arrlandNFT = _arrlandNFT;
    }

    function addWalletsTogiveawaylist(address[] memory _wallets, uint256[] memory _tokensCount) public onlyOwner {
        require(_wallets.length == _tokensCount.length, "Both arrays need to have the same length");
        uint256 tokenSum = 0;
        for(uint i = 0; i < _wallets.length; i++) {
            giveawaylist[_wallets[i]] = _tokensCount[i];
            tokenSum = tokenSum.add(_tokensCount[i]);
        }    
        IArrLandNFT(arrlandNFT).reserveTokens(tokenSum);
    }

    function claimGiveAway() public {
        require(giveawaylist[msg.sender] > 0, "Give away alredy claimed");

        uint256 numberOfTokens = giveawaylist[msg.sender];
        giveawaylist[msg.sender] = 0;
        for (uint i = 0; i < numberOfTokens; i++) {
            IArrLandNFT(arrlandNFT).spawn_pirate(msg.sender, 0, 1);            
        }
        emit giveawayClaimed(msg.sender, numberOfTokens);
    }

    function sendGiveAway(address _to, uint256 numberOfTokens) public onlyOwner {
        require(_to != address(0), "mint to the zero address");
        require(numberOfTokens > 0, "number of tokens must be greater then 0");
        IArrLandNFT(arrlandNFT).sendGiveAway(_to, numberOfTokens, 0);
    }

}