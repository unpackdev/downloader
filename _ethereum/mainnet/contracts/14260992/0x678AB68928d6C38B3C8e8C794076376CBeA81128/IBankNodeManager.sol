// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";

import "./IBNPLProtocolConfig.sol";

import "./BNPLKYCStore.sol";
import "./BankNodeLendingRewards.sol";

/// @title BNPL BankNodeManager contract
///
/// @notice
/// - Features:
///     **Create a bank node**
///     **Add lendable token**
///     **Set minimum BankNode bonded amount**
///     **Set loan overdue grace period**
///
/// @author BNPL
interface IBankNodeManager {
    struct LendableToken {
        address tokenContract;
        address swapMarket;
        uint24 swapMarketPoolFee;
        uint8 decimals;
        uint256 valueMultiplier;
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

    /// @notice Get whether the banknode exists
    ///
    /// @param bankNodeId The bank node id
    /// @return BankNodeIdExists Returns `0` when it does not exist, otherwise returns `1`
    function bankNodeIdExists(uint32 bankNodeId) external view returns (uint256);

    /// @notice Get the contract address of the specified bank node
    ///
    /// @param bankNodeId The bank node id
    /// @return BankNodeContract The contract address of the node
    function getBankNodeContract(uint32 bankNodeId) external view returns (address);

    /// @notice Get the lending pool token contract (ERC20) address of the specified bank node
    ///
    /// @param bankNodeId Bank node id
    /// @return BankNodeToken The lending pool token contract (ERC20) address of the node
    function getBankNodeToken(uint32 bankNodeId) external view returns (address);

    /// @notice Get the staking pool contract address of the specified bank node
    ///
    /// @param bankNodeId The bank node id
    /// @return BankNodeStakingPoolContract The staking pool contract address of the node
    function getBankNodeStakingPoolContract(uint32 bankNodeId) external view returns (address);

    /// @notice Get the staking pool token contract (ERC20) address of the specified bank node
    ///
    /// @param bankNodeId The bank node id
    /// @return BankNodeStakingPoolToken The staking pool token contract (ERC20) address of the node
    function getBankNodeStakingPoolToken(uint32 bankNodeId) external view returns (address);

    /// @notice Get the lendable token contract (ERC20) address of the specified bank node
    ///
    /// @param bankNodeId The bank node id
    /// @return BankNodeLendableToken The lendable token contract (ERC20) address of the node
    function getBankNodeLendableToken(uint32 bankNodeId) external view returns (address);

    /// @notice Get all bank nodes loan statistic
    ///
    /// @return totalAmountOfAllActiveLoans uint256 Total amount of all activeLoans
    /// @return totalAmountOfAllLoans uint256 Total amount of all loans
    function getBankNodeLoansStatistic()
        external
        view
        returns (uint256 totalAmountOfAllActiveLoans, uint256 totalAmountOfAllLoans);

    /// @notice Get BNPL KYC store contract
    ///
    /// @return BNPLKYCStore BNPL KYC store contract
    function bnplKYCStore() external view returns (BNPLKYCStore);

    /// @dev This contract is called through the proxy.
    ///
    /// @param _protocolConfig BNPLProtocolConfig contract address
    /// @param _configurator BNPL contract platform configurator address
    /// @param _minimumBankNodeBondedAmount The minimum BankNode bonded amount required to create the bankNode
    /// @param _loanOverdueGracePeriod Loan overdue grace period (secs)
    /// @param _bankNodeLendingRewards BankNodeLendingRewards contract address
    /// @param _bnplKYCStore BNPLKYCStore contract address
    function initialize(
        IBNPLProtocolConfig _protocolConfig,
        address _configurator,
        uint256 _minimumBankNodeBondedAmount,
        uint256 _loanOverdueGracePeriod,
        BankNodeLendingRewards _bankNodeLendingRewards,
        BNPLKYCStore _bnplKYCStore
    ) external;

    /// @notice Get whether lendable tokens are enabled
    ///
    /// @param lendableTokenAddress The lendable token contract (ERC20) address
    /// @return enabledLendableTokens Returns `0` when it does not exist, otherwise returns `1`
    function enabledLendableTokens(address lendableTokenAddress) external view returns (uint8);

    /// @notice Get lendable token data
    ///
    /// @param lendableTokenAddress The lendable token contract (ERC20) address
    /// @return tokenContract The lendable token contract (ERC20) address
    /// @return swapMarket The configured swap market contract address (ex. SushiSwap Router)
    /// @return swapMarketPoolFee The configured swap market fee
    /// @return decimals The decimals for lendable tokens
    /// @return valueMultiplier `USD_VALUE = amount * valueMultiplier / 10 ** 18`
    /// @return unusedFundsLendingMode lending mode (1)
    /// @return unusedFundsLendingContract (ex. AAVE lending pool contract address)
    /// @return unusedFundsLendingToken (ex. AAVE tokens contract address)
    /// @return unusedFundsIncentivesController (ex. AAVE incentives controller contract address)
    /// @return symbol The lendable token symbol
    /// @return poolSymbol The pool lendable token symbol
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

    /// @notice Get bank node data according to the specified id
    ///
    /// @param bankNodeId The bank node id
    /// @return bankNodeContract The bank node contract address
    /// @return bankNodeToken The bank node token contract (ERC20) address
    /// @return bnplStakingPoolContract The bank node staking pool contract address
    /// @return bnplStakingPoolToken The bank node staking pool token contract (ERC20) address
    /// @return lendableToken The bank node lendable token contract (ERC20) address
    /// @return creator The bank node creator address
    /// @return id The bank node id
    /// @return createdAt The creation time of the bank node
    /// @return createBlock The creation block of the bank node
    /// @return nodeName The name of the bank node
    /// @return website The website of the bank node
    /// @return configUrl The config url of the bank node
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

