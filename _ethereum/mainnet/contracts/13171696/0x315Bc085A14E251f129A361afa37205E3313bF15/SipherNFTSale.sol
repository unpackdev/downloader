// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import "./Address.sol";

import "./ISipherNFT.sol";
import "./ISipherNFTSale.sol";
import "./Whitelist.sol";


contract SipherNFTSale is ISipherNFTSale, Whitelist {

  using Address for address;

  // at initial launch, the owner can buy up to 500 tokens
  uint64 public constant MAX_OWNER_BOUGHT_INITIAL = 500;
  uint64 public constant CAP_PER_WHITELISTED_ADDRESS = 1;
  uint64 public constant CAP_PER_ADDRESS = 5;
  uint256 public constant SALE_PRICE = 10**17; // 0.1 ether

  bytes32 public override merkleRoot; // store the merkle root data for verification purpose

  ISipherNFT public immutable override nft;
  SaleRecord internal _saleRecord;
  SaleConfig internal _saleConfig;
  mapping (address => UserRecord) internal _userRecord;

  event OwnerBought(address indexed buyer, uint256 amount, uint256 amountWeiPaid);
  event WhitelistBought(address indexed buyer, uint256 amount, uint256 amountWeiPaid);
  event PublicBought(address indexed buyer, uint256 amount, uint256 amountWeiPaid);
  event WithdrawSaleFunds(address indexed recipient, uint256 amount);
  event RollStartIndex(address indexed trigger);
  event UpdateSaleEndTime(uint64 endTime);
  event SetMerkleRoot(bytes32 merkelRoot);

  constructor(
    ISipherNFT _nft,
    uint64 _whitelistTime,
    uint64 _publicTime,
    uint64 _endTime,
    uint64 _maxSupply,
    uint256 _maxWhitelistSize
  ) Whitelist(_maxWhitelistSize) {
    nft = _nft;
    _saleConfig = SaleConfig({
      whitelistTime: _whitelistTime,
      publicTime: _publicTime,
      endTime: _endTime,
      maxSupply: _maxSupply
    });
  }

  function withdrawSaleFunds(address payable recipient, uint256 amount) external onlyOwner {
    (bool success, ) = recipient.call{ value: amount }('');
    require(success, 'SipherNFTSale: withdraw funds failed');
    emit WithdrawSaleFunds(recipient, amount);
  }

  /**
   * @dev Allow owner to set the merkle root only once before whitelist buy time
   */
  function setMerkleRoot(bytes32 _root) external onlyOwner {
    require(
      _blockTimestamp() < _saleConfig.whitelistTime,
      'SipherNFTSale: only update before whitelist buy time'
    );
    require(_root != bytes32(0), 'SipherNFTSale: invalid root');
    require(merkleRoot == bytes32(0), 'SipherNFTSale: already set merkle root');
    merkleRoot = _root;
    emit SetMerkleRoot(_root);
  }

  /**
   * @dev Buy amount of NFT tokens
   *   There are different caps for different users at different times
   *   The total sold tokens should be capped to maxSupply
   * @param amount amount of token to buy
   */
  function buy(uint64 amount) external payable override {
    address buyer = msg.sender;
    // only EOA or the owner can buy, disallow contracts to buy
    require(!buyer.isContract() || buyer == owner(), 'SipherNFTSale: only EOA or owner');
    require(merkleRoot != bytes32(0), 'SipherNFTSale: merkle root is not set yet');

    _validateAndUpdateWithBuyAmount(buyer, amount);

    nft.mintGenesis(amount, buyer);
  }

  /**
   * @dev Roll the final start index of the NFT, only call after sale is ended
   */
  function rollStartIndex() external override {
    require(_blockTimestamp() > _saleConfig.endTime, 'SipherNFTSale: sale not ended');

    address sender = msg.sender;
    require(!sender.isContract() || sender == owner(), 'SipherNFTSale: only EOA or owner');

    require(merkleRoot != bytes32(0), 'SipherNFTSale: merkle root is not set yet');
    nft.rollStartIndex();

    emit RollStartIndex(sender);
  }

  /**
   * @dev Update sale end time by the owner only
   *  if new sale end time is in the past, the sale round will be halted
   */
  function updateSaleEndTime(uint64 _endTime) external onlyOwner {
    _saleConfig.endTime = _endTime;
    emit UpdateSaleEndTime(_endTime);
  }

  /**
   * @dev Return the config, with times (whitelistTime, publicTime, endTime) and max supply
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
  *       - can buy up to MAX_OWNER_BOUGHT_INITIAL before endTime with price = 0
   *      - after sale is ended, can buy with no limit (but within maxSupply) with price = 0
   *    3. If the buy time is in whitelist buy time:
   *      - each whitelisted buyer can buy up to CAP_PER_WHITELISTED_ADDRESS tokens with SALE_PRICE per token
   *    4. If the buy time is in public buy time:
   *      - each buyer can buy up to total of CAP_PER_ADDRESS tokens with SALE_PRICE per token
   */
  function _validateAndUpdateWithBuyAmount(address buyer, uint64 amount) internal {
    SaleConfig memory config = _saleConfig;

    // ensure total sold doens't exceed max supply
    require(
      _saleRecord.totalSold + amount <= _saleConfig.maxSupply,
      'SipherNFTSale: max supply reached'
    );

    address owner = owner();
    uint256 totalPaid = msg.value;
    uint256 timestamp = _blockTimestamp();

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

    require(config.whitelistTime <= timestamp, 'SipherNFTSale: not started');
    require(timestamp <= config.endTime, 'SipherNFTSale: already ended');

    if (config.whitelistTime <= timestamp && timestamp < config.publicTime) {
      // only whitelisted can buy at this period
      require(isWhitelistedAddress(buyer), 'SipherNFTSale: only whitelisted buyer');
      // whitelisted address can buy up to CAP_PER_WHITELISTED_ADDRESS token
      require(totalPaid == amount * SALE_PRICE, 'SipherNFTSale: invalid paid value');
      require(
        _userRecord[buyer].whitelistBought + amount <= CAP_PER_WHITELISTED_ADDRESS,
        'SipherNFTSale: whitelisted cap reached'
      );
      _saleRecord.totalWhitelistSold += amount;
      _userRecord[buyer].whitelistBought += amount;
      _saleRecord.totalSold += amount;
      emit WhitelistBought(buyer, amount, totalPaid);
      return;
    }

    if (config.publicTime <= timestamp && timestamp < config.endTime) {
      // anyone can buy up to CAP_PER_ADDRESS tokens with price of SALE_PRICE eth per token
      // it is applied for total of whitelistBought + publicBought
      require(totalPaid == amount * SALE_PRICE, 'SipherNFTSale: invalid paid value');
      require(
        _userRecord[buyer].publicBought + _userRecord[buyer].whitelistBought + amount <= CAP_PER_ADDRESS,
        'SipherNFTSale: normal cap reached'
      );
      _saleRecord.totalPublicSold += amount;
      _userRecord[buyer].publicBought += amount;
      _saleRecord.totalSold += amount;
      emit PublicBought(buyer, amount, totalPaid);
    }
  }

  function _blockTimestamp() internal view returns (uint256) {
    return block.timestamp;
  }
}
