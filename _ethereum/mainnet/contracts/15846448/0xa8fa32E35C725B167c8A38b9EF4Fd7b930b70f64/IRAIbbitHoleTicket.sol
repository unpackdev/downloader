// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IRAIbbitHoleTicket {

    //////////////////////////////
   // User Execution Functions //
  //////////////////////////////

  // Mint giveaway ticket tokens to an address by owner.
  function giveawayTicket(address _to, uint256 _quantity) external;
  // User can burn their RPF tokens and mint ticket tokens.
  function mintTicket(uint256 _burnId) external;

    /////////////////////////
   // Set Phase Functions //
  /////////////////////////

  // Set the variables to enable the public mint phase by owner.
  function setPublicMintPhase(uint256 _startTime, uint256 _endTime) external;

    /////////////////////////
   // Set Roles Functions //
  /////////////////////////

  // Set the authorized status of an address, true to have authorized access, false otherwise.
  function setAuthorizer(address _authorizer, bool _authorizedStatus) external;

    //////////////////////////
   // Set Params Functions //
  //////////////////////////

  // Set collection royalties with platforms that support ERC2981.
  function setDefaultRoyalty(address _receiver, uint96 _feeNumerator) external;
  // Set royalties of specific token with platforms that support ERC2981.
  function setTokenRoyalty(uint256 _tokenId, address _receiver, uint96 _feeNumerator) external;
  // Set the URI to return the tokens metadata.
  function setBaseURI(string memory _baseURI) external;

  // This event is triggered whenever a call to #setPublicMintPhase succeeds.
  event PhaseSet(uint256 _startTime, uint256 _endTime, string _type);
  // This event is triggered whenever a call to #setBurnMintRateForRPFs succeeds.
  event NumberSet(uint256 _amount, string _type);
  // This event is triggered whenever a call to #setAuthorizer succeeds.
  event AuthorizerChange(address _addressChange, bool _status);
  // This event is triggered whenever a call to #setBaseURI succeeds.
  event BaseURISet(string _baseURI);
}