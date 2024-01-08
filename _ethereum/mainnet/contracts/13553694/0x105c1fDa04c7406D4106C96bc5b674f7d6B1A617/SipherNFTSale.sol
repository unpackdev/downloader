// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import "./Address.sol";
import "./ISipherNFT.sol";
import "./ISipherNFTSale.sol";
import "./Whitelist.sol";

contract SipherNFTSale is ISipherNFTSale, Whitelist {
  using Address for address;

  // at initial launch, the owner can buy up to 500 tokens
  uint32 public constant MAX_OWNER_BOUGHT_INITIAL = 500;
  uint32 public constant MAX_PUBLIC_BOUGHT = 7038;
  uint32 public constant PUBLIC_SALE_CAP_PER_ADDRESS = 5;
  uint32 public constant REDUCE_PRICE_INTERVAL = 600; //10 minutes
  uint256 public constant REDUCE_PRICE_LEVEL = 50000000000000000; //0.05 ether
  uint256 public constant SALE_BASE_PRICE = 100000000000000000; // 0.10 ether
  uint256 public constant SALE_PUBLIC_STARTING_PRICE = 900000000000000000; //0.9 ether

  bytes32 public override merkleRoot; // store the merkle root data for verification purpose

  ISipherNFT public immutable override nft;
  SaleRecord internal _saleRecord;
  SaleConfig internal _saleConfig;
  mapping(address => UserRecord) internal _userRecord;

  event OwnerBought(address indexed buyer, uint32 amount, uint256 amountWeiPaid);
  event PrivateBought(address indexed buyer, uint32 amount, uint256 amountWeiPaid);
  event FreeMintBought(address indexed buyer, uint32 amount, uint256 amountWeiPaid);
  event PublicBought(address indexed buyer, uint32 amount, uint256 amountWeiPaid);
  event WithdrawSaleFunds(address indexed recipient, uint256 amount);
  event RollStartIndex(address indexed trigger);
  event UpdateSaleEndTime(uint64 endTime);
  event SetMerkleRoot(bytes32 merkelRoot);
  event Refund(address buyer, uint256 refundAmount);

  constructor(
    ISipherNFT _nft,
    uint64 _publicTime,
    uint64 _publicEndTime,
    uint64 _privateTime,
    uint64 _freeMintTime,
    uint64 _endTime,
    uint32 _maxSupply
  ) {
    nft = _nft;
    _saleConfig = SaleConfig({
      publicTime: _publicTime,
      publicEndTime: _publicEndTime,
      privateTime: _privateTime,
      freeMintTime: _freeMintTime,
      endTime: _endTime,
      maxSupply: _maxSupply
    });
  }

  function withdrawSaleFunds(address payable recipient, uint256 amount) external onlyOwner {
    (bool success, ) = recipient.call{value: amount}('');
    require(success, 'SipherNFTSale: withdraw funds failed');
    emit WithdrawSaleFunds(recipient, amount);
  }

  /**
   * @dev Allow owner to set the merkle root only once before whitelist buy time
   */
  function setMerkleRoot(bytes32 _root) external onlyOwner {
    require(
      _blockTimestamp() < _saleConfig.publicTime,
      'SipherNFTSale: only update before whitelist buy time'
    );
    require(_root != bytes32(0), 'SipherNFTSale: invalid root');
    require(merkleRoot == bytes32(0), 'SipherNFTSale: already set merkle root');
    merkleRoot = _root;
    emit SetMerkleRoot(_root);
  }

  function getPublicSaleCurrentPrice() public view returns (uint256 currentPrice) {
    uint256 timestamp = _blockTimestamp();
    if (timestamp < _saleConfig.publicTime) {
      currentPrice = SALE_PUBLIC_STARTING_PRICE;
      return currentPrice;
    } else if (timestamp >= _saleConfig.publicTime && timestamp < _saleConfig.publicEndTime) {
      uint256 i = 0;
      while ((_saleConfig.publicTime + i * REDUCE_PRICE_INTERVAL) <= timestamp && i < 17) {
        i++;
      }
      currentPrice = SALE_PUBLIC_STARTING_PRICE - (i - 1) * REDUCE_PRICE_LEVEL;
      return currentPrice;
    } else {
      currentPrice = SALE_BASE_PRICE;
      return currentPrice;
    }
  }

  /**
   * @dev Buy amount of NFT tokens
   *   There are different caps for different users at different times
   *   The total sold tokens should be capped to maxSupply
   * @param amount amount of token to buy
   */
  function buy(
    uint32 amount,
    uint32 privateCap,
    uint32 freeMintCap,
    bytes32[] memory proofs
  ) external payable override {
    address buyer = msg.sender;
    // only EOA or the owner can buy, disallow contracts to buy
    require(
      (!buyer.isContract() && buyer == tx.origin) || buyer == owner(),
      'SipherNFTSale: only EOA or owner'
    );
    require(merkleRoot != bytes32(0), 'SipherNFTSale: merkle root is not set yet');
    uint256 unitPrice = getPublicSaleCurrentPrice();

    _validateAndUpdateWithBuyAmount(buyer, amount, privateCap, freeMintCap, unitPrice, proofs);

    nft.mintGenesis(amount, buyer, unitPrice);
  }

  /**
   * @dev Roll the final start index of the NFT, only call after sale is ended
   */
  function rollStartIndex() external override {
    require(_blockTimestamp() > _saleConfig.endTime, 'SipherNFTSale: sale not ended');

    address sender = msg.sender;
    require(
      (!sender.isContract() && sender == tx.origin) || sender == owner(),
      'SipherNFTSale: only EOA or owner'
    );

    require(merkleRoot != bytes32(0), 'SipherNFTSale: merkle root is not set yet');
    nft.rollStartIndex();

    emit RollStartIndex(sender);
  }

  /**
   * @dev Update sale end time by the owner only
   */
  function updateSaleConfigTime(
    uint64 _publicTime,
    uint64 _publicEndTime,
    uint64 _privateTime,
    uint64 _freeMintTime,
    uint64 _endTime
  ) external onlyOwner {
    require(_publicTime >= _saleConfig.publicTime, 'SipherNFTSale: Invalid sale time input');
    _saleConfig.publicTime = _publicTime;
    _saleConfig.publicEndTime = _publicEndTime;
    _saleConfig.privateTime = _privateTime;
    _saleConfig.freeMintTime = _freeMintTime;
    _saleConfig.endTime = _endTime;
    emit UpdateSaleEndTime(_endTime);
  }

  /**
   * @dev Return the sale config
   */
  function getSaleConfig() external view override returns (SaleConfig memory config) {
    config = _saleConfig;
  }

  /**
   * @dev Return the record, with number of tokens have been sold for different groups
   */
  function getSaleRecord() external view override returns (SaleRecord memory record) {
    record = _saleRecord;
  }

  /**
   * @dev Return the user record
   */
  function getUserRecord(address user) external view override returns (UserRecord memory record) {
    record = _userRecord[user];
  }

  /**
     * @dev Validate if it is valid to buy and update corresponding data
     *  Logics:
     *    1. Can not buy more than maxSupply
     *    2. If the buyer is the owner:
     *      - can buy up to MAX_OWNER_BOUGHT_INITIAL before endTime with price = 0
     *      - after sale is ended, can buy with no limit (but within maxSupply) with price = 0
          3. If the buy time is in public buy time:
     *      - each buyer can buy up to total of PUBLIC_SALE_CAP_PER_ADDRESS tokens at currentPrice per token
     *    4. If the buy time is in whitelist buy time:
     *      - each whitelisted buyer can buy up to privateCap tokens at SALE_BASE_PRICE per token
     *    5. If the buy time is in free mint time:
     *      - each whitelisted buyer can buy up to total of freeMintCap tokens at 0 ETH per token
     */
  function _validateAndUpdateWithBuyAmount(
    address buyer,
    uint32 amount,
    uint32 privateCap,
    uint32 freeMintCap,
    uint256 unitPrice,
    bytes32[] memory proofs
  ) internal {
    SaleConfig memory config = _saleConfig;
    // ensure total sold doens't exceed max supply
    require(
      _saleRecord.totalSold + amount <= _saleConfig.maxSupply,
      'SipherNFTSale: max supply reached'
    );

    address owner = owner();
    uint256 totalPaid = msg.value;
    uint256 timestamp = _blockTimestamp();
    uint256 costToMint = unitPrice * amount;

    if (buyer == owner) {
      // if not ended, owner can buy up to MAX_OWNER_BOUGHT_INITIAL, otherwise there is no cap
      if (timestamp <= config.endTime) {
        require(
          _saleRecord.ownerBought + amount <= MAX_OWNER_BOUGHT_INITIAL,
          'SipherNFTSale: max owner initial reached'
        );
      }
      _saleRecord.ownerBought += amount;
      _saleRecord.totalSold += amount;
      emit OwnerBought(buyer, amount, totalPaid);
      return;
    }

    require(config.publicTime <= timestamp, 'SipherNFTSale: Public Sale not started');
    require(timestamp <= config.endTime, 'SipherNFTSale: already ended');

    if (config.publicTime <= timestamp && timestamp < config.publicEndTime) {
      // anyone can buy up to PUBLIC_SALE_CAP_PER_ADDRESS tokens with price of currentPrice eth per token
      require(
        _saleRecord.totalPublicSold + amount <= MAX_PUBLIC_BOUGHT,
        'SipherNFTSale: max public sale supply reached'
      );
      require(
        _userRecord[buyer].publicBought + amount <= PUBLIC_SALE_CAP_PER_ADDRESS,
        'SipherNFTSale: normal cap reached'
      );
      require(
        (totalPaid >= costToMint) && (costToMint >= SALE_BASE_PRICE),
        'SipherNFTSale: invalid paid value'
      );
      _saleRecord.totalPublicSold += amount;
      _userRecord[buyer].publicBought += amount;
      _saleRecord.totalSold += amount;
      // refund if customer paid more than the cost to mint
      if (msg.value > costToMint) {
        Address.sendValue(payable(msg.sender), msg.value - costToMint);
        emit Refund(buyer, msg.value - costToMint);
      }
      emit PublicBought(buyer, amount, totalPaid);
      return;
    }

    if (config.publicEndTime <= timestamp && timestamp < config.freeMintTime) {
      require(
        config.privateTime <= timestamp && timestamp < config.freeMintTime,
        'SipherNFTSale: Private Sale not started'
      );
      // whitelisted address can buy up to privateCap token at SALE_BASE_PRICE ETH
      require(totalPaid == amount * SALE_BASE_PRICE, 'SipherNFTSale: invalid paid value');
      require(
        _userRecord[buyer].whitelistBought + amount <= privateCap,
        'SipherNFTSale: whitelisted private sale cap reached'
      );
      // only whitelisted can buy at this period
      require(
        isWhitelistedAddress(buyer, privateCap, freeMintCap, proofs) &&
          whitelistedMerkelRoot != bytes32(0),
        'SipherNFTSale: only whitelisted buyer'
      );
      _saleRecord.totalWhitelistSold += amount;
      _userRecord[buyer].whitelistBought += amount;
      _saleRecord.totalSold += amount;
      emit PrivateBought(buyer, amount, totalPaid);
      return;
    }

    if (config.freeMintTime <= timestamp && timestamp < config.endTime) {
      require(
        config.freeMintTime <= timestamp && timestamp < config.endTime,
        'Free Mint for Guidmaster not started'
      );
      // only whitelisted can buy at this period
      require(totalPaid == 0, 'Invalid paid amount');
      require(
        isWhitelistedAddress(buyer, privateCap, freeMintCap, proofs) &&
          whitelistedMerkelRoot != bytes32(0),
        'SipherNFTSale: only whitelisted buyer'
      );
      // whitelisted address can buy up to freeMintCap token at 0 ETH
      require(
        _userRecord[buyer].freeMintBought + amount <= freeMintCap,
        'SipherNFTSale: free mint cap reached'
      );
      _saleRecord.totalFreeMintSold += amount;
      _userRecord[buyer].freeMintBought += amount;
      _saleRecord.totalSold += amount;
      emit FreeMintBought(buyer, amount, totalPaid);
      return;
    }
  }

  function _blockTimestamp() internal view returns (uint256) {
    return block.timestamp;
  }
}
