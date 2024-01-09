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

    mapping(address => uint8) public override enabledLendableTokens;

    mapping(address => LendableToken) public override lendableTokens;

    mapping(uint32 => BankNode) public override bankNodes;
    mapping(address => uint32) public override bankNodeAddressToId;

    uint256 public override minimumBankNodeBondedAmount;
    uint256 public override loanOverdueGracePeriod;

    uint32 public override bankNodeCount;
    IERC20 public override bnplToken;

    BankNodeLendingRewards public override bankNodeLendingRewards;

    IBNPLProtocolConfig public override protocolConfig;
    BNPLKYCStore public override bnplKYCStore;

    function bankNodeIdExists(uint32 bankNodeId) external view override returns (uint256) {
        return (bankNodeId >= 1 && bankNodeId <= bankNodeCount) ? 1 : 0;
    }

    function getBankNodeContract(uint32 bankNodeId) external view override returns (address) {
        require(bankNodeId >= 1 && bankNodeId <= bankNodeCount, "Invalid or unregistered bank node id!");
        return bankNodes[bankNodeId].bankNodeContract;
    }

    function getBankNodeToken(uint32 bankNodeId) external view override returns (address) {
        require(bankNodeId >= 1 && bankNodeId <= bankNodeCount, "Invalid or unregistered bank node id!");
        return bankNodes[bankNodeId].bankNodeToken;
    }

    function getBankNodeStakingPoolContract(uint32 bankNodeId) external view override returns (address) {
        require(bankNodeId >= 1 && bankNodeId <= bankNodeCount, "Invalid or unregistered bank node id!");
        return bankNodes[bankNodeId].bnplStakingPoolContract;
    }

    function getBankNodeStakingPoolToken(uint32 bankNodeId) external view override returns (address) {
        require(bankNodeId >= 1 && bankNodeId <= bankNodeCount, "Invalid or unregistered bank node id!");
        return bankNodes[bankNodeId].bnplStakingPoolToken;
    }

    function getBankNodeLendableToken(uint32 bankNodeId) external view override returns (address) {
        require(bankNodeId >= 1 && bankNodeId <= bankNodeCount, "Invalid or unregistered bank node id!");
        return bankNodes[bankNodeId].lendableToken;
    }

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

    /// @notice allows admins with the role "CONFIGURE_NODE_MANAGER_ROLE" to add support for a new ERC20 token to be used as lendable tokens for new bank nodes
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

    /// @notice allows admins with the role "CONFIGURE_NODE_MANAGER_ROLE" to enable/disable support for ERC20 tokens to be used as lendable tokens for new bank nodes (does not effect existing nodes)
    function setLendableTokenStatus(address tokenContract, uint8 enabled)
        external
        override
        onlyRole(CONFIGURE_NODE_MANAGER_ROLE)
    {
        require(enabled == 0 || enabled == 1, "enabled 1 or 0");
        enabledLendableTokens[tokenContract] = enabled;
    }

    /// @notice allows admins with the role "CONFIGURE_NODE_MANAGER_ROLE" to set the minimum BNPL to bond per node
    function setMinimumBankNodeBondedAmount(uint256 _minimumBankNodeBondedAmount)
        external
        override
        onlyRole(CONFIGURE_NODE_MANAGER_ROLE)
    {
        minimumBankNodeBondedAmount = _minimumBankNodeBondedAmount;
    }

    /// @notice allows admins with the role "CONFIGURE_NODE_MANAGER_ROLE" to set the loan overdue grace period per node
    function setLoanOverdueGracePeriod(uint256 _loanOverdueGracePeriod)
        external
        override
        onlyRole(CONFIGURE_NODE_MANAGER_ROLE)
    {
        loanOverdueGracePeriod = _loanOverdueGracePeriod;
    }

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
        output.bankNodeContract = address(new BeaconProxy(address(protocolConfig.upBeaconBankNode()), ""));
        output.bnplStakingPoolContract = address(
            new BeaconProxy(address(protocolConfig.upBeaconBankNodeStakingPool()), "")
        );

        output.bnplStakingPoolToken = _createBankNodeLendingPoolTokenClone(
            "Banking Node Pool BNPL",
            "pBNPL",
            18,
            address(0),
            output.bnplStakingPoolContract
        );
        output.bankNodeToken = _createBankNodeLendingPoolTokenClone(
            lendableToken.poolSymbol,
            lendableToken.poolSymbol,
            lendableToken.decimals,
            address(0),
            output.bankNodeContract
        );

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

        TransferHelper.safeTransferFrom(
            address(bnplToken),
            msg.sender,
            output.bnplStakingPoolContract,
            input.tokensToBond
        );

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

    /// @notice creates a new bonded bank node
    /// @param operator The node operator who will be assigned the permissions of bank node admin for the newly created bank node
    /// @param tokensToBond The number of BNPL tokens to bond for the node
    /// @param lendableTokenAddress Which lendable token will be lent to borrowers for this bank node (ex. the address of USDT's erc20 smart contract)
    /// @param nodeName the official name of the bank node
    /// @param website the official website of the bank node
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
