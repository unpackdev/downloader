// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./IPool.sol";
import "./FlashLoanSimpleReceiverBase.sol";

import "./Interfaces.sol";

contract DoughV1Flashloan is FlashLoanSimpleReceiverBase {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    event Log(string message, uint256 val);

    address public doughV1Index = address(0);

    constructor(IPoolAddressesProvider provider, address _doughV1Index) FlashLoanSimpleReceiverBase(provider) {
        doughV1Index = _doughV1Index;
    }

    bytes32 internal dataHash = bytes32(0);
    // if 1 then can enter flashlaon, if 2 then callback
    uint256 internal status = 1;

    modifier verifyDataHash(bytes memory data_) {
        bytes32 dataHash_ = keccak256(data_);
        require(dataHash_ == dataHash && dataHash_ != bytes32(0), "invalid-data-hash");
        require(status == 2, "already-entered3");
        dataHash = bytes32(0);
        _;
        status = 1;
    }
    modifier reentrancy() {
        require(status == 1, "already-entered1");
        status = 2;
        _;
        require(status == 1, "already-entered2");
    }

    //  tokenAmount = _tokenAmount[user][tokenAddress]
    mapping(address => mapping(address => uint256)) private _tokenAmount;

    function flashloanReq(address loanToken, uint256 loanAmount, uint256 feeAmount, uint256 funcId) external reentrancy {
        //  Loop: funcId = 0 , DeLoop: funcId = 1;
        require(funcId == 0 || funcId == 1, "invalid-id");
        IERC20(loanToken).transferFrom(msg.sender, address(this), feeAmount);
        _tokenAmount[msg.sender][loanToken] = feeAmount;
        bytes memory data = abi.encode(msg.sender, loanToken, loanAmount, funcId);
        dataHash = bytes32(keccak256(data));
        IPool(address(POOL)).flashLoanSimple(address(this), loanToken, loanAmount, data, 0);
    }

    function executeOperation(address asset, uint256 amount, uint256 premium, address initiator, bytes memory data) public verifyDataHash(data) returns (bool) {
        require(initiator == address(this), "not-same-sender");
        require(msg.sender == address(POOL), "not-aave-sender");

        (address sender, , , uint256 funcId) = abi.decode(data, (address, address, uint256, uint256));
        //  Loop: funcId = 0 , DeLoop: funcId = 1;
        require(funcId == 0 || funcId == 1, "invalid-id");
        require(premium <= _tokenAmount[sender][asset], "Not enough amount to return loan");

        // pay back the loan amount and the premium (flashloan fee)
        uint256 amountToReturn = amount.add(premium);

        //------- Custom Logic Start ---------
        IERC20(asset).approve(sender, amount);
        IDoughV1Dsa(sender).executeAction(asset, amount, funcId);
        IERC20(asset).transferFrom(sender, address(this), amount);
        //------- Custom Logic End   ---------

        IERC20(asset).approve(address(POOL), amountToReturn);

        uint256 doughFee = _tokenAmount[sender][asset] - premium;
        IERC20(asset).transfer(IDoughV1Index(doughV1Index).TREASURY(), doughFee);
        _tokenAmount[sender][asset] = 0;

        emit Log("borrowed amount", amount);
        emit Log("flashloan fee", premium);
        emit Log("dough fee", doughFee);
        emit Log("amountToReturn", amountToReturn);
        return true;
    }
}
