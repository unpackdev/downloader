//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./AccessControl.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./Pausable.sol";
import "./ERC1155Holder.sol";
import "./SafeMath.sol";
import "./AniftyERC1155.sol";

contract AniftyCollection is Ownable, Pausable, ERC1155Holder {
  using SafeMath for uint256;

  struct CollectionInfo {
    uint256 tokenId;
    uint256 totalTokenAmount;
    uint256 availableTokenAmount;
    uint256 price;
    address ERC20Token;
  }

  uint256 public roundId;
  // List of ERC20 tokens that are currently being used as a payment option for a collection
  address[] public paymentERC20Tokens;
  // Mapping to check if ERC20 exists in the list
  mapping(address => bool) public existingERC20Token;
  // Mapping of round to end timestamp
  mapping(uint256 => uint256) public roundEndTimestamp;
  // Mapping of round to collections
  mapping(uint256 => CollectionInfo[]) public roundCollection;
  // Address of Anifty's ERC1155 contract
  AniftyERC1155 public aniftyERC1155;

  constructor(address _aniftyERC1155) public {
      aniftyERC1155 = AniftyERC1155(_aniftyERC1155);
  }

  /********************** VIEWS ********************************/

  function totalPaymentERC20Tokens() external view returns (uint256) {
    return paymentERC20Tokens.length;
  }

  function totalCollection(uint256 _roundId) external view returns (uint256) {
    return roundCollection[_roundId].length;
  }

  function getCollectionInfo(uint256 _roundId, uint256[] memory _indexes) external view returns (uint256[] memory, uint256[] memory, uint256[] memory, uint256[] memory, address[] memory) {
    uint256[] memory tokenId = new uint256[](_indexes.length);
    uint256[] memory totalTokenAmount = new uint256[](_indexes.length);
    uint256[] memory availableTokenAmount = new uint256[](_indexes.length);
    uint256[] memory price = new uint256[](_indexes.length);
    address[] memory ERC20Token = new address[](_indexes.length);

    for (uint256 i = 0; i < _indexes.length; i++) {
      CollectionInfo storage collectables = roundCollection[_roundId][_indexes[i]];
      tokenId[i] = collectables.tokenId;
      totalTokenAmount[i] = collectables.totalTokenAmount;
      availableTokenAmount[i] = collectables.availableTokenAmount;
      price[i] = collectables.price;
      ERC20Token[i] = collectables.ERC20Token;
    }

    return (tokenId, totalTokenAmount, availableTokenAmount, price, ERC20Token);
  }

  /********************** BUY ********************************/

  function buyCollectable(uint256 _collectableIndex, uint256 _amount) payable external whenNotPaused {
    CollectionInfo storage collectable = roundCollection[roundId][_collectableIndex];
    require(collectable.availableTokenAmount >= _amount, 'AniftyCollection: Not enough tokens available');
    require(_amount > 0, 'AniftyCollection: Purchase amount must be greater than 0');
    require(block.timestamp < roundEndTimestamp[roundId], 'AniftyCollection: Cannot buy after roundEndTimestamp');
    // Empty address indicates the collectable accepts ETH as payment
    if (collectable.ERC20Token == address(0)) {
      require(msg.value >= collectable.price, 'AniftyCollection: Insufficient fund to buy collectable');
    } else {
      IERC20(collectable.ERC20Token).transferFrom(msg.sender, address(this), collectable.price);
    }
    collectable.availableTokenAmount = collectable.availableTokenAmount.sub(_amount);
    aniftyERC1155.safeTransferFrom(address(this), msg.sender, collectable.tokenId, _amount, "");
  }

  /********************** OWNER ********************************/

  function addToCollection(
    uint256[] memory _tokenIds,
    uint256[] memory _amounts,
    address[] memory _ERC20Tokens,
    uint256[] memory _prices,
    uint256 _roundEndTimestamp) external onlyOwner {
      require(_amounts.length == _ERC20Tokens.length && _amounts.length == _prices.length, "AniftyCollection: Incorrect parameter length");
      aniftyERC1155.safeBatchTransferFrom(msg.sender, address(this), _tokenIds, _amounts, "");
      roundId = roundId.add(1);
      roundEndTimestamp[roundId] = _roundEndTimestamp;
      for (uint256 i = 0; i < _tokenIds.length; i++) {
        uint256 tokenId = _tokenIds[i];
        address ERC20Token = _ERC20Tokens[i];
        uint256 price = _prices[i];
        uint256 amount = _amounts[i];
        roundCollection[roundId].push(CollectionInfo(tokenId, amount, amount, price, ERC20Token));
        if (!existingERC20Token[ERC20Token] && ERC20Token != address(0)) {
          paymentERC20Tokens.push(ERC20Token);
        }
      }
  }

  function addToRound(
    uint256 addRoundId,
    uint256[] memory _tokenIds,
    uint256[] memory _amounts,
    address[] memory _ERC20Tokens,
    uint256[] memory _prices) external onlyOwner {
      require(_amounts.length == _ERC20Tokens.length && _amounts.length == _prices.length, "AniftyCollection: Incorrect parameter length");
      aniftyERC1155.safeBatchTransferFrom(msg.sender, address(this), _tokenIds, _amounts, "");
      for (uint256 i = 0; i < _tokenIds.length; i++) {
        uint256 tokenId = _tokenIds[i];
        address ERC20Token = _ERC20Tokens[i];
        uint256 price = _prices[i];
        roundCollection[addRoundId].push(CollectionInfo(tokenId, _tokenIds.length, _tokenIds.length, price, ERC20Token));
        if (!existingERC20Token[ERC20Token] && ERC20Token != address(0)) {
          paymentERC20Tokens.push(ERC20Token);
        }
      }
    }

  function withdrawETH() public onlyOwner {
    msg.sender.transfer(address(this).balance);
  }

  function withdrawERC20(address _ERC20Token) public onlyOwner {
    IERC20 withdrawToken = IERC20(_ERC20Token);
    withdrawToken.transfer(msg.sender, withdrawToken.balanceOf(address(this)));
  }

  function withdrawAllERC20() public onlyOwner {
    for (uint256 i = 0; i < paymentERC20Tokens.length; i++) {
      withdrawERC20(paymentERC20Tokens[i]);
    }
  }

  function withdrawAllTokens() external onlyOwner {
    withdrawETH();
    withdrawAllERC20();
  }

  function withdrawERC1155(uint256 _roundId, uint256 _collectableIndex, uint256 _amount) public onlyOwner {
    CollectionInfo storage collectable = roundCollection[_roundId][_collectableIndex];
    require(collectable.availableTokenAmount >= _amount, 'AniftyCollection: Not enough tokens available');
    require(block.timestamp >= roundEndTimestamp[_roundId], 'AniftyCollection: Can only withdraw after roundEndTimestamp');
    collectable.availableTokenAmount = collectable.availableTokenAmount.sub(_amount);
    aniftyERC1155.safeTransferFrom(address(this), msg.sender, collectable.tokenId, _amount, "");
  }

  function withdrawAllERC1155(uint256 _roundId) external onlyOwner {
    for (uint256 i = 0; i < roundCollection[_roundId].length; i++) {
      CollectionInfo memory collectable = roundCollection[_roundId][i];
      uint256 ERC1155Balance = aniftyERC1155.balanceOf(address(this), collectable.tokenId);
      if (ERC1155Balance > 0) {
        withdrawERC1155(_roundId, i, ERC1155Balance);
      }
    }
  }

  // Sweep function in the case where someone accidently transfers an ERC1155 into this contract
  function sweepERC1155(uint256 _tokenId, uint256 _amount) external onlyOwner {
    aniftyERC1155.safeTransferFrom(address(this), msg.sender, _tokenId, _amount, "");
  }

  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }
}
