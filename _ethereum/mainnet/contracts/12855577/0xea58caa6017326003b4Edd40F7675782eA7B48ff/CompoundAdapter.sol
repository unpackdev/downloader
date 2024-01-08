// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./Initializable.sol";
import "./SafeMath.sol";
import "./ICERC20.sol";
import "./IAdapter.sol";
import "./INutmeg.sol";
import "./Governable.sol";
import "./Math.sol";

contract CompoundAdapter is Governable, IAdapter {
    using SafeMath for uint;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    struct PosInfo {
        uint collAmt;
        uint sumIpcStart;
    }

    address public nutmeg;

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

    function initialize(address nutmegAddr, address governorAddr) external initializer {
        nutmeg = nutmegAddr;
        __Governable__init(governorAddr);
    }

//    constructor(address nutmegAddr, address governorAddr) {
//        nutmeg = nutmegAddr;
//        __Governable__init(governorAddr);
//    }

    modifier onlyNutmeg() {
        require(msg.sender == nutmeg, 'only nutmeg can call');
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

        uint posId = INutmeg(nutmeg).getCurrPositionId();
        INutmeg.Position memory pos = INutmeg(nutmeg).getPosition(posId);
        require(IERC20Upgradeable(baseToken).balanceOf(pos.owner) >= baseAmt, 'openPosition: insufficient balance');

        // borrow base tokens from nutmeg
        INutmeg(nutmeg).borrow(baseToken, collToken, baseAmt, borrowAmt);

        _increaseDebtAndCollateral(baseToken, posId);

        // mint collateral tokens from compound
        pos = INutmeg(nutmeg).getPosition(posId);
        uint mintAmt = _doMint(pos, borrowAmt);
        uint currSumIpc = _calcLatestSumIpc(collToken);
        totalMintAmt[collToken] = totalMintAmt[collToken].add(mintAmt);
        PosInfo storage posInfo = posInfoMap[posId];
        posInfo.sumIpcStart = currSumIpc;
        posInfo.collAmt = mintAmt;

        // set the collAmt to the position in nutmeg.
        INutmeg(nutmeg).setCollAmt(posId, mintAmt);
        emit openPositionEvent(posId, INutmeg(nutmeg).getCurrSender(), baseAmt, borrowAmt);
    }

    /// @notice Close a position by the borrower
    function closePosition() external onlyNutmeg override returns (uint) {
        uint posId = INutmeg(nutmeg).getCurrPositionId();
        INutmeg.Position memory pos = INutmeg(nutmeg).getPosition(posId);
        require(pos.owner == INutmeg(nutmeg).getCurrSender(), 'closePosition: original caller is not the owner');

        uint collAmt = _getCollTokenAmount(pos);
        uint redeemAmt = _doRedeem(pos, collAmt);

        // allow nutmeg to receive redeemAmt from the adapter
        IERC20Upgradeable(pos.baseToken).safeApprove(nutmeg, 0);
        IERC20Upgradeable(pos.baseToken).safeApprove(nutmeg, redeemAmt);

        // repay to nutmeg
        _decreaseDebtAndCollateral(pos.baseToken, pos.id, redeemAmt);
        INutmeg(nutmeg).repay(pos.baseToken, redeemAmt);
        pos = INutmeg(nutmeg).getPosition(posId);
        totalLoss[pos.baseToken] =
            totalLoss[pos.baseToken].add(pos.repayDeficit);
        totalMintAmt[pos.collToken] = totalMintAmt[pos.collToken].sub(pos.collAmt);
        emit closePositionEvent(posId, INutmeg(nutmeg).getCurrSender(), redeemAmt);
        return redeemAmt;
    }

    /// @notice Liquidate a position
    function liquidate() external override onlyNutmeg  {
        uint posId = INutmeg(nutmeg).getCurrPositionId();
        INutmeg.Position memory pos = INutmeg(nutmeg).getPosition(posId);
        require(_okToLiquidate(pos), 'liquidate: position is not ready for liquidation yet.');

        uint amount = _getCollTokenAmount(pos);
        uint redeemAmt = _doRedeem(pos, amount);
        IERC20Upgradeable(pos.baseToken).safeApprove(nutmeg, 0);
        IERC20Upgradeable(pos.baseToken).safeApprove(nutmeg, redeemAmt);

        // liquidate the position in nutmeg.
        _decreaseDebtAndCollateral(pos.baseToken, posId, redeemAmt);
        INutmeg(nutmeg).liquidate(pos.baseToken, redeemAmt);
        pos = INutmeg(nutmeg).getPosition(posId);
        totalLoss[pos.baseToken] = totalLoss[pos.baseToken].add(pos.repayDeficit);
        totalMintAmt[pos.collToken] = totalMintAmt[pos.collToken].sub(pos.collAmt);
        emit liquidateEvent(posId, INutmeg(nutmeg).getCurrSender());
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

        INutmeg(nutmeg).distributeCreditLosses(baseToken, collateralLoss, poolLoss);

        emit creditEvent(baseToken, collateralLoss, poolLoss);
        totalLoss[baseToken] = 0;
        totalLoan[baseToken] = totalLoan[baseToken].sub(poolLoss);
        totalCollateral[baseToken] = totalCollateral[baseToken].sub(collateralLoss);
    }

    function _increaseDebtAndCollateral(address token, uint posId) internal {
        INutmeg.Position memory pos = INutmeg(nutmeg).getPosition(posId);
        totalLoan[token] = totalLoan[token].add(pos.loanAmt);
        totalCollateral[token] = totalCollateral[token].add(pos.baseAmt);
    }

    /// @dev decreaseDebtAndCollateral
    function _decreaseDebtAndCollateral(address token, uint posId, uint redeemAmt) internal {
        INutmeg.Position memory pos = INutmeg(nutmeg).getPosition(posId);
        uint totalLoans = pos.loanAmt;
        if (redeemAmt >= totalLoans) {
            totalLoan[token] = totalLoan[token].sub(totalLoans);
        } else {
            totalLoan[token] = totalLoan[token].sub(redeemAmt);
        }
        totalCollateral[token] = totalCollateral[token].sub(pos.baseAmt);
    }

    /// @dev Do the mint from the 3rd party pool.this
    function _doMint(INutmeg.Position memory pos, uint amount) internal returns(uint) {
        uint balBefore = ICERC20(pos.collToken).balanceOf(address(this));
        IERC20Upgradeable(pos.baseToken).safeApprove(pos.collToken, 0);
        IERC20Upgradeable(pos.baseToken).safeApprove(pos.collToken, amount);
        uint result = ICERC20(pos.collToken).mint(amount);
        require(result == 0, '_doMint mint error');
        uint balAfter = ICERC20(pos.collToken).balanceOf(address(this));
        uint mintAmount = balAfter.sub(balBefore);
        require(mintAmount > 0, 'opnPos: zero mnt');
        return mintAmount;
    }

    /// @dev Do the redeem from the 3rd party pool.
    function _doRedeem(INutmeg.Position memory pos, uint amount) internal returns(uint) {
        uint balBefore = IERC20Upgradeable(pos.baseToken).balanceOf(address(this));
        uint result = ICERC20(pos.collToken).redeem(amount);
        require(result == 0, 'rdm fail');
        uint balAfter = IERC20Upgradeable(pos.baseToken).balanceOf(address(this));
        uint redeemAmt = balAfter.sub(balBefore);
        return redeemAmt;
    }

    /// @dev Get the amount of cTokens a position holds
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
        sumIpcMap[collToken] = sumIpcMap[collToken].add(currIpc);
        return sumIpcMap[collToken];
    }

    /// @dev Check if the position is eligible to be liquidated.
    function _okToLiquidate(INutmeg.Position memory pos) internal view returns(bool) {
        uint interest = INutmeg(nutmeg).getPositionInterest(pos.baseToken, pos.id);
        return (interest.mul(2) >= pos.baseAmt);
    }

    function version() public virtual pure returns (string memory) {
        return "1.0.3";
    }
}
