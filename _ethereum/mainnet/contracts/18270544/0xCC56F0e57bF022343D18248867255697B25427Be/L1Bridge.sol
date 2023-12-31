// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./Ownable.sol";
import "./IERC20.sol";
import "./IERC20Permit.sol";

import "./IStandardBridge.sol";

contract L1Bridge is Ownable {
    /// @notice bips
    uint256 public FEE;

    uint32 public RECEIVE_DEFAULT_GAS_LIMIT = 200_000;

    event EtherDeposit(address from, address to, uint256 amount);
    event TokenDeposit(address from, address to, address l1Token, address l2Token, uint256 amount);

    constructor(uint256 _fee) Ownable() {
        FEE = _fee;
    }

    function initiateEtherDeposit(address payable _l1StandardBridge, address _to) public payable {
        uint256 _fee = msg.value * FEE / 10_000;
        uint256 _amount = msg.value - _fee;
        IStandardBridge(_l1StandardBridge).bridgeETHTo{value: _amount}(_to, RECEIVE_DEFAULT_GAS_LIMIT, bytes(""));

        emit EtherDeposit(msg.sender, _to, _amount);
    }

    function initiateERC20Deposit(
        address payable _l1StandardBridge,
        address _l1Token,
        address _l2Token,
        address _to,
        uint256 _amount
    ) public {
        _initiateERC20Deposit(_l1StandardBridge, _l1Token, _l2Token, _to, _amount);
    }

    function initiateERC20DepositWithPermit(
        address payable _l1StandardBridge,
        address _l1Token,
        address _l2Token,
        address _to,
        uint256 _amount,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external {
        IERC20Permit(_l1Token).permit(msg.sender, address(this), _amount, _deadline, _v, _r, _s);
        _initiateERC20Deposit(_l1StandardBridge, _l1Token, _l2Token, _to, _amount);
    }

    function _initiateERC20Deposit(
        address payable _l1StandardBridge,
        address _l1Token,
        address _l2Token,
        address _to,
        uint256 _amount
    ) internal {
        IERC20 erc20 = IERC20(_l1Token);
        require(erc20.transferFrom(msg.sender, address(this), _amount), "!transferFrom");

        uint256 _fee = _amount * FEE / 10_000;
        uint256 _amountSubFee = _amount - _fee;

        erc20.approve(_l1StandardBridge, _amountSubFee);
        IStandardBridge(_l1StandardBridge).depositERC20To(
            _l1Token, _l2Token, _to, _amountSubFee, RECEIVE_DEFAULT_GAS_LIMIT, bytes("")
        );
        erc20.approve(_l1StandardBridge, 0);

        emit TokenDeposit(msg.sender, _to, _l1Token, _l2Token, _amountSubFee);
    }

    function withdrawEtherFees() public onlyOwner {
        (bool sent, bytes memory data) = owner().call{value: payable(address(this)).balance}("");
        require(sent, "Failed to send Ether");
    }

    function withdrawERC20Fees(address _token) public onlyOwner {
        IERC20 erc20 = IERC20(_token);
        bool sent = erc20.transfer(owner(), erc20.balanceOf(address(this)));
        require(sent, "Failed to send token");
    }

    function setFee(uint256 _fee) public onlyOwner {
        FEE = _fee;
    }
}
