// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IBridge.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IERC721.sol";
import "./IERC1155.sol";

import "./ERC1155Receiver.sol";

contract Bridge is IBridge, ERC1155Receiver {
    using SafeERC20 for IERC20;

    struct CallData {
        address target;
        bytes data;
    }

    address public override committee;
    address public withdrawTo;

    modifier onlyCommittee() {
        require(msg.sender == committee, "Bridge: FORBIDDEN");
        _;
    }

    constructor(address _committee, address _withdrawTo) {
        committee = _committee;
        withdrawTo = _withdrawTo;
    }

    function setCommittee(address _committee) external onlyCommittee {
        committee = _committee;
    }

    function setWithdrawTo(address _withdrawTo) external onlyCommittee {
        withdrawTo = _withdrawTo;
    }

    function bridge() external payable override {
        require(!_isContract(msg.sender), "Bridge: IS_CONTRACT");
        emit Bridge(msg.sender, msg.value);
    }

    function bridgeERC20(address token, uint256 amount) external override {
        require(!_isContract(msg.sender), "Bridge: IS_CONTRACT");
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        emit BridgeERC20(msg.sender, token, amount);
    }

    function bridgeERC721(address token, uint256 tokenId) external override {
        require(!_isContract(msg.sender), "Bridge: IS_CONTRACT");
        IERC721(token).transferFrom(msg.sender, address(this), tokenId);
        emit BridgeERC721(msg.sender, token, tokenId);
    }

    function bridgeERC1155(
        address token,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts
    ) external override {
        require(!_isContract(msg.sender), "Bridge: IS_CONTRACT");
        IERC1155(token).safeBatchTransferFrom(msg.sender, address(this), tokenIds, amounts, "");
        emit BridgeERC1155(msg.sender, token, tokenIds, amounts);
    }

    function withdraw(uint256 amount) external override onlyCommittee {
        require(address(this).balance >= amount, "Bridge: BALANCE_EXCEED");
        payable(withdrawTo).transfer(amount);
    }

    function withdrawERC20(address token, uint256 amount) external override onlyCommittee {
        IERC20(token).transfer(withdrawTo, amount);
    }

    function withdrawERC721(address token, uint256 tokenId) external override onlyCommittee {
        IERC721(token).transferFrom(address(this), withdrawTo, tokenId);
    }

    function withdrawERC1155(
        address token,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts
    ) external override onlyCommittee {
        IERC1155(token).safeBatchTransferFrom(address(this), withdrawTo, tokenIds, amounts, "");
    }

    function multiCall(CallData[] calldata callDatas) external onlyCommittee {
        for (uint256 i = 0; i < callDatas.length; i++) {
            (bool success, ) = callDatas[i].target.call(callDatas[i].data);
            require(success, "Bridge: Transaction call failed");
        }
    }

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external pure override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external pure override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    function _isContract(address account) private view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
}
