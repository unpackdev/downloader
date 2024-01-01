// SPDX-License-Identifier: GPL-3.0-or-later

// ░██╗░░░░░░░██╗░██╗░██╗░░░░░░██████╗░░██╗░░██╗░██╗░░░██╗░███████╗
// ░██║░░██╗░░██║░██║░██║░░░░░░██╔══██╗░╚██╗██╔╝░╚██╗░██╔╝░╚════██║
// ░╚██╗████╗██╔╝░██║░██║░░░░░░██║░░██║░░╚███╔╝░░░╚████╔╝░░░░███╔═╝
// ░░████╔═████║░░██║░██║░░░░░░██║░░██║░░██╔██╗░░░░╚██╔╝░░░██╔══╝░░
// ░░╚██╔╝░╚██╔╝░░██║░███████╗░██████╔╝░██╔╝╚██╗░░░░██║░░░░███████╗
// ░░░╚═╝░░░╚═╝░░░╚═╝░╚══════╝░╚═════╝░░╚═╝░░╚═╝░░░░╚═╝░░░░╚══════╝

// It ain't much, but it's honest work.

pragma solidity ^0.8.17;

import "./WildxyzGroupOasis.sol";
import "./WildxyzGroupAllowlistSigner.sol";

import "./ProcessPresaleMintable.sol";

