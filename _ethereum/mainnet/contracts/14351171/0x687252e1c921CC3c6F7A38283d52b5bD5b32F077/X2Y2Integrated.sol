// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "./Ownable.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./IERC721Receiver.sol";
import "./IERC1155Receiver.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IERC721.sol";
import "./IERC3156FlashBorrower.sol";
import "./IERC1155.sol";

contract X2Y2Integrated is Ownable, Pausable, ReentrancyGuard, IERC721Receiver, IERC1155Receiver {
    using SafeERC20 for IERC20;

    struct Market {
        bool directCall; // t for call; f for delegate call (helpers)
        bool active;
    }

    struct ERC20Approval {
        IERC20 token;
        address target;
    }

    struct ERC20Transfer {
        uint256 amount;
        IERC20 token;
    }

    struct MarketOrder {
        address addr;
        uint256 value;
        bytes data;
    }

    struct ERC721Token {
        IERC721 token;
        uint256 tokenId;
    }

    struct ERC1155Token {
        IERC1155 token;
        uint256 tokenId;
        uint256 amount;
    }

    event Result(uint256 index, bool success);
    event MarketUpdate(address market);
    event ApprovalAddrUpdate(address addr);

    uint256 public maxApproval = type(uint256).max - 1;
    mapping(address => Market) public markets;
    mapping(address => bool) public erc20ApprovalAddresses;

    constructor(
        address[] memory _marketAddrs,
        Market[] memory _markets,
        address[] memory _approvalAddresses
    ) {
        require(_markets.length == _marketAddrs.length, 'Constructor: length check');
        for (uint256 i = 0; i < _markets.length; i++) {
            markets[_marketAddrs[i]] = _markets[i];
            emit MarketUpdate(_marketAddrs[i]);
        }
        for (uint256 i = 0; i < _approvalAddresses.length; i++) {
            erc20ApprovalAddresses[_approvalAddresses[i]] = true;
            emit ApprovalAddrUpdate(_approvalAddresses[i]);
        }
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function buyOS(MarketOrder[] memory marketOrders) external payable nonReentrant whenNotPaused {
        _executeOrder(marketOrders);
        uint256 balance = address(this).balance;
        if (balance > 0) {
            msg.sender.call{value: balance}('');
        }
    }

    function buy(
        ERC20Approval[] memory erc20Approvals,
        ERC20Transfer[] memory erc20Transfers,
        MarketOrder[] memory marketOrders,
        ERC721Token[] memory erc721Tokens,
        ERC1155Token[] memory erc1155Tokens,
        IERC20[] memory moreDustTokens
    ) external payable nonReentrant whenNotPaused {
        require(marketOrders.length > 0, 'Sender: no order specified');

        _transferTokens(erc20Transfers);
        _approveTokens(erc20Approvals);
        _executeOrder(marketOrders);
        _transferERC721Tokens(erc721Tokens);
        _transferERC1155Tokens(erc1155Tokens);
        _returnDusts(erc20Transfers, moreDustTokens);
    }

    function _executeOrder(MarketOrder[] memory marketOrders) internal {
        for (uint256 i = 0; i < marketOrders.length; i++) {
            MarketOrder memory m = marketOrders[i];

            require(markets[m.addr].active, 'Execute: inactive market');
            bool directCall = markets[m.addr].directCall;

            (bool success, ) = directCall
                ? m.addr.call{value: m.value}(m.data)
                : m.addr.delegatecall(m.data);
            emit Result(i, success);
        }
    }

    function _transferERC721Tokens(ERC721Token[] memory erc721Tokens) internal {
        for (uint256 i = 0; i < erc721Tokens.length; i++) {
            ERC721Token memory x = erc721Tokens[i];

            address(x.token).call(
                abi.encodeWithSelector(
                    0x23b872dd, // transferFrom(address,address,uint256)
                    address(this),
                    msg.sender,
                    x.tokenId
                )
            );
        }
    }

    function _transferERC1155Tokens(ERC1155Token[] memory erc1155Tokens) internal {
        for (uint256 i = 0; i < erc1155Tokens.length; i++) {
            ERC1155Token memory x = erc1155Tokens[i];
            uint256 balance = x.token.balanceOf(address(this), x.tokenId);
            if (balance > x.amount) {
                balance = x.amount;
            }
            if (balance > 0) {
                address(x.token).call(
                    abi.encodeWithSelector(
                        0xf242432a, // safeTransferFrom(address,address,uint256,uint256,bytes)
                        address(this),
                        msg.sender,
                        x.tokenId,
                        balance,
                        bytes('')
                    )
                );
            }
        }
    }

    function _approveTokens(ERC20Approval[] memory erc20Approvals) internal {
        for (uint256 i = 0; i < erc20Approvals.length; i++) {
            ERC20Approval memory a = erc20Approvals[i];

            require(erc20ApprovalAddresses[a.target], 'Approve: unable to approve token');
            a.token.approve(a.target, maxApproval);
        }
    }

    function _transferTokens(ERC20Transfer[] memory erc20Transfers) internal {
        for (uint256 i = 0; i < erc20Transfers.length; i++) {
            ERC20Transfer memory t = erc20Transfers[i];
            if (t.amount > 0) {
                t.token.safeTransferFrom(msg.sender, address(this), t.amount);
            }
        }
    }

    function _returnDusts(ERC20Transfer[] memory dusts, IERC20[] memory moreDusts) internal {
        uint256 balance = address(this).balance;
        if (balance > 0) {
            msg.sender.call{value: balance}('');
        }

        for (uint256 i = 0; i < dusts.length; i++) {
            IERC20 t = dusts[i].token;
            uint256 balance = t.balanceOf(address(this));
            if (balance > 0) {
                // transfer(address,uint256)
                address(t).call(abi.encodeWithSelector(0xa9059cbb, msg.sender, balance));
            }
        }

        for (uint256 i = 0; i < moreDusts.length; i++) {
            IERC20 t = moreDusts[i];
            uint256 balance = t.balanceOf(address(this));
            if (balance > 0) {
                // transfer(address,uint256)
                address(t).call(abi.encodeWithSelector(0xa9059cbb, msg.sender, balance));
            }
        }
    }

    // settings
    function updateMarkets(address[] memory _marketAddrs, Market[] memory _markets)
        external
        onlyOwner
    {
        require(_markets.length == _marketAddrs.length, 'Owner: length check');
        for (uint256 i = 0; i < _markets.length; i++) {
            markets[_marketAddrs[i]] = _markets[i];
            emit MarketUpdate(_marketAddrs[i]);
        }
    }

    function disableMarkets(address[] memory _markets) external onlyOwner {
        for (uint256 i = 0; i < _markets.length; i++) {
            delete markets[_markets[i]].active;
        }
    }

    function batchApprove(
        IERC20[] memory tokens,
        address[] memory tos,
        bool disapprove
    ) external onlyOwner {
        for (uint256 i = 0; i < tokens.length; i++) {
            IERC20 t = tokens[i];
            for (uint256 j = 0; j < tos.length; j++) {
                address to = tos[j];
                uint256 approval = disapprove ? 0 : maxApproval;
                t.approve(to, approval);
            }
        }
    }

    function updateApprovalAddresses(address[] memory toAdd, address[] memory toRemove)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < toAdd.length; i++) {
            erc20ApprovalAddresses[toAdd[i]] = true;
            emit ApprovalAddrUpdate(toAdd[i]);
        }
        for (uint256 i = 0; i < toRemove.length; i++) {
            erc20ApprovalAddresses[toRemove[i]] = true;
            emit ApprovalAddrUpdate(toRemove[i]);
        }
    }

    // safety
    function ethStuck(address[] memory tos, uint256[] memory amounts)
        external
        onlyOwner
        nonReentrant
    {
        require(tos.length == amounts.length, 'Owner: length check');
        for (uint256 i = 0; i < tos.length; i++) {
            // ignore result
            tos[i].call{value: amounts[i]}('');
        }
    }

    function erc20Stuck(
        address[] memory tos,
        IERC20[] memory tokens,
        uint256[] memory amounts
    ) external onlyOwner nonReentrant {
        require(tos.length == tokens.length, 'Owner: length check');
        require(tokens.length == amounts.length, 'Owner: length check');

        for (uint256 i = 0; i < tos.length; i++) {
            tokens[i].safeTransfer(tos[i], amounts[i]);
        }
    }

    function erc721Stuck(
        address[] memory tos,
        IERC721[] memory tokens,
        uint256[] memory tokenIds
    ) external onlyOwner nonReentrant {
        require(tos.length == tokens.length, 'Owner: length check');
        require(tokens.length == tokenIds.length, 'Owner: length check');

        for (uint256 i = 0; i < tos.length; i++) {
            tokens[i].safeTransferFrom(address(this), tos[i], tokenIds[i]);
        }
    }

    function erc1155Stuck(
        address[] memory tos,
        IERC1155[] memory tokens,
        uint256[] memory tokenIds,
        uint256[] memory amounts
    ) external onlyOwner nonReentrant {
        require(tos.length == tokens.length, 'Owner: length check');
        require(tokens.length == tokenIds.length, 'Owner: length check');
        require(amounts.length == tokenIds.length, 'Owner: length check');

        for (uint256 i = 0; i < tos.length; i++) {
            tokens[i].safeTransferFrom(address(this), tos[i], tokenIds[i], amounts[i], '');
        }
    }

    // receivers
    function supportsInterface(bytes4 interfaceId) external view returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId;
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}
