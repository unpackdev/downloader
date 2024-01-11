// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
pragma abicoder v2;

// import "./console.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./IERC721Receiver.sol";
import "./IERC1155Receiver.sol";
import "./MerkleProof.sol";

/* solhint-disable not-rely-on-time */
//Interface
abstract contract ERC20Interface {
  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public virtual;

  function transfer(address recipient, uint256 amount) public virtual;
}

abstract contract ERC721Interface {
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
  ) public virtual;

  function balanceOf(address owner) public view virtual returns (uint256 balance);
}

abstract contract ERC1155Interface {
  function safeBatchTransferFrom(
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) public virtual;
}

abstract contract CustomInterface {
  function bridgeSafeTransferFrom(
    address dapp,
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) public virtual;
}

contract VaultSwap is Ownable, Pausable, ReentrancyGuard, IERC721Receiver, IERC1155Receiver {
  using Counters for Counters.Counter;

  // Struct Payment
  struct PaymentStruct {
    bool status;
    uint256 value;
  }

  // Swap Struct
  struct SwapStruct {
    address dapp; // dapp asset contract address, needs to be white-listed
    AssetType typeStd; // the type? (TODO maybe change to enum)
    uint256[] tokenId; // list of asset ids (only 0 used i ncase of non-erc1155)
    uint256[] blc; //
    bytes data;
  }

  // Swap Status
  enum SwapStatus {
    Pending,
    Completed,
    Canceled
  }
  enum AssetType {
    ERC20,
    ERC721,
    ERC1155,
    CUSTOM
  }

  // SwapIntent Struct
  struct SwapIntent {
    uint256 id;
    address payable addressOne;
    uint256 valueOne; // must
    address payable addressTwo; // must
    uint256 valueTwo; //  must
    uint256 swapStart;
    uint256 swapEnd;
    uint256 swapFee;
    SwapStatus status;
  }

  address public swapVaultNFT; // is used to list users that pay no fees (give them vip nfts)
  address payable public vaultAddress; // to pay fees

  mapping(address => address) public dappRelations; // to specify contracts for custom interfaced smart contracts

  bytes32 public _whiteListMerkleRoot; // whitelist of tokens

  bool public whiteListEnabled;

  Counters.Counter private _swapIds;

  // Flag for the createSwap
  bool private swapFlag;

  // NFT Mapping
  mapping(uint256 => SwapStruct[]) public nftsOne; // assets to trade for initiators
  mapping(uint256 => SwapStruct[]) public nftsTwo; // assets to trade for confirtmators

  // Mapping key/value for get the swap infos
  mapping(address => SwapIntent[]) public swapList; // storing swaps of each user
  mapping(uint256 => uint256) public swapMatch; // to check swap_id => number in order of the user's swaps

  // Struct for the payment rules
  PaymentStruct public payment;

  // Events
  event SwapEvent(
    address indexed _creator,
    uint256 indexed time,
    SwapStatus indexed _status,
    uint256 _swapId,
    address _swapCounterPart
  );

  // Events
  event EditCounterPartEvent(address _creator, uint256 time, uint256 _swapId, address _swapCounterPart);
  event WhiteListChange(address _dapp, bool _status);
  event PaymentReceived(address indexed _payer, uint256 _value);

  // solhint-disable-next-line func-visibility
  constructor(address _swapVaultNFT, address _vaultAddress) {
    swapVaultNFT = _swapVaultNFT;
    vaultAddress = payable(_vaultAddress);
  }

  receive() external payable {
    emit PaymentReceived(msg.sender, msg.value);
  }

  /* solhint-disable no-unused-vars */
  function onERC721Received(
    address operator,
    address from,
    uint256 tokenId,
    bytes calldata data
  ) external override returns (bytes4) {
    return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
  }

  function onERC1155Received(
    address operator,
    address from,
    uint256 id,
    uint256 value,
    bytes calldata data
  ) external override returns (bytes4) {
    return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
  }

  function onERC1155BatchReceived(
    address operator,
    address from,
    uint256[] calldata id,
    uint256[] calldata value,
    bytes calldata data
  ) external override returns (bytes4) {
    return bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"));
  }

  /* solhint-enable no-unused-vars */

  function getWeiPayValueAmount() external view returns (uint256) {
    return payment.value;
  }

  // Get swap infos
  function getSwapListByAddress(address _creator) external view returns (SwapIntent[] memory) {
    return swapList[_creator];
  }

  // Get swap infos
  function getSwapIntentByAddress(address _creator, uint256 _swapId) external view returns (SwapIntent memory) {
    return swapList[_creator][swapMatch[_swapId]];
  }

  // Get SwapStructLength
  function getSwapStructSize(uint256 _swapId, bool _nfts) external view returns (uint256) {
    if (_nfts) return nftsOne[_swapId].length;
    else return nftsTwo[_swapId].length;
  }

  // Get SwapStruct
  function getSwapStruct(
    uint256 _swapId,
    bool _nfts,
    uint256 _index
  ) external view returns (SwapStruct memory) {
    if (_nfts) return nftsOne[_swapId][_index];
    else return nftsTwo[_swapId][_index];
  }

  // Get SwapStruct
  function getSwapStructs(uint256 _swapId, bool _nfts) external view returns (SwapStruct[] memory) {
    if (_nfts) return nftsOne[_swapId];
    else return nftsTwo[_swapId];
  }

  function supportsInterface(bytes4 interfaceID) external view virtual override returns (bool) {
    return interfaceID == 0x01ffc9a7 || interfaceID == 0x4e2312e0;
  }

  function checkWhitelist(
    SwapStruct[] memory _nftsOne,
    SwapStruct[] memory _nftsTwo,
    bytes32[][] calldata merkleProofOne,
    bytes32[][] calldata merkleProofTwo
  ) internal view {
    if (whiteListEnabled) {
      uint256 i;
      for (i = 0; i < _nftsOne.length; i++) {
        bool isWhitelisted = MerkleProof.verify(
          merkleProofOne[i],
          _whiteListMerkleRoot,
          keccak256(abi.encodePacked(_nftsOne[i].dapp))
        );
        require(isWhitelisted, "Dapp is not supported"); // check if Dapp is supported
      }
      for (i = 0; i < _nftsTwo.length; i++) {
        bool isWhitelisted = MerkleProof.verify(
          merkleProofTwo[i],
          _whiteListMerkleRoot,
          keccak256(abi.encodePacked(_nftsTwo[i].dapp))
        );
        require(isWhitelisted, "Dapp is not supported"); // check if Dapp is supported
      }
    }
  }

  function initSwapIntent(SwapIntent memory _swapIntent) private view returns (SwapIntent memory) {
    PaymentStruct memory paymentCache = payment;
    if (paymentCache.status) {
      if (ERC721Interface(swapVaultNFT).balanceOf(msg.sender) == 0) {
        _swapIntent.valueOne += paymentCache.value;
        _swapIntent.swapFee = paymentCache.value;
      } else {
        _swapIntent.swapFee = 0;
      }
    }

    _swapIntent.addressOne = payable(msg.sender); // to ensure that only sender can create swap intents
    _swapIntent.id = _swapIds.current(); // set swap id
    _swapIntent.swapStart = block.timestamp; // set the time when swap started
    _swapIntent.swapEnd = 0; // will be set to non-zero on close/cancel
    _swapIntent.status = SwapStatus.Pending; // identify the status of the swap

    return _swapIntent;
  }

  function transferAssetByType(
    SwapStruct memory _swapStruct,
    address _from,
    address _to
  ) private {
    if (_swapStruct.typeStd == AssetType.ERC20) {
      if (_from == address(this)) {
        ERC20Interface(_swapStruct.dapp).transfer(_to, _swapStruct.blc[0]);
      } else {
        ERC20Interface(_swapStruct.dapp).transferFrom(_from, _to, _swapStruct.blc[0]);
      }
    } else if (_swapStruct.typeStd == AssetType.ERC721) {
      uint256 tokenIdIndex;
      for (tokenIdIndex = 0; tokenIdIndex < _swapStruct.tokenId.length; tokenIdIndex++) {
        ERC721Interface(_swapStruct.dapp).safeTransferFrom(
          _from,
          _to,
          _swapStruct.tokenId[tokenIdIndex],
          _swapStruct.data
        );
      }
    } else if (_swapStruct.typeStd == AssetType.ERC1155) {
      ERC1155Interface(_swapStruct.dapp).safeBatchTransferFrom(
        _from,
        _to,
        _swapStruct.tokenId,
        _swapStruct.blc,
        _swapStruct.data
      );
    } else {
      address dappRelation = dappRelations[_swapStruct.dapp];
      if (_from == address(this)) _from = dappRelation;
      if (_to == address(this)) _to = dappRelation;
      CustomInterface(dappRelation).bridgeSafeTransferFrom(
        _swapStruct.dapp,
        _from,
        _to,
        _swapStruct.tokenId,
        _swapStruct.blc,
        _swapStruct.data
      );
    }
  }

  // Create Swap
  function createSwapIntent(
    SwapIntent memory _swapIntent,
    SwapStruct[] memory _nftsOne,
    SwapStruct[] memory _nftsTwo,
    bytes32[][] calldata merkleProofOne,
    bytes32[][] calldata merkleProofTwo
  ) external payable whenNotPaused nonReentrant {
    require(msg.value >= _swapIntent.valueOne, "More eth required"); // Bigger eth value required
    // check the payment satisfies

    _swapIntent = initSwapIntent(_swapIntent);

    swapMatch[_swapIds.current()] = swapList[msg.sender].length; // specify the number of the swap in the list of user swaps
    swapList[msg.sender].push(_swapIntent); // add the swpa intent to the user

    checkWhitelist(_nftsOne, _nftsTwo, merkleProofOne, merkleProofTwo);
    uint256 i;
    for (i = 0; i < _nftsOne.length; i++) {
      nftsOne[_swapIntent.id].push(_nftsOne[i]); // fill swap with initalizer nfts
    }
    for (i = 0; i < _nftsTwo.length; i++) {
      nftsTwo[_swapIntent.id].push(_nftsTwo[i]); // fill swap with respondent nfts
    }

    for (i = 0; i < _nftsOne.length; i++) {
      transferAssetByType(_nftsOne[i], _swapIntent.addressOne, address(this));
    }

    emit SwapEvent(msg.sender, block.timestamp, _swapIntent.status, _swapIntent.id, _swapIntent.addressTwo);
    _swapIds.increment();
  }

  // Close the swap
  function closeSwapIntent(
    address _swapCreator,
    uint256 _swapId,
    bytes32[][] calldata merkleProofOne,
    bytes32[][] calldata merkleProofTwo
  ) external payable whenNotPaused nonReentrant {
    SwapIntent memory swapIntentCache = swapList[_swapCreator][swapMatch[_swapId]];
    require(
      swapIntentCache.status == SwapStatus.Pending,
      "Swap is not opened" // Swap Status is not opened
    );
    require(
      swapIntentCache.addressTwo == msg.sender,
      "Not interested counterpart" // Not the interested counterpart
    );

    uint256 valueRequired = swapIntentCache.valueTwo;
    PaymentStruct memory paymentCache = payment;
    if (paymentCache.status) {
      if (ERC721Interface(swapVaultNFT).balanceOf(msg.sender) == 0) {
        valueRequired += paymentCache.value;
        if (paymentCache.value + swapIntentCache.swapFee > 0)
          vaultAddress.transfer(paymentCache.value + swapIntentCache.swapFee);
      } else {
        if (swapIntentCache.swapFee > 0) vaultAddress.transfer(swapIntentCache.swapFee);
      }
    }

    require(msg.value >= valueRequired, "More eth required"); // Bigger eth value required
    // check the payment satisfies
    delete valueRequired;
    delete paymentCache;

    swapIntentCache.addressTwo = payable(msg.sender); // to make address payable
    swapIntentCache.swapEnd = block.timestamp; // set time of swap closing (TODO maybe move in the end)
    swapIntentCache.status = SwapStatus.Completed; // (TODO maybe move in the end)

    // solhint-disable-next-line reentrancy
    swapList[_swapCreator][swapMatch[_swapId]] = swapIntentCache;

    SwapStruct[] memory _nftsOne = nftsOne[_swapId];
    SwapStruct[] memory _nftsTwo = nftsTwo[_swapId];

    checkWhitelist(_nftsOne, _nftsTwo, merkleProofOne, merkleProofTwo);

    //From Owner 1 to Owner 2
    for (uint256 i = 0; i < _nftsOne.length; i++) {
      transferAssetByType(_nftsOne[i], address(this), swapIntentCache.addressTwo);
    }
    if (swapIntentCache.valueOne > 0) swapIntentCache.addressTwo.transfer(swapIntentCache.valueOne);

    //From Owner 2 to Owner 1
    for (uint256 i = 0; i < _nftsTwo.length; i++) {
      transferAssetByType(_nftsTwo[i], swapIntentCache.addressTwo, swapIntentCache.addressOne);
    }
    if (swapIntentCache.valueTwo > 0) swapIntentCache.addressOne.transfer(swapIntentCache.valueTwo);

    emit SwapEvent(
      msg.sender,
      block.timestamp,
      SwapStatus.Completed,
      _swapId,
      _swapCreator // temp
    );
  }

  // Cancel Swap
  function cancelSwapIntent(address _swapCreator, uint256 _swapId) external nonReentrant {
    SwapIntent memory swapIntentCache = swapList[_swapCreator][swapMatch[_swapId]];
    SwapStruct[] memory _nftsOne = nftsOne[_swapId];
    require(
      swapIntentCache.status == SwapStatus.Pending,
      "Swap is not opened" // Swap Status is not opened
    );
    require(
      msg.sender == swapIntentCache.addressOne || msg.sender == swapIntentCache.addressTwo,
      "Not interested counterpart" // Not the interested counterpart
    );
    //Rollback
    if (swapIntentCache.swapFee > 0) payable(msg.sender).transfer(swapIntentCache.swapFee);

    swapIntentCache.swapEnd = block.timestamp;
    swapIntentCache.status = SwapStatus.Canceled;
    // solhint-disable-next-line reentrancy
    swapList[_swapCreator][swapMatch[_swapId]] = swapIntentCache;

    uint256 i;
    for (i = 0; i < _nftsOne.length; i++) {
      transferAssetByType(_nftsOne[i], address(this), swapIntentCache.addressOne);
    }

    if (swapIntentCache.valueOne > 0) swapIntentCache.addressOne.transfer(swapIntentCache.valueOne);

    emit SwapEvent(msg.sender, block.timestamp, SwapStatus.Canceled, _swapId, address(0));
  }

  // Edit CounterPart Address
  function editCounterPart(uint256 _swapId, address payable _counterPart) external {
    require(
      swapList[msg.sender][swapMatch[_swapId]].id == _swapId &&
        msg.sender == swapList[msg.sender][swapMatch[_swapId]].addressOne,
      "Only for swap initiator" // Only for swap initiator
    );
    swapList[msg.sender][swapMatch[_swapId]].addressTwo = _counterPart;

    emit EditCounterPartEvent(msg.sender, block.timestamp, _swapId, _counterPart);
  }

  // Set SWAPVAULT NFT address
  function setSwapNftAddress(address _swapVaultNFT) external onlyOwner {
    swapVaultNFT = _swapVaultNFT;
  }

  // Set Vault address
  function setVaultAddress(address payable _vaultAddress) external onlyOwner {
    vaultAddress = _vaultAddress;
  }

  // Handle dapp relations for the bridges
  function setDappRelation(address _dapp, address _customInterface) external onlyOwner {
    dappRelations[_dapp] = _customInterface;
  }

  // Handle the whitelist
  function setWhitelist(bytes32 merkleRootTreeHash) external onlyOwner {
    _whiteListMerkleRoot = merkleRootTreeHash;
  }

  // Turn on/off whitelisting by setting opposite boolean
  function toggleWhitelistEnabled() external onlyOwner {
    whiteListEnabled = !whiteListEnabled;
  }

  // Set the payment
  function setPayment(bool _status, uint256 _value) external onlyOwner whenNotPaused {
    payment.status = _status;
    payment.value = _value * (1 wei);
  }
}
