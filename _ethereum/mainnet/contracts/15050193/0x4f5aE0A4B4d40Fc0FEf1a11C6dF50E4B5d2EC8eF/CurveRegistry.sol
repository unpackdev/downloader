// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./SafeERC20.sol";

// solhint-disable func-name-mixedcase
interface ICurveAddressProvider {
  function get_registry() external view returns (address);

  function get_address(uint256 _id) external view returns (address);
}

interface ICurveRegistry {
  function get_pool_from_lp_token(address lpToken)
    external
    view
    returns (address);

  function get_lp_token(address swapAddress) external view returns (address);

  function get_n_coins(address _pool) external view returns (uint256[2] memory);

  function get_coins(address _pool) external view returns (address[8] memory);

  function get_underlying_coins(address _pool)
    external
    view
    returns (address[8] memory);
}

interface ICurveFactoryRegistry {
  function get_n_coins(address _pool) external view returns (uint256);

  function get_coins(address _pool) external view returns (address[4] memory);

  function get_underlying_coins(address _pool)
    external
    view
    returns (address[8] memory);

  function is_meta(address _pool) external view returns (bool);
}

interface ICurveCryptoRegistry {
  function get_pool_from_lp_token(address lpToken)
    external
    view
    returns (address);

  function get_lp_token(address swapAddress) external view returns (address);

  function get_n_coins(address _pool) external view returns (uint256);

  function get_coins(address _pool) external view returns (address[8] memory);
}

// solhint-enable func-name-mixedcase

