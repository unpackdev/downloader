// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./IRadRouter.sol";
import "./RevenueSplitMapping.sol";
import "./IERC721.sol";
import "./ERC721Holder.sol";

contract RadRouter is IRadRouter, ERC721Holder {
  using RevenueSplitMapping for RevMap;

  struct Ledger {
    RevMap RetailSplits;
    RevMap ResaleSplits;
    mapping (uint256 => Asset) Assets;
    uint256[] retailedAssets;
  }

  struct Asset {
    address owner; // does not change on escrow, only through sale
    uint256 minPrice;
    bool resale;
    Creator creator;
    Buyer buyer;
  }

  struct Creator {
    address wallet;
    uint256 share;
  }

  struct Buyer {
    address wallet;
    uint256 amountEscrowed;
  }

  modifier onlyBy(address _account)
  {
    require(
      msg.sender == _account,
      'Sender not authorized'
    );
    _;
  }

  address public administrator_; // Rad administrator account
  mapping(address => Ledger) private Ledgers;

  /**
   * @dev Initializes the contract and sets the router administrator `administrator_`
   */
  constructor() { administrator_ = msg.sender; }

  /**
   * @dev See {IRadRouter-setRevenueSplit}.
   */
  function setRevenueSplit(address _ledger, address payable _stakeholder, uint256 _share, bool _retail) public onlyBy(administrator_) virtual override returns (bool success) {
    require(_ledger != address(0), 'Asset ledger cannot be the zero address');
    require(_stakeholder != address(0), 'Stakeholder cannot be the zero address');
    require(_share >= 0 && _share <= 100, 'Stakeholder share must be at least 0% and at most 100%');

    uint256 total;

    if (_retail) {
      if (_share == 0) {
        Ledgers[_ledger].RetailSplits.remove(_stakeholder);
        emit RetailRevenueSplitChange(_ledger, _stakeholder, _share, Ledgers[_ledger].RetailSplits.size(), Ledgers[_ledger].RetailSplits.total);
        return true;
      }
      if (Ledgers[_ledger].RetailSplits.contains(_stakeholder)) {
        require(Ledgers[_ledger].RetailSplits.size() <= 5, 'Cannot split revenue more than 5 ways.');
        total = Ledgers[_ledger].RetailSplits.total - Ledgers[_ledger].RetailSplits.get(_stakeholder);
      } else {
        require(Ledgers[_ledger].RetailSplits.size() < 5, 'Cannot split revenue more than 5 ways.');
        total = Ledgers[_ledger].RetailSplits.total;
      }
    } else {
      if (_share == 0) {
        Ledgers[_ledger].ResaleSplits.remove(_stakeholder);
        emit ResaleRevenueSplitChange(_ledger, _stakeholder, _share, Ledgers[_ledger].ResaleSplits.size(), Ledgers[_ledger].ResaleSplits.total);
        return true;
      }
      if (Ledgers[_ledger].ResaleSplits.contains(_stakeholder)) {
        require(Ledgers[_ledger].ResaleSplits.size() <= 5, 'Cannot split revenue more than 5 ways.');
        total = Ledgers[_ledger].ResaleSplits.total - Ledgers[_ledger].RetailSplits.get(_stakeholder);
      } else {
        require(Ledgers[_ledger].ResaleSplits.size() < 5, 'Cannot split revenue more than 5 ways.');
        total = Ledgers[_ledger].ResaleSplits.total;
      }
    }
    require(_share + total <= 100, 'Total revenue split cannot exceed 100%');

    if (_retail) {
      Ledgers[_ledger].RetailSplits.set(_stakeholder, _share);
      emit RetailRevenueSplitChange(_ledger, _stakeholder, _share, Ledgers[_ledger].RetailSplits.size(), Ledgers[_ledger].RetailSplits.total);
    } else {
      Ledgers[_ledger].ResaleSplits.set(_stakeholder, _share);
      emit ResaleRevenueSplitChange(_ledger, _stakeholder, _share, Ledgers[_ledger].ResaleSplits.size(), Ledgers[_ledger].ResaleSplits.total);
    }

    success = true;
  }

  /**
   * @dev See {IRadRouter-getRevenueSplit}.
   */
  function getRevenueSplit(address _ledger, address payable _stakeholder, bool _retail) external view virtual override returns (uint256 share) {
    if (_retail) {
      share = Ledgers[_ledger].RetailSplits.get(_stakeholder);
    } else {
      share = Ledgers[_ledger].ResaleSplits.get(_stakeholder);
    }
  }

  /**
   * @dev See {IRadRouter-setRevenueSplits}.
   */
  function setRevenueSplits(address _ledger, address payable[] calldata _stakeholders, uint256[] calldata _shares, bool _retail) public virtual override returns (bool success) {
    require(_stakeholders.length == _shares.length, 'Stakeholders and shares must have equal length');
    require(_stakeholders.length <= 5, 'Cannot split revenue more than 5 ways.');
    if (_retail) {
      Ledgers[_ledger].RetailSplits.clear();
    } else {
      Ledgers[_ledger].ResaleSplits.clear();
    }
    for (uint256 i = 0; i < _stakeholders.length; i++) {
      setRevenueSplit(_ledger, _stakeholders[i], _shares[i], _retail);
    }

    success = true;
  }

  function getRevenueStakeholders(address _ledger, bool _retail) external view virtual override returns (address[] memory stakeholders) {
    if (_retail) {
      stakeholders = Ledgers[_ledger].RetailSplits.keys;
    } else {
      stakeholders = Ledgers[_ledger].ResaleSplits.keys;
    }
  }

  /**
   * @dev See {IRadRouter-setAssetMinPrice}.
   */
  function setAssetMinPrice(address _ledger, uint256 _assetId, uint256 _minPrice) public virtual override returns (bool success) {
    require(_ledger != address(0), 'Asset ledger cannot be the zero address');
    IERC721 ledger = IERC721(_ledger);
    address owner = ledger.ownerOf(_assetId);
    require(msg.sender == owner || msg.sender == administrator_, 'Only the asset owner or Rad administrator can set the asset minimum price');
    require(owner == address(this) || ledger.isApprovedForAll(owner, address(this)) || ledger.getApproved(_assetId) == address(this), 'Must approve Rad Router as an operator before setting minimum price.');

    Ledgers[_ledger].Assets[_assetId].owner = owner;
    Ledgers[_ledger].Assets[_assetId].minPrice = _minPrice;

    emit AssetMinPriceChange(_ledger, _assetId, _minPrice);

    success = true;
  }

  /**
   * @dev See {IRadRouter-getAssetMinPrice}.
   */
  function getAssetMinPrice(address _ledger, uint256 _assetId) external view virtual override returns (uint256 minPrice) {
    minPrice = Ledgers[_ledger].Assets[_assetId].minPrice;
  }

  /**
   * @dev See {IRadRouter-setAssetMinPriceAndRevenueSplits}.
   */
  function setAssetMinPriceAndRevenueSplits(address _ledger, address payable[] calldata _stakeholders, uint256[] calldata _shares, bool _retail, uint256 _assetId, uint256 _minPrice) public virtual override returns (bool success) {
    success = setRevenueSplits(_ledger, _stakeholders, _shares, _retail) && setAssetMinPrice(_ledger, _assetId, _minPrice);
  }

  /**
   * @dev See {IRadRouter-sellerEscrowDeposit}.
   */
  function sellerEscrowDeposit(address _ledger, uint256 _assetId) public virtual override returns (bool success) {
    success = sellerEscrowDeposit(_ledger, _assetId, false, 0);
  }

  /**
   * @dev See {IRadRouter-sellerEscrowDepositWithCreatorShare}.
   */
  function sellerEscrowDepositWithCreatorShare(address _ledger, uint256 _assetId, uint256 _creatorResaleShare) public virtual override returns (bool success) {
    require(_ledger != address(0), 'Asset ledger cannot be the zero address');
    require(_creatorResaleShare >= 0 && _creatorResaleShare <= 100, 'Creator share must be at least 0% and at most 100%');

    IERC721 ledger = IERC721(_ledger);
    address owner = ledger.ownerOf(_assetId);

    require(
      msg.sender == owner ||
      msg.sender == administrator_,
      'Only the asset owner or Rad administrator can change asset ownership'
    );

    require(
      ledger.isApprovedForAll(owner, address(this)) ||
      ledger.getApproved(_assetId) == address(this),
      'Must set Rad Router as an operator for all assets before depositing to escrow.'
    );

    if (
      Ledgers[_ledger].Assets[_assetId].creator.wallet == address(0) ||
      Ledgers[_ledger].Assets[_assetId].creator.wallet == owner ||
      Ledgers[_ledger].Assets[_assetId].owner == owner
    ) {

      if (Ledgers[_ledger].Assets[_assetId].creator.wallet == address(0)) {
        Ledgers[_ledger].Assets[_assetId].creator.wallet = owner;
      }

      require(
        Ledgers[_ledger].Assets[_assetId].creator.wallet == owner ||
        Ledgers[_ledger].Assets[_assetId].creator.share == 0 ||
        Ledgers[_ledger].Assets[_assetId].owner == owner,
        'Cannot set creator share.'
      );

      uint256 total = Ledgers[_ledger].Assets[_assetId].creator.share;
      address[] storage stakeholders = Ledgers[_ledger].ResaleSplits.keys;

      for (uint256 i = 0; i < stakeholders.length; i++) {
        total += Ledgers[_ledger].ResaleSplits.get(stakeholders[i]);
      }

      require(total <= 100, 'Creator share cannot exceed total ledger stakeholder when it is 100.');

      Ledgers[_ledger].Assets[_assetId].creator.share = _creatorResaleShare;
    }

    success = sellerEscrowDeposit(_ledger, _assetId, false, 0);
  }

  /**
   * @dev See {IRadRouter-sellerEscrowDepositWithCreatorShareBatch}.
   */
  function sellerEscrowDepositWithCreatorShareBatch(address _ledger, uint256[] calldata _assetIds, uint256 _creatorResaleShare) public virtual override returns (bool success) {
    success = false;

    for (uint256 i = 0; i < _assetIds.length; i++) {
      if (!sellerEscrowDepositWithCreatorShare(_ledger, _assetIds[i], _creatorResaleShare)) {
        success = false;
        break;
      } else {
        success = true;
      }
    }
  }

  /**
   * @dev See {IRadRouter-sellerEscrowDepositWithCreatorShareWithMinPrice}.
   */
  function sellerEscrowDepositWithCreatorShareWithMinPrice(address _ledger, uint256 _assetId, uint256 _creatorResaleShare, uint256 _minPrice) public virtual override returns (bool success) {
    require(_ledger != address(0), 'Asset ledger cannot be the zero address');
    require(_creatorResaleShare >= 0 && _creatorResaleShare <= 100, 'Creator share must be at least 0% and at most 100%');

    IERC721 ledger = IERC721(_ledger);
    address owner = ledger.ownerOf(_assetId);

    require(
      msg.sender == owner ||
      msg.sender == administrator_,
      'Only the asset owner or Rad administrator can change asset ownership'
    );

    require(
      ledger.isApprovedForAll(owner, address(this)) ||
      ledger.getApproved(_assetId) == address(this),
      'Must set Rad Router as an operator for all assets before depositing to escrow.'
    );

    if (
      Ledgers[_ledger].Assets[_assetId].creator.wallet == address(0) ||
      Ledgers[_ledger].Assets[_assetId].creator.wallet == owner ||
      Ledgers[_ledger].Assets[_assetId].owner == owner
    ) {
      if (Ledgers[_ledger].Assets[_assetId].creator.wallet == address(0)) {
        Ledgers[_ledger].Assets[_assetId].creator.wallet = owner;
      }

      require(
        Ledgers[_ledger].Assets[_assetId].creator.wallet == owner ||
        Ledgers[_ledger].Assets[_assetId].creator.share == 0 ||
        Ledgers[_ledger].Assets[_assetId].owner == owner,
        'Cannot set creator share.'
      );

      uint256 total = Ledgers[_ledger].Assets[_assetId].creator.share;
      address[] storage stakeholders = Ledgers[_ledger].ResaleSplits.keys;

      for (uint256 i = 0; i < stakeholders.length; i++) {
        total += Ledgers[_ledger].ResaleSplits.get(stakeholders[i]);
      }

      require(total <= 100, 'Creator share cannot exceed total ledger stakeholder when it is 100.');

      Ledgers[_ledger].Assets[_assetId].creator.share = _creatorResaleShare;
    }

    success = sellerEscrowDeposit(_ledger, _assetId, true, _minPrice);
  }

  /**
   * @dev See {IRadRouter-sellerEscrowDepositWithCreatorShareWithMinPriceBatch}.
   */
  function sellerEscrowDepositWithCreatorShareWithMinPriceBatch(address _ledger, uint256[] calldata _assetIds, uint256 _creatorResaleShare, uint256 _minPrice) public virtual override returns (bool success) {
    success = false;
    for (uint256 i = 0; i < _assetIds.length; i++) {
      if (!sellerEscrowDepositWithCreatorShareWithMinPrice(_ledger, _assetIds[i], _creatorResaleShare, _minPrice)) {
        success = false;
        break;
      } else {
        success = true;
      }
    }
  }

  /**
   * @dev See {IRadRouter-sellerEscrowDeposit}.
   */
  function sellerEscrowDeposit(address _ledger, uint256 _assetId, bool _setMinPrice, uint256 _minPrice) public virtual override returns (bool success) {
    require(_ledger != address(0), 'Asset ledger cannot be the zero address');
    IERC721 ledger = IERC721(_ledger);
    address owner = ledger.ownerOf(_assetId);
    require(msg.sender == owner || msg.sender == administrator_, 'Only the asset owner or Rad administrator can change asset ownership');
    require(ledger.isApprovedForAll(owner, address(this)) || ledger.getApproved(_assetId) == address(this), 'Must set Rad Router as an operator for all assets before depositing to escrow');

    if (_setMinPrice) {
      setAssetMinPrice(_ledger, _assetId, _minPrice);
    }

    Ledgers[_ledger].Assets[_assetId].owner = owner;

    ledger.safeTransferFrom(owner, address(this), _assetId);

    if (Ledgers[_ledger].Assets[_assetId].buyer.wallet != address(0)) {
      _fulfill(_ledger, _assetId);
    }

    emit SellerEscrowChange(_ledger, _assetId, owner, true);

    success = true;
  }

  /**
   * @dev See {IRadRouter-sellerEscrowDepositBatch}.
   */
  function sellerEscrowDepositBatch(address _ledger, uint256[] calldata _assetIds) external virtual override returns (bool success) {
    success = sellerEscrowDepositBatch(_ledger, _assetIds, false, 0);
  }

  /**
   * @dev See {IRadRouter-sellerEscrowDepositBatch}.
   */
  function sellerEscrowDepositBatch(address _ledger, uint256[] calldata _assetIds, bool _setMinPrice, uint256 _minPrice) public virtual override returns (bool success) {
    for (uint256 i = 0; i < _assetIds.length; i++) {
      sellerEscrowDeposit(_ledger, _assetIds[i], _setMinPrice, _minPrice);
    }

    success = true;
  }

  /**
   * @dev See {IRadRouter-sellerEscrowWithdraw}.
   */
  function sellerEscrowWithdraw(address _ledger, uint256 _assetId) external virtual override returns (bool success) {
    require(_ledger != address(0), 'Asset ledger cannot be the zero address');
    IERC721 ledger = IERC721(_ledger);
    address owner = Ledgers[_ledger].Assets[_assetId].owner;
    require(msg.sender == owner || msg.sender == administrator_, 'Only the asset owner or Rad administrator can change asset ownership');
    require(ledger.isApprovedForAll(owner, address(this)), 'Must set Rad Router as an operator for all assets before depositing to escrow');

    Ledgers[_ledger].Assets[_assetId].creator.wallet = address(0);
    Ledgers[_ledger].Assets[_assetId].creator.share = 0;

    ledger.safeTransferFrom(address(this), owner, _assetId);

    emit SellerEscrowChange(_ledger, _assetId, owner, false);

    success = true;
  }

  /**
   * @dev See {IRadRouter-buyerEscrowDeposit}.
   */
  function buyerEscrowDeposit(address _ledger, uint256 _assetId) external payable virtual override returns (bool success) {
    require(_ledger != address(0), 'Asset ledger cannot be the zero address');

    require(
      Ledgers[_ledger].Assets[_assetId].buyer.wallet == address(0) ||
      Ledgers[_ledger].Assets[_assetId].buyer.wallet == msg.sender,
      'Another buyer has already escrowed'
    );

    require(
      Ledgers[_ledger].Assets[_assetId].buyer.amountEscrowed + msg.value >= Ledgers[_ledger].Assets[_assetId].minPrice,
      'Buyer did not send enough ETH'
    );

    Ledgers[_ledger].Assets[_assetId].buyer.wallet = msg.sender;
    Ledgers[_ledger].Assets[_assetId].buyer.amountEscrowed += msg.value;

    IERC721 ledger = IERC721(_ledger);

    if (ledger.ownerOf(_assetId) == address(this)) {
      _fulfill(_ledger, _assetId);
    }

    emit BuyerEscrowChange(_ledger, _assetId, msg.sender, true);

    success = true;
  }

  /**
   * @dev See {IRadRouter-buyerEscrowWithdraw}.
   */
  function buyerEscrowWithdraw(address _ledger, uint256 _assetId) external virtual override returns (bool success) {
    require(_ledger != address(0), 'Asset ledger cannot be the zero address');
    require(
      msg.sender == Ledgers[_ledger].Assets[_assetId].buyer.wallet ||
      msg.sender == Ledgers[_ledger].Assets[_assetId].owner ||
      msg.sender == administrator_,
      'msg.sender must be the buyer, seller, or Rad operator'
    );

    payable(Ledgers[_ledger].Assets[_assetId].buyer.wallet).transfer(Ledgers[_ledger].Assets[_assetId].buyer.amountEscrowed);

    Ledgers[_ledger].Assets[_assetId].buyer.wallet = address(0);
    Ledgers[_ledger].Assets[_assetId].buyer.amountEscrowed = 0;

    emit BuyerEscrowChange(_ledger, _assetId, msg.sender, false);

    success = true;
  }

  /**
   * @dev See {IRadRouter-getSellerWallet}.
   */
  function getSellerWallet(address _ledger, uint256 _assetId) public view override returns (address wallet) {
    if (Ledgers[_ledger].Assets[_assetId].owner == address(0)) {
      require(_ledger != address(0), 'Asset ledger cannot be the zero address');
      IERC721 ledger = IERC721(_ledger);
      wallet = ledger.ownerOf(_assetId);
    } else {
      wallet = Ledgers[_ledger].Assets[_assetId].owner;
    }
  }

  /**
   * @dev See {IRadRouter-getSellerWallet}.
   */
  function getSellerDeposit(address _ledger, uint256 _assetId) public view override returns (uint256 amount) {
    require(_ledger != address(0), 'Asset ledger cannot be the zero address');
    IERC721 ledger = IERC721(_ledger);
    address owner = ledger.ownerOf(_assetId);

    if (owner == address(this)) {
      return _assetId;
    }

    return 0;
  }

  /**
   * @dev See {IRadRouter-getBuyerWallet}.
   */
  function getBuyerWallet(address _ledger, uint256 _assetId) public view override returns (address wallet) {
    wallet = Ledgers[_ledger].Assets[_assetId].buyer.wallet;
  }

  /**
   * @dev See {IRadRouter-getBuyerDeposit}.
   */
  function getBuyerDeposit(address _ledger, uint256 _assetId) public view override returns (uint256 amount) {
    amount = Ledgers[_ledger].Assets[_assetId].buyer.amountEscrowed;
  }

  /**
   * @dev See {IRadRouter-getAssetIsResale}.
   */
  function getAssetIsResale(address _ledger, uint256 _assetId) public view override returns (bool resale) {
    resale = Ledgers[_ledger].Assets[_assetId].resale;
  }

  /**
   * @dev See {IRadRouter-getRetailedAssets}.
   */
  function getRetailedAssets(address _ledger) public view override returns (uint256[] memory assets) {
    assets = Ledgers[_ledger].retailedAssets;
  }

  /**
   * @dev See {IRadRouter-getCreatorWallet}.
   */
  function getCreatorWallet(address _ledger, uint256 _assetId) public view override returns (address wallet) {
    wallet = Ledgers[_ledger].Assets[_assetId].creator.wallet;
  }

  /**
   * @dev See {IRadRouter-getCreatorShare}.
   */
  function getCreatorShare(address _ledger, uint256 _assetId) public view override returns (uint256 amount) {
    amount = Ledgers[_ledger].Assets[_assetId].creator.share;
  }

  /**
   * @dev Fulfills asset sale transaction and pays out all revenue split stakeholders
   *
   * Requirements:
   *
   * - `_ledger` cannot be the zero address.
   * - `_assetId` owner must be this contract
   * - `_assetId` buyer must not be the zero address
   *
   * Emits a {EscrowFulfill} event.
   */
  function _fulfill(address _ledger, uint256 _assetId) internal virtual returns (bool success) {
    IERC721 ledger = IERC721(_ledger);

    require(
      ledger.ownerOf(_assetId) == address(this),
      'Seller has not escrowed'
    );

    require(
      Ledgers[_ledger].Assets[_assetId].buyer.wallet != address(0),
      'Buyer has not escrowed'
    );

    require(
      Ledgers[_ledger].Assets[_assetId].buyer.amountEscrowed >= Ledgers[_ledger].Assets[_assetId].minPrice,
      'Buyer escrow amount is less than asset min price'
    );

    ledger.safeTransferFrom(
      address(this),
      Ledgers[_ledger].Assets[_assetId].buyer.wallet,
      _assetId
    );

    if (!Ledgers[_ledger].Assets[_assetId].resale) {
      if (Ledgers[_ledger].RetailSplits.size() > 0) {
        uint256 totalShareSplit = 0;

        for (uint256 i = 0; i < Ledgers[_ledger].RetailSplits.size(); i++) {
          address stakeholder = Ledgers[_ledger].RetailSplits.getKeyAtIndex(i);
          uint256 share = Ledgers[_ledger].RetailSplits.get(stakeholder);

          if (totalShareSplit + share > 100) {
            share = totalShareSplit + share - 100;
          }

          uint256 payout = Ledgers[_ledger].Assets[_assetId].buyer.amountEscrowed * share / 100;
          payable(stakeholder).transfer(payout);
          emit StakeholderPayout(_ledger, _assetId, stakeholder, payout, share, true);
          totalShareSplit += share;

          // ignore other share stake holders if total max split has been reached
          if (totalShareSplit >= 100) {
            break;
          }
        }

        if (totalShareSplit < 100) {
          uint256 remainingShare = 100 - totalShareSplit;
          uint256 payout = Ledgers[_ledger].Assets[_assetId].buyer.amountEscrowed * remainingShare / 100;
          payable(Ledgers[_ledger].Assets[_assetId].owner).transfer(payout);
          emit StakeholderPayout(_ledger, _assetId, Ledgers[_ledger].Assets[_assetId].owner, payout, remainingShare, true);
        }
      } else { // if no revenue split is defined, send all to asset owner
        uint256 payout = Ledgers[_ledger].Assets[_assetId].buyer.amountEscrowed;
        payable(Ledgers[_ledger].Assets[_assetId].owner).transfer(payout);
        emit StakeholderPayout(_ledger, _assetId, Ledgers[_ledger].Assets[_assetId].owner, payout, 100, true);
      }

      Ledgers[_ledger].Assets[_assetId].resale = true;
      Ledgers[_ledger].retailedAssets.push(_assetId);
    } else {
      uint256 totalShareSplit = 0;

      if (
        Ledgers[_ledger].Assets[_assetId].creator.share > 0 &&
        Ledgers[_ledger].Assets[_assetId].creator.wallet != address(0)
      ) {
        uint256 creatorPayout = Ledgers[_ledger].Assets[_assetId].buyer.amountEscrowed * Ledgers[_ledger].Assets[_assetId].creator.share / 100;

        if (creatorPayout > 0) {
          totalShareSplit = Ledgers[_ledger].Assets[_assetId].creator.share;
          payable(Ledgers[_ledger].Assets[_assetId].creator.wallet).transfer(creatorPayout);
        }

        emit StakeholderPayout(
          _ledger,
          _assetId,
          Ledgers[_ledger].Assets[_assetId].creator.wallet,
          creatorPayout,
          Ledgers[_ledger].Assets[_assetId].creator.share,
          false);
      }

      if (Ledgers[_ledger].ResaleSplits.size() > 0) {
        for (uint256 i = 0; i < Ledgers[_ledger].ResaleSplits.size(); i++) {
          address stakeholder = Ledgers[_ledger].ResaleSplits.getKeyAtIndex(i);
          uint256 share = Ledgers[_ledger].ResaleSplits.get(stakeholder) - (Ledgers[_ledger].Assets[_assetId].creator.share / 100);

          if (totalShareSplit + share > 100) {
            share = totalShareSplit + share - 100;
          }

          uint256 payout = Ledgers[_ledger].Assets[_assetId].buyer.amountEscrowed * share / 100;

          payable(stakeholder).transfer(payout);
          emit StakeholderPayout(_ledger, _assetId, stakeholder, payout, share, false);

          totalShareSplit += share;

          // ignore other share stake holders if total max split has been reached
          if (totalShareSplit >= 100) {
            break;
          }
        }

        if (totalShareSplit < 100) {
          uint256 remainingShare = 100 - totalShareSplit;
          uint256 payout = Ledgers[_ledger].Assets[_assetId].buyer.amountEscrowed * remainingShare / 100;
          payable(Ledgers[_ledger].Assets[_assetId].owner).transfer(payout);
          emit StakeholderPayout(_ledger, _assetId, Ledgers[_ledger].Assets[_assetId].owner, payout, remainingShare, false);
        }
      } else { // if no revenue split is defined, send all to asset owner
        uint256 remainingShare = 100 - totalShareSplit;
        uint256 payout = Ledgers[_ledger].Assets[_assetId].buyer.amountEscrowed * remainingShare / 100;
        payable(Ledgers[_ledger].Assets[_assetId].owner).transfer(payout);
        emit StakeholderPayout(_ledger, _assetId, Ledgers[_ledger].Assets[_assetId].owner, payout, remainingShare, false);
      }
    }

    emit EscrowFulfill(
      _ledger,
      _assetId,
      Ledgers[_ledger].Assets[_assetId].owner,
      Ledgers[_ledger].Assets[_assetId].buyer.wallet,
      Ledgers[_ledger].Assets[_assetId].buyer.amountEscrowed
    );

    Ledgers[_ledger].Assets[_assetId].owner = Ledgers[_ledger].Assets[_assetId].buyer.wallet;
    Ledgers[_ledger].Assets[_assetId].minPrice = 0;
    Ledgers[_ledger].Assets[_assetId].buyer.wallet = address(0);
    Ledgers[_ledger].Assets[_assetId].buyer.amountEscrowed = 0;

    success = true;
  }
}
