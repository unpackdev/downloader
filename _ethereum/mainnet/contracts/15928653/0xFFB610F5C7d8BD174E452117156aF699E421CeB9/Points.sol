pragma solidity ^0.8.0;

import "./WCToken.sol";

contract Points is WCToken{

    address[] validators = [
        address(0xe8c86c4302F9D6367b758a4073fda1f4396f5bea),
        address(0x789c807966D1e796B0E60324B44358bDa8455449),
        address(0xe0746f497B02b5F85Ec2598963F2316F86454Fcf),
        address(0xa7910350064e84894622278905F6a73430F8B541),
        address(0xc02b7c7cF5b57E085844B17d468B5b9Cbf5a0d24)];

    mapping (uint8 => uint24) results;
    uint256 lastVoteTime = 0;
    address lastVoter = address(0);
    uint8[] quorum = [0,0,0,0,0];

    constructor() ERC1155("WCToken") {
    }

    /*
    @notice Validator calls this function to set the winner token, must call for each category.
    Fills the results array with the validators vote.
    @param winnerTk The winning Token id
    */
    function setPoints(uint24 winnerTk)
    public{
        bool isValidator = false;
        uint8 vdId = 0;
        for(uint8 i = 0;i<validators.length;i++){
            isValidator = isValidator || (validators[i] == msg.sender);
            if(isValidator){
                vdId = i;
            }
        }
        require(isValidator);
        if(block.timestamp - lastVoteTime < 10800){
            if(results[_getCatForToken(winnerTk)] == winnerTk){
                quorum[_getCatForToken(winnerTk)] += 1;
            }
        } else {
            require(lastVoter != msg.sender);
            lastVoteTime = block.timestamp;
            lastVoter = msg.sender;
            results[_getCatForToken(winnerTk)] = winnerTk;
            quorum[_getCatForToken(winnerTk)] = 1;
        }
    }

    /*
    @notice Internal function that returns the category of that particular token
    [0-31] Category 0, winner of WC
    [32-1023] Category 2, finalists, First and second (biggest id << smallest)  5bits + 5bits
    [1024-1034576] Category 4, Semifinalists, concatenated ids from ltr from biggest to smallest
    @param tkId The tokenId of the token
    */
    function _getCatForToken(uint256 tkId) internal pure returns(uint8){
        if (tkId < 2 ** 5)
            return 0;
        if (tkId < 2 ** 10)
            return 2;
        return 4;
    }

    /*
    @notice 
    @param category
    @returns The tokenId that won a particular category
    */
    function _getOracleWinners(uint8 category)
    private
    view
    returns(uint24){
        require(quorum[category] > 1);
        return results[category];
    }

    /*
    @notice Call this function to send ETH if you won any WCToken category
    @param tkId The tokenId that won
    */
    function redeemEth(uint256 tkId)
    public
    {
        uint8 tokenCat = _getCatForToken(tkId);
        require(tkId == _getOracleWinners(tokenCat));
        require(block.timestamp > 1671760029);
        uint256 balance = balanceOf(msg.sender, tkId);
        uint256 poolOfWinners = totalSupply(tkId);
        uint256 prize = (totalSupplys[tokenCat] * 0.005 ether * balance) / poolOfWinners;
        totalSupplys[tokenCat] = totalSupplys[tokenCat];
        _safeTransferFrom(msg.sender, address(1),tkId, balance, "");

        require(prize > 0, "Prize cant be zero");
        (bool sent, bytes memory data) = msg.sender.call{value: (prize - 100)}("");
        require(sent); //, "Failed to send Ether"

    }

}