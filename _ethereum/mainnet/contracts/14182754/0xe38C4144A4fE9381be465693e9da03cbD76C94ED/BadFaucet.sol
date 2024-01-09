// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./SafeMath.sol";
import "./IERC721.sol";
import "./IERC20.sol";

/** 
  * @author Atlas Corporation
  * @title Bad Token Faucet 
  */
contract BadFaucet {

    using SafeMath for uint256;

    IERC721 immutable public bayc;
    IERC721 immutable public mayc;
    IERC721 immutable public badBanana;
    IERC20 immutable public bad;

    uint256 public maxClaimPerTransaction;
    uint256 public numTokensPerNFT;

    mapping(uint256 => bool) public baycTokenClaimed;
    mapping(uint256 => bool) public maycTokenClaimed;
    mapping(uint256 => bool) public badBananaTokenClaimed;

    event TokensClaimed(address _address, uint256 _amount);

    constructor() {

        // Bored Ape Yacht Club
        bayc = IERC721(0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D);

        // Mutant Ape Yacht Club
        mayc = IERC721(0x60E4d786628Fea6478F785A6d7e704777c86a7c6);

        // Bad Banana NFT
        badBanana = IERC721(0x819b71FBb346a8fAd8f782F3E4B3Db1d551b8E6f);

        // Bad Banana Token
        bad = IERC20(0xeb5Dc378E9532828446b73b1a948D04218a26588);

        maxClaimPerTransaction = 10;
        numTokensPerNFT = 10000 ether;

    }

    /**
      * @notice claim BAD tokens for BAYC, MAYC, and Bad Banana holders
      * @dev maximum of 10 NFTs can be used per claim transaction
      * @param _baycTokens array of BAYC token numbers owned by sender  
      * @param _maycTokens array of MAYC token numbers owned by sender
      * @param _badBananaTokens array of Bad Banana token numbers owner by sender
      */
    function claimBad(
        uint256[] calldata _baycTokens, 
        uint256[] calldata _maycTokens, 
        uint256[] calldata _badBananaTokens
    )
        external
    {
        uint256 totalTokensSubmitted = _baycTokens.length.add(_maycTokens.length).add(_badBananaTokens.length);
        require(totalTokensSubmitted > 0,"Must provide at least 1 NFT token");
        require(totalTokensSubmitted <= maxClaimPerTransaction,"Must provide 10 or less tokens per transaction");
        
        for(uint256 i = 0; i < _baycTokens.length; i++){
            require(bayc.ownerOf(_baycTokens[i])==msg.sender,"Sender does not own all BAYC tokens submitted");
            require(!baycTokenClaimed[_baycTokens[i]],"BAYC token already claimed");
            baycTokenClaimed[_baycTokens[i]] = true;
        }

        for(uint256 i = 0; i < _maycTokens.length; i++){
            require(mayc.ownerOf(_maycTokens[i])==msg.sender,"Sender does not own all MAYC tokens submitted");
            require(!maycTokenClaimed[_maycTokens[i]],"MAYC token already claimed");
            maycTokenClaimed[_maycTokens[i]] = true;
        }

        for(uint256 i = 0; i < _badBananaTokens.length; i++){
            require(badBanana.ownerOf(_badBananaTokens[i])==msg.sender,"Sender does not own all Bad Banana tokens submitted");
            require(!badBananaTokenClaimed[_badBananaTokens[i]],"Bad Banana token already claimed");
            badBananaTokenClaimed[_badBananaTokens[i]] = true;
        }

        uint256 numBadTokens = totalTokensSubmitted.mul(numTokensPerNFT);
        require(bad.balanceOf(address(this)) >= numBadTokens, "Not enough tokens remaining in faucet");
        require(bad.transfer(msg.sender,numBadTokens),"Error sending coins to caller");

        emit TokensClaimed(msg.sender, numBadTokens);
    
    }
}