contract CurveRegistry is Ownable {
  using SafeERC20 for IERC20;

  ICurveAddressProvider private constant CURVE_ADDRESS_PROVIDER =
    ICurveAddressProvider(0x0000000022D53366457F9d5E68Ec105046FC4383);

  ICurveRegistry public CurveMainRegistry;
  ICurveCryptoRegistry public CryptoRegistry;
  ICurveFactoryRegistry public FactoryRegistry;

  address private constant WBTC_ADDRESS =
    0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
  address private constant SBTC_CRV_TOKEN =
    0x075b1bb99792c9E1041bA13afEf80C91a1e70fB3;
  address internal constant ETH_ADDRESS =
    0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

  // Mapping from {poolAddress} to {status}
  mapping(address => bool) public shouldUseUnderlying;
  // Mapping from {poolAddress} to {depositAddress}
  mapping(address => address) private depositAddresses;

  constructor() {
    CurveMainRegistry = ICurveRegistry(CURVE_ADDRESS_PROVIDER.get_registry());

    FactoryRegistry = ICurveFactoryRegistry(
      CURVE_ADDRESS_PROVIDER.get_address(3)
    );

    CryptoRegistry = ICurveCryptoRegistry(
      CURVE_ADDRESS_PROVIDER.get_address(5)
    );

    // @notice Initial assigments for deposit addresses
    depositAddresses[
      0x45F783CCE6B7FF23B2ab2D70e416cdb7D6055f51
    ] = 0xbBC81d23Ea2c3ec7e56D39296F0cbB648873a5d3;
    depositAddresses[
      0xA2B47E3D5c44877cca798226B7B8118F9BFb7A56
    ] = 0xeB21209ae4C2c9FF2a86ACA31E123764A3B6Bc06;
    depositAddresses[
      0x52EA46506B9CC5Ef470C5bf89f17Dc28bB35D85C
    ] = 0xac795D2c97e60DF6a99ff1c814727302fD747a80;
    depositAddresses[
      0x06364f10B501e868329afBc005b3492902d6C763
    ] = 0xA50cCc70b6a011CffDdf45057E39679379187287;
    depositAddresses[
      0x79a8C46DeA5aDa233ABaFFD40F3A0A2B1e5A4F27
    ] = 0xb6c057591E073249F2D9D88Ba59a46CFC9B59EdB;
    depositAddresses[
      0xA5407eAE9Ba41422680e2e00537571bcC53efBfD
    ] = 0xFCBa3E75865d2d561BE8D220616520c171F12851;

    // @notice Which pools should use underlting tokens to add liquidity
    // {address} should/n't user underlting {status}
    shouldUseUnderlying[0xDeBF20617708857ebe4F679508E7b7863a8A8EeE] = true;
    shouldUseUnderlying[0xEB16Ae0052ed37f479f7fe63849198Df1765a733] = true;
  }

  function isCurvePool(address swapAddress) public view returns (bool) {
    if (CurveMainRegistry.get_lp_token(swapAddress) != address(0)) {
      return true;
    }
    return false;
  }

  function isFactoryPool(address swapAddress) public view returns (bool) {
    if (FactoryRegistry.get_coins(swapAddress)[0] != address(0)) {
      return true;
    }
    return false;
  }

  function isCryptoPool(address swapAddress) public view returns (bool) {
    if (CryptoRegistry.get_coins(swapAddress)[0] != address(0)) {
      return true;
    }
    return false;
  }

  /**
    @notice This function is used to check if the curve pool is a metapool
    @notice all factory pools are metapools
    @param swapAddress Curve swap address for the pool
    @return isMeta true if the pool is a metapool, false otherwise
    */
  function isMetaPool(address swapAddress) public view returns (bool isMeta) {
    if (isCurvePool(swapAddress)) {
      uint256[2] memory poolTokenCounts = CurveMainRegistry.get_n_coins(
        swapAddress
      );
      if (poolTokenCounts[0] == poolTokenCounts[1]) return false;
      else return true;
    }
    if (isFactoryPool(swapAddress)) {
      if (FactoryRegistry.is_meta(swapAddress)) {
        return true;
      }
    }
    return isMeta;
  }

  /* 
    @notice This function is used to get the curve pool deposit address
    @notice The deposit address is used for pools with wrapped (c, y) tokens
    @param swapAddress Curve swap address for the pool
    @return depositAddress curve pool deposit address or the swap address not mapped
    */
  function getDepositAddress(address swapAddress)
    external
    view
    returns (address depositAddress)
  {
    depositAddress = depositAddresses[swapAddress];
    if (depositAddress == address(0)) return swapAddress;
  }

  /*
    @notice This function is used to get the curve pool swap address
    @notice The token and swap address is the same for metapool factory pools
    @param swapAddress Curve swap address for the pool
    @return swapAddress curve pool swap address or address(0) if pool doesnt exist
    */
  function getSwapAddress(address tokenAddress)
    external
    view
    returns (address swapAddress)
  {
    swapAddress = CurveMainRegistry.get_pool_from_lp_token(tokenAddress);
    if (swapAddress != address(0)) {
      return swapAddress;
    } else if (isFactoryPool(tokenAddress)) {
      return tokenAddress;
    } else if (
      CryptoRegistry.get_pool_from_lp_token(tokenAddress) != address(0)
    ) {
      return CryptoRegistry.get_pool_from_lp_token(tokenAddress);
    }
    return address(0);
  }

  /*
    @notice This function is used to check the curve pool token address
    @notice The token and swap address is the same for metapool factory pools
    @param swapAddress Curve swap address for the pool
    @return tokenAddress curve pool token address or address(0) if pool doesnt exist
    */
  function getTokenAddress(address swapAddress)
    external
    view
    returns (address tokenAddress)
  {
    tokenAddress = CurveMainRegistry.get_lp_token(swapAddress);
    if (tokenAddress != address(0)) {
      return tokenAddress;
    }
    if (isFactoryPool(swapAddress)) {
      return swapAddress;
    }
    if (isCryptoPool(swapAddress)) {
      return CryptoRegistry.get_lp_token(swapAddress);
    }
    return address(0);
  }

  /**
    @notice Checks the number of non-underlying tokens in a pool
    @param swapAddress Curve swap address for the pool
    @return count The number of underlying tokens in the pool
    */
  function getNumTokens(address swapAddress)
    public
    view
    returns (uint256 count)
  {
    if (isCurvePool(swapAddress)) {
      return CurveMainRegistry.get_n_coins(swapAddress)[0];
    } else if (isCryptoPool(swapAddress)) {
      return CryptoRegistry.get_n_coins(swapAddress);
    } else if (isFactoryPool(swapAddress)) {
      return FactoryRegistry.get_n_coins(swapAddress);
    }
  }

  /**
    @notice This function returns an array of underlying pool token addresses
    @param swapAddress Curve swap address for the pool
    @return poolTokens returns 4 element array containing the addresses of the pool tokens (0 address if pool contains < 4 tokens)
    */
  function getPoolTokens(address swapAddress)
    public
    view
    returns (address[8] memory poolTokens)
  {
    if (isMetaPool(swapAddress)) {
      if (isFactoryPool(swapAddress)) {
        address[4] memory poolTokenCounts = FactoryRegistry.get_coins(
          swapAddress
        );

        for (uint256 i = 0; i < 4; i++) {
          poolTokens[i] = poolTokenCounts[i];
          if (poolTokens[i] == address(0)) break;
        }
      } else if (isCryptoPool(swapAddress)) {
        poolTokens = CryptoRegistry.get_coins(swapAddress);
      } else {
        poolTokens = CurveMainRegistry.get_coins(swapAddress);
      }
    } else {
      if (isBtcPool(swapAddress)) {
        poolTokens = CurveMainRegistry.get_coins(swapAddress);
      } else if (isCurvePool(swapAddress)) {
        if (isEthPool(swapAddress)) {
          poolTokens = CurveMainRegistry.get_coins(swapAddress);
        } else {
          poolTokens = CurveMainRegistry.get_underlying_coins(swapAddress);
        }
      } else if (isCryptoPool(swapAddress)) {
        poolTokens = CryptoRegistry.get_coins(swapAddress);
      } else {
        address[4] memory poolTokenCounts = FactoryRegistry.get_coins(
          swapAddress
        );

        for (uint256 i = 0; i < 4; i++) {
          poolTokens[i] = poolTokenCounts[i];
          if (poolTokens[i] == address(0)) break;
        }
      }
    }
    return poolTokens;
  }

  /**
    @notice This function checks if the curve pool contains WBTC
    @param swapAddress Curve swap address for the pool
    @return true if the pool contains WBTC, false otherwise
    */
  function isBtcPool(address swapAddress) public view returns (bool) {
    address[8] memory poolTokens = CurveMainRegistry.get_coins(swapAddress);
    for (uint256 i = 0; i < 4; i++) {
      if (poolTokens[i] == WBTC_ADDRESS || poolTokens[i] == SBTC_CRV_TOKEN)
        return true;
    }
    return false;
  }

  /**
    @notice This function checks if the curve pool contains ETH
    @param swapAddress Curve swap address for the pool
    @return true if the pool contains ETH, false otherwise
    */
  function isEthPool(address swapAddress) public view returns (bool) {
    address[8] memory poolTokens = CurveMainRegistry.get_coins(swapAddress);
    for (uint256 i = 0; i < 4; i++) {
      if (poolTokens[i] == ETH_ADDRESS) {
        return true;
      }
    }
    return false;
  }

  /**
    @notice This function is used to check if the pool contains the token
    @param swapAddress Curve swap address for the pool
    @param tokenContractAddress contract address of the token
    @return isUnderlying true if the pool contains the token, false otherwise
    @return underlyingIndex index of the token in the pool, 0 if pool does not contain the token
    */
  function isUnderlyingToken(address swapAddress, address tokenContractAddress)
    external
    view
    returns (bool isUnderlying, uint256 underlyingIndex)
  {
    address[8] memory poolTokens = getPoolTokens(swapAddress);
    for (uint256 i = 0; i < 8; i++) {
      if (poolTokens[i] == tokenContractAddress) return (true, i);
    }
  }

  /**
    @notice Updates to the latest curve main registry from the address provider
    */
  function updateCurveRegistry() external onlyOwner {
    address newAddress = CURVE_ADDRESS_PROVIDER.get_registry();
    require(address(CurveMainRegistry) != newAddress, "Already up-to-date");

    CurveMainRegistry = ICurveRegistry(newAddress);
  }

  /**
    @notice Updates to the latest curve v1 factory registry from the address provider
    */
  function updateFactoryRegistry() external onlyOwner {
    address newAddress = CURVE_ADDRESS_PROVIDER.get_address(3);
    require(address(FactoryRegistry) != newAddress, "Already up-to-date");

    FactoryRegistry = ICurveFactoryRegistry(newAddress);
  }

  /**
    @notice Updates to the latest curve crypto registry from the address provider
    */
  function updateCryptoRegistry() external onlyOwner {
    address newAddress = CURVE_ADDRESS_PROVIDER.get_address(5);
    require(address(CryptoRegistry) != newAddress, "Already up-to-date");

    CryptoRegistry = ICurveCryptoRegistry(newAddress);
  }

  /**
    @notice Add new pools which use the _use_underlying bool
    @param swapAddresses Curve swap addresses for the pool
    @param addUnderlying True if underlying tokens are always added
    */
  function updateShouldUseUnderlying(
    address[] calldata swapAddresses,
    bool[] calldata addUnderlying
  ) external onlyOwner {
    require(swapAddresses.length == addUnderlying.length, "Mismatched arrays");
    for (uint256 i = 0; i < swapAddresses.length; i++) {
      shouldUseUnderlying[swapAddresses[i]] = addUnderlying[i];
    }
  }

  /**
    @notice Add new pools which use uamounts for add_liquidity
    @param swapAddresses Curve swap addresses to map from
    @param _depositAddresses Curve deposit addresses to map to
    */
  function updateDepositAddresses(
    address[] calldata swapAddresses,
    address[] calldata _depositAddresses
  ) external onlyOwner {
    require(
      swapAddresses.length == _depositAddresses.length,
      "Mismatched arrays"
    );
    for (uint256 i = 0; i < swapAddresses.length; i++) {
      depositAddresses[swapAddresses[i]] = _depositAddresses[i];
    }
  }

  /**
    @notice Withdraws tokens that had been sent to registry address
    @param tokens ERC20 Token addressess (ZeroAddress if ETH)
    */
  function withdrawTokens(address[] calldata tokens) external onlyOwner {
    for (uint256 i = 0; i < tokens.length; i++) {
      uint256 qty;

      if (tokens[i] == ETH_ADDRESS) {
        qty = address(this).balance;
        Address.sendValue(payable(owner()), qty);
      } else {
        qty = IERC20(tokens[i]).balanceOf(address(this));
        IERC20(tokens[i]).safeTransfer(owner(), qty);
      }
    }
  }
}
