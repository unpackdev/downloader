// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./Ownable.sol";
import "./IERC1155.sol";
import "./ERC1155Holder.sol";
import "./console.sol";

contract RewardTable is Ownable, ERC1155Holder {

    address public immutable erc1155Contract;
    uint256 public totalSupply;
    address public rewarder;

    uint256[] public ids = new uint256[](0);

    constructor(address _erc1155Contract) {
        erc1155Contract = _erc1155Contract;
    }

    function setRewarder(address _rewarder) external onlyOwner {
        require(_rewarder != address(0), "RewardTable: rewarder is address(0)");
        rewarder = _rewarder;
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) public pure override returns (bytes4) {
        revert("RewardTable: Not allowed");
    }

    function onERC1155BatchReceived(
        address,
        address _from,
        uint256[] calldata _ids,
        uint256[] calldata _values,
        bytes calldata
    ) public override returns (bytes4) {
        require(_msgSender() == erc1155Contract, "RewardTable: invalid contract");
        require(owner() == _from, "RewardTable: only owner can add rewards");

        for (uint256 i = 0; i < _ids.length; i++) {
            uint256 id = _ids[i];
            ids.push(id);
            totalSupply += _values[i];
        }

        return this.onERC1155BatchReceived.selector;
    }

    function withdraw(
        uint256[] calldata _ids,
        uint256[] calldata _values,
        bytes calldata _data
    ) external onlyOwner {
        IERC1155(erc1155Contract).safeBatchTransferFrom(
            address(this),
            owner(),
            _ids,
            _values,
            _data
        );
    }
}
