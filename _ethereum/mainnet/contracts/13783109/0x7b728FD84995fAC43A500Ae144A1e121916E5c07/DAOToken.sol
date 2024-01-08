// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "./ERC20.sol";
import "./SafeERC20.sol";
import "./EnumerableSet.sol";

import "./INonfungiblePositionManager.sol";
import "./IUniswapV3Factory.sol";
import "./IDAOToken.sol";
import "./IDAOFactory.sol";

import "./FullMath.sol";
import "./MintMath.sol";
import "./UniswapMath.sol";

/// @title DAO Token Contracts.
contract DAOToken is IDAOToken, ERC20 {
    using FullMath for uint256;
    using MintMath for MintMath.Anchor;
    using SafeERC20 for IERC20;
    using UniswapMath for INonfungiblePositionManager;
    using EnumerableSet for EnumerableSet.AddressSet;

    address public override owner;
    EnumerableSet.AddressSet private _managers;
    address public immutable override WETH9;

    uint256 public override temporaryAmount;
    MintMath.Anchor private _anchor;

    address public immutable override factory;
    uint256 public immutable override lpRatio;
    uint256 public immutable lpTotalAmount;
    uint256 public lpCurrentAmount;

    address public override lpToken0;
    address public override lpToken1;
    address public override lpPool;

    address public constant override UNISWAP_V3_POSITIONS = 0xC36442b4a4522E871399CD717aBDD847Ab11FE88;

    uint256 private constant MAX_UINT256 = type(uint256).max;

    modifier onlyOwner() {
        require(_msgSender() == owner, 'onlyOwner');
        _;
    }

    modifier onlyOwnerOrManager() {
        require(_managers.contains(_msgSender()) || _msgSender() == owner, 'onlyOwnerOrManager');
        _;
    }

    constructor(
        address[] memory _genesisTokenAddressList,
        uint256[] memory _genesisTokenAmountList,
        uint256 _lpRatio,
        uint256 _lpTotalAmount,
        address _factoryAddress,
        address payable _ownerAddress,
        MintMath.MintArgs memory _mintArgs,
        string memory _erc20Name,
        string memory _erc20Symbol
    ) ERC20(_erc20Name, _erc20Symbol) {
        require(_genesisTokenAddressList.length == _genesisTokenAmountList.length, 'GENESIS LENGTH INVALID');
        for (uint256 i = 0; i < _genesisTokenAddressList.length; i++) {
            _mint(_genesisTokenAddressList[i], _genesisTokenAmountList[i]);
        }
        if (totalSupply() > 0) {
            temporaryAmount = totalSupply().divMul(100, _lpRatio);
            temporaryAmount = temporaryAmount < _lpTotalAmount ? temporaryAmount : _lpTotalAmount;
            _mint(address(this), temporaryAmount);
        }

        _anchor.initialize(_mintArgs, block.timestamp);
        owner = _ownerAddress;
        factory = _factoryAddress;
        lpRatio = _lpRatio;
        lpTotalAmount = _lpTotalAmount;
        lpCurrentAmount = temporaryAmount;
        WETH9 = INonfungiblePositionManager(UNISWAP_V3_POSITIONS).WETH9();
    }

    function staking() external view override returns (address) {
        return IDAOFactory(factory).staking();
    }

    function transferOwnership(address payable _newOwner) external override onlyOwner {
        require(_newOwner != address(0));
        owner = _newOwner;
        emit TransferOwnership(_newOwner);
    }

    function destruct() external override onlyOwner {
        selfdestruct(payable(owner));
    }

    function managers() external view override returns (address[] memory) {
        address[] memory _managers_ = new address[](_managers.length());
        for (uint256 i = 0; i < _managers.length(); i++) {
            _managers_[i] = _managers.at(i);
        }
        return _managers_;
    }

    function isManager(address _address) external view override returns (bool) {
        return _managers.contains(_address);
    }

    function addManager(address manager) external override onlyOwner {
        _managers.add(manager);
        emit AddManager(manager);
    }

    function removeManager(address manager) external override onlyOwner {
        _managers.remove(manager);
        emit RemoveManager(manager);
    }

    function createLPPoolOrLinkLPPool(
        uint256 _baseTokenAmount,
        address _quoteTokenAddress,
        uint256 _quoteTokenAmount,
        uint24 _fee,
        int24 _tickLower,
        int24 _tickUpper,
        uint160 _sqrtPriceX96
    ) external payable override onlyOwner {
        require(lpPool == address(0), 'LP POOL ALREADY EXISTS');
        require(_baseTokenAmount > 0, 'BASE TOKEN AMOUNT MUST > 0');
        require(_quoteTokenAmount > 0, 'QUOTE TOKEN AMOUNT MUST > 0');
        require(_baseTokenAmount <= temporaryAmount, 'NOT ENOUGH TEMPORARYAMOUNT');
        require(_quoteTokenAddress != address(0), 'QUOTE TOKEN NOT EXIST');
        require(_quoteTokenAddress != address(this), 'QUOTE TOKEN CAN NOT BE BASE TOKEN');
        require(_fee == 500 || _fee == 3000 || _fee == 10000, 'FEE INVALID');

        INonfungiblePositionManager inpm = INonfungiblePositionManager(UNISWAP_V3_POSITIONS);
        address pool = IUniswapV3Factory(inpm.factory()).getPool(address(this), _quoteTokenAddress, _fee);

        IERC20(address(this)).safeApprove(UNISWAP_V3_POSITIONS, MAX_UINT256);
        if (_quoteTokenAddress != WETH9) {
            IERC20(_quoteTokenAddress).safeApprove(UNISWAP_V3_POSITIONS, MAX_UINT256);
            IERC20(_quoteTokenAddress).safeTransferFrom(_msgSender(), address(this), _quoteTokenAmount);
        }

        uint256 amount0;
        uint256 amount1;
        if (pool == address(0)) {
            (lpPool, lpToken0, lpToken1, amount0, amount1) = inpm.createDAOTokenPoolAndMint(
                _baseTokenAmount,
                _quoteTokenAddress,
                _quoteTokenAmount,
                _fee,
                _tickLower,
                _tickUpper,
                _sqrtPriceX96,
                msg.value
            );
        } else {
            INonfungiblePositionManager.MintParams memory params = UniswapMath.buildMintParams(
                _baseTokenAmount,
                _quoteTokenAddress,
                _quoteTokenAmount,
                _fee,
                _tickLower,
                _tickUpper
            );
            lpPool = pool;
            lpToken0 = params.token0;
            lpToken1 = params.token1;
            (, , amount0, amount1) = inpm.mint{value: msg.value}(params);
        }

        if (_quoteTokenAddress == WETH9) {
            INonfungiblePositionManager(UNISWAP_V3_POSITIONS).refundETH();
            if (address(this).balance > 0) {
                (bool success, ) = _msgSender().call{value: address(this).balance}(new bytes(0));
                require(success, 'refundETH failed');
            }
        } else {
            uint256 balance_ = IERC20(_quoteTokenAddress).balanceOf(address(this));
            if (balance_ > 0) IERC20(_quoteTokenAddress).safeTransfer(_msgSender(), balance_);
        }

        if (lpToken0 == address(this)) {
            temporaryAmount -= amount0;
        } else {
            temporaryAmount -= amount1;
        }

        emit CreateLPPoolOrLinkLPPool(
            _baseTokenAmount,
            _quoteTokenAddress,
            _quoteTokenAmount,
            _fee,
            _sqrtPriceX96,
            _tickLower,
            _tickUpper,
            lpPool
        );
    }

    function updateLPPool(
        uint256 _baseTokenAmount,
        int24 _tickLower,
        int24 _tickUpper
    ) external override onlyOwner {
        require(_baseTokenAmount <= temporaryAmount, 'NOT ENOUGH TEMPORARYAMOUNT');
        require(lpPool != address(0), 'NO POOL');

        (uint256 amount0, uint256 amount1) = INonfungiblePositionManager(UNISWAP_V3_POSITIONS).mintToLPByTick(
            lpPool,
            _baseTokenAmount,
            _tickLower,
            _tickUpper
        );
        if (lpToken0 == address(this)) {
            temporaryAmount -= amount0;
        } else {
            temporaryAmount -= amount1;
        }
        emit UpdateLPPool(_baseTokenAmount);
    }

    function mint(
        address[] memory _mintTokenAddressList,
        uint24[] memory _mintTokenAmountRatioList,
        uint256 _startTimestamp,
        uint256 _endTimestamp,
        int24 _tickLower,
        int24 _tickUpper
    ) external override onlyOwnerOrManager {
        require(_mintTokenAddressList.length == _mintTokenAmountRatioList.length, 'MINT ADDRESS LENGTH INVALID');
        require(_startTimestamp == _anchor.lastTimestamp, 'START TIMESTAMP INVALID');
        require(_endTimestamp <= block.timestamp, 'END TIMESTAMP INVALID 1');
        require(_endTimestamp > _anchor.lastTimestamp, 'END TIMESTAMP INVALID 2');
        uint256 mintValue = _anchor.total(_endTimestamp);

        uint256 ratioSum = 0;
        for (uint256 index; index < _mintTokenAmountRatioList.length; index++) {
            ratioSum += _mintTokenAmountRatioList[index];
        }
        for (uint256 index; index < _mintTokenAmountRatioList.length; index++) {
            _mint(_mintTokenAddressList[index], (mintValue * _mintTokenAmountRatioList[index]) / ratioSum);
        }

        uint256 thisTemporaryAmount = mintValue.divMul(100, lpRatio);
        uint256 lpLeftAmount = lpTotalAmount - lpCurrentAmount;
        thisTemporaryAmount = thisTemporaryAmount < lpLeftAmount ? thisTemporaryAmount : lpLeftAmount;
        if (thisTemporaryAmount > 0) {
            _mint(address(this), thisTemporaryAmount);
            temporaryAmount += thisTemporaryAmount;
            lpCurrentAmount += thisTemporaryAmount;

            if (lpPool != address(0)) {
                (uint256 amount0, uint256 amount1) = INonfungiblePositionManager(UNISWAP_V3_POSITIONS).mintToLPByTick(
                    lpPool,
                    thisTemporaryAmount,
                    _tickLower,
                    _tickUpper
                );
                if (lpToken0 == address(this)) {
                    temporaryAmount -= amount0;
                } else {
                    temporaryAmount -= amount1;
                }
            }
        }
        emit Mint(
            _mintTokenAddressList,
            _mintTokenAmountRatioList,
            _startTimestamp,
            _endTimestamp,
            _tickLower,
            _tickUpper,
            mintValue
        );
    }

    function bonusWithdraw() external override {
        uint256 count = INonfungiblePositionManager(UNISWAP_V3_POSITIONS).balanceOf(address(this));
        require(count > 0, 'NO POOL');
        uint256[] memory tokenIdList = new uint256[](count);
        for (uint256 index = 0; index < count; index++) {
            tokenIdList[index] = INonfungiblePositionManager(UNISWAP_V3_POSITIONS).tokenOfOwnerByIndex(
                address(this),
                index
            );
        }
        _bonusWithdrawByTokenIdList(tokenIdList);
    }

    function bonusWithdrawByTokenIdList(uint256[] memory tokenIdList) external override {
        INonfungiblePositionManager pm = INonfungiblePositionManager(UNISWAP_V3_POSITIONS);
        for (uint256 index = 0; index < tokenIdList.length; index++) {
            uint256 tokenId = tokenIdList[index];
            require(pm.ownerOf(tokenId) == address(this));
        }
        _bonusWithdrawByTokenIdList(tokenIdList);
    }

    function mintAnchor()
        external
        view
        override
        returns (
            uint128 p,
            uint16 aNumerator,
            uint16 aDenominator,
            uint16 bNumerator,
            uint16 bDenominator,
            uint16 c,
            uint16 d,
            uint256 lastTimestamp,
            uint256 n
        )
    {
        p = _anchor.args.p;
        aNumerator = _anchor.args.aNumerator;
        aDenominator = _anchor.args.aDenominator;
        bNumerator = _anchor.args.bNumerator;
        bDenominator = _anchor.args.bDenominator;
        c = _anchor.args.c;
        d = _anchor.args.d;

        lastTimestamp = _anchor.lastTimestamp;
        n = _anchor.n;
    }

    function _bonusWithdrawByTokenIdList(uint256[] memory tokenIdList) private {
        address _staking = IDAOFactory(factory).staking();
        require(_staking != address(0), 'NO _staking');
        uint256 token0TotalAmount = 0;
        uint256 token1TotalAmount = 0;

        uint256 token0Add = 0;
        uint256 token1Add = 0;
        for (uint256 index = 0; index < tokenIdList.length; index++) {
            (token0Add, token1Add) = INonfungiblePositionManager(UNISWAP_V3_POSITIONS).bonusWithdrawByTokenId(
                tokenIdList[index],
                lpToken0,
                lpToken1
            );
            token0TotalAmount += token0Add;
            token1TotalAmount += token1Add;
        }

        if (token0TotalAmount > 0) {
            uint256 bonusToken0TotalAmount = token0TotalAmount / 100;
            uint256 stackingToken0TotalAmount = token0TotalAmount - bonusToken0TotalAmount;
            IERC20(address(lpToken0)).safeTransfer(_staking, stackingToken0TotalAmount);
            IERC20(address(lpToken0)).safeTransfer(_msgSender(), bonusToken0TotalAmount);
        }

        if (token1TotalAmount > 0) {
            uint256 bonusToken1TotalAmount = token1TotalAmount / 100;
            uint256 stackingToken1TotalAmount = token1TotalAmount - bonusToken1TotalAmount;
            IERC20(address(lpToken1)).safeTransfer(_staking, stackingToken1TotalAmount);
            IERC20(address(lpToken1)).safeTransfer(_msgSender(), bonusToken1TotalAmount);
        }

        emit BonusWithdrawByTokenIdList(_msgSender(), tokenIdList, token0TotalAmount, token1TotalAmount);
    }

    receive() external payable {}
}
