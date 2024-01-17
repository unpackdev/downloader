//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./IERC1155.sol";
import "./ERC1155Holder.sol";

import "./CruzoMarket.sol";

contract ContractSeller is ERC1155Holder {
    CruzoMarket private market;
    IERC1155 private token;

    constructor(CruzoMarket _market, IERC1155 _token) {
        market = _market;
        token = _token;
        _token.setApprovalForAll(address(market), true);
    }

    function openTrade(
        uint256 _tokenId,
        uint256 _amount,
        uint256 _price
    ) external {
        market.openTrade(address(token), _tokenId, _amount, _price);
    }

    receive() external payable {
        market.closeTrade(address(token), 1);
    }
}
