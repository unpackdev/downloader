// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "./Initializable.sol";
import "./ContextUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./IERC20.sol";
import "./IERC721.sol";
import "./IERC777.sol";
import "./IERC1155.sol";

contract ERCXMultisender is Initializable, ContextUpgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    uint256 public txFee;
    uint256 public subscriptionFee;
    mapping(address => bool) public subscriptions;

    constructor() {}

    function initialize(uint256 _txFee, uint256 _subscriptionFee) public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();

        txFee = _txFee;
        subscriptionFee = _subscriptionFee;
        subscriptions[_msgSender()] = true;
    }

    function multiSendEthers(address[] calldata to, uint256[] calldata amounts) external payable nonReentrant {
        require(to.length == amounts.length);
        require(to.length <= 255); // maximum length (to not run out of gas)

        uint256 amountLeft = msg.value;
        for (uint256 i = 0; i < to.length; i++) {
            require(amountLeft >= amounts[i], 'Not enough ethereum send for all transfers');
            (bool sent, ) = to[i].call{value: amounts[i]}('');
            require(sent, 'Failed to send ether to one of the addresses');
            amountLeft -= amounts[i];
        }

        require(subscriptions[_msgSender()] || amountLeft >= txFee, 'Fee is not sufficient');
    }

    function multiSendERC20(
        address tokenAddress,
        address[] calldata to,
        uint256[] calldata amounts
    ) external payable {
        require(subscriptions[_msgSender()] || msg.value >= txFee, 'Fee is not sufficient');
        require(to.length == amounts.length);
        require(to.length <= 255); // maximum length (to not run out of gas)

        for (uint256 i = 0; i < to.length; i++) {
            IERC20(tokenAddress).transferFrom(_msgSender(), to[i], amounts[i]);
        }
    }

    function multiSendERC721(
        address tokenAddress,
        address[] calldata to,
        uint256[] calldata ids
    ) external payable {
        require(subscriptions[_msgSender()] || msg.value >= txFee, 'Fee is not sufficient');
        require(to.length == ids.length);
        require(to.length <= 255); // maximum length (to not run out of gas)

        for (uint256 i = 0; i < to.length; i++) {
            IERC721(tokenAddress).transferFrom(_msgSender(), to[i], ids[i]);
        }
    }

    function multiSendERC777(
        address tokenAddress,
        address[] calldata to,
        uint256[] calldata amounts,
        bytes calldata data
    ) external payable {
        require(subscriptions[_msgSender()] || msg.value >= txFee, 'Fee is not sufficient');
        require(to.length == amounts.length);
        require(to.length <= 255); // maximum length (to not run out of gas)

        for (uint256 i = 0; i < to.length; i++) {
            IERC777(tokenAddress).operatorSend(_msgSender(), to[i], amounts[i], data, '');
        }
    }

    function multiSendIERC1155(
        address tokenAddress,
        address[] calldata to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external payable {
        require(subscriptions[_msgSender()] || msg.value >= txFee, 'Fee is not sufficient');
        require(to.length == ids.length);
        require(to.length <= 255); // maximum length (to not run out of gas)

        for (uint256 i = 0; i < to.length; i++) {
            IERC1155(tokenAddress).safeTransferFrom(_msgSender(), to[i], ids[i], amounts[i], data);
        }
    }

    function multiSendIERC1155Batch(
        address tokenAddress,
        address[] calldata to,
        uint256[][] calldata ids,
        uint256[][] calldata amounts,
        bytes calldata data
    ) external payable {
        require(subscriptions[_msgSender()] || msg.value >= txFee, 'Fee is not sufficient');
        require(to.length == ids.length);
        require(to.length <= 255); // maximum length (to not run out of gas)

        for (uint256 i = 0; i < to.length; i++) {
            IERC1155(tokenAddress).safeBatchTransferFrom(_msgSender(), to[i], ids[i], amounts[i], data);
        }
    }

    function getLifelongSubscription() external payable {
        require(!subscriptions[_msgSender()], 'You already have a subscription');
        require(msg.value >= subscriptionFee, 'Fee is not sufficient');
        subscriptions[_msgSender()] = true;
    }

    function setLifelongSubscriptions(address[] calldata accounts) external onlyOwner {
        for (uint256 i = 1; i < accounts.length; i++) {
            subscriptions[accounts[i]] = true;
        }
    }

    function setTxFee(uint256 newTxFee) external onlyOwner {
        txFee = newTxFee;
    }

    function setSubscriptionFee(uint256 newSubscriptionFee) external onlyOwner {
        subscriptionFee = newSubscriptionFee;
    }

    function getRewards() external onlyOwner {
        (bool sent, ) = owner().call{value: address(this).balance}('');
        require(sent, 'Failed to pay out rewards');
    }
}
