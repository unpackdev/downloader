// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";

import "./IBNPLProtocolConfig.sol";

import "./BNPLKYCStore.sol";
import "./BankNodeLendingRewards.sol";

interface IBankNodeManager {
    struct LendableToken {
        address tokenContract;
        address swapMarket;
        uint24 swapMarketPoolFee;
        uint8 decimals;
        uint256 valueMultiplier; // USD_VALUE = amount * valueMultiplier / 10**18
        uint16 unusedFundsLendingMode;
        address unusedFundsLendingContract;
        address unusedFundsLendingToken;
        address unusedFundsIncentivesController;
        string symbol;
        string poolSymbol;
    }

    struct BankNode {
        address bankNodeContract;
        address bankNodeToken;
        address bnplStakingPoolContract;
        address bnplStakingPoolToken;
        address lendableToken;
        address creator;
        uint32 id;
        uint64 createdAt;
        uint256 createBlock;
        string nodeName;
        string website;
        string configUrl;
    }

    struct BankNodeDetail {
        uint256 totalAssetsValueBankNode;
        uint256 totalAssetsValueStakingPool;
        uint256 tokensCirculatingBankNode;
        uint256 tokensCirculatingStakingPool;
        uint256 totalLiquidAssetsValue;
        uint256 baseTokenBalanceBankNode;
        uint256 baseTokenBalanceStakingPool;
        uint256 accountsReceivableFromLoans;
        uint256 virtualPoolTokensCount;
        address baseLiquidityToken;
        address poolLiquidityToken;
        bool isNodeDecomissioning;
        uint256 nodeOperatorBalance;
        uint256 loanRequestIndex;
        uint256 loanIndex;
        uint256 valueOfUnusedFundsLendingDeposits;
        uint256 totalLossAllTime;
        uint256 onGoingLoanCount;
        uint256 totalTokensLocked;
        uint256 getUnstakeLockupPeriod;
        uint256 tokensBondedAllTime;
        uint256 poolTokenEffectiveSupply;
        uint256 nodeTotalStaked;
        uint256 nodeBondedBalance;
        uint256 nodeOwnerBNPLRewards;
        uint256 nodeOwnerPoolTokenRewards;
    }

    struct BankNodeData {
        BankNode data;
        BankNodeDetail detail;
    }

    struct CreateBankNodeContractsInput {
        uint32 bankNodeId;
        address operatorAdmin;
        address operator;
        address lendableTokenAddress;
    }
    struct CreateBankNodeContractsOutput {
        address bankNodeContract;
        address bankNodeToken;
        address bnplStakingPoolContract;
        address bnplStakingPoolToken;
    }

    function bankNodeIdExists(uint32 bankNodeId) external view returns (uint256);

    function getBankNodeContract(uint32 bankNodeId) external view returns (address);

    function getBankNodeToken(uint32 bankNodeId) external view returns (address);

    function getBankNodeStakingPoolContract(uint32 bankNodeId) external view returns (address);

    function getBankNodeStakingPoolToken(uint32 bankNodeId) external view returns (address);

    function getBankNodeLendableToken(uint32 bankNodeId) external view returns (address);

    function getBankNodeLoansStatistic()
        external
        view
        returns (uint256 totalAmountOfAllActiveLoans, uint256 totalAmountOfAllLoans);

    function bnplKYCStore() external view returns (BNPLKYCStore);

    function initialize(
        IBNPLProtocolConfig _protocolConfig,
        address _configurator,
        uint256 _minimumBankNodeBondedAmount,
        uint256 _loanOverdueGracePeriod,
        BankNodeLendingRewards _bankNodeLendingRewards,
        BNPLKYCStore _bnplKYCStore
    ) external;

    function enabledLendableTokens(address lendableTokenAddress) external view returns (uint8);

    function lendableTokens(address lendableTokenAddress)
        external
        view
        returns (
            address tokenContract,
            address swapMarket,
            uint24 swapMarketPoolFee,
            uint8 decimals,
            uint256 valueMultiplier, //USD_VALUE = amount * valueMultiplier / 10**18
            uint16 unusedFundsLendingMode,
            address unusedFundsLendingContract,
            address unusedFundsLendingToken,
            address unusedFundsIncentivesController,
            string calldata symbol,
            string calldata poolSymbol
        );

    function bankNodes(uint32 bankNodeId)
        external
        view
        returns (
            address bankNodeContract,
            address bankNodeToken,
            address bnplStakingPoolContract,
            address bnplStakingPoolToken,
            address lendableToken,
            address creator,
            uint32 id,
            uint64 createdAt,
            uint256 createBlock,
            string calldata nodeName,
            string calldata website,
            string calldata configUrl
        );

    function bankNodeAddressToId(address bankNodeAddressTo) external view returns (uint32);

    function minimumBankNodeBondedAmount() external view returns (uint256);

    function loanOverdueGracePeriod() external view returns (uint256);

    function bankNodeCount() external view returns (uint32);

    function bnplToken() external view returns (IERC20);

    function bankNodeLendingRewards() external view returns (BankNodeLendingRewards);

    function protocolConfig() external view returns (IBNPLProtocolConfig);

    function getBankNodeList(
        uint32 start,
        uint32 count,
        bool reverse
    ) external view returns (BankNodeData[] memory, uint32);

    function getBankNodeDetail(address bankNode) external view returns (BankNodeDetail memory);

    function addLendableToken(LendableToken calldata _lendableToken, uint8 enabled) external;

    function setLendableTokenStatus(address tokenContract, uint8 enabled) external;

    function setMinimumBankNodeBondedAmount(uint256 _minimumBankNodeBondedAmount) external;

    function setLoanOverdueGracePeriod(uint256 _loanOverdueGracePeriod) external;

    function createBondedBankNode(
        address operator,
        uint256 tokensToBond,
        address lendableTokenAddress,
        string calldata nodeName,
        string calldata website,
        string calldata configUrl,
        address nodePublicKey,
        uint32 kycMode
    ) external returns (uint32);
}
