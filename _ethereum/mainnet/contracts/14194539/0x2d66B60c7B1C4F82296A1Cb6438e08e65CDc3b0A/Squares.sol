// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./IERC721.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./AdAuction.sol";
import "./SportsDataAPIConsumer.sol";
import "./RandomGameBoard.sol";
import "./SquaresNFT.sol";
import "./Tag.sol";

/** 
  * @author Atlas Corporation
  * @title Squares on Chain
  */
contract Squares is Ownable, SquaresNFT, RandomGameBoard, SportsDataAPIConsumer, AdAuction {

    using SafeMath for uint256;

    mapping(uint256 => bool) public quarterPrizeClaimed;
    uint256 public totalPrizeCollected;

    constructor()
    SportsDataAPIConsumer(0x0aefab6f66d0278B99B6eCbFa8a03f9828cD90b0)
    AdAuction("Atlas Corp",0xe64581F067Cfdce58657E3c0F58175e638C30f2B)
    {
    }

    function getGameBoardRandomness() public override(RandomGameBoard) onlyOwner returns (bytes32) {
        return super.getGameBoardRandomness();
    }

    function assignGameBoard() public override(RandomGameBoard) onlyOwner {
        super.assignGameBoard();
    }

    function getGameScores() public override(SportsDataAPIConsumer) onlyOwner {
        super.getGameScores();
    }

    function getTile(uint256 _homeScore, uint256 _awayScore) public view returns (uint256) {
        require(gameState == GameState.Set, "Game not set");
        require(_homeScore >= 0 && _homeScore <= 9,"Home score must be within the bounds 0 to 9");
        require(_awayScore >= 0 && _awayScore <= 9,"Home score must be within the bounds 0 to 9");
        
        if(teamAssignment){
            return calculateTileNumber(homeTeamMap[_homeScore], awayTeamMap[_awayScore]);
        }
        else{
            return calculateTileNumber(awayTeamMap[_awayScore], homeTeamMap[_homeScore]);
        }
    }

    function calculateTileNumber(uint256 _x, uint256 _y) public pure returns (uint256){
        require(_x >= 0 && _x <= 9, "X out of bounds");
        require(_y >= 0 && _y <= 9, "Y out of bounds");
        return _y.mul(10).add(_x).add(1);
    }

    function getScorePair(uint256 _tokenId) public view returns (uint256 _homeScore, uint256 _awayScore){
        require(gameState == GameState.Set, "Game not set");
        require(_tokenId > 0, "TokenID must be greater than 0");
        require(_tokenId <= 100, "TokenID must be less than 100");

        uint256 x = _tokenId.sub(1).mod(10);
        uint256 y = _tokenId.sub(1).sub(x).div(10);

        if(teamAssignment){
            return (homeTeam[x],awayTeam[y]);
        }
        else{
            return (homeTeam[y],awayTeam[x]);
        }
    }

    function startAdSale() public override(AdAuction) onlyOwner {
        require(gameState != GameState.Complete, "Game is complete. No more ads");
        super.startAdSale();
    }

    function stopAdSale() public override(AdAuction) onlyOwner {
        totalPrizeCollected = address(this).balance;
        super.stopAdSale();
    }

    function claimPrize(uint256 _quarter) public {
        require(_quarter >= 1 && _quarter <= 4, "Quarter must be 1 through 4");
        require(quarter[_quarter].homeDataState == DataState.Complete, "Home Score Not Set");
        require(quarter[_quarter].awayDataState == DataState.Complete, "Away Score Not Set");
        require(!quarterPrizeClaimed[_quarter],"Prize already claimed");
        require(ownerOf(quarterWinner(_quarter))==msg.sender,"Caller does not own winning tile");
        require(!adSaleActive,"Prizes cannot be claimed while Ad Auction is live");
        require(totalPrizeCollected!=0,"No prize pool");
        require(payable(msg.sender).send(totalPrizeCollected.div(4)));
        quarterPrizeClaimed[_quarter] = true;
    }

    function quarterWinner(uint256 _quarter) public view returns (uint256) {
        require(_quarter >= 1 && _quarter <= 4, "Quarter must be 1 through 4");
        require(quarter[_quarter].homeDataState == DataState.Complete, "Home Score Not Set");
        require(quarter[_quarter].awayDataState == DataState.Complete, "Away Score Not Set");

        if(_quarter == 4){
            return getTile(
                quarter[5].homeScoreTotal.mod(10),
                quarter[5].awayScoreTotal.mod(10)
            );
        }
        else {
            return getTile(
                quarter[_quarter].homeScoreTotal.mod(10),
                quarter[_quarter].awayScoreTotal.mod(10)
            );
        }
        
    }

    function setBaseURI(string memory _URI) public override(SquaresNFT) onlyOwner {
        super.setBaseURI(_URI);
    }

    function startClaim() public override(SquaresNFT) onlyOwner {
        super.startClaim();
    }

    function withdrawBalance() public onlyOwner {
        require(quarterPrizeClaimed[1],"Quarter 1  prize not claimed");
        require(quarterPrizeClaimed[2],"Quarter 1  prize not claimed");
        require(quarterPrizeClaimed[3],"Quarter 1  prize not claimed");
        require(quarterPrizeClaimed[4],"Quarter 1  prize not claimed");
        require(payable(owner()).send(address(this).balance));
    }

    // To be used in the event of an emergency. Should there be a contract failure, having this
    // function in place will allow winners to be paid manually. 
    // If this function is called, expect a post mortem from: MorrisMustang.eth, howieDoin.eth

    function emergencyRug() public onlyOwner {
        require(payable(owner()).send(address(this).balance));
    }

}