// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "./Address.sol";
import "./SafeMath.sol";
import "./ERC20.sol";
import "./SafeERC20.sol";

import "./FundProxy.sol";
import "./FundLogic.sol";
import "./BuybackVault.sol";

contract FundDeployer {
    using SafeMath for uint256;
    using Address for address;
    using SafeERC20 for ERC20;

    address public owner;
    address public oracle;

    uint256 public BUYBACK_FEE;
    uint256 public constant BUYBACK_FEE_MAX = 10000;

    uint256 public MAX_PERFORMANCE_FEE_ALLOWED = 5000;

    address public PARASWAP_TOKEN_PROXY;
    address public PARASWAP_AUGUSTUS;

    uint256 public feeWaitPeriod = 1 days;

    address public buybackVault;

    address public fundLogic;

    address[] public deployedFunds;
    mapping(address => bool) isDeployedFund;

    event FundDeployed(
        address fund,
        string fundName,
        string managerName,
        address depositAsset,
        address manager,
        uint256 timestamp
    );

    event OwnerUpdate(
        address oldOwner,
        address newOwner
    );

    event OracleUpdate(
        address oldOracle,
        address newOracle
    );

    event LogicUpdate(
        address oldLogic,
        address newLogic
    );

    event BuybackFeeUpdate(
        uint256 oldFee,
        uint256 newFee
    );

    event BuybackVaultUpdate(
        address oldVault,
        address newVault
    );

    event ParaswapUpdate(
        address oldParaswapProxy,
        address oldParaswapAugustus,
        address newParaswapProxy,
        address newParaswapAugustus
    );

    event MaxPerformanceFeeUpdate(
        uint256 oldMaxPerformanceFeeAllowed,
        uint256 newMaxPerformanceFeeAllowed
    );

    event FeeWaitPeriodChange(
        uint256 oldFeeWaitPeriod,
        uint256 newFeeWaitPeriod
    );

    modifier onlyOwner {
        require(msg.sender == owner, "Unauthorized: Only owner");
        _;
    }

    constructor(
        address _oracle,
        uint256 _buybackFee,
        address _paraswapProxy,
        address _paraswapAugustus,
        address _bbvault,
        address _fundLogic
    ) public {
        owner = msg.sender;
        oracle = _oracle;
        BUYBACK_FEE = _buybackFee;
        PARASWAP_TOKEN_PROXY = _paraswapProxy;
        PARASWAP_AUGUSTUS = _paraswapAugustus;
        buybackVault = _bbvault;
        fundLogic = _fundLogic;
    }

    function changeOwner(address _owner) external onlyOwner {
        emit OwnerUpdate(owner, _owner);
        owner = _owner;
    }

    function changeOracle(address _oracle) external onlyOwner {
        emit OracleUpdate(oracle, _oracle);
        oracle = _oracle;
    }

    function changeLogic(address _newLogic) external onlyOwner {
        emit LogicUpdate(fundLogic, _newLogic);
        fundLogic = _newLogic;
    }

    function changeFeeWaitPeriod(uint256 _newPeriod) external onlyOwner {
        emit FeeWaitPeriodChange(feeWaitPeriod, _newPeriod);
        feeWaitPeriod = _newPeriod;
    }

    function changeBuybackFee(uint256 _newFee) external onlyOwner {
        // Ensure our users we will never set an extremly high buy back fee
        require(_newFee <= 5000, "Buyback fee too big");
        emit BuybackFeeUpdate(BUYBACK_FEE, _newFee);
        BUYBACK_FEE = _newFee;
    }

    function changeBuybackVault(address _newVault) external onlyOwner {
        emit BuybackVaultUpdate(buybackVault, _newVault);
        buybackVault = _newVault;
    }

    function changeMaxPerformanceFeeAllowed(uint256 _newMax) external onlyOwner {
        require (_newMax < 10000, "Max performance fee allowed too big");
        emit MaxPerformanceFeeUpdate(MAX_PERFORMANCE_FEE_ALLOWED, _newMax);
        MAX_PERFORMANCE_FEE_ALLOWED = _newMax;
    }

    function upgradeParaswap(address _paraProxy, address _paraAugustus) external onlyOwner {
        emit ParaswapUpdate(PARASWAP_TOKEN_PROXY, PARASWAP_AUGUSTUS, _paraProxy, _paraAugustus);
        PARASWAP_TOKEN_PROXY = _paraProxy;
        PARASWAP_AUGUSTUS = _paraAugustus;
    }

    function getBuybackFee() external view returns (uint256,uint256) {
        return (BUYBACK_FEE, BUYBACK_FEE_MAX);
    }

    function getParaswapAddresses() external view returns (address,address) {
        return (PARASWAP_AUGUSTUS, PARASWAP_TOKEN_PROXY);
    }

    function getBuybackVault() external view returns (address) {
        return buybackVault;
    }

    function getOracle() external view returns (address) {
        return oracle;
    }

    function getDeployedFunds() external view returns (address[] memory) {
        return deployedFunds;
    }

    function getFundLogic() external view returns (address) {
        return fundLogic;
    }

    function getFeeWaitPeriod() external view returns (uint256) {
        return feeWaitPeriod;
    }

    function addressIsFund(address _fund) external view returns (bool) {
        return isDeployedFund[_fund];
    }

    function deployFund(
        string memory _fundName,
        string memory _managerName,
        address _depositAsset,
        uint256 _performanceFee,
        uint256 _minDeposit,
        uint256 _maxDeposit
    ) external returns (address) {
        require(_performanceFee <= MAX_PERFORMANCE_FEE_ALLOWED, "Performance fee too big");
        // _depositAsset will be validated when the fund is created

        bytes memory constructData = abi.encodeWithSignature(
            "init(address,address,address,string,string,address,uint256,address,address,address,uint256,uint256)",
            oracle,
            address(this),
            msg.sender,
            _fundName,
            _managerName,
            _depositAsset,
            _performanceFee,
            PARASWAP_TOKEN_PROXY,
            PARASWAP_AUGUSTUS,
            buybackVault,
            _minDeposit,
            _maxDeposit
        );

        address _fundProxy = address(new FundProxy(constructData, fundLogic));

        require(FundLogic(_fundProxy).getFundLogic() == fundLogic && FundLogic(_fundProxy).getManager() == msg.sender, "FundProxy creation failed");

        deployedFunds.push(_fundProxy);
        isDeployedFund[_fundProxy] = true;
        BuybackVault(buybackVault).addFund(_fundProxy);

        emit FundDeployed(
            _fundProxy,
            _fundName,
            _managerName,
            _depositAsset,
            msg.sender,
            block.timestamp
        );

        // Alert buyback vault with new fund

        return _fundProxy;
    }

    function getRegisteredFundsLength() external view returns (uint) {
        return deployedFunds.length;
    }

    function getIsDeployedFund(address _fund) external view returns (bool) {
        return isDeployedFund[_fund];
    }
}