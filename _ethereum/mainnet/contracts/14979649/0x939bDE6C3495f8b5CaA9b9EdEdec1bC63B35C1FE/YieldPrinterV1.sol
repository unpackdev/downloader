// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
pragma experimental ABIEncoderV2;

import "./IERC20Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./SafeMath.sol";
import "./IFlashLoanReceiver.sol";
import "./ILendingPool.sol";
import "./ILendingPoolAddressesProvider.sol";
import "./CERC20.sol";
import "./Comptroller.sol";
import "./YieldPrinterStorage.sol";

contract YieldPrinterV1 is IFlashLoanReceiver, YieldPrinterStorage, OwnableUpgradeable {
    using SafeMath for uint256;

    struct LoanData {
        IERC20Upgradeable underlying;
        CERC20 cToken;
        uint256 flashLoanedAmount;
        uint256 flashLoanPremium;
    }

    modifier onlyPool() {
        require(
            msg.sender == address(getLendingPool()),
            "FlashLoan: could be called by lending pool only"
        );
        _;
    }

    function initialize(address lpAddressesProvider, address comptroller) public initializer {
        __Ownable_init();
        YieldPrinterStorage.initializeStorage(comptroller, lpAddressesProvider);
    }

    function executeOperation(
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata premiums,
        address,
        bytes calldata params
    )
        external
        onlyPool
        override
        returns (bool)
    {

        //
        // This contract now has the funds requested.
        // Your logic goes here.
        //
        (address cErc20Contract, uint256 totalAmount, bytes32 operation) = abi.decode(params, (address, uint256, bytes32));
        LoanData memory loanData;
        loanData.underlying = IERC20Upgradeable(assets[0]);
        loanData.cToken = CERC20(cErc20Contract);
        loanData.flashLoanedAmount = amounts[0];
        loanData.flashLoanPremium = premiums[0];

        if(operation == keccak256("DEPOSIT")) {
            // approve underlying asset to be able to be transfered by the cToken contract
            loanData.underlying.approve(cErc20Contract, totalAmount);

            // Mint cTokens
            loanData.cToken.mint(totalAmount);

            // Enter the market for the supplied asset to use it as collateral
            address[] memory cTokens = new address[](1);
            cTokens[0] = cErc20Contract;
            Comptroller(getComptroller()).enterMarkets(cTokens);

            // Borrow token
            uint256 borrowAmount = loanData.flashLoanedAmount.add(loanData.flashLoanPremium);
            loanData.cToken.borrow(borrowAmount);
        }

        if(operation == keccak256("WITHDRAW")) {
            // approve underlying asset to be able to be transfered by the cToken contract
            loanData.underlying.approve(cErc20Contract, loanData.flashLoanedAmount);

            uint256 error = loanData.cToken.repayBorrow(loanData.flashLoanedAmount);
            require(error == 0, "RepayBorrow Error");

            uint256 cTokenBalance = loanData.cToken.balanceOf(address(this));

            // Retrieve deposited assets
            loanData.cToken.redeem(cTokenBalance);
        }
        
        // Approve the LendingPool contract allowance to *pull* the owed amount
        for (uint i = 0; i < assets.length; i++) {
            uint amountOwing = amounts[i].add(premiums[i]);
            IERC20Upgradeable(assets[i]).approve(getLendingPool(), amountOwing);
        }
        
        return true;
    }

    function depositToComp(address token, address cToken, uint256 amount) external onlyOwner {
        // Total deposit: 40% amount, 60% flash loan
        uint256 totalAmount = (amount.mul(5)).div(2);

        // loan is 70% of total deposit
        uint256 flashLoanAmount = totalAmount.sub(amount);
        bytes memory data = abi.encode(cToken, totalAmount, keccak256("DEPOSIT"));

        // take loan
        takeLoan(token, flashLoanAmount, data);
    }

    function withdrawFromComp(address token, address cToken) external onlyOwner {
        // get the borrow balance
        uint256 borrowBalance = CERC20(cToken).borrowBalanceCurrent(address(this));
        require(borrowBalance > 0, "Borrowed balance must be > 0");

        bytes memory data = abi.encode(cToken, 0, keccak256("WITHDRAW"));

        // take flash loan to repay COMPOUND loan
        takeLoan(token, borrowBalance, data);
    }

    function withdrawToken(address _tokenAddress) external onlyOwner {
        uint256 balance = IERC20Upgradeable(_tokenAddress).balanceOf(address(this));
        require(IERC20Upgradeable(_tokenAddress).transfer(owner(), balance), "Failed to withdraw token");
    }

    function withdrawAllEth() external onlyOwner {
        uint amount = address(this).balance;

        (bool success, ) = owner().call{value: amount}("");
        require(success, "Failed to send Ether");
    }

    function takeLoan(address asset, uint256 amount, bytes memory params) internal {
        address receiverAddress = address(this);
        // 0 = no debt, 1 = stable, 2 = variable
        uint256 noDebt = 0;
        uint16 referralCode = 0;
        address onBehalfOf = address(this);

        address[] memory assets = new address[](1);
        assets[0] = address(asset);

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = amount;

        uint256[] memory modes = new uint256[](1);
        modes[0] = noDebt;

        ILendingPool(getLendingPool()).flashLoan(
            receiverAddress,
            assets,
            amounts,
            modes,
            onBehalfOf,
            params,
            referralCode
        );
    }

    /**
        can receive ETH
     */
    receive() external payable {}
}
