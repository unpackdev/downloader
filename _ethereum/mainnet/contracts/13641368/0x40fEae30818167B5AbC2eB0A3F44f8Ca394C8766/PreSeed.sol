//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

import "./SafeERC20.sol";
import "./Ownable.sol";

contract PreSeed is Ownable {
    using SafeERC20 for IERC20;

    address public immutable egtAddress;
    address public immutable multiSigVaultAddress;
    uint256 public immutable egtPerKWei; // egt amount per 1000 wei
    uint256 public immutable maxWeiCollected;

    uint256 public immutable startDate; // pre-seed start date
    uint256 public immutable ethStartDate; // date at which eth or EGT is now accepted

    uint256 public constant DECIMALS = 10**18;
    uint256 public constant KWEI = 1000;

    uint256 public weiCollected;
    bool public isSeedActive = true;

    mapping(address => uint256) public weiCollectedByAddress;

    modifier isETHSeedOpen {
        require(
            block.timestamp >= ethStartDate && isSeedActive,
            "ETH_NOT_ACTIVE"
        );
        _;
    }

    modifier isEGTSeedOpen {
        require(block.timestamp >= startDate && isSeedActive, "EGT_NOT_ACTIVE");
        _;
    }

    modifier isNotFull {
        require(maxWeiCollected > weiCollected, "FULL");
        _;
    }

    event EthContributed(
        address indexed contributor,
        uint256 egtAmount,
        uint256 ethAmount
    );

    constructor(
        address _egtAddress,
        address _multiSigVaultAddress,
        uint256 _egtPerKWei,
        uint256 _maxWeiCollected,
        uint256 _startDate,
        uint256 _ethStartDate
    ) {
        require(_ethStartDate > _startDate, "INVALID_DATES");

        egtAddress = _egtAddress;
        multiSigVaultAddress = _multiSigVaultAddress;
        egtPerKWei = _egtPerKWei;
        maxWeiCollected = _maxWeiCollected;
        startDate = _startDate;
        ethStartDate = _ethStartDate;
    }

    function contributeETH() external payable isETHSeedOpen() isNotFull() {
        require(msg.value > 0, "AMOUNT_TOO_SMALL");

        weiCollected = weiCollected + msg.value;
        require(weiCollected <= maxWeiCollected, "INVALID_AMOUNT");
        weiCollectedByAddress[msg.sender] =
            weiCollectedByAddress[msg.sender] +
            msg.value;

        // send eth to vault
        (bool isSent, ) = multiSigVaultAddress.call{value: msg.value}("");
        require(isSent, "TRANSFER_FAILED");

        emit EthContributed(msg.sender, 0, msg.value);
    }

    function contributeEGT(uint256 _egtAmount)
        external
        isEGTSeedOpen()
        isNotFull()
    {
        require(_egtAmount > 0, "AMOUNT_TOO_SMALL");
        uint256 weiAmount = (_egtAmount * KWEI) / egtPerKWei;

        weiCollected = weiCollected + weiAmount;
        require(weiCollected <= maxWeiCollected, "INVALID_AMOUNT");
        weiCollectedByAddress[msg.sender] =
            weiCollectedByAddress[msg.sender] +
            weiAmount;

        // send EGT to vault
        IERC20(egtAddress).safeTransferFrom(
            msg.sender,
            multiSigVaultAddress,
            _egtAmount
        );
        emit EthContributed(msg.sender, _egtAmount, weiAmount);
    }

    function closeSeed() external onlyOwner {
        isSeedActive = false;
    }

    function flushEGT() external {
        uint256 egtBalance = IERC20(egtAddress).balanceOf(address(this));
        if (egtBalance > 0) {
            IERC20(egtAddress).safeTransfer(multiSigVaultAddress, egtBalance);
        }
    }
}
