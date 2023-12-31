// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.19;

import "./IDittoPoolFactory.sol";
import "./FactoryTemplates.sol";
import "./IDittoPool.sol";
import "./IDittoRouter.sol";
import "./IPoolManager.sol";
import "./IMetadataGenerator.sol";

import "./LpNft.sol";
import "./OwnerTwoStep.sol";
import "./IPermitter.sol";

import "./ReentrancyGuard.sol";
import "./Clones.sol";
import "./IERC721.sol";
import "./ERC20.sol";
import "./SafeTransferLib.sol";

contract DittoPoolFactory is IDittoPoolFactory, OwnerTwoStep, ReentrancyGuard {
    using SafeTransferLib for ERC20;
    using Clones for address;

    ///@dev The protocol fee is a 1e18 based number that is multiplied by the proceeds of a trade to determine the protocol fee
    ///@dev Packed tightly with _feeProtocolRecipient
    uint96 private _feeProtocol;
    uint96 internal constant MAX_PROTOCOL_FEE = 0.1e18;

    /// @dev The address that receives the protocol fee
    address private _feeProtocolRecipient;

    /// @dev The NFT that represents LP positions
    LpNft private _lpNft;

    ///@dev Implementations of DittoPool that can be cloned to create new pools
    address[] private _poolTemplates;

    ///@dev Implementations of PoolManager that can be cloned to create new pool managers on pool creation
    IPoolManager[] private _poolManagerTemplates;

    ///@dev Implementations of Permitter that can be cloned to create new permitter on pool creation
    IPermitter[] private _permitterTemplates;

    ///@dev The routers that are allowed to interact with pools
    mapping(address => bool) private _routers;

    // ***************************************************************
    // * ========================= EVENTS ========================== *
    // ***************************************************************
    event DittoPoolFactoryDittoPoolCreated(
        PoolTemplate poolTemplate,
        address dittoPool,
        PoolManagerTemplate poolManagerTemplate,
        address poolManager,
        PermitterTemplate permitterTemplate,
        address permitter,
        bytes permitterInitData
    );
    event DittoPoolFactoryAdminAddedPoolTemplate(address poolTemplate);
    event DittoPoolFactoryAdminAddedPoolManagerTemplate(address poolManagerTemplate);
    event DittoPoolFactoryAdminAddedPermitterTemplate(address permitterTemplate);
    event DittoPoolFactoryAdminAddedRouter(address router);
    event DittoPoolFactoryAdminUpdatedLpNft(address lpNft);
    event DittoPoolFactoryAdminSetProtocolFeeRecipient(address protocolFeeRecipient);
    event DittoPoolFactoryAdminSetProtocolFeeMultiplier(uint96 protocolFeeMultiplier);

    // ***************************************************************
    // * ========================= ERRORS ========================== *
    // ***************************************************************
    error DittoPoolFactoryInvalidTemplateIndex(uint256 templateIndex);
    error DittoPoolFactoryInvalidProtocolFee();

    /**
     * @notice Instantiates a new DittoPoolFactory by deploying a new liquidity position NFT, settting state,
     *   and adding the initial templates
     *
     */
    constructor(
        LpNft lpNft_,
        address feeProtocolRecipient_,
        uint96 feeProtocol_,
        address[] memory poolTemplates_,
        IPoolManager[] memory poolManagerTemplates_,
        IPermitter[] memory permitterTemplates_
    ) {
        _setLpNft(lpNft_);
        _setProtocolFee(feeProtocol_);
        _setProtocolFeeRecipient(feeProtocolRecipient_);
        _addPoolTemplates(poolTemplates_);
        _addPoolManagerTemplates(poolManagerTemplates_);
        _addPermitterTemplates(permitterTemplates_);
    }

    // ***************************************************************
    // * ================== MAIN INTERFACE ========================= *
    // ***************************************************************

    ///@inheritdoc IDittoPoolFactory
    function createDittoPool(
        PoolTemplate memory poolTemplate_,
        PoolManagerTemplate calldata poolManagerTemplate_,
        PermitterTemplate calldata permitterTemplate_
    )
        external
        nonReentrant
        returns (IDittoPool dittoPool, uint256 lpId, IPoolManager poolManager, IPermitter permitter)
    {
        // STEP 0: CHECK PRECONDITIONS AND CACHE LIQUIDITY PROVIDER
        if (poolTemplate_.templateIndex >= _poolTemplates.length) {
            revert DittoPoolFactoryInvalidTemplateIndex(poolTemplate_.templateIndex);
        }

        address liquidityProvider = poolTemplate_.owner;
        bytes memory permitterInitData;

        // STEP 1: CREATE THE PERMITTER
        if (permitterTemplate_.templateIndex < _permitterTemplates.length) {
            permitter = IPermitter(address(_permitterTemplates[permitterTemplate_.templateIndex]).clone());
            permitterInitData = permitter.initialize(permitterTemplate_.templateInitData);
        }

        // STEP 2: CREATE THE DITTOPOOL
        address templateAddr = _poolTemplates[poolTemplate_.templateIndex];
        dittoPool = IDittoPool(templateAddr.clone());

        // STEP 3: CREATE THE POOL MANAGER
        if (poolManagerTemplate_.templateIndex < _poolManagerTemplates.length) {
            poolManager = IPoolManager(address(_poolManagerTemplates[poolManagerTemplate_.templateIndex]).clone());
            poolManager.initialize(address(dittoPool), poolManagerTemplate_.templateInitData);
            poolTemplate_.owner = address(poolManager);
        }

        emit DittoPoolFactoryDittoPoolCreated(
            poolTemplate_,
            address(dittoPool),
            poolManagerTemplate_,
            address(poolManager),
            permitterTemplate_,
            address(permitter),
            permitterInitData
        );

        // STEP 4: INITIALIZE DITTOPOOL
        dittoPool.initPool(poolTemplate_, templateAddr, _lpNft, permitter);

        // STEP 5: REGISTER NEW DITTOPOOL
        _lpNft.setApprovedDittoPool(address(dittoPool), IERC721(poolTemplate_.nft));

        // STEP 6: ADDLIQUIDITY IF REQUESTED
        lpId = _addLiquidityIfRequested(poolTemplate_, permitterTemplate_, dittoPool, liquidityProvider);
    }

    // ***************************************************************
    // * ============== EXTERNAL VIEW FUNCTIONS ===================== *
    // ***************************************************************

    ///@inheritdoc IDittoPoolFactory
    function poolTemplates() external view override returns (address[] memory) {
        return _poolTemplates;
    }

    ///@inheritdoc IDittoPoolFactory
    function poolManagerTemplates() external view override returns (IPoolManager[] memory) {
        return _poolManagerTemplates;
    }

    ///@inheritdoc IDittoPoolFactory
    function permitterTemplates() external view override returns (IPermitter[] memory) {
        return _permitterTemplates;
    }

    ///@inheritdoc IDittoPoolFactory
    function isWhitelistedRouter(address router_) external view override returns (bool) {
        return _routers[router_];
    }

    ///@inheritdoc IDittoPoolFactory
    function protocolFeeRecipient() external view returns (address) {
        return _feeProtocolRecipient;
    }

    ///@inheritdoc IDittoPoolFactory
    function getProtocolFee() external view returns (uint96) {
        return _feeProtocol;
    }

    ///@inheritdoc IDittoPoolFactory
    function lpNft() external view returns (LpNft lpNft_) {
        return _lpNft;
    }

    // ***************************************************************
    // * ==================== ADMIN FUNCTIONS ====================== *
    // ***************************************************************

    ///@inheritdoc IDittoPoolFactory
    function addPoolTemplates(address[] calldata poolTemplates_) external onlyOwner {
        _addPoolTemplates(poolTemplates_);
    }

    ///@inheritdoc IDittoPoolFactory
    function addPoolManagerTemplates(IPoolManager[] calldata poolManagerTemplates_) external onlyOwner {
        _addPoolManagerTemplates(poolManagerTemplates_);
    }

    ///@inheritdoc IDittoPoolFactory
    function addPermitterTemplates(IPermitter[] calldata permitterTemplates_) external onlyOwner {
        _addPermitterTemplates(permitterTemplates_);
    }

    ///@inheritdoc IDittoPoolFactory
    function addRouters(IDittoRouter[] calldata routers_) external onlyOwner {
        uint256 routerCount = routers_.length;
        for (uint256 i = 0; i < routerCount;) {
            address router = address(routers_[i]);
            _routers[router] = true;
            emit DittoPoolFactoryAdminAddedRouter(router);
            unchecked {
                ++i;
            }
        }
    }

    ///@inheritdoc IDittoPoolFactory
    function setProtocolFee(uint96 feeProtocol_) external onlyOwner {
        _setProtocolFee(feeProtocol_);
    }

    ///@inheritdoc IDittoPoolFactory
    function setProtocolFeeRecipient(address feeProtocolRecipient_) external onlyOwner {
        _setProtocolFeeRecipient(feeProtocolRecipient_);
    }

    ///@inheritdoc IDittoPoolFactory
    function setLpNft(LpNft lpNft_) external onlyOwner {
        _setLpNft(lpNft_);
    }

    // ***************************************************************
    // * ============= PRIVATE HELPER FUNCTIONS ==================== *
    // ***************************************************************

    /**
     * @notice Adds liquidity to the new pool if requested.
     *   In a separate function to avoid stack too deep errors
     *
     * @param poolTemplate_ The pool template
     * @param permitterTemplate_ The permitter template
     * @param dittoPool_ The DittoPool
     * @param liquidityProvider_ The liquidity provider
     * @return lpId The lp id
     */
    function _addLiquidityIfRequested(
        PoolTemplate memory poolTemplate_,
        PermitterTemplate calldata permitterTemplate_,
        IDittoPool dittoPool_,
        address liquidityProvider_
    ) private returns (uint256 lpId) {
        bool areNftsToAdd = poolTemplate_.nftIdList.length != 0;
        bool areErc20sToAdd = poolTemplate_.initialTokenBalance != 0;
        if (areErc20sToAdd || areNftsToAdd) {
            if (areErc20sToAdd) {
                ERC20(poolTemplate_.token).safeTransferFrom(
                    liquidityProvider_, address(this), poolTemplate_.initialTokenBalance
                );
                ERC20(poolTemplate_.token).safeApprove(address(dittoPool_), poolTemplate_.initialTokenBalance);
            }
            if (areNftsToAdd) {
                _transferNftsToFactory(IERC721(poolTemplate_.nft), liquidityProvider_, poolTemplate_.nftIdList);
                IERC721(poolTemplate_.nft).setApprovalForAll(address(dittoPool_), true);
            }

            lpId = dittoPool_.createLiquidity(
                liquidityProvider_,
                poolTemplate_.nftIdList,
                poolTemplate_.initialTokenBalance,
                permitterTemplate_.liquidityDepositPermissionData,
                poolTemplate_.referrer
            );

            if (areNftsToAdd) {
                IERC721(poolTemplate_.nft).setApprovalForAll(address(dittoPool_), false);
            }
        }
    }

    /**
     * @notice maximum 10%, must <= 1 - MAX_FEE
     *
     * @param feeProtocol_ proposed protocol fee
     */
    function _setProtocolFee(uint96 feeProtocol_) private {
        if (feeProtocol_ > MAX_PROTOCOL_FEE) {
            revert DittoPoolFactoryInvalidProtocolFee();
        }
        _feeProtocol = feeProtocol_;
        emit DittoPoolFactoryAdminSetProtocolFeeMultiplier(feeProtocol_);
    }

    /**
     * @notice Set the protocol fee recipient
     *
     * @param feeProtocolRecipient_ address of the protocol fee recipient to set
     */
    function _setProtocolFeeRecipient(address feeProtocolRecipient_) private {
        _feeProtocolRecipient = feeProtocolRecipient_;

        emit DittoPoolFactoryAdminSetProtocolFeeRecipient(feeProtocolRecipient_);
    }

    /**
     * @notice set the LP NFT collection that represents liquidity created by this factory
     * 
     * @param lpNft_ address of the LP NFT collection
     */
    function _setLpNft(LpNft lpNft_) private {
        _lpNft = lpNft_;

        emit DittoPoolFactoryAdminUpdatedLpNft(address(lpNft_));
    }

    /**
     * @notice Transfer the NFTs to the factory, so that it pass them to the pool.
     *
     * @param nft_ address of the NFT collection
     * @param from_ address to transfer from
     * @param nftIdList_ array of token IDs for the NFT to transfer
     */
    function _transferNftsToFactory(IERC721 nft_, address from_, uint256[] memory nftIdList_) private {
        uint256 countTokenIds = nftIdList_.length;
        uint256 tokenId;
        for (uint256 i = 0; i < countTokenIds;) {
            tokenId = nftIdList_[i];
            nft_.transferFrom(from_, address(this), tokenId);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Adds pool templates to the registry of templates stored on this contract
     * @param poolTemplates_ array of addresses of pool templates to add
     */
    function _addPoolTemplates(address[] memory poolTemplates_) private {
        uint256 countPoolTemplates = poolTemplates_.length;
        address poolTemplate;
        for (uint256 i = 0; i < countPoolTemplates;) {
            poolTemplate = poolTemplates_[i];
            _poolTemplates.push(poolTemplate);
            emit DittoPoolFactoryAdminAddedPoolTemplate(poolTemplate);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Adds pool manager templates to the registry of templates stored on this contract
     * @param poolManagerTemplates_ array of addresses of pool manager templates to add
     */
    function _addPoolManagerTemplates(IPoolManager[] memory poolManagerTemplates_) private {
        uint256 countPoolManagerTemplates = poolManagerTemplates_.length;
        IPoolManager poolManagerTemplate;
        for (uint256 i = 0; i < countPoolManagerTemplates;) {
            poolManagerTemplate = poolManagerTemplates_[i];
            _poolManagerTemplates.push(poolManagerTemplate);
            emit DittoPoolFactoryAdminAddedPoolManagerTemplate(address(poolManagerTemplate));
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Adds permitter templates to the registry of templates stored on this contract
     * @param permitterTemplates_ array of addresses of permitter templates to add
     */
    function _addPermitterTemplates(IPermitter[] memory permitterTemplates_) private {
        uint256 countPermitterTemplates = permitterTemplates_.length;
        IPermitter permitterTemplate;
        for (uint256 i = 0; i < countPermitterTemplates;) {
            permitterTemplate = permitterTemplates_[i];
            _permitterTemplates.push(permitterTemplate);
            emit DittoPoolFactoryAdminAddedPermitterTemplate(address(permitterTemplate));
            unchecked {
                ++i;
            }
        }
    }
}
