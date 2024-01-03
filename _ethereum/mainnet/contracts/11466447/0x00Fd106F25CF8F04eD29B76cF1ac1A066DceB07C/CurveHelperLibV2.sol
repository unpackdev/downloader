// SPDX-License-Identifier: Apache-2.0-with-puul-exception
pragma solidity >=0.6.12;

import "./SafeMath.sol";
import "./Address.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeCast.sol";
import "./UniswapHelper.sol";
import "./Console.sol";
import "./CurveHelper.sol";
import "./ICurveDepositor.sol";
import "./ICurveGauge.sol";
import "./ICurveRegistry.sol";
import "./ICurveVotingEscrow.sol";
import "./Fees.sol";

library CurveHelperLibV2 {
  using Address for address;
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  uint256 public constant DIVISOR = 10000;
  uint256 public constant MAX_CRV_RESERVE = 5000; // 50%

  address public constant CRV = address(0xD533a949740bb3306d119CC777fa900bA034cd52);
  address public constant USDC = address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
  address public constant DAI = address(0x6B175474E89094C44Da98b954EedeAC495271d0F);
  address public constant USDT = address(0xdAC17F958D2ee523a2206206994597C13D831ec7);
  address public constant TUSD = address(0x0000000000085d4780B73119b644AE5ecd22b376);
  address public constant SUSD = address(0x57Ab1ec28D129707052df4dF418D58a2D46d5f51);
  address public constant HUSD = address(0xdF574c24545E5FfEcb9a659c229253D4111d87e1);
  address public constant GUSD = address(0x056Fd409E1d7A124BD7017459dFEa2F387b6d5Cd);
  address public constant BUSD = address(0x4Fabb145d64652a948d72533023f6E7A623C7C53);
  address public constant MUSD = address(0xe2f2a5C287993345a840Db3B0845fbC70f5935a5);
  address public constant DUSD = address(0x5BC25f649fc4e26069dDF4cF4010F9f706c23831);
  address public constant PAX = address(0x8E870D67F660D95d5be530380D0eC0bd388289E1);
  address public constant USDK = address(0x1c48f86ae57291F7686349F12601910BD8D470bb);
  address public constant USDN = address(0x674C6Ad92Fd080e4004b2312b45f796a192D27a0);
  address public constant RSR = address(0x8762db106B2c2A0bccB3A80d1Ed41273552616E8);
  address public constant MTA = address(0xa3BeD4E1c75D00fa6f4E5E6922DB7261B5E9AcD2);
  address public constant DFD = address(0x20c36f062a31865bED8a5B1e512D9a1A20AA333A);
  address public constant KEEP = address(0x85Eee30c52B0b379b046Fb0F85F4f3Dc3009aFEC);
  address public constant THREEPOOL = address(0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490);
  
  // Curve
  address public constant CRV_VOTING_ESCROW = address(0x5f3b5DfEb7B28CDbD7FAba78963EE202a494e2A2);
  address public constant CRV_VESTING_ESCROW = address(0x575CCD8e2D300e2377B43478339E364000318E2c);
  address public constant CRV_GAUGE_CTLR = address(0x2F50D538606Fa9EDD2B11E2446BEb18C9D5846bB);
  address public constant CRV_MINTER = address(0xd061D61a4d941c39E5453435B6345Dc261C2fcE0);
  address public constant CRV_POOL_PROXY = address(0x6e8f6D1DA6232d5E40b0B8758A0145D6C5123eB7);
  
  address public constant CRV_COMPOUND_SWAP = address(0xA2B47E3D5c44877cca798226B7B8118F9BFb7A56);
  address public constant CRV_COMPOUND_LP = address(0x845838DF265Dcd2c412A1Dc9e959c7d08537f8a2); // cCrv
  address public constant CRV_COMPOUND_DEPOSIT = address(0xeB21209ae4C2c9FF2a86ACA31E123764A3B6Bc06);
  address public constant CRV_COMPOUND_GAUGE = address(0x7ca5b0a2910B33e9759DC7dDB0413949071D7575);

  address public constant CRV_USDT_SWAP = address(0x52EA46506B9CC5Ef470C5bf89f17Dc28bB35D85C);
  address public constant CRV_USDT_LP = address(0x9fC689CCaDa600B6DF723D9E47D84d76664a1F23); // tCrv
  address public constant CRV_USDT_DEPOSIT = address(0xac795D2c97e60DF6a99ff1c814727302fD747a80);
  address public constant CRV_USDT_GAUGE = address(0xBC89cd85491d81C6AD2954E6d0362Ee29fCa8F53);

  address public constant CRV_Y_SWAP = address(0x45F783CCE6B7FF23B2ab2D70e416cdb7D6055f51);
  address public constant CRV_Y_LP = address(0xdF5e0e81Dff6FAF3A7e52BA697820c5e32D806A8); // yCrv
  address public constant CRV_Y_DEPOSIT = address(0xbBC81d23Ea2c3ec7e56D39296F0cbB648873a5d3);
  address public constant CRV_Y_STAKING = address(0x0001FB050Fe7312791bF6475b96569D83F695C9f);
  address public constant CRV_Y_TOKEN_YFI = address(0x0bc529c00C6401aEF6D220BE8C6Ea1667F6Ad93e); // yfi
  address public constant CRV_Y_GAUGE = address(0xFA712EE4788C042e2B7BB55E6cb8ec569C4530c1);

  address public constant CRV_3POOL_SWAP = address(0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7);
  address public constant CRV_3POOL_LP = address(0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490); // 3poolCrv
  address public constant CRV_3POOL_DEPOSIT = address(0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7);
  address public constant CRV_3POOL_GAUGE = address(0xbFcF63294aD7105dEa65aA58F8AE5BE2D9d0952A);

  address public constant CRV_BUSD_SWAP = address(0x79a8C46DeA5aDa233ABaFFD40F3A0A2B1e5A4F27);
  address public constant CRV_BUSD_LP = address(0x3B3Ac5386837Dc563660FB6a0937DFAa5924333B); // bCrv
  address public constant CRV_BUSD_DEPOSIT = address(0xb6c057591E073249F2D9D88Ba59a46CFC9B59EdB);
  address public constant CRV_BUSD_GAUGE = address(0x69Fb7c45726cfE2baDeE8317005d3F94bE838840);

  address public constant CRV_SUSDV2_SWAP = address(0xA5407eAE9Ba41422680e2e00537571bcC53efBfD);
  address public constant CRV_SUSDV2_LP = address(0xC25a3A3b969415c80451098fa907EC722572917F); // sCrv
  address public constant CRV_SUSDV2_DEPOSIT = address(0xFCBa3E75865d2d561BE8D220616520c171F12851);
  address public constant CRV_SUSDV2_STAKING = address(0xDCB6A51eA3CA5d3Fd898Fd6564757c7aAeC3ca92);
  address public constant CRV_SUSDV2_GAUGE = address(0xA90996896660DEcC6E997655E065b23788857849);

  address public constant CRV_PAX_SWAP = address(0x06364f10B501e868329afBc005b3492902d6C763);
  address public constant CRV_PAX_LP = address(0xD905e2eaeBe188fc92179b6350807D8bd91Db0D8); // pCrv
  address public constant CRV_PAX_DEPOSIT = address(0xA50cCc70b6a011CffDdf45057E39679379187287);
  address public constant CRV_PAX_GAUGE = address(0x64E3C23bfc40722d3B649844055F1D51c1ac041d);

  address public constant CRV_GUSD_SWAP = address(0x4f062658EaAF2C1ccf8C8e36D6824CDf41167956);
  address public constant CRV_GUSD_LP = address(0xD2967f45c4f384DEEa880F807Be904762a3DeA07); // gusdCrv
  address public constant CRV_GUSD_DEPOSIT = address(0x0aE274c98c0415C0651AF8cF52b010136E4a0082);
  address public constant CRV_GUSD_GAUGE = address(0xC5cfaDA84E902aD92DD40194f0883ad49639b023);

  address public constant CRV_HUSD_SWAP = address(0x3eF6A01A0f81D6046290f3e2A8c5b843e738E604);
  address public constant CRV_HUSD_LP = address(0x5B5CFE992AdAC0C9D48E05854B2d91C73a003858); // husdCrv
  address public constant CRV_HUSD_DEPOSIT = address(0x0a53FaDa2d943057C47A301D25a4D9b3B8e01e8E);
  address public constant CRV_HUSD_GAUGE = address(0x2db0E83599a91b508Ac268a6197b8B14F5e72840);

  address public constant CRV_USDK_SWAP = address(0x3E01dD8a5E1fb3481F0F589056b428Fc308AF0Fb);
  address public constant CRV_USDK_LP = address(0x97E2768e8E73511cA874545DC5Ff8067eB19B787); // usdkCrv
  address public constant CRV_USDK_DEPOSIT = address(0x6600e98b71dabfD4A8Cac03b302B0189Adb86Afb);
  address public constant CRV_USDK_GAUGE = address(0xC2b1DF84112619D190193E48148000e3990Bf627);

  address public constant CRV_USDN_SWAP = address(0x0f9cb53Ebe405d49A0bbdBD291A65Ff571bC83e1);
  address public constant CRV_USDN_LP = address(0x4f3E8F405CF5aFC05D68142F3783bDfE13811522); // usdnCrv
  address public constant CRV_USDN_DEPOSIT = address(0x35796DAc54f144DFBAD1441Ec7C32313A7c29F39);
  address public constant CRV_USDN_GAUGE = address(0xF98450B5602fa59CC66e1379DFfB6FDDc724CfC4);

  address public constant CRV_MUSD_SWAP = address(0x8474DdbE98F5aA3179B3B3F5942D724aFcdec9f6);
  address public constant CRV_MUSD_LP = address(0x1AEf73d49Dedc4b1778d0706583995958Dc862e6); // musdCrv
  address public constant CRV_MUSD_DEPOSIT = address(0x78CF256256C8089d68Cde634Cf7cDEFb39286470);
  address public constant CRV_MUSD_GAUGE = address(0x5f626c30EC1215f4EdCc9982265E8b1F411D1352);

  address public constant CRV_RSV_SWAP = address(0xC18cC39da8b11dA8c3541C598eE022258F9744da);
  address public constant CRV_RSV_LP = address(0xC2Ee6b0334C261ED60C72f6054450b61B8f18E35); // rsvCrv
  address public constant CRV_RSV_DEPOSIT = address(0xBE175115BF33E12348ff77CcfEE4726866A0Fbd5);
  address public constant CRV_RSV_GAUGE = address(0x4dC4A289a8E33600D8bD4cf5F6313E43a37adec7);

  address public constant CRV_DUSD_SWAP = address(0x8038C01A0390a8c547446a0b2c18fc9aEFEcc10c);
  address public constant CRV_DUSD_LP = address(0x3a664Ab939FD8482048609f652f9a0B0677337B9); // dusdCrv
  address public constant CRV_DUSD_DEPOSIT = address(0x61E10659fe3aa93d036d099405224E4Ac24996d0);
  address public constant CRV_DUSD_GAUGE = address(0xAEA6c312f4b3E04D752946d329693F7293bC2e6D);

  address public constant CRV_REGISTRY = address(0x7002B727Ef8F5571Cb5F9D70D13DBEEb4dFAe9d1);
  address public constant CRV_CALC = address(0xc1DB00a8E5Ef7bfa476395cdbcc98235477cDE4E);

  struct Storage {
    IERC20 ICRV;
    UniswapHelper _uni;
    CurveHelper _curve;
    ICurveRegistry _registry;
    ICurveVotingEscrow _ve;

    address _lp;
    uint256 _crvReserve;
    uint256 _crvReserveAmount;
    bool _crvWhitelisted;
    ICurveGauge _gauge;
    ICurveDepositor _depositor;
    address[] _coins;
    mapping (address => uint256) _decimals;
  }

  function deposit(Storage storage _storage, address token, uint256 amount, uint256 min) external returns (uint256 mint) {
    require(amount > 0, '!amount');
    require(_storage._decimals[token] > 0, '!token');

    // calculate mimimum lps
    // uint256 vp = _storage._depositor.get_virtual_price();
    // uint256 scale = 18 + (18 - _storage._decimals[token]);
    // uint256 v = amount.mul(10**scale).div(vp);
    // uint256 min = v.mul(DIVISOR.sub(slippage)).div(DIVISOR);

    // ready deposit for curve
    IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
    IERC20(token).safeApprove(address(_storage._depositor), 0);
    IERC20(token).safeApprove(address(_storage._depositor), amount);

    // yeah this looks stupid, curve uses fixed arrays, not sure if there is a better way
    int128 idx = _getCoinIdx(_storage, token);
    uint256 v0 = idx == 0 ? amount : 0;
    uint256 v1 = idx == 1 ? amount : 0;
    uint256 v2 = idx == 2 ? amount : 0;
    uint256 v3 = idx == 3 ? amount : 0;
    uint256 v4 = idx == 4 ? amount : 0;
    uint256 bef = IERC20(_storage._lp).balanceOf(address(this));
    if (_storage._coins.length == 3) {
      _storage._depositor.add_liquidity([v0, v1, v2], min);
    } else if (_storage._coins.length == 4) {
      _storage._depositor.add_liquidity([v0, v1, v2, v3], min);
    } else if (_storage._coins.length == 5) {
      _storage._depositor.add_liquidity([v0, v1, v2, v3, v4], min);
    }
    uint256 aft = IERC20(_storage._lp).balanceOf(address(this));
    mint = aft.sub(bef, '!lp');
  }

  function getMinAmount(Storage storage _storage, address token, uint256 amount, uint256 slippage) external view returns (uint256 min) {
    int128 idx = _getCoinIdx(_storage, token);
    uint256 v0 = idx == 0 ? amount : 0;
    uint256 v1 = idx == 1 ? amount : 0;
    uint256 v2 = idx == 2 ? amount : 0;
    uint256 v3 = idx == 3 ? amount : 0;
    uint256 v4 = idx == 4 ? amount : 0;
    if (_storage._coins.length == 3) {
      min = _storage._depositor.calc_token_amount([v0, v1, v2], true);
    } else if (_storage._coins.length == 4) {
      min = _storage._depositor.calc_token_amount([v0, v1, v2, v3], true);
    } else if (_storage._coins.length == 5) {
      min = _storage._depositor.calc_token_amount([v0, v1, v2, v3, v4], true);
    }
    min = min.mul(DIVISOR.sub(slippage)).div(DIVISOR);
  }

  function removeLiquidity(Storage storage _storage, address token, uint256 amount, uint256 min) external {
    int128 i = _getCoinIdx(_storage, token);
    uint256 bef = IERC20(token).balanceOf(address(this));
    IERC20(_storage._lp).safeApprove(address(_storage._depositor), 0);
    IERC20(_storage._lp).safeApprove(address(_storage._depositor), amount);
    _storage._depositor.remove_liquidity_one_coin(amount, i, min);
    uint256 aft = IERC20(token).balanceOf(address(this));
    IERC20(token).safeTransfer(msg.sender, aft.sub(bef));
  }

  function convertFees(Fees _fees, IERC20 reward, uint256 amount) external returns(uint256 feeAmt) {
    feeAmt = _fees.rewardFee(amount);
    if (feeAmt > 0) {
      address dest = _fees.reward();
      require(dest != address(0));
      reward.safeTransfer(dest, feeAmt);
    }
  }

  function earn(Storage storage _storage) external {
    uint256 total = IERC20(_storage._lp).balanceOf(address(this));
    if (total > 0) {
      IERC20(_storage._lp).safeApprove(address(_storage._gauge), 0);
      IERC20(_storage._lp).safeApprove(address(_storage._gauge), total);
      _storage._gauge.deposit(total);
    }
  }

  function unearn(Storage storage _storage, uint256 amount) external {
    uint256 balance = IERC20(_storage._lp).balanceOf(address(this));
    if (amount > balance) {
      _storage._gauge.withdraw(amount - balance);
    }
  }

  function _getCoinIdx(Storage storage _storage, address token) internal view returns (int128) {
    address[] memory coins = _getCoins(_storage);
    for (uint256 i = 0; i < coins.length; i++) {
      if (coins[i] == token) return SafeCast.toInt128(SafeCast.toInt256(i));
    }
    revert('!coinIdx');    
  }

  function estimateWithdraw(Storage storage _storage, address token, uint256 amount, uint256 slippage) external view returns (uint256 est) {
    int128 i = _getCoinIdx(_storage, token);
    est = _storage._depositor.calc_withdraw_one_coin(amount, i);
    est = est.mul(DIVISOR.sub(slippage)).div(DIVISOR);
  }

  function getAmounts(Storage storage _storage, address token, uint256 amount) external view returns (uint256[] memory amounts) {
    return _getAmounts(_storage, token, amount);
  }

  function _getAmounts(Storage storage _storage, address token, uint256 amount) internal view returns (uint256[] memory amounts) {
    address[] memory coins = _getCoins(_storage);
    amounts = new uint256[](coins.length);
    for (uint256 i = 0; i < coins.length; i++) {
      amounts[i] = coins[i] == token ? amount : 0;
    }    
  }

  function _getCoins(Storage storage _storage) internal view returns(address[] memory coins) {
    uint256 len = _storage._coins.length;
    coins = new address[](len);
    for (uint256 i = 0; i < len; i++) {
      coins[i] = _storage._coins[i];
    }
  }

  function createLock(Storage storage _storage, uint256 amount, uint256 lockTime) external {
    require(_storage._crvWhitelisted, '!white');
    require(_storage._crvReserve >= amount, '!crv');
    _storage._crvReserve = _storage._crvReserve.sub(amount);
    _storage._ve.create_lock(amount, lockTime);
  }

  function increaseLock(Storage storage _storage, uint256 amount) external {
    require(_storage._crvWhitelisted, '!white');
    require(_storage._crvReserve >= amount, '!crv');
    _storage._crvReserve = _storage._crvReserve.sub(amount);
    _storage._ve.increase_amount(amount);
  }

  function extendLock(Storage storage _storage, uint256 lockTime) external {
    require(_storage._crvWhitelisted, '!white');
    _storage._ve.increase_unlock_time(lockTime);
  }

}
