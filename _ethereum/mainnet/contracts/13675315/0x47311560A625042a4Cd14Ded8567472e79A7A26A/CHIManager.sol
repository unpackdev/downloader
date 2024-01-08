// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.6;
pragma abicoder v2;

import "./SafeMath.sol";
import "./IERC721.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./MerkleProof.sol";

import "./ERC721Upgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";

import "./IUniswapV3Factory.sol";

import "./YANGPosition.sol";
import "./LiquidityHelper.sol";

import "./IYANGDepositCallBack.sol";
import "./ICHIManager.sol";
import "./ICHIVaultDeployer.sol";

contract CHIManager is
    ICHIManager,
    ReentrancyGuardUpgradeable,
    ERC721Upgradeable
{
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using YANGPosition for mapping(bytes32 => YANGPosition.Info);
    using YANGPosition for YANGPosition.Info;
    using LiquidityHelper for ICHIVault;

    // CHI ID
    uint176 private _nextId;
    // protocol fee
    uint256 private _vaultFee;
    // stragegy provider fee
    uint256 private _providerFee;

    /// YANG position
    mapping(bytes32 => YANGPosition.Info) public positions;

    /// @dev The token ID data
    mapping(uint256 => CHIData) private _chi;

    address public v3Factory;
    address public yangNFT;
    bytes32 public merkleRoot;

    address public manager; // MultiSig Address
    address public deployer; // CHIVault Deployer Address
    address public treasury; // MultiSig Address
    address public governance; // DAO Address, upgradable

    uint256 private _tempChiId;
    address private _tempVault;
    bool private _enableSwap;

    modifier subscripting(uint256 chiId) {
        _tempChiId = chiId;
        _;
        _tempChiId = 0;
    }

    modifier onlyYANG() {
        require(msg.sender == yangNFT, "y");
        _;
    }

    modifier onlyManager() {
        require(msg.sender == manager, "manager");
        _;
    }

    modifier onlyProviders(bytes32[] calldata merkleProof) {
        bytes32 node = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(merkleProof, merkleRoot, node), "providers");
        _;
    }

    modifier onlyProviderOrManager(uint256 tokenId) {
        require(
            _isApprovedOrOwner(msg.sender, tokenId) || msg.sender == manager,
            "NA"
        );
        _;
    }

    modifier onlyWhenNotPaused(uint256 tokenId) {
        require(!_chi[tokenId].config.paused, "paused");
        _tempVault = _chi[tokenId].vault;
        _;
        _tempVault = address(0);
    }

    modifier onlyWhenNotArchived(uint256 tokenId) {
        require(!_chi[tokenId].config.archived, "archived");
        _tempVault = _chi[tokenId].vault;
        _;
        _tempVault = address(0);
    }

    modifier isAuthorizedForToken(uint256 tokenId) {
        require(_isApprovedOrOwner(msg.sender, tokenId), "not approved");
        _;
    }

    // initialize
    function initialize(
        bytes32 _merkleRoot,
        address _v3Factory,
        address _yangNFT,
        address _deployer,
        address _manager,
        address _governance,
        address _treasury
    ) public initializer {
        v3Factory = _v3Factory;
        yangNFT = _yangNFT;
        merkleRoot = _merkleRoot;

        manager = _manager;
        treasury = _treasury;
        governance = _governance;
        deployer = _deployer;

        _vaultFee = 15 * 1e4;
        _providerFee = 5 * 1e4;
        _nextId = 1;
        _enableSwap = true;
        __ERC721_init("YIN Uniswap V3 Positions Manager", "CHI");
        __ReentrancyGuard_init();
    }

    // VIEW

    function chi(uint256 tokenId)
        external
        view
        override
        returns (
            address owner,
            address operator,
            address pool,
            address vault,
            uint256 accruedProtocolFees0,
            uint256 accruedProtocolFees1,
            uint24 fee,
            uint256 totalShares
        )
    {
        require(_exists(tokenId), "ITID");
        ICHIVault _vault = ICHIVault(_chi[tokenId].vault);
        return (
            ownerOf(tokenId),
            _chi[tokenId].operator,
            _chi[tokenId].pool,
            _chi[tokenId].vault,
            _vault.accruedProtocolFees0(),
            _vault.accruedProtocolFees1(),
            _vault.feeTier(),
            _vault.totalSupply()
        );
    }

    function chiVault(uint256 tokenId)
        external
        view
        override
        returns (
            uint256 amount0,
            uint256 amount1,
            uint256 collect0,
            uint256 collect1
        )
    {
        require(_exists(tokenId), "ITID");
        ICHIVault _vault = ICHIVault(_chi[tokenId].vault);
        (amount0, amount1) = _vault.getTotalAmounts();
        collect0 = _vault.accruedCollectFees0();
        collect1 = _vault.accruedCollectFees1();
    }

    function yang(uint256 yangId, uint256 chiId)
        external
        view
        override
        returns (uint256 shares)
    {
        YANGPosition.Info storage _position = positions.get(yangId, chiId);
        shares = _position.shares;
    }

    function config(uint256 tokenId)
        external
        view
        override
        returns (
            bool isPaused,
            bool isArchived,
            uint256 maxUSDLimit
        )
    {
        return (
            _chi[tokenId].config.paused,
            _chi[tokenId].config.archived,
            _chi[tokenId].config.maxUSDLimit
        );
    }

    // UTILITIES

    function setMerkleRoot(bytes32 _merkleRoot) external onlyManager {
        emit UpdateMerkleRoot(msg.sender, merkleRoot, _merkleRoot);

        merkleRoot = _merkleRoot;
    }

    function setGovernance(address newGov) external onlyManager {
        emit UpdateGovernance(msg.sender, governance, newGov);

        governance = newGov;
    }

    function setVaultFee(uint256 _vaultFee_) external {
        require(_vaultFee_ < 1e6, "f");
        require(msg.sender == governance, "gov");

        emit UpdateVaultFee(msg.sender, _vaultFee, _vaultFee_);

        _vaultFee = _vaultFee_;
    }

    function setProviderFee(uint256 _providerFee_) external {
        require(_providerFee_ < 1e6, "f");
        require(_providerFee_ < _vaultFee, "PLV");
        require(msg.sender == governance, "gov");

        emit UpdateProviderFee(msg.sender, _providerFee, _providerFee_);

        _providerFee = _providerFee_;
    }

    function setMaxUSDLimit(uint256 tokenId, uint256 _maxUSDLimit)
        external
        isAuthorizedForToken(tokenId)
    {
        emit UpdateMaxUSDLimit(
            msg.sender,
            _chi[tokenId].config.maxUSDLimit,
            _maxUSDLimit
        );

        _chi[tokenId].config.maxUSDLimit = _maxUSDLimit;
    }

    function setSwapSwitch(bool _enableSwap_) external onlyManager {
        emit UpdateSwapSwitch(msg.sender, _enableSwap, _enableSwap_);

        _enableSwap = _enableSwap_;
    }

    // CHI OPERATIONS

    function mint(MintParams calldata params, bytes32[] calldata merkleProof)
        external
        override
        onlyProviders(merkleProof)
        returns (uint256 tokenId, address vault)
    {
        address uniswapPool = IUniswapV3Factory(v3Factory).getPool(
            params.token0,
            params.token1,
            params.fee
        );

        require(uniswapPool != address(0), "NEP");

        vault = ICHIVaultDeployer(deployer).createVault(
            uniswapPool,
            address(this),
            _vaultFee
        );
        _mint(params.recipient, (tokenId = _nextId++));

        CHIConfig memory _config_ = CHIConfig({
            paused: false,
            archived: false,
            maxUSDLimit: 0
        });

        _chi[tokenId] = CHIData({
            operator: params.recipient,
            pool: uniswapPool,
            vault: vault,
            config: _config_
        });

        emit Create(tokenId, uniswapPool, vault, _vaultFee);
    }

    function subscribeSingle(
        uint256 yangId,
        uint256 tokenId,
        bool zeroForOne,
        uint256 exactAmount,
        uint256 maxTokenAmount,
        uint256 minShares
    )
        external
        override
        onlyYANG
        subscripting(tokenId)
        onlyWhenNotPaused(tokenId)
        nonReentrant
        returns (
            uint256 shares,
            uint256 amount0,
            uint256 amount1
        )
    {
        (shares, amount0, amount1) = ICHIVault(_tempVault).depositSingle(
            yangId,
            zeroForOne,
            exactAmount,
            maxTokenAmount,
            minShares
        );

        bytes32 positionKey = keccak256(abi.encodePacked(yangId, tokenId));
        positions[positionKey].shares = positions[positionKey].shares.add(
            shares
        );
    }

    function subscribe(
        uint256 yangId,
        uint256 tokenId,
        uint256 amount0Desired,
        uint256 amount1Desired,
        uint256 amount0Min,
        uint256 amount1Min
    )
        external
        override
        onlyYANG
        subscripting(tokenId)
        onlyWhenNotPaused(tokenId)
        nonReentrant
        returns (
            uint256 shares,
            uint256 amount0,
            uint256 amount1
        )
    {
        (shares, amount0, amount1) = ICHIVault(_tempVault).deposit(
            yangId,
            amount0Desired,
            amount1Desired,
            amount0Min,
            amount1Min
        );

        bytes32 positionKey = keccak256(abi.encodePacked(yangId, tokenId));
        positions[positionKey].shares = positions[positionKey].shares.add(
            shares
        );
    }

    function unsubscribe(
        uint256 yangId,
        uint256 tokenId,
        uint256 shares,
        uint256 amount0Min,
        uint256 amount1Min
    )
        external
        override
        onlyYANG
        onlyWhenNotArchived(tokenId)
        nonReentrant
        returns (uint256 amount0, uint256 amount1)
    {
        bytes32 positionKey = keccak256(abi.encodePacked(yangId, tokenId));
        YANGPosition.Info storage _position = positions[positionKey];
        require(_position.shares >= shares, "s");

        (amount0, amount1) = ICHIVault(_tempVault).withdraw(
            yangId,
            shares,
            amount0Min,
            amount1Min,
            yangNFT
        );
        _position.shares = positions[positionKey].shares.sub(shares);
    }

    function unsubscribeSingle(
        uint256 yangId,
        uint256 tokenId,
        bool zeroForOne,
        uint256 shares,
        uint256 amountOutMin
    )
        external
        override
        onlyYANG
        onlyWhenNotArchived(tokenId)
        nonReentrant
        returns (uint256 amount)
    {
        bytes32 positionKey = keccak256(abi.encodePacked(yangId, tokenId));
        YANGPosition.Info storage _position = positions[positionKey];
        require(_position.shares >= shares, "s");

        amount = ICHIVault(_tempVault).withdrawSingle(
            yangId,
            zeroForOne,
            shares,
            amountOutMin,
            yangNFT
        );
        _position.shares = positions[positionKey].shares.sub(shares);
    }

    // CALLBACK

    function _verifyCallback(address caller) internal view {
        require(_chi[_tempChiId].vault == caller, "CF");
    }

    function CHIDepositCallback(
        IERC20 token0,
        uint256 amount0,
        IERC20 token1,
        uint256 amount1,
        address recipient
    ) external override {
        _verifyCallback(msg.sender);
        IYANGDepositCallBack(yangNFT).YANGDepositCallback(
            token0,
            amount0,
            token1,
            amount1,
            recipient
        );
    }

    function collectProtocol(uint256 tokenId) external override {
        require(msg.sender == manager, "authority");

        ICHIVault vault = ICHIVault(_chi[tokenId].vault);
        uint256 accruedProtocolFees0 = vault.accruedProtocolFees0();
        uint256 accruedProtocolFees1 = vault.accruedProtocolFees1();

        uint256 amount0 = accruedProtocolFees0.mul(_providerFee).div(1e6);
        uint256 amount1 = accruedProtocolFees1.mul(_providerFee).div(1e6);

        vault.collectProtocol(
            amount0,
            amount1,
            IERC721(address(this)).ownerOf(tokenId)
        );
        vault.collectProtocol(
            accruedProtocolFees0.sub(amount0),
            accruedProtocolFees1.sub(amount1),
            treasury
        );
    }

    function addAndRemoveRanges(
        uint256 tokenId,
        RangeParams[] calldata addRanges,
        RangeParams[] calldata removeRanges
    )
        external
        override
        isAuthorizedForToken(tokenId)
        onlyWhenNotPaused(tokenId)
    {
        ICHIVault vault = ICHIVault(_tempVault);
        for (uint256 i = 0; i < addRanges.length; i++) {
            vault.addRange(addRanges[i].tickLower, addRanges[i].tickUpper);
        }
        for (uint256 i = 0; i < removeRanges.length; i++) {
            vault.removeRange(
                removeRanges[i].tickLower,
                removeRanges[i].tickUpper
            );
        }
        emit ChangeLiquidity(tokenId, _tempVault);
    }

    function addAllLiquidityToPosition(
        uint256 tokenId,
        uint256[] calldata ranges,
        uint256[] calldata amount0Totals,
        uint256[] calldata amount1Totals
    )
        external
        override
        isAuthorizedForToken(tokenId)
        onlyWhenNotPaused(tokenId)
    {
        ICHIVault(_tempVault).addAllLiquidityToPosition(
            ranges,
            amount0Totals,
            amount1Totals
        );
        emit ChangeLiquidity(tokenId, _tempVault);
    }

    function removeRangesLiquidityFromPosition(
        uint256 tokenId,
        uint256[] calldata ranges,
        uint128[] calldata liquidities
    )
        external
        override
        onlyWhenNotArchived(tokenId)
        isAuthorizedForToken(tokenId)
    {
        require(ranges.length == liquidities.length, "len");
        for (uint256 i = 0; i < ranges.length; i++) {
            ICHIVault(_tempVault).removeLiquidityFromPosition(
                ranges[i],
                liquidities[i]
            );
        }
        emit ChangeLiquidity(tokenId, _tempVault);
    }

    function removeRangesAllLiquidityFromPosition(
        uint256 tokenId,
        uint256[] calldata ranges
    )
        external
        override
        onlyWhenNotArchived(tokenId)
        isAuthorizedForToken(tokenId)
    {
        for (uint256 i = 0; i < ranges.length; i++) {
            ICHIVault(_tempVault).removeAllLiquidityFromPosition(ranges[i]);
        }
        emit ChangeLiquidity(tokenId, _tempVault);
    }

    function pausedCHI(uint256 tokenId)
        external
        override
        onlyWhenNotPaused(tokenId)
        onlyProviderOrManager(tokenId)
    {
        ICHIVault(_tempVault).removeVaultAllLiquidityFromPosition();
        _chi[tokenId].config.paused = true;

        emit ChangeLiquidity(tokenId, _tempVault);
    }

    function unpausedCHI(uint256 tokenId)
        external
        override
        onlyWhenNotPaused(tokenId)
        onlyProviderOrManager(tokenId)
    {
        _chi[tokenId].config.paused = false;
    }

    function archivedCHI(uint256 tokenId)
        external
        override
        onlyManager
        onlyWhenNotPaused(tokenId)
    {
        _chi[tokenId].config.archived = true;
    }

    function sweep(
        uint256 tokenId,
        address token,
        address to
    ) external override onlyManager {
        ICHIVault(_chi[tokenId].vault).sweep(token, to);

        emit Sweep(msg.sender, to, token, tokenId);
    }

    function emergencyBurn(
        uint256 tokenId,
        int24 tickLower,
        int24 tickUpper
    ) external override onlyManager {
        ICHIVault(_chi[tokenId].vault).emergencyBurn(tickLower, tickUpper);

        emit EmergencyBurn(msg.sender, tokenId, tickLower, tickUpper);
    }

    function swap(uint256 tokenId, ICHIVault.SwapParams memory params)
        external
        override
        isAuthorizedForToken(tokenId)
        returns (uint256 amountOut)
    {
        require(_enableSwap, "unable");
        amountOut = ICHIVault(_chi[tokenId].vault).swapPercentage(params);
        emit Swap(
            tokenId,
            params.tokenIn,
            params.tokenOut,
            params.percentage,
            amountOut
        );
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721Upgradeable)
        returns (string memory)
    {
        require(_exists(tokenId));
        return "";
    }

    function baseURI() public pure override returns (string memory) {}

    /// @inheritdoc IERC721Upgradeable
    function getApproved(uint256 tokenId)
        public
        view
        override(ERC721Upgradeable)
        returns (address)
    {
        require(
            _exists(tokenId),
            "ERC721Upgradeable: approved query for nonexistent token"
        );

        return _chi[tokenId].operator;
    }

    /// @dev Overrides _approve to use the operator in the position, which is packed with the position permit nonce
    function _approve(address to, uint256 tokenId)
        internal
        override(ERC721Upgradeable)
    {
        _chi[tokenId].operator = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }
}
