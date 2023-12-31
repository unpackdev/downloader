// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./ERC20Permit.sol";

import "./ISTBT.sol";

contract WSTBT is ERC20Permit {
    address immutable public stbtAddress; // = 0x530824DA86689C9C17CdC2871Ff29B058345b44a;

    event Wrap(address indexed sender, uint stbtAmount, uint shares);
    event Unwrap(address indexed sender, uint stbtAmount, uint shares);

    event ControllerTransfer(
        address _controller,
        address indexed _from,
        address indexed _to,
        uint256 _value,
        bytes _data,
        bytes _operatorData
    );

    constructor(string memory name_, string memory symbol_, address stbtAddress_) 
    ERC20Permit(name_) ERC20(name_, symbol_) {
        stbtAddress = stbtAddress_;
    }

    modifier onlyController() {
        require(msg.sender == ISTBT(stbtAddress).controller(), 'WSTBT: NOT_CONTROLLER');
        _;
    }

    function transfer(address _recipient, uint256 _amount) public override returns (bool) {
        _checkSendPermission(msg.sender);
        _checkReceivePermission(_recipient);
        return super.transfer(_recipient, _amount);
    }

    function transferFrom(address _sender, address _recipient, uint256 _amount) public override returns (bool) {
        _checkSendPermission(_sender);
        _checkReceivePermission(_recipient);
        return super.transferFrom(_sender, _recipient, _amount);
    }

    function _checkSendPermission(address _sender) private view {
        (bool sendAllowed, , uint64 expiryTime) = ISTBT(stbtAddress).permissions(_sender);
        require(sendAllowed, 'WSTBT: NO_SEND_PERMISSION');
        require(expiryTime == 0 || expiryTime > block.timestamp, 'WSTBT: SEND_PERMISSION_EXPIRED');
    }

    function _checkReceivePermission(address _recipient) private view {
        (, bool receiveAllowed, uint64 expiryTime) = ISTBT(stbtAddress).permissions(_recipient);
        require(receiveAllowed, 'WSTBT: NO_RECEIVE_PERMISSION');
        require(expiryTime == 0 || expiryTime > block.timestamp, 'WSTBT: RECEIVE_PERMISSION_EXPIRED');
    }

    function controllerTransfer(address _from, address _to, uint256 _value, bytes calldata _data, bytes calldata _operatorData) external onlyController {
        _transfer(_from, _to, _value);
        emit ControllerTransfer(msg.sender, _from, _to, _value, _data, _operatorData);
    }

    function wrap(uint256 stbtAmount) public returns (uint wrappedShares) {
        require(stbtAmount != 0, "WSTBT: ZERO_AMOUNT");
        _checkReceivePermission(msg.sender);
        wrappedShares = ISTBT(stbtAddress).getSharesByAmount(stbtAmount);
        ISTBT(stbtAddress).transferFrom(msg.sender, address(this), stbtAmount);
        _mint(msg.sender, wrappedShares);
        emit Wrap(msg.sender, stbtAmount, wrappedShares);
    }

    function unwrap(uint256 unwrappedShares) public returns (uint stbtAmount) {
        require(unwrappedShares != 0, "WSTBT: ZERO_AMOUNT");
        _checkSendPermission(msg.sender);
        stbtAmount = ISTBT(stbtAddress).getAmountByShares(unwrappedShares);
        ISTBT(stbtAddress).transfer(msg.sender, stbtAmount);
        _burn(msg.sender, unwrappedShares);
        emit Unwrap(msg.sender, stbtAmount, unwrappedShares);
    }

    function getWstbtByStbt(uint256 stbtAmount) external view returns (uint256) {
        return ISTBT(stbtAddress).getSharesByAmount(stbtAmount);
    }
    function getStbtByWstbt(uint256 wstbtAmount) external view returns (uint256) {
        return ISTBT(stbtAddress).getAmountByShares(wstbtAmount);
    }
    function stbtPerToken() external view returns (uint256) {
        return ISTBT(stbtAddress).getAmountByShares(1 ether);
    }
    function tokensPerStbt() external view returns (uint256) {
        return ISTBT(stbtAddress).getSharesByAmount(1 ether);
    }
}

