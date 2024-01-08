// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "Ownable.sol";
import "Address.sol";
import "JackpotNFT.sol";


contract Jackpot is Ownable {
   using Address for address payable;

   uint256 constant public GOLDEN_TICKET_ID_START = 1_000_000;

   uint public notBefore;

   // tokenId => if withdrawn
   mapping (uint256 => bool) withdrawls;
   uint256 ended = 0;

   // time people have to withdraw their awards.
   // after that we will take the rest and spend it on marketing for next projects.
   uint256 cooldown = 60 * 60 * 24 * 14;    // 2 weeks

   JackpotNFT tokens;

   event Ended();
   event PotIncreased(uint256 by, uint256 total);
   event Withdrawn(uint256 tokenId, address who, address to);

   uint256 payoutForTicket;
   uint256 payoutForWinner;
   uint256 winnerTokenId;

   constructor(JackpotNFT _tokens, uint _notBefore) {
      tokens = _tokens;
      notBefore = _notBefore;
   }

   function closeCompetition(uint256 _winnerTokenId) onlyOwner notEnded external {
      require(tokens.exists(_winnerTokenId), "Jackpot#2");
      require(isGoldenTicket(_winnerTokenId), "Jackpot#1");
      require(block.timestamp > notBefore, "Jackpot#8");
      ended = block.timestamp;
      winnerTokenId = _winnerTokenId;

      uint256 balance = address(this).balance;
      uint256 totalTickets = tokens.goldenTicketsFound();
      require(totalTickets > 1, "Jackpot#5");

      // everyone shares 1/3 of the pot
      uint256 tokenShare = balance / 3;
      // note: we / by total tickets as winner takes both normal share and winner's share
      payoutForTicket = tokenShare / totalTickets;
      // winner takes the rest
      payoutForWinner = balance - (payoutForTicket * totalTickets);

      emit Ended();
   }

   function withdraw(uint256 _tokenId, address payable _to) hasEnded external {
      require(isGoldenTicket(_tokenId), "Jackpot#1");
      require(tokens.ownerOf(_tokenId) == _msgSender(), "Jackpot#6");
      require(!withdrawls[_tokenId], "Jackpot#already-withdrawn");
      withdrawls[_tokenId] = true;
      uint256 payout = payoutForTicket;

      if (_tokenId == winnerTokenId) {
         // winner takes both regular ticket's payout and winner's payout
         payout += payoutForWinner;
      }

      emit Withdrawn(_tokenId, _msgSender(), _to);

      _to.sendValue(payout);
   }

   // when the competition ends - players have 2 weeks to withdraw their funds.
   // the rest will be withdrawn and spent on marketing
   function withdrawRest(address payable _to) afterCooldown onlyOwner external {
      _to.sendValue(address(this).balance);
   }

   receive() external payable {
      if (ended == 0) {
         emit PotIncreased(msg.value, address(this).balance);
      }
   }

   function isGoldenTicket(uint256  _id) public pure returns (bool) {
      return _id >= GOLDEN_TICKET_ID_START;
   }

   modifier hasEnded() {
      require(ended != 0, "Jackpot#4");
      _;
   }

   modifier notEnded() {
      require(ended == 0, "Jackpot#3");
      _;
   }

   modifier afterCooldown() {
      require(ended != 0, "Jackpot#4");
      require(block.timestamp > (ended + cooldown), "Jackpot#10");
      _;
   }
}