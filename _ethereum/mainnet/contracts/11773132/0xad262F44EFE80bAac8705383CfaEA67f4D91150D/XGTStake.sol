pragma solidity ^0.5.16;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./EIP712MetaTransaction.sol";
import "./EIP712Base.sol";
import "./ICToken.sol";
import "./IComptroller.sol";
import "./IBridgeContract.sol";
import "./IXGTGenerator.sol";
import "./IPERC20.sol";
import "./IChainlinkOracle.sol";

contract XGTStake is Initializable, Ownable, EIP712MetaTransaction {
    using SafeMath for uint256;

    IPERC20 public stakeToken;
    ICToken public cToken;
    IComptroller public comptroller;
    IPERC20 public comp;
    IBridgeContract public bridge;
    IChainlinkOracle public ethDaiOracle;
    IChainlinkOracle public gasOracle;

    address public xgtGeneratorContract;
    address public xgtFund;

    bool public paused;
    uint256 public averageGasPerDeposit;
    uint256 public averageGasPerWithdraw;
    address public refundAddress;

    uint256 public interestCut; // Interest Cut in Basis Points (250 = 2.5%)
    address public interestCutReceiver;

    mapping(address => uint256) public userDepositsDai;
    mapping(address => uint256) public userDepositsCDai;
    uint256 public totalDeposits;

    function initializeStake(
        address _stakeToken,
        address _cToken,
        address _comptroller,
        address _comp,
        address _bridge,
        address _interestAddress,
        address _refundAddress
    ) public {
        require(
            interestCutReceiver == address(0),
            "XGTSTAKE-ALREADY-INITIALIZED"
        );
        initMeta("XGTStake", "1");
        averageGasPerDeposit = 500000;
        averageGasPerWithdraw = 500000;
        interestCut = 250;
        _transferOwnership(msg.sender);
        stakeToken = IPERC20(_stakeToken);
        cToken = ICToken(_cToken);
        comptroller = IComptroller(_comptroller);
        comp = IPERC20(_comp);
        bridge = IBridgeContract(_bridge);
        ethDaiOracle = IChainlinkOracle(
            0x64EaC61A2DFda2c3Fa04eED49AA33D021AeC8838
        );
        gasOracle = IChainlinkOracle(
            0x169E633A2D1E6c10dD91238Ba11c4A708dfEF37C
        );
        interestCutReceiver = _interestAddress;
        refundAddress = _refundAddress;
    }

    function setXGTGeneratorContract(address _address) external {
        require(
            xgtGeneratorContract == address(0),
            "XGTSTAKE-GEN-ADDR-ALREADY-SET"
        );
        xgtGeneratorContract = _address;
    }

    function pauseContracts(bool _pause) external onlyOwner {
        paused = _pause;
    }

    function changeRefundAddress(address _address) external onlyOwner {
        refundAddress = _address;
    }

    function changeInterestAddress(address _address) external onlyOwner {
        interestCutReceiver = _address;
    }

    function changeGasOracle(address _address) external onlyOwner {
        gasOracle = IChainlinkOracle(_address);
    }

    function changePriceOracle(address _address) external onlyOwner {
        ethDaiOracle = IChainlinkOracle(_address);
    }

    function changeBridge(address _address) external onlyOwner {
        bridge = IBridgeContract(_address);
    }

    function changeInterestCut(uint256 _newValue) external onlyOwner {
        require(_newValue <= 9999, "XGTSTAKE-INVALID-CUT");
        interestCut = _newValue;
    }

    function changeGasCosts(uint256 _deposit, uint256 _withdraw)
        external
        onlyOwner
    {
        averageGasPerDeposit = _deposit;
        averageGasPerWithdraw = _withdraw;
    }

    function depositTokens(uint256 _amount) external notPaused {
        require(
            stakeToken.transferFrom(msgSender(), address(this), _amount),
            "XGTSTAKE-DAI-TRANSFER-FAILED"
        );

        uint256 amountLeft = _amount;

        // If it is a metatx, refund the executor in DAI
        if (msgSender() != msg.sender) {
            uint256 refundAmount = currentRefundCostDeposit();
            require(refundAmount < _amount, "XGTSTAKE-DEPOSIT-TOO-SMALL");
            amountLeft = _amount.sub(refundAmount);
            require(
                stakeToken.transfer(refundAddress, refundAmount),
                "XGTSTAKE-DAI-REFUND-FAILED"
            );
        }

        require(
            stakeToken.approve(address(cToken), _amount),
            "XGTSTAKE-DAI-APPROVE-FAILED"
        );

        uint256 balanceBefore = cToken.balanceOf(address(this));
        require(
            cToken.mint(amountLeft) == 0,
            "XGTSTAKE-COMPOUND-DEPOSIT-FAILED"
        );
        uint256 cDai = cToken.balanceOf(address(this)).sub(balanceBefore);

        userDepositsDai[msgSender()] = userDepositsDai[msgSender()].add(
            amountLeft
        );
        userDepositsCDai[msgSender()] = userDepositsCDai[msgSender()].add(cDai);
        totalDeposits = totalDeposits.add(amountLeft);

        bytes4 _methodSelector =
            IXGTGenerator(address(0)).tokensStaked.selector;
        bytes memory data =
            abi.encodeWithSelector(_methodSelector, amountLeft, msgSender());
        bridge.requireToPassMessage(xgtGeneratorContract, data, 750000);
    }

    function withdrawTokens(uint256 _amount) external {
        uint256 userDepositDai = userDepositsDai[msgSender()];
        uint256 userDepositCDai = userDepositsCDai[msgSender()];
        require(userDepositDai > 0, "XGTSTAKE-NO-DEPOSIT");

        // If user puts in MAX_UINT256, skip this calcualtion
        // and set it to the maximum possible
        uint256 cDaiToRedeem = uint256(2**256 - 1);
        uint256 amount = _amount;
        if (amount != cDaiToRedeem) {
            cDaiToRedeem = userDepositCDai.mul(amount).div(userDepositDai);
        }

        // If the calculation for some reason came up with too much
        // or if the user set to withdraw everything: set max
        if (cDaiToRedeem > userDepositCDai) {
            cDaiToRedeem = userDepositCDai;
            amount = userDepositDai;
        }

        totalDeposits = totalDeposits.sub(amount);
        userDepositsDai[msgSender()] = userDepositDai.sub(amount);
        userDepositsCDai[msgSender()] = userDepositCDai.sub(cDaiToRedeem);

        uint256 before = stakeToken.balanceOf(address(this));
        require(
            cToken.redeem(cDaiToRedeem) == 0,
            "XGTSTAKE-COMPOUND-WITHDRAW-FAILED"
        );
        uint256 diff = (stakeToken.balanceOf(address(this))).sub(before);
        require(diff >= amount, "XGTSTAKE-COMPOUND-AMOUNT-MISMATCH");

        // Deduct the interest cut
        uint256 interest = diff.sub(amount);
        uint256 cut = 0;
        if (interest != 0) {
            cut = (interest.mul(interestCut)).div(10000);
            require(
                stakeToken.transfer(interestCutReceiver, cut),
                "XGTSTAKE-INTEREST-CUT-TRANSFER-FAILED"
            );
        }

        uint256 amountLeft = diff.sub(cut);
        // If it is a metatx, refund the executor in DAI
        if (msgSender() != msg.sender) {
            uint256 refundAmount = currentRefundCostWithdraw();
            require(refundAmount < _amount, "XGTSTAKE-WITHDRAW-TOO-SMALL");
            amountLeft = amountLeft.sub(refundAmount);
            require(
                stakeToken.transfer(refundAddress, refundAmount),
                "XGTSTAKE-DAI-REFUND-FAILED"
            );
        }

        // Transfer the rest to the user
        require(
            stakeToken.transfer(msgSender(), amountLeft),
            "XGTSTAKE-USER-TRANSFER-FAILED"
        );

        bytes4 _methodSelector =
            IXGTGenerator(address(0)).tokensUnstaked.selector;
        bytes memory data =
            abi.encodeWithSelector(_methodSelector, _amount, msgSender());
        bridge.requireToPassMessage(xgtGeneratorContract, data, 750000);
    }

    function correctBalance(address _user) external {
        bytes4 _methodSelector =
            IXGTGenerator(address(0)).manualCorrectDeposit.selector;
        bytes memory data =
            abi.encodeWithSelector(
                _methodSelector,
                userDepositsDai[_user],
                _user
            );
        bridge.requireToPassMessage(xgtGeneratorContract, data, 750000);
    }

    function claimComp() external {
        comptroller.claimComp(address(this));
        uint256 balance = comp.balanceOf(address(this));
        if (balance > 0) {
            require(
                comp.transferFrom(address(this), interestCutReceiver, balance),
                "XGTSTAKE-TRANSFER-FAILED"
            );
        }
    }

    function currentRefundCostDeposit() public returns (uint256) {
        return _getTXCost(averageGasPerDeposit);
    }

    function currentRefundCostWithdraw() public returns (uint256) {
        return _getTXCost(averageGasPerWithdraw);
    }

    function _getTXCost(uint256 _gasAmount) internal returns (uint256) {
        uint256 oracleAnswerPrice = uint256(ethDaiOracle.latestAnswer());
        uint256 oracleAnswerGas = uint256(gasOracle.latestAnswer());
        if (oracleAnswerPrice > 0 && oracleAnswerGas > 0) {
            uint256 refund =
                (
                    uint256(oracleAnswerGas)
                        .mul(_gasAmount)
                        .mul(uint256(1000000))
                        .div(oracleAnswerPrice)
                );
            return refund;
        }
        return 0;
    }

    modifier notPaused() {
        require(!paused, "XGTSTAKE-Paused");
        _;
    }
}
