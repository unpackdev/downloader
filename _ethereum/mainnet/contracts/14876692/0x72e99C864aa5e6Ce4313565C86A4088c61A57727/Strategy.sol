// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.14;
import "./ERC4626.sol";
import "./NotionalProxy.sol";
import "./Ownable.sol";
import "./IArbVault.sol";
import "./nERC1155Interface.sol";
import "./ILadle.sol";
import "./IFlashLoan.sol";

error UnAuthorization();

// reference: https://etherscan.io/address/0x253898A4B57615949eE73892bA22b7cFAc17f715#code
contract Strategy is Ownable {
    address public immutable nProxy = 0x1344A36A1B56144C3Bc62E7757377D288fDE0369;
    ILadle public immutable ladle = ILadle(0x6cB18fF2A33e981D1e38A663Ca056c0a5265066A);

    address public immutable vault;
    address public immutable asset;
    uint16  public immutable currencyID;
    uint256 immutable DECIMALS_DIFFERENCE;
    uint256 immutable maturity;

    // Base for percentage calculations. BPS (10000 = 100%, 100 = 1%)
    uint256 private constant MAX_BPS = 10_000;
    uint256 internal constant BASE_SCALE = 1_000_000;
    uint256 internal constant REWARD_FEE_PCT = 200_000;
    uint256 internal slippage_tolerane = 300;

    // Scaling factor for entering positions as the fcash estimations have rounding errors
    uint256 internal constant FCASH_SCALING = 9_995;



    // YIELD PROTOCOL

    // FYUSDC 2206
    address immutable fytoken = 0x4568bBcf929AB6B4d716F2a3D5A967a1908B4F1C;
    address immutable notionalJoin = 0x62DdD41F8A65B03746656D85b6B2539aE42e23e8;
    address immutable usdcJoin = 0x0d9A1A773be5a83eEbda23bf98efB8585C3ae4f4;
    bytes6 constant seriesID = bytes4(0x30323036);
    bytes6 constant ilkID = bytes4(0x31350000);
    bytes12 yieldVaultID;

    // BALANCER
    address immutable balancerVault = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;
    bool internal flashloanToggle;

    // Constant necessary to accept ERC1155 fcash tokens (for migration purposes)
    bytes4 internal constant ERC1155_ACCEPTED = bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));

    uint256 public totalFYDebt;
    uint256 public totalfCash;

    function onERC1155Received(address _sender, address _from, uint256 _id, uint256 _amount, bytes calldata _data) public returns(bytes4){
        return ERC1155_ACCEPTED;
    }

    function _checkOnlyVault() internal {
        if (msg.sender != vault) {
            revert UnAuthorization();
        }
    }

    constructor(address _vault, uint16 _currencyID) {
        vault = _vault;
        currencyID = _currencyID;
        (Token memory assetToken, Token memory underlyingToken) = NotionalProxy(nProxy).getCurrency(_currencyID);
        //@dev baseAsset unmatched
        require (underlyingToken.tokenAddress == address(IArbVault(vault).asset()));
        {
            nERC1155Interface(nProxy).setApprovalForAll(notionalJoin, true);
            (yieldVaultID, ) = ladle.build(seriesID, ilkID, 0);
        }
        {
            asset = underlyingToken.tokenAddress;
            maturity = IArbVault(vault).maturity();
            ERC20(asset).approve(address(nProxy), type(uint256).max);
            ERC20(asset).approve(usdcJoin, type(uint256).max);

            DECIMALS_DIFFERENCE = uint256(underlyingToken.decimals) * MAX_BPS / uint256(assetToken.decimals);
        }
    }

    function experiment(address target, bytes calldata data) external onlyOwner {
        target.call(data);
    }

    function repayFYDebt(uint256 repayAmount) internal {
        if(repayAmount == 0) {
            return;
        }
        uint256 previousAmount = ERC20(asset).balanceOf(address(this));
        ERC20(asset).transfer(address(ladle), repayAmount);
        ladle.close(yieldVaultID, address(this), -int128(int(totalfCash)), -int128(int(repayAmount)));
        ladle.retrieve(asset, address(this));

        require(ERC20(asset).balanceOf(address(this)) > previousAmount);
    }

    function exit() external returns(uint256 loss, uint256 profit) {
        _checkOnlyVault();
        uint256 currentBalance = ERC20(asset).balanceOf(address(this));
        if (totalFYDebt > currentBalance) {

            address[] memory assets = new address[](1);
            uint256[] memory amounts = new uint256[](1);
            assets[0] =  asset;
            amounts[0] = totalFYDebt - currentBalance;

            flashloanToggle = true;
            IFlashLoan(balancerVault).flashLoan(address(this), assets, amounts, "");
            flashloanToggle = false;
        } else {
            repayFYDebt(totalFYDebt);
            totalFYDebt = 0;
        }
        AccountContext memory _accountContext = NotionalProxy(nProxy).getAccountContext(address(this));

        // If there is something to settle, do it and withdraw to the strategy's balance
        if (uint256(_accountContext.nextSettleTime) < block.timestamp) {
            NotionalProxy(nProxy).settleAccount(address(this));
        }

        (int256 cashBalance,,) = NotionalProxy(nProxy).getAccountBalance(currencyID, address(this));

        if(cashBalance > 0) {
            NotionalProxy(nProxy).withdraw(currencyID, uint88(uint256(cashBalance)), true);
        }
        currentBalance = ERC20(asset).balanceOf(address(this));
        ERC20(asset).transfer(vault, currentBalance);
    }

    function deposit(uint256 assets) external {
        _checkOnlyVault();
        ERC20(asset).transferFrom(msg.sender, address(this), assets);
    }

    function encodeTrade(
        TradeActionType _type,
        uint256 marketIndex,
        uint256 fCashAmount,
        uint256 minImpliedRate
    ) internal pure returns (bytes32) {
        return
            bytes32(
                uint256(
                    (uint256(uint8(_type)) << 248) |
                        (marketIndex << 240) |
                        (fCashAmount << 152) |
                        (minImpliedRate << 120)
                )
            );
    }

    /*
     * @notice
     *  Get the market index of a current position to calculate the real cash valuation
     * @param _maturity, Maturity of the position to value
     * @param _activeMarkets, All current active markets for the currencyID
     * @return uint256 result, market index of the position to value
     */
    function _getMarketIndexForMaturity(
        uint256 _maturity
    ) internal view returns(uint256) {
        MarketParameters[] memory _activeMarkets = NotionalProxy(nProxy).getActiveMarkets(currencyID);
        bool success = false;
        for(uint256 j=0; j<_activeMarkets.length; j++){
            if(_maturity == _activeMarkets[j].maturity) {
                // Return array index + 1 as market indices in Notional start at 1
                return j+1;
            }
        }

        if (success == false) {
            return 0;
        }
    }

    function buyFCash(uint256 underlyingAmount, uint256 _minfCash) internal returns(uint256) {
        require(int256(underlyingAmount) > 0);
        uint256 marketIndex = _getMarketIndexForMaturity(maturity);

        int88 amountTrade = int88(uint88(
            underlyingAmount * MAX_BPS / DECIMALS_DIFFERENCE * FCASH_SCALING / MAX_BPS
        ));

        int256 fCashAmount = NotionalProxy(nProxy).getfCashAmountGivenCashAmount(
            currencyID,
            -amountTrade,
            marketIndex,
            block.timestamp
        );

        require(fCashAmount > 0);
        require(uint256(fCashAmount) > _minfCash);
        BalanceActionWithTrades[] memory action = new BalanceActionWithTrades[](1);
        action[0].actionType = DepositActionType.DepositUnderlying;
        action[0].currencyID = currencyID;
        action[0].depositActionAmount = underlyingAmount;
        action[0].trades = new bytes32[](1);
        action[0].trades[0] = encodeTrade(TradeActionType.Lend, marketIndex, uint88(uint256(fCashAmount)), 0);

        NotionalProxy(nProxy).batchBalanceAndTradeAction(address(this), action);
        return uint256(fCashAmount);
    }

    function borrowFromYield(uint128 collateral, uint128 amount, uint128 max) internal returns(uint256) {
        uint128 art = ladle.serve(yieldVaultID, address(this), collateral, amount, max);
        totalFYDebt += uint256(art);
    }

    function toNotionalDecimal(uint256 underlyingAmount) internal returns (uint256 notionalAmount) {
        notionalAmount = underlyingAmount * MAX_BPS / DECIMALS_DIFFERENCE;
    }

    function invest(uint256 investAmount, uint128 _minfCash, uint128 _maxDebt) external onlyOwner {
        uint256 amount = ERC20(asset).balanceOf(address(this));
        if (investAmount > amount) {
            // get total liquidity
            address[] memory assets = new address[](1);
            uint256[] memory amounts = new uint256[](1);

            assets[0] =  asset;
            amounts[0] = investAmount - amount;

            flashloanToggle = true;
            IFlashLoan(balancerVault).flashLoan(address(this), assets, amounts, abi.encode(investAmount, _minfCash, _maxDebt));
            flashloanToggle = false;
        } else {
            totalfCash += buyFCash(investAmount, _minfCash);
        }
    }

    function estimatedAssets() external view returns(uint256) {
        return ERC20(asset).balanceOf(address(this)) + totalfCash * DECIMALS_DIFFERENCE / MAX_BPS - totalFYDebt;
    }


    function receiveFlashLoan(
        address[] memory tokens,
        uint256[] memory amounts,
        uint256[] memory feeAmounts,
        bytes memory userData
    ) external {
        require(msg.sender == balancerVault);
        require(flashloanToggle);
        uint256 needAmount = amounts[0] + feeAmounts[0];

        if (userData.length > 0) {
            (uint256 investAmount, uint128 minFCash, uint128 maxDebt) = abi.decode(userData, (uint256, uint128, uint128));
            uint256 getFCashAmount = buyFCash(investAmount, uint256(minFCash));
            totalfCash += getFCashAmount;
            uint256 currentWant = ERC20(asset).balanceOf(address(this));
            if (currentWant < needAmount) {
                totalFYDebt += borrowFromYield(uint128(getFCashAmount), uint128(needAmount - currentWant), maxDebt);
            }
        } else {
            repayFYDebt(ERC20(asset).balanceOf(address(this)));
        }
        ERC20(asset).transfer(msg.sender, needAmount);
    }
}