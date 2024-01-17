// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./ERC20.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract CPC01 is ERC20, Ownable {
    struct Investment {
        uint256 idInvestment;
        uint256 floatDecimals;
        uint256 interestRate;
        uint256 investmentDate;
        uint256 investmentDueDate;
        uint256 investmentPaymentDate;
        uint256 investmentAmount;
        uint256 investmentDueAmount;
        bool isPaid;
        string USDCInvestmentTransaction;
        string CPC01CollateralTransaction;
    }

    struct Payment {
        uint256 idInvestmentOperation;
        uint256 payment;
        string USDCPaymentTransaction;
        string CPC01CollateralTransaction;
    }

    struct Collateral {
        string asset;
        uint256 amount;
    }

    uint256 public investmentCount = 0;
    uint256 public paymentCount = 0;
    uint256 public collateralCount = 0;
    Investment[] public investments;
    Payment[] public payments;
    mapping(uint256 => Collateral) public collaterals;

    uint256 public constant FLOAT_DECIMALS = 2;

    // Token Issuer
    string public constant INVESTOR = "Criptoloja - https://criptoloja.com";
    // Collateral Assets
    string public constant COLLATERAL_ASSETS =
        "MB Tokens - https://www.mercadobitcoin.com.br";
    // Criptoloja collateral wallet which will receive CPC01 Tokens
    address public constant CRIPTOLOJA_WALLET =
        0x14629b1CE895E8e6258190a466709Df09D784b88;
    // MB Tokens wallet which will receive USDCs
    address public constant MBTOKENS_WALLET =
        0x14629b1CE895E8e6258190a466709Df09D784b88;

    // Event to register each Investment
    event InvestmentEvent(
        uint256 idInvestment,
        string investor,
        string collateralAssets,
        uint256 floatDecimals,
        uint256 interestRate,
        uint256 investmentDate,
        uint256 investmentDueDate,
        uint256 investmentPaymentDate,
        uint256 investmentAmount,
        uint256 investmentDueAmount,
        string USDCInvestmentTransaction,
        string CPC01CollateralTransaction
    );

    // Event to register each Payment
    event PaymentEvent(
        uint256 idInvestmentOperation,
        uint256 payments,
        string USDCPaymentTransaction,
        string CPC01CollateralTransaction
    );

    constructor(uint256 totalSupply) ERC20("Criptoloja Plano de Crescimento - 01", "CPC01") {
        _mint(msg.sender, totalSupply);
    }

    // Create an Investmnet
    function newInvestment(
        uint256 interestRate,
        uint256 investmentDate,
        uint256 investmentDueDate,
        uint256 investmentPaymentDate,
        uint256 investmentAmount,
        uint256 investmentDueAmount,
        string memory USDCInvestmentTransaction,
        string memory CPC01CollateralTransaction
    ) public onlyOwner {
        investments.push(
            Investment(
                investmentCount,
                FLOAT_DECIMALS,
                interestRate,
                investmentDate,
                investmentDueDate,
                investmentPaymentDate,
                investmentAmount,
                investmentDueAmount,
                false,
                USDCInvestmentTransaction,
                CPC01CollateralTransaction
            )
        );

        emit InvestmentEvent(
            investmentCount,
            INVESTOR,
            COLLATERAL_ASSETS,
            FLOAT_DECIMALS,
            interestRate,
            investmentDate,
            investmentDueDate,
            investmentPaymentDate,
            investmentAmount,
            investmentDueAmount,
            USDCInvestmentTransaction,
            CPC01CollateralTransaction
        );

        investmentCount += 1;
    }

    // Create a Payment
    function newPayment(
        uint256 idInvestmentOperation,
        uint256 payment_,
        string memory USDCPaymentTransaction,
        string memory CPC01CollateralTransaction
    ) public onlyOwner {
        require(
            investments[idInvestmentOperation].isPaid == false,
            "Investment already paid"
        );
        investments[idInvestmentOperation].isPaid = true;
        payments.push(
            Payment(
                idInvestmentOperation,
                payment_,
                USDCPaymentTransaction,
                CPC01CollateralTransaction
            )
        );

        emit PaymentEvent(
            idInvestmentOperation,
            payment_,
            USDCPaymentTransaction,
            CPC01CollateralTransaction
        );

        paymentCount += 1;
    }

    function addCollateral(string memory _asset, uint256 _amount)
        public
        onlyOwner
    {
        require(_amount > 0, "Amount should be > 0");
        collaterals[collateralCount].asset = _asset;
        collaterals[collateralCount].amount = _amount;
        collateralCount += 1;
    }

    function updateCollateral(uint256 _id, uint256 _amount) public onlyOwner {
        require(_amount >= 0, "Amount should be >= 0");
        require(_id < collateralCount, "Collateral asset doesn't exist");
        collaterals[_id].amount = _amount;
    }

    function getCollateralList() public view returns (Collateral[] memory) {
        Collateral[] memory collateral_ = new Collateral[](collateralCount);
        for (uint256 i = 0; i < collateralCount; i++) {
            collateral_[i] = collaterals[i];
        }
        return collateral_;
    }

    function getActiveInvestmentsCount() public view returns (uint256) {
        uint256 total = 0;
        for (uint256 i; i < investmentCount; i++) {
            if (!investments[i].isPaid) {
                total++;
            }
        }
        return total;
    }

    function getTotalInvestedAmount() public view returns (uint256) {
        uint256 total = 0;
        for (uint256 i; i < investmentCount; i++) {
            total += investments[i].investmentAmount;
        }
        return total;
    }

    function getTotalActiveInvestedAmount() public view returns (uint256) {
        uint256 total = 0;
        for (uint256 i; i < investmentCount; i++) {
            if (!investments[i].isPaid) {
                total += investments[i].investmentAmount;
            }
        }
        return total;
    }

    function getTotalDueInvestedAmount() public view returns (uint256) {
        uint256 total = 0;
        for (uint256 i; i < investmentCount; i++) {
            if (!investments[i].isPaid) {
                total += investments[i].investmentDueAmount;
            }
        }
        return total;
    }

    function getTotalPaidAmount() public view returns (uint256) {
        uint256 total = 0;
        for (uint256 i; i < paymentCount; i++) {
            total += payments[i].payment;
        }
        return total;
    }
}