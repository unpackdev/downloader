// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

import "./Context.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./AccessControl.sol";

// import "./console.sol";

interface IToken {
    function mint(address, uint256) external;

    function exists(uint256) external view returns (bool);
}

abstract contract Shop is Pausable, AccessControl, ReentrancyGuard {
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    struct Sale {
        address tokenContract;
        uint256 price;
        uint256 idFrom;
        uint256 idTo;
        uint32 since;
        uint32 until;
        bool enabled;
    }

    mapping(uint256 => Sale) public sales;

    constructor() {
        _setRoleAdmin(OPERATOR_ROLE, OPERATOR_ROLE);
        _setupRole(OPERATOR_ROLE, _msgSender());
    }

    function setSale(uint256 saleId, Sale memory sale)
        external
        onlyRole(OPERATOR_ROLE)
    {
        sales[saleId] = sale;
    }

    function revokeSale(uint256 saleId) external onlyRole(OPERATOR_ROLE) {
        sales[saleId].enabled = false;
    }

    function isPurchasable(uint256 saleId, uint256 tokenId)
        public
        view
        returns (bool)
    {
        Sale memory sale = sales[saleId];

        if (IToken(sale.tokenContract).exists(tokenId)) {
            return false;
        }

        uint32 timestamp = uint32(block.timestamp);
        if (timestamp < sale.since || sale.until < timestamp) {
            return false;
        }

        if (tokenId < sale.idFrom || sale.idTo < tokenId) {
            return false;
        }

        return true;
    }

    function getStock(uint256 saleId) public view returns (uint256) {
        Sale memory sale = sales[saleId];
        uint256 cnt;
        for (uint256 i = sale.idFrom; i <= sale.idTo; i++) {
            if (isPurchasable(saleId, i)) {
                cnt++;
            }
        }
        return cnt;
    }

    function purchase(uint256 saleId, uint256 tokenId)
        external
        payable
        whenNotPaused
        nonReentrant
    {
        Sale memory sale = sales[saleId];
        require(sale.enabled, "Shop: sale disabled");

        uint256 price = sale.price;
        require(msg.value == price, "Shop: invalid price");

        uint32 timestamp = uint32(block.timestamp);
        require(
            sale.since <= timestamp && timestamp <= sale.until,
            "Shop: outside of sale period"
        );

        require(
            sale.idFrom <= tokenId && tokenId <= sale.idTo,
            "Shop: tokenId is outside of sale tokens"
        );

        IToken(sale.tokenContract).mint(_msgSender(), tokenId);
    }

    function pause() external onlyRole(OPERATOR_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(OPERATOR_ROLE) {
        _unpause();
    }

    function withdraw() external onlyRole(OPERATOR_ROLE) {
        payable(_msgSender()).transfer(address(this).balance);
    }
}

contract SMCSymbolShop is Shop {}
