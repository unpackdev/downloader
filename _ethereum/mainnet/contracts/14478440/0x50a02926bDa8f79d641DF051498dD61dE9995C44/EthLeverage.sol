// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

import "./Ownable.sol";
import "./ERC20.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IFlashLoanRecipient.sol";
import "./IBalancerVault.sol";
import "./ILido.sol";
import "./IWETH.sol";
import "./ILendingPool.sol";
import "./IAaveProtocolDataProvider.sol";
import "./ICurveFi.sol";

// Strat Example
// User deposit 1 ETH
// Flash borrow 2 ETH
// Deposit 3 ETH in Lido
// Deposit 3 stETH on AAVE
// Borrow 2 ETH from AAVE
// Repay Flash loan
// Final position on AAVE : 3 stETH and 2 ETH
// Leverage 3x on stETH, LTV = 66% (max is 70%, liquidation is at 75%)

contract EthLeverage is IFlashLoanRecipient, ERC20, Ownable {
    using SafeERC20 for IERC20;
    // The wallets allowed to deposit withdraw
    mapping(address => bool) private team;

    // An event triggered when a deposit is completed
    event Deposit(uint256 _value);
    // An event triggered when a withdrawal is completed
    event Withdrawal(address indexed _to, uint256 _value);

    address internal constant steth = address(0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84);
    address internal constant lidoPool = address(0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84);
    address internal constant balancerVault = address(0xBA12222222228d8Ba445958a75a0704d566BF2C8);
    address internal constant wethAddress = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    address internal constant lendingPool = address(0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9);
    address private constant dataProvider = address(0x057835Ad21a177dbdd3090bB1CAE03EaCF78Fc6d);
    address private constant curveStEthPool = address(0xDC24316b9AE028F1497c275EB9192a3Ea0f67022);
    uint8 private constant DEPOSIT = 1;
    uint8 private constant REDEEM = 2;
    uint8 private constant LEVERAGE_FACTOR = 3;
    uint8 private constant LEVERAGE_BORROW = 2;
    uint32 public safeSlippageTolerance;
    uint32 private constant DEFAULT_SLIPPAGE_TOLERANCE = 999000;
    uint32 private constant SLIPPAGE_PRECISION = 1000000;

    uint8 public constant INTEREST_RATE_MODE = 2; //variable

    ERC20 weth = ERC20(wethAddress);

    modifier onlyTeam {
        require(team[msg.sender] == true, "Not allowed");
        _;
    }


    constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) {
        safeSlippageTolerance = DEFAULT_SLIPPAGE_TOLERANCE;
        // Add team addresses
        team[0xAfCb545E3F2fA80f1AF9F29262b0bD823CD660D5] = true;
        team[0x0C0BB3535E96b47C0E7A65bEFd1A11B7e13BCBeb] = true;
        team[0xEA29fa603cd0DEdDb183a5Db54FA182b564E8412] = true;
        team[0x90Cc775BB8f21eF9cbA7868c6Aa7e91a13A8a7B8] = true;
        team[0x5fBBa8D0D0C77DB5EF559b2D02BC42460aefd452] = true;
        team[0xD0114334C97b446d6360e6994F742F3F9AB63462] = true;
        team[0x2Dea1237679c5df256DbFddA0fD82b274cD59Bdd] = true;
        team[0x6Cf9AA65EBaD7028536E353393630e2340ca6049] = true;

        IERC20(steth).safeApprove(lendingPool, type(uint).max);
        IERC20(weth).safeApprove(lendingPool, type(uint).max);
        IERC20(steth).safeApprove(curveStEthPool, type(uint).max);
    }

    /**
     * @dev It calculates the total underlying value of {token} held by the vault and the different strategies.
    **/
    function overallBalance() public view returns (uint) {
        uint256 totalBalance = address(this).balance * LEVERAGE_FACTOR;
        totalBalance += getVirtualBalance();
        return totalBalance;
    }

    function getVirtualBalance() private view returns (uint256) {
        (uint256 supplyBal,,,,,,,,) = IAaveProtocolDataProvider(dataProvider).getUserReserveData(steth, address(this));
        return supplyBal;
    }

    /**
     * @dev Deposits an amount in the vault.
    **/
    function deposit() public payable onlyTeam {
        require(msg.value > 0);

        uint256 _amount = msg.value;
        uint256 _pool = overallBalance();

        // Mint shares
        uint256 shares = 0;
        if (totalSupply() == 0) {
            shares = _amount;
        } else {
            uint256 poolShare = _amount * LEVERAGE_FACTOR * 1e18 / _pool;
            shares = poolShare * totalSupply() / (1e18 - poolShare);
        }
        _leverage(_amount);
        _mint(msg.sender, shares);
        emit Deposit(msg.value);
    }

    function _mintSteth(uint256 _amountToDeposit) private returns (uint256) {
        return ILido(lidoPool).submit{value : _amountToDeposit}(0x0000000000000000000000000000000000000000);
    }

    function _leverage(uint256 _amount) internal {
        IERC20[] memory tokens = new IERC20[](1);
        uint256[] memory amounts = new uint256[](1);
        tokens[0] = weth;

        //66% LTV => 2x on original amount + amount = 3x leverage
        amounts[0] = LEVERAGE_BORROW * _amount;
        makeFlashLoan(tokens, amounts, abi.encode(amounts[0], DEPOSIT, 0, 0, msg.sender));
    }


    function makeFlashLoan(
        IERC20[] memory tokens,
        uint256[] memory amounts,
        bytes memory userData
    ) internal {
        IBalancerVault(balancerVault).flashLoan(this, tokens, amounts, userData);
    }

    function receiveFlashLoan(
        IERC20[] memory tokens,
        uint256[] memory amounts,
        uint256[] memory feeAmounts,
        bytes memory userData
    ) external override {
        require(msg.sender == balancerVault);
        (uint256 flashLoanAmount, uint8 order, uint256 stEthWithdrawAmount, uint32 slippageTolerance, address user) = abi.decode(
            bytes(userData)
        , (uint256
            , uint8
            , uint256
            , uint32
            , address));

        if (order == DEPOSIT) {
            // Unwrap ETH
            IWETH(wethAddress).withdraw(IERC20(wethAddress).balanceOf(address(this)));

            _mintSteth(address(this).balance);
            ILendingPool(lendingPool).deposit(steth, IERC20(steth).balanceOf(address(this)), address(this), 0);

            ILendingPool(lendingPool).borrow(wethAddress, flashLoanAmount, INTEREST_RATE_MODE, 0, address(this));

            //repay flashloan
            IERC20(wethAddress).transfer(balancerVault, IERC20(wethAddress).balanceOf(address(this)));
        }

        if (order == REDEEM) {
            ILendingPool(lendingPool).repay(wethAddress, flashLoanAmount, INTEREST_RATE_MODE, address(this));

            ILendingPool(lendingPool).withdraw(steth, stEthWithdrawAmount, address(this));

            uint expectedAmountOut = ICurveFi(curveStEthPool).calc_token_amount([0, stEthWithdrawAmount], false);
            uint256 min_dy = slippageTolerance * expectedAmountOut / SLIPPAGE_PRECISION;
            ICurveFi(curveStEthPool).exchange(1, 0, stEthWithdrawAmount, min_dy);

            // Wrap ETH
            IWETH(wethAddress).deposit{value : flashLoanAmount}();

            //repay flash loan
            IERC20(wethAddress).transfer(balancerVault, flashLoanAmount);

            //put the default Slippage Tolerance back to default
            safeSlippageTolerance = DEFAULT_SLIPPAGE_TOLERANCE;

            //transfer the rest to the user
            (bool success,) = payable(user).call{value : address(this).balance}("");
            require(success, "Transfer failed.");
        }

    }

    //Slippage tolerance with 4 digits precision. 999999 = 99.9999%
    function redeem(uint256 _shares, uint32 _slippageTolerance) external {
        require(_shares <= balanceOf(msg.sender), "Not enough shares");
        require(_slippageTolerance > safeSlippageTolerance, "Fat finger sir?");
        IERC20[] memory tokens = new IERC20[](1);
        uint256[] memory amounts = new uint256[](1);

        tokens[0] = weth;

        //66% LTV => 2x on original amount
        uint256 deleveragedStEthBal = _shares * overallBalance() / (totalSupply() * LEVERAGE_FACTOR);

        (,, uint256 currentVariableDebt,,,,,,) = IAaveProtocolDataProvider(dataProvider).getUserReserveData(wethAddress, address(this));
        uint256 borrowAmount = _shares * currentVariableDebt / (totalSupply());

        uint256 stEthWithdrawAmount = deleveragedStEthBal * LEVERAGE_FACTOR;

        amounts[0] = borrowAmount;
        _burn(msg.sender, _shares);
        makeFlashLoan(tokens, amounts, abi.encode(amounts[0], REDEEM, stEthWithdrawAmount, _slippageTolerance, msg.sender));
    }

    function totalStEthBalance() public view returns (uint256) {
        return overallBalance() / LEVERAGE_FACTOR;
    }

    receive() external payable {}

    /**
     * @dev Temporary method to set team member
     */
    function setTeamMember(address memberAddress) external onlyOwner {
        team[memberAddress] = true;
    }

    /**
    * @dev Temporary method to remove team member
    */
    function setSlippageTolerance(uint32 _newSlippageTolerance) external onlyOwner {
        safeSlippageTolerance = _newSlippageTolerance;
    }

    function getIouVirtualPrice() external view returns (uint256) {
        if (totalSupply() != 0)
            return totalStEthBalance() * 1e18 / totalSupply();
        return 0;
    }

    /**
     * @dev Temporary method to remove team member
     */
    function removeTeamMember(address memberAddress) external onlyOwner {
        team[memberAddress] = false;
    }
}
