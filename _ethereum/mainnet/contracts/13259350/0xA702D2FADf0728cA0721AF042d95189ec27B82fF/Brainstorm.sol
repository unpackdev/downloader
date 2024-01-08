// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./ERC721.sol";
import "./FundingCycles.sol";
import "./JuiceboxProject.sol";
import "./ERC721.sol";
import "./Address.sol";

contract Brainstorm is JuiceboxProject, ERC721 {
  event Submit(
    uint256 indexed round,
    uint256 indexed number,
    uint256 value,
    address author,
    address caller
  );

  event Mint(uint256 round, address author, string quote, uint256 payout, address caller);
  event ChangeSumbitionPrice(uint256 indexed price, address caller);
  event ChangePayout(uint256 indexed amount, address caller);

  // The funding cycles contract. Each funding cycle is a round.
  FundingCycles public fundingCycles;

  // Quotes from each round.
  mapping(uint256 => string[]) private _quotes;

  // The winner from each round.
  mapping(uint256 => uint256) public winners;

  // The authors of each quote. Authors can't be overwritten.
  mapping(string => address payable) public authors;

  // The price of submition that gets routed to the treasury.
  uint256 public submitionPrice = 1000000000000000;

  // The payout to the winner.
  uint256 public payout = 100000000000000000;

  // All quotes for a round.
  function quotes(uint256 _round) external view returns (string[] memory) {
    return _quotes[_round];
  }

  // The number of quotes of a round.
  function quoteCount(uint256 _round) external view returns (uint256) {
    return _quotes[_round].length;
  }

  // A chunk of quotes for a round.
  function quotes(
    uint256 _round,
    uint256 _from,
    uint256 _length
  ) external view returns (string[] memory page) {
    require(_length > 0, '0x00: BAD_ARGS');
    for (uint256 _i = 0; _i < _length; _i++) page[_i] = _quotes[_round][_from + _i];
  }

  // The current round.
  function currentRound() public view returns (uint256) {
    return fundingCycles.currentOf(projectId).number;
  }

  constructor(
    uint256 _projectId,
    ITerminalDirectory _terminalDirectory,
    FundingCycles _fundingCycles
  ) JuiceboxProject(_projectId, _terminalDirectory) ERC721('Brainstorm', 'BRAINSTORM') {
    fundingCycles = _fundingCycles;
  }

  // The author will get the payout from the DAO if the quote is chosen as the winner.
  function submit(string memory _quote, address payable _author) external payable {
    // Price must be equal to the submission price.
    require(msg.value >= submitionPrice, '0x01: PRICE_TOO_LOW');

    // Can't submit the same quote again.
    require(authors[_quote] == address(0), '0x02: DUPLICATE');

    // Get the current funding cycle number.
    uint256 _round = currentRound();

    // Take fee into BrainDAO Juicebox treasury
    _takeFee(
      msg.value,
      msg.sender,
      string(
        abi.encodePacked(
          'Round ',
          _uint2str(_round),
          ' #',
          _uint2str(_quotes[_round].length + 1),
          ':\r',
          '"',
          _quote,
          '"'
        )
      ),
      false
    );

    // Add the quote to the round.
    _quotes[_round].push(_quote);

    // Set the author for the quote.
    authors[_quote] = _author;

    emit Submit(_round, _quotes[_round].length, msg.value, _author, msg.sender);
  }

  // The owner of the contract can mint a winner for each round.
  function mint(uint256 _round, uint256 _number) external payable onlyOwner {
    require(msg.value == payout, '0x03: INSUFFICIENT_PAYOUT');

    // Get the current funding cycle number.
    uint256 _currentRound = currentRound();

    // Must mint for a round that's already over.
    require(_round < _currentRound, '0x04: NOT_OVER');

    // Must mint an existing quote.
    require(_number > 0 && _quotes[_round].length >= _number, '0x05: BAD_NUMBER');

    // Get the winning quote.
    string memory _winningQuote = _quotes[_round][_number - 1];

    // Get the winning author.
    address payable _author = authors[_winningQuote];

    // Store the winner for the round.
    winners[_round] = _number;

    // Mint the winning quote for the round.
    _safeMint(owner(), _round);

    // Send the payout to the winner.
    Address.sendValue(_author, msg.value);

    emit Mint(_round, _author, _winningQuote, msg.value, msg.sender);
  }

  // The owner can change the submission price.
  function changeSubmitionPrice(uint256 _newPrice) external onlyOwner {
    submitionPrice = _newPrice;
    emit ChangeSumbitionPrice(_newPrice, msg.sender);
  }

  // The owner can change the submission price.
  function changePayout(uint256 _newPayout) external onlyOwner {
    payout = _newPayout;
    emit ChangePayout(_newPayout, msg.sender);
  }

  //https://stackoverflow.com/questions/47129173/how-to-convert-uint-to-string-in-solidity
  function _uint2str(uint256 _i) internal pure returns (string memory _uintAsString) {
    if (_i == 0) {
      return '0';
    }
    uint256 j = _i;
    uint256 len;
    while (j != 0) {
      len++;
      j /= 10;
    }
    bytes memory bstr = new bytes(len);
    uint256 k = len;
    while (_i != 0) {
      k = k - 1;
      uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
      bytes1 b1 = bytes1(temp);
      bstr[k] = b1;
      _i /= 10;
    }
    return string(bstr);
  }
}
