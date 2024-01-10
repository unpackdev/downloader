// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma abicoder v2;

import "./Ownable.sol";
import "./IERC20.sol";
import "./IUniswapV2Router01.sol";
import "./IUniswapV2Pair.sol";
import "./IUniverseVaultV3.sol";
import "./IHypervisor.sol";
import "./INonfungiblePositionManager.sol";
import "./SafeMath.sol";
import "./FullMath.sol";
import "./SafeERC20.sol";
interface IUniverseResolver{

    function checkBindingStatus(address universeVault, address vault) external view returns(bool);

    function checkUniverseVault(address universeVault) external view returns(bool);

}


contract UniverseMigrateV1 {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IUniverseResolver addressResolver;
    INonfungiblePositionManager constant nonfungiblePositionManager = INonfungiblePositionManager(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);
    //token => user => balance
    mapping(address=>mapping(address=>uint256)) _balances;
    //vault => bool
    mapping(address=>bool) approveStatus;

    enum LpType { UniV2, UniV3, Visor }

    struct UserData {
        uint256 s; //lp、share、tokenId...
        uint256 liquidity;
        uint256 amt0;
        uint256 amt1;
    }

    constructor(address _resolver) {
        addressResolver = IUniverseResolver(_resolver);
    }

    /* ========== STAKING FUNCTION ========== */

    function balanceOf(address tokenAddress, address user) external view returns(uint256){
        return _balances[tokenAddress][user];
    }

    function staking(address tokenAddress, uint256 amount) external {
        IERC20(tokenAddress).safeTransferFrom(msg.sender, address(this), amount);
        _balances[tokenAddress][msg.sender] = _balances[tokenAddress][msg.sender].add(amount);
        // EVENT
        emit Staking(msg.sender, tokenAddress, amount);
    }

    function _amountUpdate(address tokenAddress, uint256 amount) internal returns(uint256) {
        uint256 balance = _balances[tokenAddress][msg.sender];
        if(amount > balance){
            amount = balance;
        }
        require(amount > 0, "unStaking ZERO");
        _balances[tokenAddress][msg.sender] = balance.sub(amount);
        return amount;
    }

    function unStaking(address tokenAddress, uint256 amount) external {
        amount = _amountUpdate(tokenAddress, amount);
        IERC20(tokenAddress).safeTransfer(msg.sender, amount);
        // EVENT
        emit UnStaking(msg.sender, tokenAddress, amount);
    }

    function unStakingAndDeposit(address tokenAddress, address universeVault, uint256 amount) external {
        amount = _amountUpdate(tokenAddress, amount);
        _migrateFromUniV2(tokenAddress, universeVault, amount); // TODO 验证对应关系
    }

    /* ========== MIGRATE VIEW ========== */

    function balanceList(
        address user,
        address _vaultAddress,
        address[] memory tokenAddressList,
        LpType[] memory types
    ) external view returns(UserData[][] memory userDatas){
        uint len = types.length;
        userDatas = new UserData[][](len);
        for(uint i; i < len; i++){
            if(types[i] == LpType.UniV2){// uniswap v2 or sushi
                UserData[] memory temp = new UserData[](1);
                temp[0] = balanceUniV2(user, tokenAddressList[i]);
                userDatas[i] = temp;
            }else if(types[i] == LpType.Visor){ //visor
                UserData[] memory temp = new UserData[](1);
                temp[0] = balanceVisor(user, tokenAddressList[i]);
                userDatas[i] = temp;
            }else if(types[i] == LpType.UniV3){ //uniswap v3 NFT
                userDatas[i] = balanceUniV3(user, _vaultAddress);
            }else{
                UserData[] memory temp = new UserData[](1);
                temp[0] = UserData({
                                s: 0,
                                liquidity: 0,
                                amt0: 0,
                                amt1: 0
                });
                userDatas[i] = temp;
            }
        }
        return userDatas;
    }

    function balanceUniV2(
        address user,
        address v2Address
    ) public view returns(UserData memory userData){
        //uniswap v2
        IUniswapV2Pair pair = IUniswapV2Pair(v2Address);
        uint256 lp = pair.balanceOf(user);
        uint256 amount0;
        uint256 amount1;
        if(lp > 0) {
            uint256 totalLp = pair.totalSupply();
            (uint256 reserves0, uint256 reserves1,) = pair.getReserves();
            amount0 = FullMath.mulDiv(lp, reserves0, totalLp);
            amount1 = FullMath.mulDiv(lp, reserves1, totalLp);
        }
        userData = UserData({
            s: lp,
            liquidity: 0,
            amt0: amount0,
            amt1: amount1
        });
    }

    function balanceUniV3(
        address user,
        address _vaultAddress
    ) public view returns(UserData[] memory userDatas){
        IUniverseVaultV3 vault = IUniverseVaultV3(_vaultAddress);
        //find NFT number
        uint256 num = nonfungiblePositionManager.balanceOf(user);
        uint256 i;
        UserData[] memory tempDatas = new UserData[](num);
        for(uint index; index < num; index++){
            uint256 tokenId = nonfungiblePositionManager.tokenOfOwnerByIndex(user, index);
            (, , address token0, address token1, , , , uint128 _liquidity, , , uint128 tokensOwed0, uint128 tokensOwed1) = nonfungiblePositionManager.positions(tokenId);
            if(address(vault.token0()) == token0 && address(vault.token1()) == token1){
                tempDatas[index] = UserData({
                    s: tokenId,
                    liquidity: _liquidity,
                    amt0: tokensOwed0,
                    amt1: tokensOwed1
                });
                i++;
            }
        }
        userDatas = new UserData[](i);
        uint j;
        for(uint index ; index < num; index++){
            if(tempDatas[index].s > 0){
                userDatas[j] = tempDatas[index];
                j++;
            }
        }
        return userDatas;
    }

    function balanceVisor(
        address user,
        address visorAddress
    ) public view returns(UserData memory userData){
         require(visorAddress != address(0), "ZERO ADDRESS");
         IHypervisor visor = IHypervisor(visorAddress);
         uint256 share = visor.balanceOf(user);
         uint256 amount0;
         uint256 amount1;
         if(share > 0){
             uint256 totalShare = visor.totalSupply();
             (amount0, amount1) = visor.getTotalAmounts();
             amount0 = FullMath.mulDiv(share, amount0, totalShare);
             amount1 = FullMath.mulDiv(share, amount1, totalShare);
         }
         userData = UserData({
            s: share,
            liquidity: 0,
            amt0: amount0,
            amt1: amount1
         });
    }

    /* ========== MIGRATE EXTERNAL ========== */

    function migrate(address from, address to, uint256 amount, LpType dstType) external {
        if (dstType == LpType.UniV2) {
            _migrateFromUniV2(from, to, amount);
        } else if (dstType == LpType.Visor) {
            _migrateFromVisor(from, to, amount);
        } else if (dstType == LpType.UniV3) {
            _migrateFromUniV3NFT(from, to, amount);
        }
    }

    function _migrateFromUniV2(
        address v2Address,
        address universeVault,
        uint256 v2Amount
    ) internal {
        require(addressResolver.checkBindingStatus(universeVault, v2Address));
        IUniswapV2Pair pair = IUniswapV2Pair(v2Address);
        IUniverseVaultV3 vault = IUniverseVaultV3(universeVault);
        uint256 maxAmount = pair.balanceOf(msg.sender);
        if (v2Amount > maxAmount) {v2Amount = maxAmount;}
        require(v2Amount > 0, "ZERO Liq");
        // Transfer and Burn
        pair.transferFrom(msg.sender, v2Address, v2Amount);
        (uint256 amount0, uint256 amount1) = pair.burn(address(this));
        // Add to Universe
        approve(universeVault);
        vault.deposit(amount0, amount1, msg.sender);
        // Event
        emit MigrateFromUniV2(msg.sender, v2Address, v2Amount, universeVault, amount0, amount1);
    }

    function _migrateFromVisor(
        address visorAddress,
        address universeVault,
        uint256 visorLpAmount
    ) internal {
        require(addressResolver.checkBindingStatus(universeVault, visorAddress));
        IHypervisor visor = IHypervisor(visorAddress);
        IUniverseVaultV3 vault = IUniverseVaultV3(universeVault);
        uint256 maxAmount = visor.balanceOf(msg.sender);
        if (visorLpAmount > maxAmount) {visorLpAmount = maxAmount;}
        require(visorLpAmount > 0, "ZERO Liq");
        // send lp to address this
        visor.transferFrom(msg.sender, address(this), visorLpAmount);
        // Withdraw
        (uint256 amount0, uint256 amount1) = visor.withdraw(visorLpAmount, address(this), address(this));
        // Add to Universe
        approve(universeVault);
        vault.deposit(amount0, amount1, msg.sender);
        // Event
        emit MigrateFromVisor(msg.sender, visorAddress, visorLpAmount, universeVault, amount0, amount1);
    }


    function _migrateFromUniV3NFT(
        address ,
        address vaultAddress,
        uint256 tokenId
    ) internal {
        require(addressResolver.checkUniverseVault(vaultAddress));
        IUniverseVaultV3 vault = IUniverseVaultV3(vaultAddress);
        ( , , , , , , , uint128 liq, , , , ) = nonfungiblePositionManager.positions(tokenId);
        require(liq > 0,"ZERO");

        INonfungiblePositionManager.DecreaseLiquidityParams  memory decreaseLiquidityParam
            = INonfungiblePositionManager.DecreaseLiquidityParams({
                tokenId: tokenId ,
                liquidity: liq ,
                amount0Min: 0 ,
                amount1Min: 0 ,
                deadline: block.timestamp
            });
        nonfungiblePositionManager.decreaseLiquidity(decreaseLiquidityParam);

        INonfungiblePositionManager.CollectParams memory collectParams
        = INonfungiblePositionManager.CollectParams({
            tokenId: tokenId ,
            recipient: address(this) ,
            amount0Max: type(uint128).max ,
            amount1Max: type(uint128).max
            });

        (uint amountA, uint amountB) = nonfungiblePositionManager.collect(collectParams);

        //add to uniswap v3
        approve(vaultAddress);
        vault.deposit(amountA, amountB, msg.sender);
    }


    /* ========== INTERNAL ========== */

    function approve(address universeVault) internal {
        if (!approveStatus[universeVault]) {
            IUniverseVaultV3 vault = IUniverseVaultV3(universeVault);
            vault.token0().approve(universeVault, uint256(-1));
            vault.token1().approve(universeVault, uint256(-1));
            approveStatus[universeVault] = true;
        }
    }


    /* ========== EVENT ========== */

    event Staking(
        address indexed user,
        address tokenAddress,
        uint256 amount
    );

    event UnStaking(
        address indexed user,
        address tokenAddress,
        uint256 amount
    );

    event MigrateFromUniV2(
        address indexed user,
        address lpAddress,
        uint256 lpAmout,
        address universeVault,
        uint256 amount0,
        uint256 amount1
    );

    event MigrateFromVisor(
        address indexed user,
        address lpAddress,
        uint256 lpAmout,
        address universeVault,
        uint256 amount0,
        uint256 amount1
    );

}
