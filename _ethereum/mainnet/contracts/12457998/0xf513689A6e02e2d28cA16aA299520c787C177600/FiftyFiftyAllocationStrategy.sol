pragma solidity 0.6.6;
pragma experimental ABIEncoderV2;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./IAllocationStrategy.sol";
import "./IAaveLendingPoolAddressesProvider.sol";
import "./IAaveLendingPool.sol";
import "./IAToken.sol";
import "./IComptroller.sol";
import "./ICToken.sol";
import "./UniswapModule.sol";

/**
    @title Fifty Fifty allocation strategy
    @author Overall Finance
    @notice Used for allocating oToken funds to Aave and Compound in 50/50 proportion
*/
contract FiftyFiftyAllocationStrategy is IAllocationStrategy, UniswapModule, Ownable {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public COMP;
    IERC20 public underlying;
    IAToken public aToken;
    ICToken public cToken;
    ILendingPoolAddressesProvider public provider;
    IAaveLendingPool public lendingPool;
    IComptroller public comptroller;
    address public uniswapRouter;
    bool initialised;

   /**
        @notice Constructor
        @param _aToken Address of the aToken
        @param _lendingPoolAddressesProvider Address of the Aave lending pool addresses provider
        @param _cToken Address of the cToken
        @param _comptroller Address of the comptroller
        @param _compAddress Address of the COMP token
        @param _underlying Address of the underlying token
        @param _uniswapRouter Address of the UniswapV2Router
    */
    constructor(address _aToken, address _lendingPoolAddressesProvider, address _cToken, address _comptroller, address _compAddress, address _underlying, address _uniswapRouter) public {
        aToken = IAToken(_aToken);
        cToken = ICToken(_cToken);
        COMP = IERC20(_compAddress);
        comptroller = IComptroller(_comptroller);
        underlying = IERC20(_underlying);
        provider = ILendingPoolAddressesProvider(_lendingPoolAddressesProvider);
        lendingPool = IAaveLendingPool(provider.getLendingPool());
        uniswapRouter = _uniswapRouter;
    }

    /**
        @notice Set maximum approves for used protocols
    */
    function setMaxApprovals() external {
        require(!initialised, "Already initialised");
        initialised = true;
        underlying.safeApprove(address(lendingPool), uint256(-1));
        underlying.safeApprove(address(cToken), uint256(-1));
        COMP.safeApprove(uniswapRouter, uint256(-1));
    }

   /**
        @notice Get the amount of underlying in the 50/50 strategy
        @return Balance denominated in the underlying asset
    */
    function balanceOfUnderlying() external override returns (uint256) {
        return aToken.balanceOf(address(this)).add(cToken.balanceOfUnderlying(address(this)));
    }

    /**
        @notice Get the amount of underlying in the 50/50 strategy, while not modifying state
        @return Balance denominated in the underlying asset
    */
    function balanceOfUnderlyingView() public view override returns(uint256) {
        uint256 exchangeRate = cToken.exchangeRateStored();
        return aToken.balanceOf(address(this)).add(cToken.balanceOf(address(this)).mul(exchangeRate).div(10**18));
    }

    /**
        @notice Deposit the underlying token in the protocol
        @param _investAmount Amount of underlying tokens to deposit by 50/50 strategy
    */
    function investUnderlying(uint256 _investAmount) external override onlyOwner returns (uint256) {

        uint256 firstInvestAmount = _investAmount.div(2);
        // TODO consider setting Aave ref id
        lendingPool.deposit(address(underlying), firstInvestAmount, address(this), 0);

        uint256 remainingInvestAmount = _investAmount - firstInvestAmount;
        require(cToken.mint(remainingInvestAmount) == 0, "mint failed");
        return _investAmount;
    }

    /**
        @notice Redeem the underlying asset from the protocol
        @param _redeemAmount Amount of oTokens to redeem
        @param _receiver Address of a receiver
    */
    function redeemUnderlying(uint256 _redeemAmount, address _receiver) external override onlyOwner returns(uint256) {
        uint256 exchangeRate = cToken.exchangeRateStored();
        uint256 underlyingBalance = balanceOfUnderlyingView();
        uint256 redeemAmountAave = _redeemAmount.mul(aToken.balanceOf(address(this))).div(underlyingBalance);
        uint256 redeemAmountCompound = _redeemAmount.mul(cToken.balanceOf(address(this)).mul(exchangeRate).div(10**18)).div(underlyingBalance);

        lendingPool.withdraw(address(underlying), redeemAmountAave, _receiver);

        require(cToken.redeemUnderlying(redeemAmountCompound) == 0, "cToken.redeemUnderlying failed");
        underlying.safeTransfer(_receiver, redeemAmountCompound);

        uint256 redeemedAmount = redeemAmountAave.add(redeemAmountCompound);
        return redeemedAmount;
    }

    /**
        @notice Redeem the entire balance from the underlying protocol
    */
    function redeemAll() external override onlyOwner {
        lendingPool.withdraw(address(underlying), uint256(-1), address(this));
        require(cToken.redeem(cToken.balanceOf(address(this))) == 0, "cToken.redeem failed");
        underlying.safeTransfer(msg.sender, underlying.balanceOf(address(this)));
    }

    /**
        @notice Claim and reinvest yield from protocols
        @param _deadline Deadline for a swap
    */
    function farmYield(uint256 _amountOutMin, uint256 _deadline) public {
        comptroller.claimComp(address(this));
        uint256 compBalance = COMP.balanceOf(address(this));

        if (compBalance > 0) {
            uint256[] memory swappedAmounts = swapTokensThroughETH(address(COMP), address(underlying), compBalance, _amountOutMin, _deadline, uniswapRouter);
            uint256 firstInvestAmount = swappedAmounts[2].div(2);
            // TODO consider setting Aave ref id
            lendingPool.deposit(address(underlying), firstInvestAmount, address(this), 0);

            uint256 remainingInvestAmount = swappedAmounts[2] - firstInvestAmount;
            require(cToken.mint(remainingInvestAmount) == 0, "mint failed");
        }
    }

    /**
        @notice Get unclaimed COMP tokens
    */
    function getUnclaimedComp() public view returns (uint256) {
        uint256 balance = comptroller.compAccrued(address(this));
        balance += supplierComp(address(cToken));
        return balance;
    }

   /**
        @notice Get unclaimed COMP tokens
    */
    function supplierComp(address cTokenAddress) internal view returns (uint256) {
        uint256 supplierIndex = comptroller.compSupplierIndex(cTokenAddress, address(this));
        uint256 supplyIndex = uint256(comptroller.compSupplyState(cTokenAddress).index);
        if (supplierIndex == 0 && supplyIndex > 0) {
            supplierIndex = 1e36;
        }
        require(supplyIndex >= supplierIndex, "CGA: underflow!");
        uint256 deltaIndex = supplyIndex - supplierIndex;
        uint256 supplierAmount = cToken.balanceOf(address(this));
        uint256 supplierDelta = supplierAmount.mul(deltaIndex) / 1e36;

        return supplierDelta;
    }
}
