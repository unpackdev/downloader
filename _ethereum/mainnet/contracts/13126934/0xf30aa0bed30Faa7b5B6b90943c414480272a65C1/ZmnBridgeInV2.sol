// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "./SafeMath.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";

import "./SafeMath16.sol";
import "./SafeBEP20.sol";
import "./ArrayUniqueUint256.sol";

contract ZmnBridgeInV2 is
    Initializable,
    UUPSUpgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    using SafeMath16 for uint16;
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    event BridgeIn(address indexed to, uint256 amount);
    event BridgeInFor(address indexed from, address indexed to, uint256 amount);
    event WithdrawToPeggedAddress(address indexed wallet, uint256 amount);

    // =========================================
    // =========================================
    // =========================================
    // V1

    // The ZMINE TOKEN!
    IBEP20 public zmn;

    // Min and max
    uint256 public minDepositZmnAmount;
    uint256 public maxDepositZmnAmount;

    uint256 public accBridgeIn;
    uint256 public accBridgeInFee;
    mapping(address => uint256) private _accBridgeInByUser;

    // Bridge fee in basis points (percentage of transfer amount)
    uint16 public feePercentBP;
    // Fixed bridge fee
    uint256 public feeUpfront;

    address public feeAddress;
    address public peggedAddress;

    // =========================================
    // =========================================
    // =========================================
    // Upgradeable

    function _authorizeUpgrade(address) internal override onlyOwner {}

    function initialize(
        IBEP20 _zmn,
        address _feeAddress,
        address _peggedAddress
    ) public initializer {
        __Ownable_init();
        zmn = _zmn;

        feePercentBP = 0;
        feeUpfront = 500 ether;
        feeAddress = _feeAddress;

        peggedAddress = _peggedAddress;
        minDepositZmnAmount = 10000 ether;
        maxDepositZmnAmount = 100000 ether;
    }

    // ======================
    // ======================

    function getAccBridgeInByUser(address _user)
        external
        view
        returns (uint256)
    {
        return _accBridgeInByUser[_user];
    }

    function _bridgeIn(address _to, uint256 _amount) internal {
        require(_amount >= minDepositZmnAmount, "Minimum amount");
        require(_amount <= maxDepositZmnAmount, "Maximum amount");
        uint256 _fee = 0;
        if (feeUpfront > 0) {
            if (feePercentBP > 0) {
                // upfront fee and percentage fee
                uint256 _amountAfterUpfrontFee = _amount.sub(feeUpfront);
                uint256 _feePecent = _amountAfterUpfrontFee
                    .mul(feePercentBP)
                    .div(10000);
                _fee = feeUpfront.add(_feePecent);
            } else {
                // only upfront fee
                _fee = feeUpfront;
            }
        } else {
            // only percentage fee
            if (feePercentBP > 0) {
                uint256 _feePecent = _amount.mul(feePercentBP).div(10000);
                _fee = _feePecent;
            }
        }
        uint256 _amountAfterFee = _amount.sub(_fee);

        // transfer token to contract
        zmn.safeTransferFrom(address(msg.sender), address(this), _amount);

        // transfer fee from contract to fee address
        zmn.safeTransfer(address(feeAddress), _fee);

        // add credit
        _accBridgeInByUser[_to] = _accBridgeInByUser[_to].add(_amountAfterFee);

        // accumulate amount
        accBridgeIn = accBridgeIn.add(_amountAfterFee);
        accBridgeInFee = accBridgeInFee.add(_fee);
    }

    function bridgeIn(uint256 _amount) public {
        _bridgeIn(msg.sender, _amount);
        emit BridgeIn(msg.sender, _amount);
    }

    function bridgeInFor(address _to, uint256 _amount) public nonReentrant {
        //Limit to self or delegated harvest to avoid unnecessary confusion
        require(address(msg.sender) != _to, "bridgeInFor: FORBIDDEN");
        _bridgeIn(_to, _amount);
        emit BridgeInFor(msg.sender, _to, _amount);
    }

    // ======================
    // ======================
    // only owner

    function setFeeUpfront(uint256 _feeUpfront) public onlyOwner {
        require(
            _feeUpfront < minDepositZmnAmount,
            "Fee more than minimum amount"
        );
        feeUpfront = _feeUpfront;
    }

    function setFeePercentBP(uint16 _feePercentBP) public onlyOwner {
        require(_feePercentBP <= 10000, "Invalid fee basis points");
        feePercentBP = _feePercentBP;
    }

    function setFeeAddress(address _feeAddress) public onlyOwner {
        feeAddress = _feeAddress;
    }

    function withdrawToPeggedAddress(uint256 _amount) public onlyOwner {
        // transfer token to pegged address
        zmn.safeTransfer(address(peggedAddress), _amount);
        emit WithdrawToPeggedAddress(address(peggedAddress), _amount);
    }

    function setPeggedAddress(address _peggedAddress) public onlyOwner {
        peggedAddress = _peggedAddress;
    }

    function setMinDepositZmnAmount(uint256 _minDepositZmnAmount)
        public
        onlyOwner
    {
        require(
            _minDepositZmnAmount <= maxDepositZmnAmount,
            "More than max value"
        );
        require(
            feeUpfront < _minDepositZmnAmount,
            "Fee more than minimum amount"
        );
        minDepositZmnAmount = _minDepositZmnAmount;
    }

    function setMaxDepositZmnAmount(uint256 _maxDepositZmnAmount)
        public
        onlyOwner
    {
        require(
            _maxDepositZmnAmount >= minDepositZmnAmount,
            "Less than min value"
        );
        maxDepositZmnAmount = _maxDepositZmnAmount;
    }

    // ======================
    // ======================
}
