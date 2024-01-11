// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./NFT.sol";
import "./MerkleProof.sol";
import "./PaymentSplitter.sol";
import "./Ownable.sol";

contract Minter is Ownable, PaymentSplitter {

  NFT public myNFT;
  bytes32 public root_presale;
  bytes32 public root_team_alloc;
  bytes32 public root_giveaway;
  uint256[] public token_id_brackets;
  uint256[] public bracket_prices;
  uint256 public current_bracket;
  uint256 public preSaleOpenTime;
  uint256 public preSaleCloseTime;
  uint256 public generalPublicOpenTime;
  uint256 public generalPublicCloseTime;
  // mapping(address => uint256) public mintedFromPresale;
  mapping(address => uint256) public mintedFromTeam;
  mapping(address => uint256) public mintedFromGiveAway;
  uint256 public totalMintedGiveaway;
  event updateRootsEvent(bytes32 root_presale, bytes32 root_team_alloc, bytes32 root_giveaway);
  event setPriceBrackets(uint256[] bracket_prices, uint256[] token_id_brackets);
  event setSalesDates(uint256[4] salesTimes);

  constructor(NFT _myNFT, address[] memory payees, uint256[] memory shares_) PaymentSplitter(payees, shares_)
  {
    myNFT = _myNFT;
  }

  function mintPresale(bytes32[] calldata proof, uint256 mintAmount) public payable
  {
    // Check if whitelisted
    require(_verify(proof, root_presale,_leaf(msg.sender, 0)), "Invalid merkle proof");
    // Check if open
    require(block.timestamp > preSaleOpenTime, "Presale not open");
    // Check if closed
    require(block.timestamp < preSaleCloseTime, "Presale closed");
    // Check if user has minted the maximum personally allowed
    // require(mintedFromPresale[msg.sender] + mintAmount <= authorizedAmount, "Already minted max amount");
    // Check if max mint for presale reached
    // require(myNFT.nextTokenId() + mintAmount < token_id_brackets[0], "Not enough NFT left in current bracket");
    // Check payment
    require(msg.value >= mintAmount * bracket_prices[current_bracket], "Not enough ETH");
    // Increment presale counter
    // mintedFromPresale[msg.sender] += mintAmount;
    // Mint
    for (uint256 i = 0; i < mintAmount; i++)
    {
      myNFT.mint(msg.sender);
    }
    // Increment presale counter
    // mintedFromPresale[msg.sender] += 1;
  }

  function mintTeamAlloc(bytes32[] calldata proof, uint256 authorizedAmount, uint256 mintAmount)  public
  {
    // Check if whitelisted
    require(_verify(proof, root_team_alloc,_leaf(msg.sender, authorizedAmount)), "Invalid merkle proof");
    // Check if team is still allowed to mint
    require(current_bracket < 2);
    // require(block.timestamp < generalPublicOpenTime, "Team claim finished");
    // Check if user has minted the maximum personally allowed
    require(mintedFromTeam[msg.sender] + mintAmount <= authorizedAmount, "Already minted max amount");
    // Increment presale counter
    mintedFromTeam[msg.sender] += mintAmount;
    // Mint
    for (uint256 i = 0; i < mintAmount; i++)
    {
      myNFT.mint(msg.sender);
    }
    // Check price brackets
    _checkPriceBrackets();
  }

  function mintGiveaway(bytes32[] calldata proof, uint256 authorizedAmount, uint256 mintAmount)  public
  {
    // Check if whitelisted
    require(_verify(proof, root_giveaway,_leaf(msg.sender, authorizedAmount)), "Invalid merkle proof");
    // Check if user has minted the maximum personally allowed
    require(mintedFromGiveAway[msg.sender] + mintAmount <= authorizedAmount, "Already minted max amount");
    // Check if total of giveaway is coherent
    require(totalMintedGiveaway + mintAmount <= 200, "Max minted for giveaway");
    // Increment giveaway counter
    totalMintedGiveaway += mintAmount;
    mintedFromGiveAway[msg.sender] += mintAmount;
    // Mint
    for (uint256 i = 0; i < mintAmount; i++)
    {
      myNFT.mint(msg.sender);
    }
    // Check price brackets
    _checkPriceBrackets();
  }

  function mint() public payable
  {
    // Check if open
    require(block.timestamp > generalPublicOpenTime, "Sale not open");
    require(block.timestamp < generalPublicCloseTime, "Sale closed");
    // Check price brackets
    _checkPriceBrackets();
    // Check payment
    require(msg.value >= bracket_prices[current_bracket], "Payment too low");
    // Mint
    myNFT.mint(msg.sender);
  }

  function multiMint(uint256 amount) public payable
  {
    // Check if open
    require(block.timestamp > generalPublicOpenTime, "Sale not open");
    require(block.timestamp < generalPublicCloseTime, "Sale closed");
    // Check if amount moves brackets one step up
    _checkPriceBrackets();
    // Check if amount moves above current bracket
    require(myNFT.nextTokenId() + amount < token_id_brackets[current_bracket], "Not enough NFT left in current bracket");

    // Check payment
    require(msg.value >= amount * bracket_prices[current_bracket]);
    // Mint
    for (uint256 i = 0; i < amount; i++)
    {
      myNFT.mint(msg.sender);
    }
  }

  function crossmint(address _to, uint256 amount) public payable {
    // Check if crossmint
    require(msg.sender == 0xdAb1a1854214684acE522439684a145E62505233,
      "This function is for Crossmint only."
    );
    // Check if open
    require(block.timestamp > generalPublicOpenTime, "Sale not open");
    require(block.timestamp < generalPublicCloseTime, "Sale closed");
    // Check if amount moves brackets one step up
    _checkPriceBrackets();
    // Check if amount moves above current bracket
    require(myNFT.nextTokenId() + amount < token_id_brackets[current_bracket], "Not enough NFT left in current bracket");

    // Check payment
    require(msg.value >= amount * bracket_prices[current_bracket]);
    // Mint
    for (uint256 i = 0; i < amount; i++)
    {
      myNFT.mint(_to);
    }
  }


  function getPrice()
  public
  view
  returns (uint256)
  {
    if (myNFT.nextTokenId() >= token_id_brackets[current_bracket])
    {
      return bracket_prices[current_bracket + 1];
    }
    else
    { 
      return bracket_prices[current_bracket];
    }
  }

  function updateBracketAfterPresale()
  public  
  {
    // Check presale closed
    require(block.timestamp > preSaleCloseTime, "Presale not closed");
    // Check if brackets needs updating
      if (1 > current_bracket)
      {
        current_bracket += 1;
      }
  }

  function setUpSales(uint256[] memory _bracket_prices, uint256[] memory _token_id_brackets, uint256[4] memory _sale_open_times) 
  public
  onlyOwner
  {
    require(_bracket_prices.length == _token_id_brackets.length);
    bracket_prices = _bracket_prices;
    token_id_brackets = _token_id_brackets;
    preSaleOpenTime = _sale_open_times[0];
    preSaleCloseTime = _sale_open_times[1];
    generalPublicOpenTime = _sale_open_times[2];
    generalPublicCloseTime = _sale_open_times[3];
    emit setPriceBrackets(_bracket_prices, _token_id_brackets);
    emit setSalesDates(_sale_open_times);
  }

  function updateRoots(bytes32 _root_giveaway, bytes32 _root_presale, bytes32 _root_team_alloc) public
  onlyOwner
  {
    root_giveaway = _root_giveaway;
    root_presale = _root_presale;
    root_team_alloc = _root_team_alloc;
    emit updateRootsEvent( root_presale,  root_team_alloc,  root_giveaway);
  }



  function _leaf(address account, uint256 amount)
  internal pure returns (bytes32)
  {
      return keccak256(abi.encodePacked(account, amount));
  }

  function _verify(bytes32[] memory proof, bytes32 root, bytes32 leaf)
  internal pure returns (bool)
  {
      return MerkleProof.verify(proof, root, leaf);
  }


  function _checkPriceBrackets()
  internal  
  {
      if (myNFT.nextTokenId() >= token_id_brackets[current_bracket])
      {
        current_bracket += 1;
      }
  }



}
