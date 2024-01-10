// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Ownable.sol";
import "./IERC20Metadata.sol";

import "./SafeMath.sol";
import "./IAccountCenter.sol";

contract EventCenter is Ownable {
    address internal constant ethAddr =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    mapping(address => uint256) public weight; // token wieght

    mapping(uint256 => uint256) public rewardAmount; // token wieght

    uint256 public epochStart;
    uint256 public epochEnd;
    uint256 public epochInterval = 1 minutes; //for test only
    uint256 public epochRound;

    address rewardCenter;
    address internal accountCenter;

    event CreateAccount(address EOA, address account);

    event UseFlashLoanForLeverage(
        address indexed EOA,
        address indexed account,
        address token,
        uint256 amount,
        uint256 epochRound,
        bool inEpoch
    );

    event AddFlashLoanScore(
        address indexed EOA,
        address indexed account,
        address token,
        uint256 amount,
        uint256 epochRound
    );

    event OpenLongLeverage(
        address EOA,
        address indexed account,
        address indexed leverageToken,
        address indexed targetToken,
        uint256 pay,
        uint256 amountTargetToken,
        uint256 amountLeverageToken,
        uint256 amountFlashLoan,
        uint256 unitAmt,
        uint256 rateMode,
        uint256 epochRound
    );

    event OpenShortLeverage(
        address EOA,
        address indexed account,
        address indexed leverageToken,
        address indexed targetToken,
        uint256 pay,
        uint256 amountTargetToken,
        uint256 amountLeverageToken,
        uint256 amountFlashLoan,
        uint256 unitAmt,
        uint256 rateMode,
        uint256 epochRound
    );

    event CloseLongLeverage(
        address EOA,
        address indexed account,
        address indexed leverageToken,
        address indexed targetToken,
        uint256 gain,
        uint256 amountTargetToken,
        uint256 amountFlashLoan,
        uint256 amountRepay,
        uint256 unitAmt,
        uint256 rateMode,
        uint256 epochRound
    );

    event CloseShortLeverage(
        address EOA,
        address indexed account,
        address indexed leverageToken,
        address indexed targetToken,
        uint256 gain,
        uint256 amountTargetToken,
        uint256 amountFlashLoan,
        uint256 amountWithDraw,
        uint256 unitAmt,
        uint256 rateMode,
        uint256 epochRound
    );

    event AddMargin(
        address EOA,
        address indexed account,
        address indexed leverageToken,
        uint256 amountLeverageToken,
        uint256 epochRound
    );

    event WithDraw(
        address EOA,
        address indexed account,
        address indexed token,
        uint256 amount,
        uint256 epochRound
    );

    event Repay(
        address EOA,
        address indexed account,
        address indexed token,
        uint256 amount,
        uint256 epochRound
    );

    event RemoveMargin(
        address EOA,
        address indexed account,
        address indexed leverageToken,
        uint256 amountLeverageToken,
        uint256 epochRound
    );

    event AddPositionScore(
        address indexed account,
        address indexed token,
        uint256 indexed reasonCode,
        address EOA,
        uint256 amount,
        uint256 tokenWeight,
        uint256 positionScore,
        uint256 epochRound
    );

    event SubPositionScore(
        address indexed account,
        address indexed token,
        uint256 indexed reasonCode,
        address EOA,
        uint256 amount,
        uint256 tokenWeight,
        uint256 positionScore,
        uint256 epochRound
    );

    event ReleasePositionReward(
        address indexed owner,
        uint256 epochRound,
        bytes32 merkelRoot
    );

    event ClaimPositionReward(
        address indexed EOA,
        uint256 epochRound,
        uint256 amount
    );

    event ClaimOpenAccountReward(
        address indexed EOA,
        address indexed account,
        uint256 amount
    );

    event StartEpoch(
        address indexed owner,
        uint256 epochRound,
        uint256 start,
        uint256 end,
        uint256 rewardAmount
    );

    event ResetScore(address indexed owner, uint256 epochRound);

    event SetAssetWeight(address indexed token, uint256 indexed weight);

    event SetEpochInterval(uint256 epochInterval);

    event ToggleEpochAutoStart(address indexed owner, bool indexed autoEpoch);

    event SetRewardCenter(address indexed owner, address indexed rewardCenter);

    modifier onlyAccountDSA() {
        require(
            accountCenter != address(0),
            "CHFRY: accountCenter not setup 1"
        );
        require(
            AccountCenterInterface(accountCenter).isSmartAccountofTypeN(
                msg.sender,
                1
            ) ||
                AccountCenterInterface(accountCenter).isSmartAccountofTypeN(
                    msg.sender,
                    2
                ),
            "CHFRY: only SmartAccount could emit Event in EventCenter"
        );
        _;
    }
    modifier onlyRewardCenter() {
        require(msg.sender == rewardCenter, "CHFRY: accountCenter not setup 1");
        _;
    }

    modifier notInEpoch() {
        require(epochEnd < block.timestamp, "CHFRY: In Epoch");
        _;
    }

    constructor(address _accountCenter) {
        accountCenter = _accountCenter;
    }

    function setRewardCenter(address _rewardCenter) public onlyOwner {
        require(
            _rewardCenter != address(0),
            "CHFRY: EventCenter address should not be 0"
        );
        rewardCenter = _rewardCenter;
        emit SetRewardCenter(msg.sender, rewardCenter);
    }

    function setEpochInterval(uint256 _epochInterval)
        external
        onlyOwner
        notInEpoch
    {
        epochInterval = _epochInterval;
        emit SetEpochInterval(_epochInterval);
    }

    function startEpoch(uint256 _rewardAmount) external notInEpoch {
        require(
            msg.sender == rewardCenter,
            "CHFRY: only Reward Center could start new Epoch"
        );
        epochRound = epochRound + 1;
        epochStart = block.timestamp;
        epochEnd = epochStart + epochInterval;
        rewardAmount[epochRound] = _rewardAmount;
        emit StartEpoch(
            msg.sender,
            epochRound,
            epochStart,
            epochEnd,
            _rewardAmount
        );
    }

    function setWeight(address _token, uint256 _weight)
        external
        onlyOwner
        notInEpoch
    {
        require(_token != address(0), "CHFRY: address shoud not be 0");
        weight[_token] = _weight;
        emit SetAssetWeight(_token, _weight);
    }

    function getWeight(address _token) external view returns (uint256) {
        return weight[_token];
    }

    function emitUseFlashLoanForLeverageEvent(address token, uint256 amount)
        external
        onlyAccountDSA
    {
        address EOA = AccountCenterInterface(accountCenter).getEOA(msg.sender);
        address account = msg.sender;
        bool inRewardEpoch = __isInRewardEpoch();
        uint256 tokenWeight = weight[token];
        bool notOverflow;
        uint256 score;
        emit UseFlashLoanForLeverage(
            EOA,
            account,
            token,
            amount,
            epochRound,
            inRewardEpoch
        );
        if (inRewardEpoch == true) {

            (notOverflow, score) = SafeMath.tryMul(score, tokenWeight);

            require(notOverflow == true, "CHFRY: You are so rich!");

            uint256 decimal;

            if (token == ethAddr) {
                decimal = 18;
            } else {
                decimal = IERC20Metadata(token).decimals();
            }
            (notOverflow, score) = SafeMath.tryDiv(score, 10**(decimal));
            
            require(notOverflow == true, "CHFRY: You are so rich!");

            emit AddFlashLoanScore(EOA, account, token, score, epochRound);
        }
    }

    function emitOpenLongLeverageEvent(
        address leverageToken,
        address targetToken,
        uint256 pay,
        uint256 amountTargetToken,
        uint256 amountLeverageToken,
        uint256 amountFlashLoan,
        uint256 unitAmt,
        uint256 rateMode
    ) external onlyAccountDSA {
        address EOA;
        address account;
        EOA = AccountCenterInterface(accountCenter).getEOA(msg.sender);
        account = msg.sender;
        addScore(EOA, account, targetToken, amountTargetToken, 1);
        emit OpenLongLeverage(
            EOA,
            account,
            leverageToken,
            targetToken,
            pay,
            amountTargetToken,
            amountLeverageToken,
            amountFlashLoan,
            unitAmt,
            rateMode,
            epochRound
        );
    }

    function emitCloseLongLeverageEvent(
        address leverageToken,
        address targetToken,
        uint256 gain,
        uint256 amountTargetToken,
        uint256 amountFlashLoan,
        uint256 amountRepay,
        uint256 unitAmt,
        uint256 rateMode
    ) external onlyAccountDSA {
        address EOA;
        address account;
        EOA = AccountCenterInterface(accountCenter).getEOA(msg.sender);
        account = msg.sender;
        subScore(EOA, account, targetToken, amountTargetToken, 1);
        emit CloseLongLeverage(
            EOA,
            account,
            leverageToken,
            targetToken,
            gain,
            amountTargetToken,
            amountFlashLoan,
            amountRepay,
            unitAmt,
            rateMode,
            epochRound
        );
    }

    function emitOpenShortLeverageEvent(
        address leverageToken,
        address targetToken,
        uint256 pay,
        uint256 amountTargetToken,
        uint256 amountLeverageToken,
        uint256 amountFlashLoan,
        uint256 unitAmt,
        uint256 rateMode
    ) external onlyAccountDSA {
        address EOA;
        address account;
        EOA = AccountCenterInterface(accountCenter).getEOA(msg.sender);
        account = msg.sender;
        addScore(EOA, account, targetToken, amountTargetToken, 2);
        emit OpenShortLeverage(
            EOA,
            account,
            leverageToken,
            targetToken,
            pay,
            amountTargetToken,
            amountLeverageToken,
            amountFlashLoan,
            unitAmt,
            rateMode,
            epochRound
        );
    }

    function emitCloseShortLeverageEvent(
        address leverageToken,
        address targetToken,
        uint256 gain,
        uint256 amountTargetToken,
        uint256 amountFlashLoan,
        uint256 amountWithDraw,
        uint256 unitAmt,
        uint256 rateMode
    ) external onlyAccountDSA {
        address EOA = AccountCenterInterface(accountCenter).getEOA(msg.sender);
        address account = msg.sender;
        subScore(EOA, account, targetToken, amountTargetToken, 4);
        emit CloseShortLeverage(
            EOA,
            account,
            leverageToken,
            targetToken,
            gain,
            amountTargetToken,
            amountFlashLoan,
            amountWithDraw,
            unitAmt,
            rateMode,
            epochRound
        );
    }

    function emitAddMarginEvent(
        address leverageToken,
        uint256 amountLeverageToken
    ) external onlyAccountDSA {
        address EOA = AccountCenterInterface(accountCenter).getEOA(msg.sender);
        address account = msg.sender;
        emit AddMargin(
            EOA,
            account,
            leverageToken,
            amountLeverageToken,
            epochRound
        );
    }

    function emitWithDrawEvent(address token, uint256 amount)
        external
        onlyAccountDSA
    {
        address EOA = AccountCenterInterface(accountCenter).getEOA(msg.sender);
        address account = msg.sender;
        emit WithDraw(EOA, account, token, amount, epochRound);
    }

    function emitRepayEvent(address token, uint256 amount)
        external
        onlyAccountDSA
    {
        address EOA = AccountCenterInterface(accountCenter).getEOA(msg.sender);
        address account = msg.sender;
        emit Repay(EOA, account, token, amount, epochRound);
    }

    function emitRemoveMarginEvent(
        address leverageToken,
        uint256 amountLeverageToken
    ) external onlyAccountDSA {
        address EOA = AccountCenterInterface(accountCenter).getEOA(msg.sender);
        address account = msg.sender;
        emit RemoveMargin(
            EOA,
            account,
            leverageToken,
            amountLeverageToken,
            epochRound
        );
    }

    function emitReleasePositionRewardEvent(
        address owner,
        uint256 _epochRound,
        bytes32 merkelRoot
    ) external onlyRewardCenter {
        emit ReleasePositionReward(owner, _epochRound, merkelRoot);
    }

    function emitClaimPositionRewardEvent(
        address EOA,
        uint256 _epochRound,
        uint256 amount
    ) external onlyRewardCenter {
        emit ClaimPositionReward(EOA, _epochRound, amount);
    }

    function emitClaimOpenAccountRewardEvent(
        address EOA,
        address account,
        uint256 amount
    ) external onlyRewardCenter {
        emit ClaimOpenAccountReward(EOA, account, amount);
    }

    function addScore(
        address EOA,
        address account,
        address token,
        uint256 amount,
        uint256 reasonCode
    ) internal {
        uint256 timeToEpochEnd;
        uint256 tokenWeight;
        uint256 positionScore;
        bool notOverflow;

        tokenWeight = weight[token];
        (notOverflow, timeToEpochEnd) = SafeMath.trySub(
            epochEnd,
            block.timestamp
        );
        if (notOverflow == false) {
            timeToEpochEnd = 0;
        }
        (notOverflow, positionScore) = SafeMath.tryMul(timeToEpochEnd, amount);
        require(notOverflow == true, "CHFRY: You are so rich!");
        (notOverflow, positionScore) = SafeMath.tryMul(
            positionScore,
            tokenWeight
        );
        require(notOverflow == true, "CHFRY: You are so rich!");

        uint256 decimal;

        if (token == ethAddr) {
            decimal = 18;
        } else {
            decimal = IERC20Metadata(token).decimals();
        }
        (notOverflow, positionScore) = SafeMath.tryDiv(
            positionScore,
            10**(decimal)
        );

        require(notOverflow == true, "CHFRY: overflow");

        emit AddPositionScore(
            account,
            token,
            reasonCode,
            EOA,
            amount,
            tokenWeight,
            positionScore,
            epochRound
        );
    }

    function subScore(
        address EOA,
        address account,
        address token,
        uint256 amount,
        uint256 reasonCode
    ) internal {
        uint256 timeToEpochEnd;
        uint256 tokenWeight;
        uint256 positionScore;
        bool notOverflow;
        tokenWeight = weight[token];
        (notOverflow, timeToEpochEnd) = SafeMath.trySub(
            epochEnd,
            block.timestamp
        );
        if (notOverflow == false) {
            timeToEpochEnd = 0;
        }
        (notOverflow, positionScore) = SafeMath.tryMul(timeToEpochEnd, amount);

        require(notOverflow == true, "CHFRY: You are so rich!");

        (notOverflow, positionScore) = SafeMath.tryMul(
            positionScore,
            tokenWeight
        );
        require(notOverflow == true, "CHFRY: You are so rich!");

        uint256 decimal;

        if (token == ethAddr) {
            decimal = 18;
        } else {
            decimal = IERC20Metadata(token).decimals();
        }
        (notOverflow, positionScore) = SafeMath.tryDiv(
            positionScore,
            10**(decimal)
        );
        require(notOverflow == true, "CHFRY: overflow");

        emit SubPositionScore(
            account,
            token,
            reasonCode,
            EOA,
            amount,
            tokenWeight,
            positionScore,
            epochRound
        );
    }

    function secToEpochEnd() external view returns (uint256 _secToEpochEnd) {
        if (epochEnd < block.timestamp) {
            _secToEpochEnd = 0;
        } else {
            _secToEpochEnd = epochEnd - block.timestamp;
        }
    }

    function isInRewardEpoch() external view returns (bool _isInRewardEpoch) {
        _isInRewardEpoch = __isInRewardEpoch();
    }

    function __isInRewardEpoch() internal view returns (bool _isInRewardEpoch) {
        if (epochEnd < block.timestamp) {
            _isInRewardEpoch = false;
        } else {
            _isInRewardEpoch = true;
        }
    }

    function convertToWei(uint256 _dec, uint256 _amt)
        internal
        pure
        returns (uint256 amt)
    {
        bool notOverflow;
        (notOverflow, amt) = SafeMath.tryDiv(_amt, 10**(_dec));
        require(notOverflow == true, "CHFRY: convertToWei overflow");
    }
}
