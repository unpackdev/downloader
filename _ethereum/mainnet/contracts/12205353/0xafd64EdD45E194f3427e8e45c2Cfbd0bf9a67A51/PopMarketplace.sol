// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.6;

import "./Ownable.sol";
import "./UniswapV2Library.sol";
import "./IUniswapV2Pair.sol";
import "./Mlp.sol";
import "./IMintableERC20.sol";
import "./IRewardManager.sol";
import "./IPopMarketplace.sol";
import "./SafeERC20.sol";

contract PopMarketplace is IFeesController, IPopMarketplace, Ownable {
    using SafeERC20 for IERC20;
    address public uniswapFactory;
    address public uniswapRouter;
    address[] public allMlp;
    address private _feesTo = msg.sender;
    uint256 private _feesPpm;
    uint256 public pendingMlpCount;
    IRewardManager public rewardManager;
    IMintableERC20 public popToken;

    mapping(uint256 => PendingMlp) public getMlp;

    enum MlpStatus {PENDING, APPROVED, CANCELED, ENDED}

    struct PendingMlp {
        address uniswapPair;
        address submitter;
        uint256 liquidity;
        uint256 endDate;
        MlpStatus status;
        uint256 bonusToken0;
        uint256 bonusToken1;
    }

    event MlpCreated(address indexed mlp);
    event MlpSubmitted(uint256 id);
    event MlpCanceled(uint256 id);
    event MlpEnded(uint256 id);

    constructor(
        address _popToken,
        address _uniswapFactory,
        address _uniswapRouter,
        address _rewardManager
    ) public {
        popToken = IMintableERC20(_popToken);
        uniswapFactory = _uniswapFactory;
        uniswapRouter = _uniswapRouter;
        rewardManager = IRewardManager(_rewardManager);
    }

    function submitMlp(
        address _token0,
        address _token1,
        uint256 _liquidity,
        uint256 _endDate,
        uint256 _bonusToken0,
        uint256 _bonusToken1
    ) public override {
        require(_endDate > now, "!datenow");

        IUniswapV2Pair pair =
            IUniswapV2Pair(
                UniswapV2Library.pairFor(uniswapFactory, _token0, _token1)
            );
        require(address(pair) != address(0), "!address0");

        if (_liquidity > 0) {
            IERC20(address(pair)).safeTransferFrom(
                msg.sender,
                address(this),
                _liquidity
            );
        }
        if (_bonusToken0 > 0) {
            IERC20(_token0).safeTransferFrom(
                msg.sender,
                address(this),
                _bonusToken0
            );
        }
        if (_bonusToken1 > 0) {
            IERC20(_token1).safeTransferFrom(
                msg.sender,
                address(this),
                _bonusToken1
            );
        }

        if (_token0 != pair.token0()) {
            uint256 tmp = _bonusToken0;
            _bonusToken0 = _bonusToken1;
            _bonusToken1 = tmp;
        }

        getMlp[pendingMlpCount++] = PendingMlp({
            uniswapPair: address(pair),
            submitter: msg.sender,
            liquidity: _liquidity,
            endDate: _endDate,
            status: MlpStatus.PENDING,
            bonusToken0: _bonusToken0,
            bonusToken1: _bonusToken1
        });
        emit MlpSubmitted(pendingMlpCount - 1);
    }

    function approveMlp(uint256 _mlpId, uint256 _allocPoint)
        external
        onlyOwner()
        returns (address mlpAddress)
    {
        PendingMlp storage pendingMlp = getMlp[_mlpId];
        require(pendingMlp.status == MlpStatus.PENDING);

        MLP newMlp =
            new MLP(
                pendingMlp.uniswapPair,
                pendingMlp.submitter,
                pendingMlp.endDate,
                uniswapRouter,
                address(this),
                rewardManager,
                pendingMlp.bonusToken0,
                pendingMlp.bonusToken1
            );
        mlpAddress = address(newMlp);
        rewardManager.add(_allocPoint, mlpAddress);
        popToken.setMinter(address(newMlp), true);
        allMlp.push(mlpAddress);
        IERC20(IUniswapV2Pair(pendingMlp.uniswapPair).token0()).safeTransfer(
            mlpAddress,
            pendingMlp.bonusToken0
        );
        IERC20(IUniswapV2Pair(pendingMlp.uniswapPair).token1()).safeTransfer(
            mlpAddress,
            pendingMlp.bonusToken1
        );

        pendingMlp.status = MlpStatus.APPROVED;
        emit MlpCreated(mlpAddress);

        return mlpAddress;
    }

    function cancelMlp(uint256 _mlpId) public override {
        PendingMlp storage pendingMlp = getMlp[_mlpId];

        require(pendingMlp.submitter == msg.sender, "!submitter");
        require(pendingMlp.status == MlpStatus.PENDING, "!pending");

        if (pendingMlp.liquidity > 0) {
            IUniswapV2Pair pair = IUniswapV2Pair(pendingMlp.uniswapPair);
            IERC20(address(pair)).safeTransfer(
                pendingMlp.submitter,
                pendingMlp.liquidity
            );
        }

        if (pendingMlp.bonusToken0 > 0) {
            IERC20(IUniswapV2Pair(pendingMlp.uniswapPair).token0())
                .safeTransfer(pendingMlp.submitter, pendingMlp.bonusToken0);
        }
        if (pendingMlp.bonusToken1 > 0) {
            IERC20(IUniswapV2Pair(pendingMlp.uniswapPair).token1())
                .safeTransfer(pendingMlp.submitter, pendingMlp.bonusToken1);
        }

        pendingMlp.status = MlpStatus.CANCELED;
        emit MlpCanceled(_mlpId);
    }

    function setFeesTo(address _newFeesTo) public override onlyOwner {
        require(_newFeesTo != address(0), "!address0");
        _feesTo = _newFeesTo;
    }

    function feesTo() public override returns (address) {
        return _feesTo;
    }

    function feesPpm() public override returns (uint256) {
        return _feesPpm;
    }

    function setFeesPpm(uint256 _newFeesPpm) public override onlyOwner {
        require(_newFeesPpm > 0, "!<0");
        _feesPpm = _newFeesPpm;
    }

    function endMlp(uint256 _mlpId) public override returns (uint256) {
        PendingMlp storage pendingMlp = getMlp[_mlpId];

        require(pendingMlp.submitter == msg.sender, "!submitter");
        require(pendingMlp.status == MlpStatus.APPROVED, "!approved");
        require(block.timestamp >= pendingMlp.endDate, "not yet ended");

        if (pendingMlp.liquidity > 0) {
            IUniswapV2Pair pair = IUniswapV2Pair(pendingMlp.uniswapPair);
            IERC20(address(pair)).safeTransfer(
                pendingMlp.submitter,
                pendingMlp.liquidity
            );
        }

        pendingMlp.status = MlpStatus.ENDED;
        emit MlpEnded(_mlpId);
        return pendingMlp.liquidity;
    }
}
