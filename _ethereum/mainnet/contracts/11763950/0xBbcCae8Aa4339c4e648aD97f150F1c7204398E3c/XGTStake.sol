pragma solidity ^0.5.16;

import "./SafeMath.sol";
import "./Initializable.sol";
import "./Ownable.sol";
import "./EIP712MetaTransaction.sol";
import "./EIP712Base.sol";
import "./ICToken.sol";
import "./IComptroller.sol";
import "./IBridgeContract.sol";
import "./IXGTGenerator.sol";
import "./IPERC20.sol";

// import "./IChainlinkOracle.sol";

contract XGTStake is
    Initializable,
    OpenZeppelinUpgradesOwnable,
    EIP712MetaTransaction("XGTStake", "1")
{
    using SafeMath for uint256;

    IPERC20 public stakeToken;
    ICToken public cToken;
    IComptroller public comptroller;
    IPERC20 public comp;
    IBridgeContract public bridge;
    // IChainlinkOracle public gasOracle;
    // IChainlinkOracle public ethDaiOracle;

    address public xgtGeneratorContract;
    address public xgtFund;

    bool public paused = false;
    // uint256 public averageGasPerDeposit = 150000;
    // uint256 public averageGasPerWithdraw = 150000;
    // mapping(address => bool) public metaTransactors;

    uint256 public interestCut = 250; // Interest Cut in Basis Points (250 = 2.5%)
    address public interestCutReceiver;

    mapping(address => uint256) public userDepositsDai;
    mapping(address => uint256) public userDepositsCDai;
    uint256 public totalDeposits;

    function initialize(
        address _stakeToken,
        address _cToken,
        address _comptroller,
        address _comp,
        address _bridge,
        address _xgtGeneratorContract
    ) public initializer {
        stakeToken = IPERC20(_stakeToken);
        cToken = ICToken(_cToken);
        comptroller = IComptroller(_comptroller);
        comp = IPERC20(_comp);
        bridge = IBridgeContract(_bridge);
        // gasOracle = IChainlinkOracle(
        // 0x169E633A2D1E6c10dD91238Ba11c4A708dfEF37C
        // );
        // ethDaiOracle = IChainlinkOracle(
        // 0x773616E4d11A78F511299002da57A0a94577F1f4
        // );
        xgtGeneratorContract = _xgtGeneratorContract;
        interestCutReceiver = 0x36985f8AA15C02964d8450c930354C70f382bBC3;
    }

    // function changeMetaTxAuth(address _user, bool _allowedToExecute)
    //     external
    //     onlyOwner
    // {
    //     metaTransactors[_user] = _allowedToExecute;
    // }

    function pauseContracts(bool _pause) external onlyOwner {
        paused = _pause;
    }

    function depositTokens(uint256 _amount) external notPaused {
        require(
            stakeToken.transferFrom(msgSender(), address(this), _amount),
            "XGTSTAKE-DAI-TRANSFER-FAILED"
        );
        require(
            stakeToken.approve(address(cToken), _amount),
            "XGTSTAKE-DAI-APPROVE-FAILED"
        );

        uint256 balanceBefore = cToken.balanceOf(address(this));
        require(cToken.mint(_amount) == 0, "XGTSTAKE-COMPOUND-DEPOSIT-FAILED");
        uint256 cDai = cToken.balanceOf(address(this)).sub(balanceBefore);

        userDepositsDai[msgSender()] = userDepositsDai[msgSender()].add(
            _amount
        );
        userDepositsCDai[msgSender()] = userDepositsCDai[msgSender()].add(cDai);
        totalDeposits = totalDeposits.add(_amount);

        bytes4 _methodSelector =
            IXGTGenerator(address(0)).tokensStaked.selector;
        bytes memory data =
            abi.encodeWithSelector(_methodSelector, _amount, msgSender());
        bridge.requireToPassMessage(xgtGeneratorContract, data, 300000);
    }

    function withdrawTokens(uint256 _amount) external notPaused {
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

        // Transfer the rest to the user
        require(
            stakeToken.transfer(msgSender(), diff.sub(cut)),
            "XGTSTAKE-USER-TRANSFER-FAILED"
        );

        bytes4 _methodSelector =
            IXGTGenerator(address(0)).tokensUnstaked.selector;
        bytes memory data =
            abi.encodeWithSelector(_methodSelector, _amount, msgSender());
        bridge.requireToPassMessage(xgtGeneratorContract, data, 300000);
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
        bridge.requireToPassMessage(xgtGeneratorContract, data, 300000);
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

    // function refundGas(
    //     uint256 _amount,
    //     address _user,
    //     uint256 _gasAmount
    // ) internal returns (uint256) {
    //     int256 latestGasPrice = gasOracle.latestAnswer();
    //     uint256 latestEthPrice =
    //         uint256(1 ether).div(uint256(ethDaiOracle.latestAnswer()));
    //     uint256 amount = _amount;
    //     if (latestGasPrice >= 0 && latestEthPrice >= 0) {
    //         uint256 refund =
    //             uint256(latestGasPrice).mul(_gasAmount).mul(latestEthPrice);
    //         require(refund < _amount, "XGTSTAKE-DEPOSIT-TOO-SMALL");
    //         amount = _amount.sub(refund);
    //         require(
    //             stakeToken.transferFrom(_user, msgSender(), refund),
    //             "XGTSTAKE-DAI-REFUND-TRANSFER-FAILED"
    //         );
    //     }
    //     return amount;
    // }

    modifier notPaused() {
        require(!paused, "XGTSTAKE-Paused");
        _;
    }
}
