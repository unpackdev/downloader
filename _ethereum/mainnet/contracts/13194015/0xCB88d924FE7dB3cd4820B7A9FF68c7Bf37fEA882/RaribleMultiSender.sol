// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./ERC1155Holder.sol";

interface RaribleUserToken {
    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes calldata _data) external;
    function setApprovalForAll(address _operator, bool _approved) external;
    function balanceOf(address _owner, uint256 _id) external view returns (uint256);
}

contract RaribleMultiSender is Ownable, ERC1155Holder {
    using SafeMath for uint256;
    
    function batchTransferFrom(address _token, address[] calldata _receivers, uint256 _id, uint256 _value, bytes calldata _data) external onlyOwner {
        require(_value > 0, 'invalid value');
        require(_receivers.length > 0, 'invalid number of receivers');
        RaribleUserToken token = RaribleUserToken(_token);
        uint256 totalAmount = _receivers.length.mul(_value);
        token.safeTransferFrom(msg.sender, address(this), _id, totalAmount, _data);
        for (uint256 i = 0; i < _receivers.length; ++i) {
            address receiver = _receivers[i];
            token.safeTransferFrom(address(this), receiver, _id, _value, _data);
        }
    }
    
    function withdraw(address _token, uint256 _id, uint256 _value, bytes calldata _data) external onlyOwner {
        RaribleUserToken token = RaribleUserToken(_token);
        token.safeTransferFrom(address(this), msg.sender, _id, _value, _data);
    }
}