// SPDX-License-Identifier: UNLICENSED
import "./console.sol";
/* 

Contract to manage the Labs funds in curve. 

Operation: 
3crv should be sent to the contract. An "admin" address can control the 3crv funds, including
staking of the 3cerv, claiming crv, and withdrawing either 3crv or crv.

A "bot" address can trigger a "topUp_Cream" call and "topUp_Aave" call, which withdraws the 3crv from swerve,
converts it to USDC, converts the USDC to crUSDC (or aUSDC), and transfers the crUSDC/aUSDC to a 
"creamAddress" or "aaveAddress". An external bot process should monitor the health factor of the creamAddress
and call topUp_Cream to add funds when needed (when the hf is too low).

*/
pragma solidity ^0.6.0;

import "./IERC20.sol";
import "./IGauge.sol";
import "./IMintr.sol";
import "./ISwap.sol";
import "./IComptroller.sol";
import "./ICToken.sol";
import "./IAToken.sol";
import "./ILendingPoolCore.sol";
import "./ILendingPool.sol";
import "./FauxblocksLib.sol";

contract FundsManager {
    // Admin - has access to all functions, including withdrawal
    // bot   - limited acess, mostly to transfer funds from swerve to aave to stave off liquidation
    // Addresses of other contracts with which this contract interacts
    address constant _USDC = address(
        0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48
    );
    function USDC() internal virtual pure returns (address) {
      return _USDC;
    }
    address constant _SWERVE_POOL_1 = address(
        0x329239599afB305DA0A2eC69c58F8a6697F9F88d
    );
    function SWERVE_POOL_1() internal virtual pure returns (address) {
      return _SWERVE_POOL_1;
    }
    address constant _THREE_CRV_GAUGE = address(
        0xbFcF63294aD7105dEa65aA58F8AE5BE2D9d0952A
    );
    function THREE_CRV_GAUGE() internal virtual pure returns (address) {
      return _THREE_CRV_GAUGE;
    }
    address constant _THREE_POOL_SWAPK = address(
        0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7
    );
    address constant _CRV = address(
        0xD533a949740bb3306d119CC777fa900bA034cd52
    );
    function CRV() internal virtual pure returns (address) {
      return _CRV;
    }
    address constant _CRV_MINTR = address(
        0xd061D61a4d941c39E5453435B6345Dc261C2fcE0
    );
    function CRV_MINTR() internal virtual pure returns (address) {
      return _CRV_MINTR;
    }
    address constant _THREE_CRV = address(
        0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490
    );
    function THREE_CRV() internal virtual pure returns (address) {
      return _THREE_CRV;
    }
    function THREE_POOL_SWAPK() internal virtual pure returns (address) {
      return _THREE_POOL_SWAPK;
    }
    address constant _CREAM_COMPTROLLER = address(
        0x3d5BC3c8d13dcB8bF317092d84783c2697AE9258
    );
    function CREAM_COMPTROLLER() internal virtual pure returns (address) {
      return _CREAM_COMPTROLLER;
    }
    address constant _CRUSDC = address(
        0x44fbeBd2F576670a6C33f6Fc0B00aA8c5753b322
    );
    function CRUSDC() internal virtual pure returns (address) {
      return _CRUSDC;
    }
    address constant _AAVE_LENDING_POOL = address(
        0x398eC7346DcD622eDc5ae82352F02bE94C62d119
    );
    function AAVE_LENDING_POOL() internal virtual pure returns (address) {
      return _AAVE_LENDING_POOL;
    }
    address constant _AAVE_LENDING_POOL_CORE = address(
        0x3dfd23A6c5E8BbcFc9581d2E864a68feb6a076d3
    );
    function AAVE_LENDING_POOL_CORE() internal virtual pure returns (address) {
      return _AAVE_LENDING_POOL_CORE;
    }
    address constant _AAVE_AUSDC = address(
        0x9bA00D6856a4eDF4665BcA2C2309936572473B7E
    );
    function AAVE_AUSDC() internal virtual pure returns (address) {
      return _AAVE_AUSDC;
    }
    // ========== MUTATIVE FUNCTIONS ==========

    /**
     * @notice Allows the admin to withdraw any erc20 in the contract
     * @param  amt The amount of the erc20 to withdraw (zero for all)
     * @param  address_erc20 The address of the erc20 to withdraw.
     */
    //
    // CURVE related functions
    //

    /**
     * @notice Stake all 3CRV tokens to the liq gauge. The 3CRV token needs
     * to be transferred to the contract address.
     */
    function stake() public {

        uint256 _amt = IERC20(THREE_CRV()).balanceOf(address(this));
        if (_amt > 0) {
            IERC20(THREE_CRV()).approve(THREE_CRV_GAUGE(), _amt);
            IGauge(THREE_CRV_GAUGE()).deposit(_amt);
        }
    }

    /**
     * @notice unStake swUSD tokens from the swUSD liq gauge.
     * @param amt - if zero, unstake all
     */
    function unstake(uint256 amt) public {
        _unstake(amt);
    }

    /**
     * @notice claim all crv tokens from the liq gauge.
     */
    function claim() public {
        IMintr(CRV_MINTR()).mint(THREE_CRV_GAUGE());
    }

    /**
     * @notice claim all rewarded swrv tokens from the swUSD liq gauge and withdraw
     */
    function claimAndWithdraw() public {
        IMintr(CRV_MINTR()).mint(THREE_CRV_GAUGE());
        require(IERC20(CRV()).transfer(msg.sender, 0), "failed to withdraw");
    }

    /**
     * @notice Unstake from curve pool, convert to USDC,
     *         supply USDC to aave, and transfer to aave address.
     * @param  unstake_amount amount to unstake
     * @param  min_usdc  minimum amount of usdc required to be received from unstake
     */
    function topUpAave_unstake(uint256 unstake_amount, uint256 min_usdc)
        public
    {

        _unstakeToUSDC(unstake_amount, min_usdc);

        uint256 usdc_amt = IERC20(USDC()).balanceOf(address(this));
        require(min_usdc < usdc_amt, "not enough usdc was received");

        IERC20(USDC()).approve(AAVE_LENDING_POOL_CORE(), usdc_amt);
        ILendingPool(AAVE_LENDING_POOL()).deposit(USDC(), usdc_amt, 0);

        //transfer to aave address
        uint256 aUSDC_amt = IAToken(AAVE_AUSDC()).balanceOf(address(this));
        (address aaveAddress) = abi.decode(FauxblocksLib.getContext(), (address));
        IAToken(AAVE_AUSDC()).transfer(aaveAddress, aUSDC_amt);
    }

    /**
     * @notice Unstake swUSD from the swerve gauge, convert all unstaked swUSD to USDC,
     *         supply usdc to cream, and transfer to cream address.
     * @param  unstake_amount amount of swUSD to unstake
     * @param  min_usdc  minimum usdc amount to receive after withdrawing from swerve
     */
    function topUpCream_unstake(uint256 unstake_amount, uint256 min_usdc)
        public
    {

        _unstakeToUSDC(unstake_amount, min_usdc);

        uint256 usdc_amt = IERC20(USDC()).balanceOf(address(this));
        require(min_usdc < usdc_amt, "not enough usdc was received");

        //mint crUSDC from cream, but first need to ensure market is entered
        IComptroller troll = IComptroller(CREAM_COMPTROLLER());
        if (!troll.checkMembership(address(this), CRUSDC())) {
            ICToken[] memory cTokens = new ICToken[](1);
            cTokens[0] = ICToken(CRUSDC());
            troll.enterMarkets(cTokens);
        }
        IERC20(USDC()).approve(CRUSDC(), usdc_amt);
        ICToken(CRUSDC()).mint(usdc_amt);

        //transfer to cream address
        uint256 crUSDC_amt = ICToken(CRUSDC()).balanceOf(address(this));
        (address creamAddress) = abi.decode(FauxblocksLib.getContext(), (address));
        
        ICToken(CRUSDC()).transfer(creamAddress, crUSDC_amt);
    }

    //  *******  VIEW FUNCTIONS  ****

    // ********  INTERNAL FUNCTIONS
    /**
     * @notice unStake 3CRV tokens from the liq gauge.
     * @param amt - if zero, unstake all
     */
    function _unstake(uint256 amt) internal {
        uint256 _amt;
        if (amt == 0) _amt = IGauge(THREE_CRV_GAUGE()).balanceOf(address(this));
        else _amt = amt;

        IERC20(THREE_CRV()).approve(THREE_CRV_GAUGE(), _amt);
        IGauge(THREE_CRV_GAUGE()).withdraw(_amt);
    }

    function _unstakeToUSDC(uint256 unstake_amount, uint256 min_usdc) internal {
        uint256 amt_of_threeCRV;
        if (unstake_amount == 0) amt_of_threeCRV = 0;
        else amt_of_threeCRV = unstake_amount;
        _unstake(amt_of_threeCRV); //unstake from the gauge into threeCRV

        //withdraw as a single usdc tokens
        // coin 1 - usdc
        IERC20(THREE_CRV()).approve(THREE_POOL_SWAPK(), amt_of_threeCRV);
        ISwap(THREE_POOL_SWAPK()).remove_liquidity_one_coin(
            amt_of_threeCRV,
            int128(1),
            min_usdc
        );
    }
}