contract WildxyzBundlePurchase is WildxyzGroupOasis, WildxyzGroupAllowlistSigner, ProcessPresaleMintable {

  uint256 public groupId_ArtistCollectors;
  uint256 public groupId_PartnersA;
  uint256 public groupId_PartnersB;

  struct ContractInfo {
    State state;
    uint256 maxSupply;
    uint256 totalSupply;
    uint256 remainingSupply;
    uint256 maxPerAddress;
    uint256 maxPerOasis;
    uint256 extraTokensPerBundle;
    uint256 extraTokenPrice;
    uint256 extraTokensTotalSupply;
    address allowlistSigner;
    Group[] groups;
  }

  struct UserInfo {
    uint256 userGroupId;
    uint256 bundleAllowance;
    uint256 extraTokenAllowance;
    bool isGroupLive;
    BundlePurchaseInfo bundlePurchaseInfo;
  }

  // bundle variables

  struct BundlePurchaseInfo {
    address owner;

    uint256 numBundles;
    uint256 numExtraTokens;

    uint256 value; // total eth value sent for this bundle + extra tokens

    uint256 numExtraTokensProcessed;

    bool processed;
  }

  enum PurchaseType {
    Oasis,
    ArtistCollectors,
    PartnersA,
    PartnersB
  }

  uint256 public extraTokensPerBundle = 2;

  mapping(address => BundlePurchaseInfo) private bundlePurchaseInfo;

  mapping(address => mapping(uint256 => uint256)) public numBundlesProcessedPerCollectionId;

  address[] public bundleOwners;

  uint256 public numBundleOwners;

  uint256 public bundleTotalSupply;
  uint256 public extraTokensTotalSupply;

  // presale minting logic

  PresaleMinterInfo[] public presaleMinters; // minter to use to mint in the bundle
  PresaleMinterInfo public extraTokenMinter; // minter to use to mint for extra tokens

  uint256 public numPresaleMinters;

  uint256 public extraTokenPrice;

  // events

  event BundlePurchased(address indexed to, uint256 quantity, uint256 extraTokens, uint256 amount, PurchaseType purchaseType, bool isDelegated, address vault);

  event ExtraTokensPurchased(address indexed to, uint256 quantity, uint256 amount);

  event BundlePurchaseProcessed(address indexed to, uint256 indexed amount, uint256 indexed extraTokens);

  // errors

  error MustPurchaseBundleBeforeAddingExtraTokens(address to);

  error MaxExtraTokensPerBundleExceeded(address to);

  error NFTAlreadyExistsInBundle(address nft);

  error NFTDoesNotExistInBundle(address nft);

  error AlreadyProcessedBundlePurchase(address to);

  // constructor

  constructor (uint256 _maxSupply, uint256 _maxPerAddress, uint256 _wildRoyalty, address _wildWallet, address _artistWallet, IAdminBeaconUpgradeable _adminBeacon, ISanctionsList _sanctions, PresaleMinterInfo[] memory _presaleMinters, PresaleMinterInfo memory _extraTokenMinter)
    WildxyzGroup(_maxSupply, _maxPerAddress, _wildRoyalty, _wildWallet, _artistWallet, _adminBeacon, _sanctions)
  {
    for (uint256 i = 0; i < _presaleMinters.length; i++) {
      presaleMinters.push(_presaleMinters[i]);
    }

    numPresaleMinters = _presaleMinters.length;

    extraTokenMinter = _extraTokenMinter;
  }
  
  function setup(
    uint256[4] memory _startTimes,
    uint256[4] memory _endTimes,
    uint256[4] memory _prices,
    uint256[4] memory _reserveSupply,
    uint256 _extraTokenPrice,
    IOasis _oasis,
    uint256 _maxPerOasis,
    address _allowlistSigner
  ) public onlyOwner setupOnce {
    _setupGroupOasis(_startTimes[0], _endTimes[0], _prices[0], _reserveSupply[0], _oasis, _maxPerOasis);

    groupId_ArtistCollectors = _setupGroupAllowlistSigner('Artist Collectors', _startTimes[1], _endTimes[1], _prices[1], _reserveSupply[1]);

    groupId_PartnersA = _setupGroupAllowlistSigner('Partners Wave 1', _startTimes[2], _endTimes[2], _prices[2], _reserveSupply[2]);
    groupId_PartnersB = _setupGroupAllowlistSigner('Partners Wave 2', _startTimes[3], _endTimes[3], _prices[3], _reserveSupply[3]);

    _setAllowlistSigner(_allowlistSigner);

    extraTokenPrice = _extraTokenPrice;
  }

  // required overrides

  function _totalSupply() internal view virtual override(WildxyzGroup) returns (uint256) {
    return bundleTotalSupply;
  }

  function getUserGroupAllowance(address _user, uint256 _groupId) public view virtual override(WildxyzGroup, WildxyzGroupOasis) returns (uint256) {
    return WildxyzGroupOasis.getUserGroupAllowance(_user, _groupId);
  }

  function getUserGroupTotalSupply(address _user, uint256 _groupId) public view virtual override(WildxyzGroup, WildxyzGroupOasis) returns (uint256) {
    return WildxyzGroupOasis.getUserGroupTotalSupply(_user, _groupId);
  }

  // internal functions

  // in addition to group price checking we check this method,
  // maybe in the future we should override something in the base contract
  function _validPurchasePrice(uint256 _groupId, uint256 _value, uint256 _numBundles, uint256 _numExtraTokens) internal view {
    uint256 groupPrice = getGroupPrice(_groupId);
    uint256 totalValue = _numBundles * groupPrice + _numExtraTokens * extraTokenPrice;

    if (_value < totalValue) revert InsufficientFunds();
  }

  function _validExtraTokenAllowance(address _receiver, uint256 _amount) internal view {
    if (bundlePurchaseInfo[_receiver].numExtraTokens + _amount > bundlePurchaseInfo[_receiver].numBundles * extraTokensPerBundle) revert MaxExtraTokensPerBundleExceeded(_receiver);
  }

  function _onBundlePurchase(address _receiver, uint256 _amount, uint256 _extraTokens, PurchaseType _purchaseType, uint256 _value) internal {
    BundlePurchaseInfo storage purchaseInfo = bundlePurchaseInfo[_receiver];

    if (purchaseInfo.owner == address(0)) {
      purchaseInfo.owner = _receiver;

      bundleOwners.push(_receiver);

      numBundleOwners++;
    }

    purchaseInfo.numBundles += _amount;
    purchaseInfo.value += _value;

    // check extra token allowance
    _validExtraTokenAllowance(_receiver, _extraTokens);

    purchaseInfo.numExtraTokens += _extraTokens;

    // add to total supply trackers
    extraTokensTotalSupply += _extraTokens;

    bundleTotalSupply += _amount;

    _addAddressTotalSupply(_receiver, _amount);

    // emit event
    emit BundlePurchased(_receiver, _amount, _extraTokens, _value, _purchaseType, false, address(0));
  }

  function _onExtraTokensPurchased(address _receiver, uint256 _amount, uint256 _value) internal {
    BundlePurchaseInfo storage purchaseInfo = bundlePurchaseInfo[_receiver];

    if (purchaseInfo.owner == address(0)) revert MustPurchaseBundleBeforeAddingExtraTokens(_receiver);

    _validExtraTokenAllowance(_receiver, _amount);

    purchaseInfo.numExtraTokens += _amount;

    extraTokensTotalSupply += _amount;

    purchaseInfo.value += _value;
  }

  // override

  function _processUseOasisCallback(address _receiver) internal virtual override returns (uint256 tokenId) {
    BundlePurchaseInfo storage purchaseInfo = bundlePurchaseInfo[_receiver];

    if (purchaseInfo.owner == address(0)) {
      purchaseInfo.owner = _receiver;

      bundleOwners.push(_receiver);

      numBundleOwners++;
    }

    purchaseInfo.numBundles++;

    bundleTotalSupply++;

    return 0;
  }

  function _purchaseWithOasis(address _receiver, uint256 _amount, uint256 _extraTokens, uint256 _value, bool isDelegated, address vault) internal {
    _processUseOasis(_receiver, vault, _amount); // this calls the '_processUseOasisCallback' method

    _onExtraTokensPurchased(msg.sender, _extraTokens, 0);

    bundlePurchaseInfo[msg.sender].value += _value;

    emit BundlePurchased(msg.sender, _amount, _extraTokens, _value, PurchaseType.Oasis, isDelegated, vault);

    _addOasisTotalSupply(msg.sender, _amount);
  }

 function _withdraw() internal virtual override {
    (bool successWild, ) = wildWallet.call{value: address(this).balance}('');
    if (!successWild) revert FailedToWithdraw('wild', wildWallet);
 }

  // public functions

  function getUserGroup(address _user, bytes memory _signature) public view virtual override returns (uint256) {
    // oasis takes priority
    if (oasis.balanceOf(_user) > 0) {
      return groupId_Oasis;
    }

    // get and validate signer
    (bool isValidSigner, uint256 signerGroupId) = _verifySignature(_user, _signature);
    if (isValidSigner) {
      return signerGroupId;
    }

    return numGroups; // an invalid group id
  }

  function getUserExtraTokenAllowance(address _user) public view returns (uint256) {
    BundlePurchaseInfo storage purchaseInfo = bundlePurchaseInfo[_user];
    uint256 numBundles = purchaseInfo.numBundles;
    uint256 numExtraTokens = purchaseInfo.numExtraTokens;

    if (numBundles == 0) return 0;

    // in case we change the extra tokens per bundle
    if (numBundles * extraTokensPerBundle < numExtraTokens) return 0;

    return numBundles * extraTokensPerBundle - numExtraTokens;
  }

  function getBundleInfo(address _user) public view returns (BundlePurchaseInfo memory) {
    return bundlePurchaseInfo[_user];
  }

  function getContractInfo() public view virtual returns (ContractInfo memory) {
    return ContractInfo(getState(), maxSupply, _totalSupply(), _remainingSupply(), maxPerAddress, maxPerOasis, extraTokensPerBundle, extraTokenPrice, extraTokensTotalSupply, allowlistSigner, _getGroupsArray());
  }

  function getUserInfo(address _user, bytes memory _signature) public view virtual returns (UserInfo memory) {
    uint256 userGroupId = getUserGroup(_user, _signature);

    return UserInfo(userGroupId, getUserGroupAllowance(_user, userGroupId), getUserExtraTokenAllowance(_user), _isGroupLive(userGroupId), getBundleInfo(_user));
  }

  function getUserContractInfo(address _user, bytes memory _signature) public view returns (UserInfo memory userInfo, ContractInfo memory contractInfo) {
    userInfo = getUserInfo(_user, _signature);
    contractInfo = getContractInfo();
  }

  // only admin

  function setExtraTokensPerBundle(uint256 _extraTokensPerBundle) public onlyAdmin {
    extraTokensPerBundle = _extraTokensPerBundle;
  }

  function setExtraTokenMinter(PresaleMinterInfo memory _extraTokenMinter) public onlyAdmin {
    extraTokenMinter = _extraTokenMinter;
  }

  function addPresaleMinter(PresaleMinterInfo memory _presaleMinter) public onlyAdmin {
    // check if nft already exists
    for (uint256 i = 0; i < presaleMinters.length; i++) {
      if (presaleMinters[i].minterAddress == _presaleMinter.minterAddress) revert NFTAlreadyExistsInBundle(_presaleMinter.minterAddress);
    }

    presaleMinters.push(_presaleMinter);

    numPresaleMinters = presaleMinters.length;
  }

  function removePresaleMinter(PresaleMinterInfo memory _presaleMinter) public onlyAdmin {
    // check if nft exists
    bool found = false;
    for (uint256 i = 0; i < presaleMinters.length; i++) {
      if (presaleMinters[i].minterAddress == _presaleMinter.minterAddress) {
        found = true;
        break;
      }
    }

    if (!found) revert NFTDoesNotExistInBundle(_presaleMinter.minterAddress);

    // remove nft
    for (uint256 i = 0; i < presaleMinters.length; i++) {
      if (presaleMinters[i].minterAddress == _presaleMinter.minterAddress) {
        presaleMinters[i] = presaleMinters[presaleMinters.length - 1];
        presaleMinters.pop();
        break;
      }
    }

    numPresaleMinters = presaleMinters.length;
  }

  function closeBundle() public onlyAdmin {
    // set all group end times to now
    for (uint256 i = 0; i < numGroups; i++) {
      groups[i].endTime = block.timestamp;
    }
  }

  function setAllEndTimes(uint256 _endTime) public onlyAdmin {
    for (uint256 i = 0; i < numGroups; i++) {
      groups[i].endTime = _endTime;
    }
  }

  function setAllPrices(uint256 _price) public onlyAdmin {
    for (uint256 i = 0; i < numGroups; i++) {
      groups[i].price = _price;
    }
  }

  // only owner
  
  // function processBundleMintPerCollection(uint256 _index, uint256 _collectionId) public onlyAdmin {
  //   address receiver = bundleOwners[_index];

  //   if (bundlePurchaseInfo[receiver].processed) revert AlreadyProcessedBundlePurchase(receiver);

  //   BundlePurchaseInfo storage purchaseInfo = bundlePurchaseInfo[receiver];

  //   uint256 numBundles = purchaseInfo.numBundles - numBundlesProcessedPerCollectionId[receiver][_collectionId];
  //   uint256 numExtraTokens = purchaseInfo.numExtraTokens;

  //   // mint _collectionId presale minter
  //   if (numBundles > 0) {
  //     for (uint256 i = 0; i < presaleMinters.length; i++) {
  //       if (presaleMinters[i].collectionId == _collectionId) {
  //         _processPresaleMinter(presaleMinters[i], receiver, numBundles);
  //         break;
  //       }
  //     }
  //   }

  //   // mint extra tokens
  //   if (numExtraTokens > 0 && extraTokenMinter.collectionId == _collectionId) {
  //     _processPresaleMinter(extraTokenMinter, receiver, numExtraTokens);
  //   }

  //   emit BundlePurchaseProcessed(receiver, numBundles, numExtraTokens);

  //   numBundlesProcessedPerCollectionId[receiver][_collectionId] += numBundles;
  //   purchaseInfo.numExtraTokensProcessed += numExtraTokens;

  //   // if all collections have been processed and all extra tokens have been processed
  //   bool allPresaleMintersProcessed = true;
  //   for (uint256 i = 0; i < presaleMinters.length; i++) {
  //     if (numBundlesProcessedPerCollectionId[receiver][presaleMinters[i].collectionId] < purchaseInfo.numBundles) {
  //       allPresaleMintersProcessed = false;
  //       break;
  //     }
  //   }
  //   purchaseInfo.processed = allPresaleMintersProcessed && purchaseInfo.numExtraTokensProcessed == purchaseInfo.numExtraTokens;
  // }

  // function processBundleMintBatchPerCollection(uint256 _fromIndex, uint256 _toIndex, uint256 _collectionId) public onlyAdmin {
  //   for (uint256 i = _fromIndex; i < _toIndex; i++) {
  //     processBundleMintPerCollection(i, _collectionId);
  //   }
  // }

  function processBundleMint(uint256 _index) public onlyAdmin {
    address receiver = bundleOwners[_index];

    if (bundlePurchaseInfo[receiver].processed) revert AlreadyProcessedBundlePurchase(receiver);

    BundlePurchaseInfo storage purchaseInfo = bundlePurchaseInfo[receiver];

    uint256 numBundles = purchaseInfo.numBundles;
    uint256 numExtraTokens = purchaseInfo.numExtraTokens;

    // mint presale minters
    if (numBundles > 0) {
      for (uint256 i = 0; i < presaleMinters.length; i++) {
        uint256 collectionValue = numBundles * presaleMinters[i].price;
        uint256 tokensToMint = numBundles;

        if (presaleMinters[i].collectionId == extraTokenMinter.collectionId) {
          collectionValue += numExtraTokens * extraTokenMinter.price;
          tokensToMint += numExtraTokens;
        }

        _processPresaleMinter(presaleMinters[i], receiver, tokensToMint, collectionValue);
      }
    }

    emit BundlePurchaseProcessed(receiver, numBundles, numExtraTokens);

    purchaseInfo.processed = true;
  }

  function processBundleMintBatch(uint256 _fromIndex, uint256 _toIndex) public onlyAdmin {
    for (uint256 i = _fromIndex; i < _toIndex; i++) {
      processBundleMint(i);
    }
  }

  // public purchase

  function purchaseExtraTokens(uint256 _amount)
    public payable virtual
    onlyUnsanctioned(msg.sender)
    whenNotPaused nonReentrant beforeEndTime
  {
    uint256 totalValue = _amount * extraTokenPrice;
    if (msg.value < totalValue) revert InsufficientFunds();

    _onExtraTokensPurchased(msg.sender, _amount, msg.value);

    emit ExtraTokensPurchased(msg.sender, _amount, msg.value);
  }

  function oasisPurchase(uint256 _amount, uint256 _extraTokens)
    public payable virtual
    onlyUnsanctioned(msg.sender)
    whenNotPaused nonReentrant onlyLive
    validGroupPriceSupply(_amount, groupId_Oasis)
  {
    _validPurchasePrice(groupId_Oasis, msg.value, _amount, _extraTokens);

    _purchaseWithOasis(msg.sender, _amount, _extraTokens, msg.value, false, msg.sender);
  }

  function oasisPurchaseDelegated(uint256 _amount, uint256 _extraTokens, address _vault) 
    public payable virtual
    onlyUnsanctioned(msg.sender)
    whenNotPaused nonReentrant onlyLive
    onlyDelegated(_vault, address(oasis))
    validGroupPriceSupply(_amount, groupId_Oasis)
  {
    _validPurchasePrice(groupId_Oasis, msg.value, _amount, _extraTokens);

    _purchaseWithOasis(msg.sender, _amount, _extraTokens, msg.value, true, _vault);
  }

  // general allowlist mint, looks up group id from signature
  function allowlistPurchase(uint256 _amount, uint256 _extraTokens, bytes memory _signature)
    public payable virtual
    onlyUnsanctioned(msg.sender)
    whenNotPaused nonReentrant onlyLive
  {
    uint256 groupId = _validateSignatureAndGetGroupId(msg.sender, _signature);
    _validGroupPriceSupplyAllowance(msg.sender, _amount, groupId);

    PurchaseType purchaseType;
    if (groupId == groupId_ArtistCollectors) {
      purchaseType = PurchaseType.ArtistCollectors;
    } else if (groupId == groupId_PartnersA) {
      purchaseType = PurchaseType.PartnersA;
    } else if (groupId == groupId_PartnersB) {
      purchaseType = PurchaseType.PartnersB;
    }

    _validPurchasePrice(groupId, msg.value, _amount, _extraTokens);

    _onBundlePurchase(msg.sender, _amount, _extraTokens, purchaseType, msg.value);
  }
}