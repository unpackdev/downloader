// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "./ERC1155.sol";
import "./IERC721.sol";
import "./IERC1155MetadataURI.sol";
import "./AccessControl.sol";
import "./ReentrancyGuard.sol";
import "./ECDSA.sol";

interface IStakingPool {
  function balanceOf(address _owner) external view returns (uint256 balance);
  function burn(address _owner, uint256 _amount) external;
}

interface IStandaloneNft721 is IERC721 {
  
  function totalSupply() external view returns (uint256);
  function numberMintedByAddress(address _address) external view returns (uint256);

  function mintNext(address _to, uint256 _amount) external;
  function addToNumberMintedByAddress(address _address, uint256 amount) external;
}

contract Raini721FunctionsV3 is AccessControl, ReentrancyGuard {
  
  using ECDSA for bytes32;

  struct PoolType {
    uint64 costInUnicorns;
    uint64 costInRainbows;
    uint64 costInEth;
    uint16 maxMintsPerAddress;
    uint32 supply;
    uint32 mintTimeStart; // the timestamp from which the pack can be minted
    bool requiresWhitelist;
  }

  mapping (uint256 => PoolType) public poolTypes;

  uint256 public constant POINT_COST_DECIMALS = 1000000000000000000;

  uint256 public rainbowToEth;
  uint256 public unicornToEth;
  uint256 public minPointsPercentToMint;

  uint256 public maxMintsPerTx;

  mapping(address => bool) public rainbowPools;
  mapping(address => bool) public unicornPools;

  mapping(address => mapping(uint256 => uint256)) public numberMintedByAddress;
  mapping (uint256 => uint) public numberOfPoolMinted;

  uint256 public mintingFeeBasisPoints;

  address public verifier;
  address public contractOwner;
  address payable public ethRecipient;
  address payable public feeRecipient;

  IStandaloneNft721 public nftContract;

  constructor(address _nftContractAddress, uint256 _maxMintsPerTx, address payable _ethRecipient, address payable _feeRecipient, address _contractOwner, address _verifier) {
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    _setupRole(DEFAULT_ADMIN_ROLE, _contractOwner);
    nftContract = IStandaloneNft721(_nftContractAddress);
    contractOwner = _contractOwner;
    ethRecipient = _ethRecipient;
    feeRecipient = _feeRecipient;
    maxMintsPerTx = _maxMintsPerTx;
    verifier = _verifier;
  }

  modifier onlyOwner() {
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()));
    _;
  }

  function setMaxMintsPerTx(uint256 _maxMintsPerTx)
    external onlyOwner {
      maxMintsPerTx = _maxMintsPerTx;
  }

  function setNftContract(address _nftContract)
    external onlyOwner {
      nftContract = IStandaloneNft721(_nftContract);
  }

  function addRainbowPool(address _rainbowPool) 
    external onlyOwner {
      rainbowPools[_rainbowPool] = true;
  }

  function removeRainbowPool(address _rainbowPool) 
    external onlyOwner {
      rainbowPools[_rainbowPool] = false;
  }

  function addUnicornPool(address _unicornPool) 
    external onlyOwner {
      unicornPools[_unicornPool] = true;
  }

  function removeUnicornPool(address _unicornPool) 
    external onlyOwner {
      unicornPools[_unicornPool] = false;
  }

  function setEtherValues(uint256 _unicornToEth, uint256 _rainbowToEth, uint256 _minPointsPercentToMint)
     external onlyOwner {
      unicornToEth = _unicornToEth;
      rainbowToEth = _rainbowToEth;
      minPointsPercentToMint = _minPointsPercentToMint;
   }

  function setFees(uint256 _mintingFeeBasisPoints) 
    external onlyOwner {
      mintingFeeBasisPoints =_mintingFeeBasisPoints;
  }

  function setVerifierAddress(address _verifier) 
    external onlyOwner {
      verifier = _verifier;
  }

  function setFeeRecipient(address payable _feeRecipient) 
    external onlyOwner {
      feeRecipient = _feeRecipient;
  }

  function setEthRecipient(address payable _ethRecipient) 
    external onlyOwner {
      ethRecipient = _ethRecipient;
  }

  function getTotalBalance(address _address, uint256 _start, uint256 _end) 
    external view returns (uint256[][] memory amounts) {
      uint256[][] memory _amounts = new uint256[][](_end - _start);
      uint256 count;
      for (uint256 i = _start; i <= _end; i++) {
        try nftContract.ownerOf(i) returns (address a) {
          if (a == _address) {
            _amounts[count] = new uint256[](2);
            _amounts[count][0] = i;
            _amounts[count][1] = 1;
            count++;
          }
        } catch Error(string memory /*reason*/) {
        }
      }

      uint256[][] memory _amounts2 = new uint256[][](count);
      for (uint256 i = 0; i < count; i++) {
        _amounts2[i] = new uint256[](2);
        _amounts2[i][0] = _amounts[i][0];
        _amounts2[i][1] = _amounts[i][1];
      }

      return _amounts2;
  }



    function initPools(
                     uint256[] memory _poolId,
                     uint256[] memory _supply,
                     uint256[] memory _costInUnicorns, 
                     uint256[] memory _costInRainbows, 
                     uint256[] memory _costInEth, 
                     uint256[] memory _maxMintsPerAddress,  
                     uint32[] memory _mintTimeStart,
                     bool[] memory _requiresWhitelist
                  ) external onlyOwner {
      

      for (uint256 i; i < _poolId.length; i++) {
        poolTypes[_poolId[i]] = PoolType({
            costInUnicorns: uint64(_costInUnicorns[i]),
            costInRainbows: uint64(_costInRainbows[i]),
            costInEth: uint64(_costInEth[i]),
            maxMintsPerAddress: uint16(_maxMintsPerAddress[i]),
            mintTimeStart: uint32(_mintTimeStart[i]),
            supply: uint32(_supply[i]),
            requiresWhitelist: _requiresWhitelist[i]
          });
      }
  }


  struct MintData {
    uint256 totalPriceRainbows;
    uint256 totalPriceUnicorns;
    uint256 minCostRainbows;
    uint256 minCostUnicorns;
    uint256 fee;
    uint256 amountEthToWithdraw;
    uint256 maxMints;
    uint256 totalToMint;
    bool success;
  }

  function checkSigniture(address msgSender, bytes memory sig, uint256 maxMints) public view returns (bool _success) {
    bytes32 _hash = keccak256(abi.encode('Raini721Functions|mint|', msgSender, maxMints));
    address signer = ECDSA.recover(_hash.toEthSignedMessageHash(), sig);
    return signer == verifier;
  }
  
  
  function mint(
      uint256[] memory _poolType,
      uint256[] memory _amount, 
      bool[] memory _useUnicorns, 
      address[] memory _rainbowPools, 
      address[] memory _unicornPools,
      bytes memory sig, 
      uint256 maxMints
    ) external payable nonReentrant {

    require(maxMints == 0 || checkSigniture(_msgSender(), sig, maxMints), 'invalid sig');

    MintData memory _locals = MintData({
      totalPriceRainbows: 0,
      totalPriceUnicorns: 0,
      minCostRainbows: 0,
      minCostUnicorns: 0,
      fee: 0,
      amountEthToWithdraw: 0,
      maxMints: 0,
      totalToMint: 0,
      success: false
    });

    for (uint256 i = 0; i < _poolType.length; i++) {
      
      PoolType memory poolType = poolTypes[_poolType[i]];

      _locals.maxMints = poolType.maxMintsPerAddress == 0 ? 10 ** 10 : poolType.maxMintsPerAddress;
      if (poolType.requiresWhitelist && (maxMints < _locals.maxMints)) {
        _locals.maxMints = maxMints;
      }

      require(block.timestamp >= poolType.mintTimeStart || hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), 'too early');
      require(numberMintedByAddress[_msgSender()][_poolType[i]] + _amount[i] <= _locals.maxMints, "Max mints reached for address");

      uint256 numberMinted = numberOfPoolMinted[_poolType[i]];
      if (numberMinted + _amount[i] > poolType.supply) {
        _amount[i] = poolType.supply - numberMinted;
      }

      _locals.totalToMint += _amount[i];

      if (poolType.maxMintsPerAddress > 0) {
        numberMintedByAddress[_msgSender()][_poolType[i]] += _amount[i];
        numberOfPoolMinted[_poolType[i]] += _amount[i];
      }

      if (poolType.costInUnicorns > 0 || poolType.costInRainbows > 0) {
        if (_useUnicorns[i]) {
          require(poolType.costInUnicorns > 0, "unicorns not allowed");
          uint256 cost = poolType.costInUnicorns * _amount[i] * POINT_COST_DECIMALS;
          _locals.totalPriceUnicorns += cost;
          if (poolType.costInEth > 0) {
            _locals.minCostUnicorns += cost;
          }
        } else {
          require(poolType.costInRainbows > 0, "rainbows not allowed");
          uint256 cost = poolType.costInRainbows * _amount[i] * POINT_COST_DECIMALS;
          _locals.totalPriceRainbows += cost;
          if (poolType.costInEth > 0) {
            _locals.minCostRainbows += cost;
          }
        }

        if (poolType.costInEth == 0) {
          if (poolType.costInRainbows > 0) {
            _locals.fee += (poolType.costInRainbows * _amount[i] * POINT_COST_DECIMALS * mintingFeeBasisPoints) / (rainbowToEth * 10000);
          } else {
            _locals.fee += (poolType.costInUnicorns * _amount[i] * POINT_COST_DECIMALS * mintingFeeBasisPoints) / (unicornToEth * 10000);
          }
        }
      }
      
      _locals.amountEthToWithdraw += poolType.costInEth * _amount[i];
    }
    
    if (_locals.totalPriceUnicorns > 0 || _locals.totalPriceRainbows > 0 ) {
      for (uint256 n = 0; n < 2; n++) {
        bool loopTypeUnicorns = n > 0;

        uint256 totalBalance = 0;
        uint256 totalPrice = loopTypeUnicorns ? _locals.totalPriceUnicorns : _locals.totalPriceRainbows;
        uint256 remainingPrice = totalPrice;

        if (totalPrice > 0) {
          uint256 loopLength = loopTypeUnicorns ? _unicornPools.length : _rainbowPools.length;

          require(loopLength > 0, "invalid pools");

          for (uint256 i = 0; i < loopLength; i++) {
            IStakingPool pool;
            if (loopTypeUnicorns) {
              require((unicornPools[_unicornPools[i]]), "invalid unicorn pool");
              pool = IStakingPool(_unicornPools[i]);
            } else {
              require((rainbowPools[_rainbowPools[i]]), "invalid rainbow pool");
              pool = IStakingPool(_rainbowPools[i]);
            }

            uint256 _balance = pool.balanceOf(_msgSender());
            totalBalance += _balance;

            if (totalBalance >=  totalPrice) {
              pool.burn(_msgSender(), remainingPrice);
              remainingPrice = 0;
              break;
            } else {
              pool.burn(_msgSender(), _balance);
              remainingPrice -= _balance;
            }
          }

          if (remainingPrice > 0) {
            totalPrice -= loopTypeUnicorns ? _locals.minCostUnicorns : _locals.minCostRainbows;
            uint256 minPoints = (totalPrice * minPointsPercentToMint) / 100;
            require(totalPrice - remainingPrice >= minPoints, "not enough balance");
            uint256 pointsToEth = loopTypeUnicorns ? unicornToEth : rainbowToEth;
            require(msg.value * pointsToEth > remainingPrice, "not enough balance");
            _locals.fee += remainingPrice / pointsToEth;
          }
        }
      }
    }


    require(_locals.amountEthToWithdraw + _locals.fee <= msg.value, "not enough eth");

    (_locals.success, ) = _msgSender().call{ value: msg.value - (_locals.amountEthToWithdraw + _locals.fee)}(""); // refund excess Eth
    require(_locals.success, "transfer failed");

    (_locals.success, ) = feeRecipient.call{ value: _locals.fee }(""); // pay fees
    require(_locals.success, "fee transfer failed");
    (_locals.success, ) = ethRecipient.call{ value: _locals.amountEthToWithdraw }(""); // pay eth recipient
    require(_locals.success, "transfer failed");


    require(_locals.totalToMint > 0, 'Allocation exhausted');
    require(_locals.totalToMint <= maxMintsPerTx, '_amount over max');
    
    nftContract.mintNext(_msgSender(), _locals.totalToMint);
  }



  // Allow the owner to withdraw Ether payed into the contract
  function withdrawEth(uint256 _amount)
    external onlyOwner {
      require(_msgSender() == contractOwner);
      require(_amount <= address(this).balance, "not enough balance");
      (bool success, ) = _msgSender().call{ value: _amount }("");
      require(success, "transfer failed");
  }
}