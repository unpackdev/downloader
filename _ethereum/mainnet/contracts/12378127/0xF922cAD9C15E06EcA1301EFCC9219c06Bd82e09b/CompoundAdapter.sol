// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./ICERC20.sol";
import "./IAdapter.sol";
import "./INutmeg.sol";
import "./Governable.sol";
import "./Math.sol";

contract CompoundAdapter is Governable, IAdapter {
    using SafeERC20 for IERC20;
    using SafeMath for uint;

    struct PosInfo {
        uint posId;
        uint collAmt;
        uint sumIpcStart;
    }

    INutmeg public immutable nutmeg;

    uint private constant MULTIPLIER = 10**18;

    address[] public baseTokens; // array of base tokens
    mapping(address => bool) public baseTokenMap; // e.g., Dai
    mapping(address => address) public tokenPairs; // Dai -> cDai or cDai -> Dai;
    mapping(address => uint) public totalMintAmt;
    mapping(address => uint) public sumIpcMap;
    mapping(uint => PosInfo) public posInfoMap;

    mapping(address => uint) public totalLoan;
    mapping(address => uint) public totalCollateral;
    mapping(address => uint) public totalLoss;

    constructor(INutmeg nutmegAddr) {
        nutmeg = nutmegAddr;
        __Governable__init();
    }

    modifier onlyNutmeg() {
        require(msg.sender == address(nutmeg), 'only nutmeg can call');
        _;
    }

    /// @dev Add baseToken collToken pairs
    function addTokenPair(address baseToken, address collToken) external onlyGov {
        baseTokenMap[baseToken] = true;
        tokenPairs[baseToken] = collToken;
        baseTokens.push(baseToken);
    }

    /// @dev Remove baseToken collToken pairs
    function removeTokenPair(address baseToken) external onlyGov {
        baseTokenMap[baseToken] = false;
        tokenPairs[baseToken] = address(0);
    }

    /// @notice Open a position.
    /// @param baseToken Base token of the position.
    /// @param collToken Collateral token of the position.
    /// @param baseAmt Amount of collateral in base token.
    /// @param borrowAmt Amount of base token to be borrowed from nutmeg.
    function openPosition(address baseToken, address collToken, uint baseAmt, uint borrowAmt)
        external onlyNutmeg override {
        require(baseAmt > 0, 'openPosition: invalid base amount');
        require(baseTokenMap[baseToken], 'openPosition: invalid baseToken address');
        require(tokenPairs[baseToken] == collToken, 'openPosition: invalid cToken address');

        uint posId = nutmeg.getCurrPositionId();
        INutmeg.Position memory pos = nutmeg.getPosition(posId);
        require(nutmeg.getCurrSender() == pos.owner, 'openPosition: only owner can initialize this call');
        require(IERC20(baseToken).balanceOf(pos.owner) >= baseAmt, 'openPosition: insufficient balance');

        // check borrowAmt
        uint maxBorrowAmt = nutmeg.getMaxBorrowAmount(baseToken, baseAmt);
        require(borrowAmt <= maxBorrowAmt, "openPosition: borrowAmt exceeds maximum");
        require(borrowAmt > baseAmt, "openPosition: borrowAmt is less than collateral");

        // borrow base tokens from nutmeg
        nutmeg.borrow(baseToken, collToken, baseAmt, borrowAmt);

        _increaseDebtAndCollateral(baseToken, posId);

        // mint collateral tokens from compound
        pos = nutmeg.getPosition(posId);
        (uint result, uint mintAmt) = _doMint(pos, borrowAmt);
        require(result == 0, 'opnPos: _doMint fail');
        if (mintAmt > 0) {
            uint currSumIpc = _calcLatestSumIpc(collToken);
            totalMintAmt[collToken] = totalMintAmt[collToken].add(mintAmt);
            PosInfo storage posInfo = posInfoMap[posId];
            posInfo.sumIpcStart = currSumIpc;
            posInfo.collAmt = mintAmt;

            // add mintAmt to the position in nutmeg.
            nutmeg.addCollToken(posId, mintAmt);
        }
        emit openPositionEvent(posId, nutmeg.getCurrSender(), baseAmt, borrowAmt);
    }

    /// @notice Close a position by the borrower
    function closePosition() external onlyNutmeg override returns (uint) {
        uint posId = nutmeg.getCurrPositionId();
        INutmeg.Position memory pos = nutmeg.getPosition(posId);
        require(pos.owner == nutmeg.getCurrSender(), 'closePosition: original caller is not the owner');

        uint collAmt = _getCollTokenAmount(pos);
        (uint result, uint redeemAmt) = _doRedeem(pos, collAmt);
        require(result == 0, 'clsPos: rdm fail');

        // allow nutmeg to receive redeemAmt from the adapter
        IERC20(pos.baseToken).safeApprove(address(nutmeg), 0);
        IERC20(pos.baseToken).safeApprove(address(nutmeg), redeemAmt);

        // repay to nutmeg
        _decreaseDebtAndCollateral(pos.baseToken, pos.id, redeemAmt);
        nutmeg.repay(pos.baseToken, redeemAmt);
        pos = nutmeg.getPosition(posId);
        totalLoss[pos.baseToken] =
            totalLoss[pos.baseToken].add(pos.repayDeficit);
        totalMintAmt[pos.collToken] = totalMintAmt[pos.collToken].sub(pos.collAmt);
        emit closePositionEvent(posId, nutmeg.getCurrSender(), redeemAmt);
        return redeemAmt;
    }

    /// @notice Liquidate a position
    function liquidate() external override onlyNutmeg  {
        uint posId = nutmeg.getCurrPositionId();
        INutmeg.Position memory pos = nutmeg.getPosition(posId);
        require(_okToLiquidate(pos), 'liquidate: position is not ready for liquidation yet.');

        uint amount = _getCollTokenAmount(pos);
        (uint result, uint redeemAmt) = _doRedeem(pos, amount);
        require(result == 0, 'lqdte: rdm fail');
        IERC20(pos.baseToken).safeApprove(address(nutmeg), 0);
        IERC20(pos.baseToken).safeApprove(address(nutmeg), redeemAmt);

        // liquidate the position in nutmeg.
        _decreaseDebtAndCollateral(pos.baseToken, posId, redeemAmt);
        nutmeg.liquidate(pos.baseToken, redeemAmt);
        pos = nutmeg.getPosition(posId);
        totalLoss[pos.baseToken] = totalLoss[pos.baseToken].add(pos.repayDeficit);
        totalMintAmt[pos.collToken] = totalMintAmt[pos.collToken].sub(pos.collAmt);
        emit liquidateEvent(posId, nutmeg.getCurrSender());
    }
    /// @notice Get value of credit tokens
    function creditTokenValue(address baseToken) public returns (uint) {
        address collToken = tokenPairs[baseToken];
        require(collToken != address(0), "settleCreditEvent: invalid collateral token" );
        uint collTokenBal = ICERC20(collToken).balanceOf(address(this));
        return collTokenBal.mul(ICERC20(collToken).exchangeRateCurrent());
    }

    /// @notice Settle credit event
    /// @param baseToken The base token address
    function settleCreditEvent( address baseToken, uint collateralLoss, uint poolLoss) external override onlyNutmeg {
        require(baseTokenMap[baseToken] , "settleCreditEvent: invalid base token" );
        require(collateralLoss <= totalCollateral[baseToken], "settleCreditEvent: invalid collateral" );
        require(poolLoss <= totalLoan[baseToken], "settleCreditEvent: invalid poolLoss" );

        nutmeg.distributeCreditLosses(baseToken, collateralLoss, poolLoss);

        emit creditEvent(baseToken, collateralLoss, poolLoss);
        totalLoss[baseToken] = 0;
        totalLoan[baseToken] = totalLoan[baseToken].sub(poolLoss);
        totalCollateral[baseToken] = totalCollateral[baseToken].sub(collateralLoss);
    }

    function _increaseDebtAndCollateral(address token, uint posId) internal {
        INutmeg.Position memory pos = nutmeg.getPosition(posId);
        for (uint i = 0; i < 3; i++) {
            totalLoan[token] = totalLoan[token].add(pos.loans[i]);
        }
        totalCollateral[token] = totalCollateral[token].add(pos.baseAmt);
    }

    /// @dev decreaseDebtAndCollateral
    function _decreaseDebtAndCollateral(address token, uint posId, uint redeemAmt) internal {
        INutmeg.Position memory pos = nutmeg.getPosition(posId);
        uint totalLoans = pos.loans[0] + pos.loans[1] + pos.loans[2];
        if (redeemAmt >= totalLoans) {
            totalLoan[token] = totalLoan[token].sub(totalLoans);
        } else {
            totalLoan[token] = totalLoan[token].sub(redeemAmt);
        }
        totalCollateral[token] = totalCollateral[token].sub(pos.baseAmt);
    }

    /// @dev Do the mint from the 3rd party pool.this
    function _doMint(INutmeg.Position memory pos, uint amount) internal returns(uint, uint) {
        uint balBefore = ICERC20(pos.collToken).balanceOf(address(this));
        require(IERC20(pos.baseToken).approve(pos.collToken, 0), '_doMint approve error');
        require(IERC20(pos.baseToken).approve(pos.collToken, amount), '_doMint approve amount error');
        uint result = ICERC20(pos.collToken).mint(amount);
        require(result == 0, '_doMint mint error');
        uint balAfter = ICERC20(pos.collToken).balanceOf(address(this));
        uint mintAmount = balAfter.sub(balBefore);
        return (result, mintAmount);
    }

    /// @dev Do the redeem from the 3rd party pool.
    function _doRedeem(INutmeg.Position memory pos, uint amount) internal returns(uint, uint) {
        uint balBefore = IERC20(pos.baseToken).balanceOf(address(this));
        uint result = ICERC20(pos.collToken).redeem(amount);
        uint balAfter = IERC20(pos.baseToken).balanceOf(address(this));
        uint redeemAmt = balAfter.sub(balBefore);
        return (result, redeemAmt);
    }

    /// @dev Get the amount of collToken a position.
    function _getCollTokenAmount(INutmeg.Position memory pos) internal returns(uint) {
        uint currSumIpc = _calcLatestSumIpc(pos.collToken);
        PosInfo storage posInfo = posInfoMap[pos.id];
        uint interest = posInfo.collAmt.mul(currSumIpc.sub(posInfo.sumIpcStart)).div(MULTIPLIER);
        return posInfo.collAmt.add(interest);
    }

    /// @dev Calculate the latest sumIpc.
    /// @param collToken The cToken.
    function _calcLatestSumIpc(address collToken) internal returns(uint) {
        uint balance = ICERC20(collToken).balanceOf(address(this));
        uint mintBalance = totalMintAmt[collToken];
        uint interest = mintBalance > balance ? mintBalance.sub(balance) : 0;
        uint currIpc = (mintBalance == 0) ? 0 : (interest.mul(MULTIPLIER)).div(mintBalance);
        if (currIpc > 0){
            sumIpcMap[collToken] = sumIpcMap[collToken].add(currIpc);
        }
        return sumIpcMap[collToken];
    }

    /// @dev Check if the position is eligible to be liquidated.
    function _okToLiquidate(INutmeg.Position memory pos) internal view returns(bool) {
        bool ok = false;
        uint interest = nutmeg.getPositionInterest(pos.baseToken, pos.id);
        if (interest.mul(2) >= pos.baseAmt) {
            ok = true;
        }
        return ok;
    }

}