    /// @notice Get bank node id with bank node address
    /// @return bankNodeId Bank node id
    function bankNodeAddressToId(address bankNodeAddressTo) external view returns (uint32);

    /// @notice Get BNPL platform protocol config contract
    /// @return minimumBankNodeBondedAmount BNPL protocol config contract
    function minimumBankNodeBondedAmount() external view returns (uint256);

    /// @notice Get the loan overdue grace period currently configured on the platform
    /// @return loanOverdueGracePeriod loan overdue grace period (secs)
    function loanOverdueGracePeriod() external view returns (uint256);

    /// @notice Get the current total number of platform bank nodes
    /// @return bankNodeCount Number of platform bank nodes
    function bankNodeCount() external view returns (uint32);

    /// @notice Get BNPL token contract
    /// @return bnplToken BNPL token contract
    function bnplToken() external view returns (IERC20);

    /// @notice Get bank node lending rewards contract
    /// @return bankNodeLendingRewards Bank node lending rewards contract
    function bankNodeLendingRewards() external view returns (BankNodeLendingRewards);

    /// @notice Get BNPL platform protocol config contract
    /// @return protocolConfig BNPL protocol config contract
    function protocolConfig() external view returns (IBNPLProtocolConfig);

    /// @notice Get bank node details list (pagination supported)
    ///
    /// @param start Where to start getting bank node
    /// @param count How many bank nodes to get
    /// @param reverse Whether to return the list in reverse order
    /// @return BankNodeList bank node details array
    /// @return BankNodeCount bank node count
    function getBankNodeList(
        uint32 start,
        uint32 count,
        bool reverse
    ) external view returns (BankNodeData[] memory, uint32);

    /// @notice Get bank node data with `bankNode` address
    ///
    /// @param bankNode bank node contract address
    /// @return bank node detail struct
    function getBankNodeDetail(address bankNode) external view returns (BankNodeDetail memory);

    /// @dev Add support for a new ERC20 token to be used as lendable tokens for new bank nodes
    ///
    /// - PRIVILEGES REQUIRED:
    ///     Admins with the role "CONFIGURE_NODE_MANAGER_ROLE"
    ///
    /// @param _lendableToken LendableToken configuration structure.
    /// @param enabled `0` or `1`, Whether to enable (cannot be used to create bank node after disable)
    ///
    /// **`_lendableToken` parameters:**
    ///
    /// ```solidity
    /// address tokenContract The lendable token contract (ERC20) address
    /// address swapMarket The configured swap market contract address (ex. SushiSwap Router)
    /// uint24 swapMarketPoolFee The configured swap market fee
    /// uint8 decimals The decimals for lendable tokens
    /// uint256 valueMultiplier `USD_VALUE = amount * valueMultiplier / 10 ** 18`
    /// uint16 unusedFundsLendingMode lending mode (1)
    /// address unusedFundsLendingContract (ex. AAVE lending pool contract address)
    /// address unusedFundsLendingToken (ex. AAVE tokens contract address)
    /// address unusedFundsIncentivesController (ex. AAVE incentives controller contract address)
    /// string symbol The lendable token symbol
    /// string poolSymbol The pool lendable token symbol
    /// ```
    function addLendableToken(LendableToken calldata _lendableToken, uint8 enabled) external;

    /// @dev Enable/Disable support for ERC20 tokens to be used as lendable tokens for new bank nodes (does not effect existing nodes)
    ///
    /// - PRIVILEGES REQUIRED:
    ///     Admins with the role "CONFIGURE_NODE_MANAGER_ROLE"
    ///
    /// @param tokenContract lendable token contract address
    /// @param enabled `0` or `1`, Whether to enable (cannot be used to create bank node after disable)
    function setLendableTokenStatus(address tokenContract, uint8 enabled) external;

    /// @dev Set the minimum BNPL to bond per node
    ///
    /// - PRIVILEGES REQUIRED:
    ///     Admins with the role "CONFIGURE_NODE_MANAGER_ROLE"
    ///
    /// @param _minimumBankNodeBondedAmount minium bank node bonded amount
    function setMinimumBankNodeBondedAmount(uint256 _minimumBankNodeBondedAmount) external;

    /// @dev Set the loan overdue grace period per node
    ///
    /// - PRIVILEGES REQUIRED:
    ///     Admins with the role "CONFIGURE_NODE_MANAGER_ROLE"
    ///
    /// @param _loanOverdueGracePeriod loan overdue grace period (secs)
    function setLoanOverdueGracePeriod(uint256 _loanOverdueGracePeriod) external;

    /// @notice Creates a new bonded bank node
    ///
    /// @dev
    /// - Steps:
    ///    1) Create bank node proxy contract
    ///    2) Create staking pool proxy contract
    ///    3) Create staking pool ERC20 token
    ///    4) Create bank node ERC20 token
    ///    5) Initialize bank node proxy contract
    ///    6) Bond tokens
    ///    7) Initialize staking pool proxy contract
    ///    8) Settings
    ///
    /// @param operator The node operator who will be assigned the permissions of bank node admin for the newly created bank node
    /// @param tokensToBond The number of BNPL tokens to bond for the node
    /// @param lendableTokenAddress Which lendable token will be lent to borrowers for this bank node (ex. the address of USDT's erc20 smart contract)
    /// @param nodeName The official name of the bank node
    /// @param website The official website of the bank node
    /// @param configUrl The bank node config file url
    /// @param nodePublicKey KYC public key
    /// @param kycMode KYC mode
    /// @return BankNodeId bank node id
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
