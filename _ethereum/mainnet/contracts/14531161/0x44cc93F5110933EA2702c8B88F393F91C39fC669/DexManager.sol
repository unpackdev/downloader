// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./SafeERC20.sol";
import "./IERC20Metadata.sol";

import "./IDex.sol";
import "./IDexManager.sol";
import "./OperationsLib.sol";

//TODO:
// - tests (+ mocked wrapper)

/// @title Interface for the DEX manager
/// @author Cosmin Grigore (@gcosmintech)
contract DexManager is Ownable, ReentrancyGuard, IDexManager {
    using SafeERC20 for IERC20;

    /// @notice Mapping for registered AMM wrappers
    mapping(uint256 => address) public override AMMs;
    /// @notice Mapping for registered AMM wrappers pause status
    mapping(uint256 => bool) public override isAMMPaused;
    /// @notice Indicates if the contract is paused or not
    bool public isPaused;
    /// @notice Last registered id
    uint256 private _lastId;

    /// @notice Constructor
    /// @param _paused Pause state of the contract
    constructor(bool _paused) {
        isPaused = _paused;
        _lastId = 0;
    }

    //-----------------
    //----------------- View methods -----------------
    //-----------------
    /// @notice View method to return the next id in line
    function getNextId() public view override returns (uint256) {
        return _lastId + 1;
    }

    /// @notice Returns the amount one would obtain from a swap
    /// @param _ammId AMM id
    /// @param _tokenIn Token in address
    /// @param _tokenOut Token to be obtained from swap address
    /// @param _amountIn Amount to be used for swap
    /// @return Token out amount
    function getAmountsOut(
        uint256 _ammId,
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn,
        bytes calldata data
    ) external override payable returns (uint256) {
        require(msg.value == 0, "ERR: NO VALUE");
        address[] memory path = new address[](2);
        path[0] = _tokenIn;
        path[1] = _tokenOut;
        return
            IDex(AMMs[_ammId]).getAmountsOut(
                _tokenIn,
                _tokenOut,
                _amountIn,
                data
            );
    }

    //-----------------
    //----------------- Owner methods -----------------
    //-----------------
    /// @notice Register a new AMM to be used with by the manager
    /// @param _amm AMM wrapper address
    function registerAMM(address _amm)
        external
        onlyOwner
        validAddress(_amm)
        returns (uint256)
    {
        uint256 id = getNextId();
        require(AMMs[id] == address(0), "ERR: ID ALREADY ASSIGNED");
        AMMs[id] = _amm;
        _lastId += 1;
        emit AMMRegistered(msg.sender, _amm, id);
        return id;
    }

    /// @notice Pause an already registered AMM
    /// @param _id AMM id
    function pauseAMM(uint256 _id) external onlyOwner {
        require(AMMs[_id] != address(0), "ERR: ID NOT ASSIGNED");
        require(!isAMMPaused[_id], "ERR: AMM already paused");
        isAMMPaused[_id] = true;
        emit AMMPaused(msg.sender);
    }

    /// @notice Unpause an already registered AMM
    /// @param _id AMM id
    function unpauseAMM(uint256 _id) external onlyOwner {
        require(AMMs[_id] != address(0), "ERR: ID NOT ASSIGNED");
        require(isAMMPaused[_id], "ERR: AMM not paused");
        isAMMPaused[_id] = false;
        emit AMMUnpaused(msg.sender);
    }

    //-----------------
    //----------------- Non-view methods -----------------
    //-----------------
    /// @notice Removes liquidity and sends obtained tokens to sender
    /// @param _ammId AMM id
    /// @param _tokenA Token A address
    /// @param _tokenB Token B address
    /// @param amountParams Amount info (Min amount for token A, Min amount for token B, LP amount to be burnt)
    /// @param _data AMM specific data
    function removeLiquidity(
        uint256 _ammId,
        address _tokenA,
        address _tokenB,
        RemoveLiquidityData calldata amountParams,
        bytes calldata _data
    )
        external
        override
        validAMM(_ammId)
        nonReentrant
        returns (uint256, uint256)
    {
        require(_tokenA != address(0), "ERR: INVALID TOKEN_A ADDRESS");
        require(_tokenB != address(0), "ERR: INVALID TOKEN_B ADDRESS");
        require(amountParams._lpAmount > 0, "ERR: INVALID LP_AMOUNT");

        bytes memory amountsData = abi.encode(
            amountParams._lpAmount,
            amountParams._amountAMin,
            amountParams._amountBMin
        );
        (uint256 obtainedA, uint256 obtainedB) = IDex(AMMs[_ammId])
            .removeLiquidity(_tokenA, _tokenB, msg.sender, amountsData, _data);
        require(obtainedA > 0 || obtainedB > 0, "ERR: SWAP FAILED");

        emit RemovedLiquidityPerformed(
            msg.sender,
            amountParams._lpAmount,
            obtainedA,
            obtainedB
        );
        return (obtainedA, obtainedB);
    }

    /// @notice Adds liquidity and sends obtained LP & leftovers to sender
    /// @param _ammId AMM id
    /// @param _tokenA Token A address
    /// @param _tokenB Token B address
    /// @param amountParams Amount info (Desired amount for token A, Desired amount for token B, Min amount for token A, Min amount for token B)
    /// @param _data AMM specific data
    function addLiquidity(
        uint256 _ammId,
        address _tokenA,
        address _tokenB,
        AddLiquidityParams calldata amountParams,
        bytes calldata _data
    )
        external
        override
        validAMM(_ammId)
        nonReentrant
        returns (
            uint256, //amountADesired-usedA
            uint256, //amountBDesired-usedB
            uint256 //amountLP
        )
    {
        require(_tokenA != address(0), "ERR: INVALID TOKEN_A ADDRESS");
        require(_tokenB != address(0), "ERR: INVALID TOKEN_B ADDRESS");
        require(
            amountParams._amountADesired > 0,
            "ERR: INVALID AMOUNT_A_DESIRED"
        );
        require(amountParams._amountAMin > 0, "ERR: INVALID AMOUNT_A_MIN");
        require(
            amountParams._amountBDesired > 0,
            "ERR: INVALID AMOUNT_B_DESIRED"
        );
        require(amountParams._amountBMin > 0, "ERR: INVALID AMOUNT_B_MIN");

        _performAddLiquidityApprovals(
            _tokenA,
            _tokenB,
            amountParams._amountADesired,
            amountParams._amountBDesired,
            _ammId
        );

        AddLiquidityTemporaryData memory data;
        bytes memory amountsData = abi.encode(
            amountParams._amountADesired,
            amountParams._amountBDesired,
            amountParams._amountAMin,
            amountParams._amountBMin
        );
        (data.usedA, data.usedB, data.obtainedLP) = IDex(AMMs[_ammId])
            .addLiquidity(_tokenA, _tokenB, msg.sender, amountsData, _data);
        require(data.obtainedLP > 0, "ERR: ADD LIQUIDITY FAILED");

        emit AddLiquidityPerformed(
            _tokenA,
            _tokenB,
            _ammId,
            amountParams._amountADesired,
            amountParams._amountBDesired,
            data.usedA,
            data.usedB,
            data.obtainedLP
        );
        return (
            amountParams._amountADesired - data.usedA,
            amountParams._amountBDesired - data.usedB,
            data.obtainedLP
        );
    }

    /// @notice Performs a swap
    /// @param _ammId AMM id
    /// @param _tokenA Token A address
    /// @param _tokenB Token B address
    /// @param _amountIn Token A amount
    /// @param _amountOutMin Min amount for Token B
    /// @param _data AMM specific data
    function swap(
        uint256 _ammId,
        address _tokenA,
        address _tokenB,
        uint256 _amountIn,
        uint256 _amountOutMin,
        bytes calldata _data
    ) external override validAMM(_ammId) nonReentrant returns (uint256) {
        require(_tokenA != address(0), "ERR: INVALID TOKEN_A ADDRESS");
        require(_tokenB != address(0), "ERR: INVALID TOKEN_B ADDRESS");
        require(_amountIn > 0, "ERR: INVALID AMOUNT_IN");
        require(_amountOutMin > 0, "ERR: INVALID AMOUNT_OUT_MIN");

        _performSwapApprovals(_tokenA, _amountIn, _ammId);
        bytes memory amountsData = abi.encode(_amountIn, _amountOutMin);
        // perform swap
        uint256 amountToSend = IDex(AMMs[_ammId]).swap(
            _tokenA,
            _tokenB,
            amountsData,
            _data
        );
        require(amountToSend > 0, "ERR: INVALID SWAP");
        require(amountToSend >= _amountOutMin, "ERR: SWAP MIN AMOUNT");

        //transfer swapped token to sender
        IERC20(_tokenB).safeTransfer(msg.sender, amountToSend);

        emit SwapPerformed(
            msg.sender,
            _tokenA,
            _tokenB,
            _ammId,
            _amountIn,
            amountToSend
        );
        return amountToSend;
    }

    //-----------------
    //----------------- Private methods -----------------
    //-----------------

    /// @notice Peforms approvals and pre-transfers for the swap operation
    /// @param _tokenA Token A address
    /// @param _amountIn Amount of token A
    /// @param _ammId Registered AMM wrapper id
    function _performSwapApprovals(
        address _tokenA,
        uint256 _amountIn,
        uint256 _ammId
    ) private {
        IERC20(_tokenA).safeTransferFrom(msg.sender, address(this), _amountIn);
        OperationsLib.safeApprove(_tokenA, AMMs[_ammId], _amountIn);
    }

    /// @notice Peforms approvals and pre-transfers for the add liquidity operation
    /// @param _tokenA Token A address
    /// @param _tokenB Token B address
    /// @param _amountADesired Amount of token A used in the operation
    /// @param _amountBDesired Amount of token B used in the operation
    /// @param _ammId Registered AMM wrapper id
    function _performAddLiquidityApprovals(
        address _tokenA,
        address _tokenB,
        uint256 _amountADesired,
        uint256 _amountBDesired,
        uint256 _ammId
    ) private {
        IERC20(_tokenA).safeTransferFrom(
            msg.sender,
            address(this),
            _amountADesired
        );
        OperationsLib.safeApprove(_tokenA, AMMs[_ammId], _amountADesired);
        IERC20(_tokenB).safeTransferFrom(
            msg.sender,
            address(this),
            _amountBDesired
        );
        OperationsLib.safeApprove(_tokenB, AMMs[_ammId], _amountBDesired);
    }

    //-----------------
    //----------------- Modifiers -----------------
    //-----------------
    modifier validAddress(address _address) {
        require(_address != address(0), "ERR: INVALID ADDRESS");
        _;
    }

    modifier validAMM(uint256 _ammId) {
        require(AMMs[_ammId] != address(0), "ERR: AMM NOT REGISTERED");
        require(!isAMMPaused[_ammId], "ERR: AMM IS PAUSED");
        _;
    }
}
