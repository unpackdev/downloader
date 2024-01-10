// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Initializable.sol";
import "./AccessControlEnumerableUpgradeable.sol";
import "./IERC20.sol";
import "./BeaconProxy.sol";
import "./ReentrancyGuardUpgradeable.sol";

import "./IBNPLBankNode.sol";
import "./IBNPLNodeStakingPool.sol";
import "./ITokenInitializableV1.sol";
import "./IBNPLProtocolConfig.sol";
import "./IBankNodeManager.sol";

import "./BankNodeLendingRewards.sol";
import "./BNPLKYCStore.sol";

import "./TransferHelper.sol";

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
contract BankNodeManager is
    Initializable,
    AccessControlEnumerableUpgradeable,
    ReentrancyGuardUpgradeable,
    IBankNodeManager
{
    struct BankNodeContracts {
        address bankNodeContract;
        address bankNodeToken;
        address bnplStakingPoolContract;
        address bnplStakingPoolToken;
    }

    struct CreateBankNodeContractsFncInput {
        uint32 bankNodeId;
        address operatorAdmin;
        address operator;
        uint256 tokensToBond;
        address lendableTokenAddress;
        address nodePublicKey;
        uint32 kycMode;
    }

    bytes32 public constant CONFIGURE_NODE_MANAGER_ROLE = keccak256("CONFIGURE_NODE_MANAGER_ROLE");

    /// @notice [Lendable token address] => [Enable status (0 or 1)]
    mapping(address => uint8) public override enabledLendableTokens;

    /// @notice [Bank node address] => [Lendable token data]
    mapping(address => LendableToken) public override lendableTokens;

    /// @notice [Bank node id] => [Bank node data]
    mapping(uint32 => BankNode) public override bankNodes;

    /// @notice [Bank node address] => [Bank node id]
    mapping(address => uint32) public override bankNodeAddressToId;

    /// @notice BNPL platform protocol config contract
    uint256 public override minimumBankNodeBondedAmount;

    /// @notice The loan overdue grace period currently configured on the platform
    uint256 public override loanOverdueGracePeriod;

    /// @notice The current total number of platform bank nodes
    uint32 public override bankNodeCount;

    /// @notice BNPL token contract
    IERC20 public override bnplToken;

    /// @notice Bank node lending rewards contract
    BankNodeLendingRewards public override bankNodeLendingRewards;

    /// @notice BNPL platform protocol config contract
    IBNPLProtocolConfig public override protocolConfig;

    /// @notice BNPL KYC store contract
    BNPLKYCStore public override bnplKYCStore;

    /// @notice whether the banknode exists
    ///
    /// @param bankNodeId Bank node id
    /// @return BankNodeIdExists Returns `0` when it does not exist, otherwise returns `1`
    function bankNodeIdExists(uint32 bankNodeId) external view override returns (uint256) {
        return (bankNodeId >= 1 && bankNodeId <= bankNodeCount) ? 1 : 0;
    }

    /// @notice Get the contract address of the specified bank node
    ///
    /// @param bankNodeId Bank node id
    /// @return BankNodeContract The contract address of the node
    function getBankNodeContract(uint32 bankNodeId) external view override returns (address) {
        require(bankNodeId >= 1 && bankNodeId <= bankNodeCount, "Invalid or unregistered bank node id!");
        return bankNodes[bankNodeId].bankNodeContract;
    }

    /// @notice Get the lending pool token contract (ERC20) address of the specified bank node
    ///
    /// @param bankNodeId Bank node id
    /// @return BankNodeToken The lending pool token contract (ERC20) address of the node
    function getBankNodeToken(uint32 bankNodeId) external view override returns (address) {
        require(bankNodeId >= 1 && bankNodeId <= bankNodeCount, "Invalid or unregistered bank node id!");
        return bankNodes[bankNodeId].bankNodeToken;
    }

    /// @notice Get the staking pool contract address of the specified bank node
    ///
    /// @param bankNodeId Bank node id
    /// @return BankNodeStakingPoolContract The staking pool contract address of the node
    function getBankNodeStakingPoolContract(uint32 bankNodeId) external view override returns (address) {
        require(bankNodeId >= 1 && bankNodeId <= bankNodeCount, "Invalid or unregistered bank node id!");
        return bankNodes[bankNodeId].bnplStakingPoolContract;
    }

    /// @notice Get the staking pool token contract (ERC20) address of the specified bank node
    ///
    /// @param bankNodeId Bank node id
    /// @return BankNodeStakingPoolToken The staking pool token contract (ERC20) address of the node
    function getBankNodeStakingPoolToken(uint32 bankNodeId) external view override returns (address) {
        require(bankNodeId >= 1 && bankNodeId <= bankNodeCount, "Invalid or unregistered bank node id!");
        return bankNodes[bankNodeId].bnplStakingPoolToken;
    }

    /// @notice Get the lendable token contract (ERC20) address of the specified bank node
    ///
    /// @param bankNodeId Bank node id
    /// @return BankNodeLendableToken The lendable token contract (ERC20) address of the node
    function getBankNodeLendableToken(uint32 bankNodeId) external view override returns (address) {
        require(bankNodeId >= 1 && bankNodeId <= bankNodeCount, "Invalid or unregistered bank node id!");
        return bankNodes[bankNodeId].lendableToken;
    }

    /// @notice Get all bank nodes loan statistic
    ///
    /// @return totalAmountOfAllActiveLoans uint256 Total amount of all activeLoans
    /// @return totalAmountOfAllLoans uint256 Total amount of all loans
    function getBankNodeLoansStatistic()
        external
        view
        override
        returns (uint256 totalAmountOfAllActiveLoans, uint256 totalAmountOfAllLoans)
    {
        totalAmountOfAllActiveLoans;
        totalAmountOfAllLoans;
        for (uint32 i = 0; i < bankNodeCount; i++) {
            IBNPLBankNode node = IBNPLBankNode(bankNodes[i + 1].bankNodeContract);
            totalAmountOfAllActiveLoans += node.totalAmountOfActiveLoans();
            totalAmountOfAllLoans += node.totalAmountOfLoans();
        }
    }

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
    ) external view override returns (BankNodeData[] memory, uint32) {
        if (start > bankNodeCount) {
            return (new BankNodeData[](0), bankNodeCount);
        }
        uint32 end;
        if (reverse) {
            start = bankNodeCount - start;
            end = (start > count) ? (start - count) : 0;
            count = start - end;
        } else {
            end = (start + count) > bankNodeCount ? bankNodeCount : (start + count);
            count = end - start;
        }
        BankNodeData[] memory tmp = new BankNodeData[](count);
        uint32 tmpIndex = 0;
        if (reverse) {
            while ((tmpIndex < count) && start > 0) {
                BankNode memory _node = bankNodes[start];
                start--;
                tmp[tmpIndex++] = BankNodeData(_node, getBankNodeDetail(_node.bankNodeContract));
            }
        } else {
            while ((tmpIndex < count) && start < bankNodeCount) {
                BankNode memory _node = bankNodes[start + 1];
                start++;
                tmp[tmpIndex++] = BankNodeData(_node, getBankNodeDetail(_node.bankNodeContract));
            }
        }
        return (tmp, bankNodeCount);
    }

    /// @notice Get bank node data with `bankNode` address
    ///
    /// @param bankNode bank node contract address
    /// @return BankNodeDetail bank node detail struct
    function getBankNodeDetail(address bankNode) public view override returns (BankNodeDetail memory) {
        IBNPLBankNode node = IBNPLBankNode(bankNode);
        IBNPLNodeStakingPool pool = IBNPLNodeStakingPool(node.nodeStakingPool());
        uint256 virtualPoolTokensCount = pool.virtualPoolTokensCount();
        uint256 tokensCirculatingStakingPool = pool.poolTokensCirculating();
        return
            BankNodeDetail({
                totalAssetsValueBankNode: node.getPoolTotalAssetsValue(),
                totalAssetsValueStakingPool: pool.getPoolTotalAssetsValue(),
                tokensCirculatingBankNode: node.poolTokensCirculating(),
                tokensCirculatingStakingPool: tokensCirculatingStakingPool,
                totalLiquidAssetsValue: node.getPoolTotalLiquidAssetsValue(),
                baseTokenBalanceBankNode: node.baseTokenBalance(),
                baseTokenBalanceStakingPool: pool.baseTokenBalance(),
                accountsReceivableFromLoans: node.accountsReceivableFromLoans(),
                virtualPoolTokensCount: virtualPoolTokensCount,
                baseLiquidityToken: address(node.baseLiquidityToken()),
                poolLiquidityToken: address(node.poolLiquidityToken()),
                isNodeDecomissioning: pool.isNodeDecomissioning(),
                nodeOperatorBalance: node.nodeOperatorBalance(),
                loanRequestIndex: node.loanRequestIndex(),
                loanIndex: node.loanIndex(),
                valueOfUnusedFundsLendingDeposits: node.getValueOfUnusedFundsLendingDeposits(),
                totalLossAllTime: node.totalLossAllTime(),
                onGoingLoanCount: node.onGoingLoanCount(),
                totalTokensLocked: pool.totalTokensLocked(),
                getUnstakeLockupPeriod: pool.getUnstakeLockupPeriod(),
                tokensBondedAllTime: pool.tokensBondedAllTime(),
                poolTokenEffectiveSupply: pool.poolTokenEffectiveSupply(),
                nodeTotalStaked: pool.getPoolWithdrawConversion(tokensCirculatingStakingPool),
                nodeBondedBalance: pool.getPoolWithdrawConversion(virtualPoolTokensCount),
                nodeOwnerBNPLRewards: pool.getNodeOwnerBNPLRewards(),
                nodeOwnerPoolTokenRewards: pool.getNodeOwnerPoolTokenRewards()
            });
    }

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
    ) external override initializer nonReentrant {
        require(address(_protocolConfig) != address(0), "_protocolConfig cannot be 0");
        require(address(_bnplKYCStore) != address(0), "kyc store cannot be 0");
        require(_configurator != address(0), "_configurator cannot be 0");
        require(_minimumBankNodeBondedAmount > 0, "_minimumBankNodeBondedAmount cannot be 0");

        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
        __AccessControlEnumerable_init_unchained();
        __ReentrancyGuard_init_unchained();

        protocolConfig = _protocolConfig;

        minimumBankNodeBondedAmount = _minimumBankNodeBondedAmount;
        loanOverdueGracePeriod = _loanOverdueGracePeriod;
        bankNodeCount = 0;
        bnplKYCStore = _bnplKYCStore;
        bnplToken = IERC20(_protocolConfig.bnplToken());
        require(address(bnplToken) != address(0), "_bnplToken cannot be 0");
        bankNodeLendingRewards = _bankNodeLendingRewards;
        require(address(bankNodeLendingRewards) != address(0), "_bankNodeLendingRewards cannot be 0");

        _setupRole(CONFIGURE_NODE_MANAGER_ROLE, _configurator);
    }

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
    function addLendableToken(LendableToken calldata _lendableToken, uint8 enabled)
        external
        override
        nonReentrant
        onlyRole(CONFIGURE_NODE_MANAGER_ROLE)
    {
        require(address(_lendableToken.tokenContract) != address(0), "tokenContract must not be 0");
        require(address(_lendableToken.swapMarket) != address(0), "swapMarket must not be 0");
        require(_lendableToken.valueMultiplier > 0, "valueMultiplier must be > 0");
        require(enabled == 0 || enabled == 1, "enabled 1 or 0");

        LendableToken storage lendableToken = lendableTokens[_lendableToken.tokenContract];
        lendableToken.tokenContract = _lendableToken.tokenContract;

        lendableToken.swapMarket = _lendableToken.swapMarket;
        lendableToken.swapMarketPoolFee = _lendableToken.swapMarketPoolFee;

        lendableToken.decimals = _lendableToken.decimals;
        lendableToken.valueMultiplier = _lendableToken.valueMultiplier;
        lendableToken.unusedFundsLendingMode = _lendableToken.unusedFundsLendingMode;
        lendableToken.unusedFundsLendingContract = _lendableToken.unusedFundsLendingContract;
        lendableToken.unusedFundsLendingToken = _lendableToken.unusedFundsLendingToken;
        lendableToken.unusedFundsIncentivesController = _lendableToken.unusedFundsIncentivesController;

        lendableToken.symbol = _lendableToken.symbol;
        lendableToken.poolSymbol = _lendableToken.poolSymbol;
        enabledLendableTokens[_lendableToken.tokenContract] = enabled;
    }

    /// @notice Enable/Disable support for ERC20 tokens to be used as lendable tokens for new bank nodes (does not effect existing nodes)
    ///
    /// - PRIVILEGES REQUIRED:
    ///     Admins with the role "CONFIGURE_NODE_MANAGER_ROLE"
    ///
    /// @param tokenContract lendable token contract address
    /// @param enabled `0` or `1`, Whether to enable (cannot be used to create bank node after disable)
    function setLendableTokenStatus(address tokenContract, uint8 enabled)
        external
        override
        onlyRole(CONFIGURE_NODE_MANAGER_ROLE)
    {
        require(enabled == 0 || enabled == 1, "enabled 1 or 0");
        enabledLendableTokens[tokenContract] = enabled;
    }

    /// @notice Set the minimum BNPL to bond per node
    ///
    /// - PRIVILEGES REQUIRED:
    ///     Admins with the role "CONFIGURE_NODE_MANAGER_ROLE"
    ///
    /// @param _minimumBankNodeBondedAmount minium bank node bonded amount
    function setMinimumBankNodeBondedAmount(uint256 _minimumBankNodeBondedAmount)
        external
        override
        onlyRole(CONFIGURE_NODE_MANAGER_ROLE)
    {
        minimumBankNodeBondedAmount = _minimumBankNodeBondedAmount;
    }

    /// @notice Set the loan overdue grace period per node
    ///
    /// - PRIVILEGES REQUIRED:
    ///     Admins with the role "CONFIGURE_NODE_MANAGER_ROLE"
    ///
    /// @param _loanOverdueGracePeriod loan overdue grace period (secs)
    function setLoanOverdueGracePeriod(uint256 _loanOverdueGracePeriod)
        external
        override
        onlyRole(CONFIGURE_NODE_MANAGER_ROLE)
    {
        loanOverdueGracePeriod = _loanOverdueGracePeriod;
    }

    /// @dev Create lending pool token contract
    ///
    /// @param name Token name
    /// @param symbol Token symbol
    /// @param decimalsValue Token decimals
    /// @param minterAdmin Token minter admin address
    /// @param minter Token minter address
    /// @return LendingPoolToken The lending pool token proxy contract address
    function _createBankNodeLendingPoolTokenClone(
        string memory name,
        string memory symbol,
        uint8 decimalsValue,
        address minterAdmin,
        address minter
    ) private returns (address) {
        BeaconProxy p = new BeaconProxy(
            address(protocolConfig.upBeaconBankNodeLendingPoolToken()),
            abi.encodeWithSelector(
                ITokenInitializableV1.initialize.selector,
                name,
                symbol,
                decimalsValue,
                minterAdmin,
                minter
            )
        );
        return address(p);
    }

    /// @dev Create staking pool token contract
    ///
    /// @param name Token name
    /// @param symbol Token symbol
    /// @param decimalsValue Token decimals
    /// @param minterAdmin Token minter admin address
    /// @param minter Token minter address
    /// @return StakingPoolToken The staking pool token proxy contract address
    function _createBankNodeStakingPoolTokenClone(
        string memory name,
        string memory symbol,
        uint8 decimalsValue,
        address minterAdmin,
        address minter
    ) private returns (address) {
        BeaconProxy p = new BeaconProxy(
            address(protocolConfig.upBeaconBankNodeStakingPool()),
            abi.encodeWithSelector(
                ITokenInitializableV1.initialize.selector,
                name,
                symbol,
                decimalsValue,
                minterAdmin,
                minter
            )
        );
        return address(p);
    }

    /// @dev Create BankNode contracts
    ///
    /// @param input `CreateBankNodeContractsFncInput` parameters structure:
    /// ```solidity
    /// uint32 bankNodeId
    /// address operatorAdmin
    /// address operator
    /// uint256 tokensToBond
    /// address lendableTokenAddress
    /// address nodePublicKey
    /// uint32 kycMode
    /// ```
    function _createBankNodeContracts(CreateBankNodeContractsFncInput memory input)
        private
        returns (BankNodeContracts memory output)
    {
        require(input.lendableTokenAddress != address(0), "lendableTokenAddress cannot be 0");
        LendableToken memory lendableToken = lendableTokens[input.lendableTokenAddress];
        require(
            lendableToken.tokenContract == input.lendableTokenAddress && lendableToken.valueMultiplier > 0,
            "invalid lendable token"
        );
        require(enabledLendableTokens[input.lendableTokenAddress] == 1, "lendable token not enabled");

        // Create bank node proxy contract
        output.bankNodeContract = address(new BeaconProxy(address(protocolConfig.upBeaconBankNode()), ""));

        // Create staking pool proxy contract
        output.bnplStakingPoolContract = address(
            new BeaconProxy(address(protocolConfig.upBeaconBankNodeStakingPool()), "")
        );

        // Create staking pool token
        output.bnplStakingPoolToken = _createBankNodeLendingPoolTokenClone(
            "Banking Node Pool BNPL",
            "pBNPL",
            18,
            address(0),
            output.bnplStakingPoolContract
        );

        // Create lending pool token
        output.bankNodeToken = _createBankNodeLendingPoolTokenClone(
            lendableToken.poolSymbol,
            lendableToken.poolSymbol,
            lendableToken.decimals,
            address(0),
            output.bankNodeContract
        );

        // Initialize bank node proxy contract
        IBankNodeInitializableV1(output.bankNodeContract).initialize(
            IBankNodeInitializableV1.BankNodeInitializeArgsV1({
                bankNodeId: input.bankNodeId,
                bnplSwapMarketPoolFee: lendableToken.swapMarketPoolFee,
                bankNodeManager: address(this),
                operatorAdmin: input.operatorAdmin,
                operator: input.operator,
                bnplToken: address(bnplToken),
                bnplSwapMarket: lendableToken.swapMarket,
                unusedFundsLendingMode: lendableToken.unusedFundsLendingMode,
                unusedFundsLendingContract: lendableToken.unusedFundsLendingContract,
                unusedFundsLendingToken: lendableToken.unusedFundsLendingToken,
                unusedFundsIncentivesController: lendableToken.unusedFundsIncentivesController,
                nodeStakingPool: output.bnplStakingPoolContract,
                baseLiquidityToken: lendableToken.tokenContract,
                poolLiquidityToken: output.bankNodeToken,
                nodePublicKey: input.nodePublicKey,
                kycMode: input.kycMode
            })
        );

        // Bond tokens
        TransferHelper.safeTransferFrom(
            address(bnplToken),
            msg.sender,
            output.bnplStakingPoolContract,
            input.tokensToBond
        );

        // Initialize staking pool proxy contract
        IBNPLNodeStakingPool(output.bnplStakingPoolContract).initialize(
            address(bnplToken),
            output.bnplStakingPoolToken,
            output.bankNodeContract,
            address(this),
            msg.sender,
            input.tokensToBond,
            bnplKYCStore,
            IBNPLBankNode(output.bankNodeContract).kycDomainId()
        );
    }

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
    /// @return id uint32 bank node id
    function createBondedBankNode(
        address operator,
        uint256 tokensToBond,
        address lendableTokenAddress,
        string calldata nodeName,
        string calldata website,
        string calldata configUrl,
        address nodePublicKey,
        uint32 kycMode
    ) external override nonReentrant returns (uint32 id) {
        require(tokensToBond >= minimumBankNodeBondedAmount && tokensToBond > 0, "Not enough tokens bonded");
        require(operator != address(0), "operator cannot be 0");
        require(lendableTokenAddress != address(0), "lendableTokenAddress cannot be 0");

        bankNodeCount = bankNodeCount + 1;
        id = bankNodeCount;

        BankNodeContracts memory createResult = _createBankNodeContracts(
            CreateBankNodeContractsFncInput({
                bankNodeId: bankNodeCount,
                operatorAdmin: operator,
                operator: operator,
                tokensToBond: tokensToBond,
                lendableTokenAddress: lendableTokenAddress,
                nodePublicKey: nodePublicKey,
                kycMode: kycMode
            })
        );
        BankNode storage bankNode = bankNodes[id];
        bankNode.id = id;

        bankNodeAddressToId[createResult.bankNodeContract] = bankNode.id;

        bankNode.bankNodeContract = createResult.bankNodeContract;
        bankNode.bankNodeToken = createResult.bankNodeToken;

        bankNode.bnplStakingPoolContract = createResult.bnplStakingPoolContract;
        bankNode.bnplStakingPoolToken = createResult.bnplStakingPoolToken;

        bankNode.lendableToken = lendableTokenAddress;
        bankNode.creator = msg.sender;

        bankNode.createdAt = uint64(block.timestamp);
        bankNode.createBlock = block.number;

        bankNode.nodeName = nodeName;
        bankNode.website = website;
        bankNode.configUrl = configUrl;

        return id;
    }
}
