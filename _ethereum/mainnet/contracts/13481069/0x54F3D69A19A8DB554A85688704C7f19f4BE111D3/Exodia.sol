//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC1155PresetMinterPauser.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./console.sol";

contract Exodia is ERC1155PresetMinterPauser, ReentrancyGuard, Ownable {
    uint256 public constant LIFETIME = 1;
    uint256 public constant ADDRESS_REFUND_PERIOD = 14 days;

    // refunds go to `owner`. purchases are made from `seller`
    address public seller;

    mapping(uint256 => uint256) public prices;

    mapping(address => uint256) public addressPaid;
    mapping(address => uint256) public addressRefundDeadline;
    uint256 public generalRefundDeadline; // The date refunds are closed is also the day owner can withdraw funds

    event MintDev(uint256 id, uint256 amount, uint256 price);
    event Buy(uint256 id, uint256 amount, uint256 price, address buyer);
    event Refund(uint256 id, uint256 amount, uint256 price, address buyer);

    constructor() ERC1155PresetMinterPauser('https://exodia.io/api/nft/{id}.json') {
        seller = _msgSender();

        _mintDev(LIFETIME, 500, 0.15 ether);
    }

    function buy(uint256 id, uint256 amount) external payable nonReentrant {
        uint256 price = getPrice(id);

        require(msg.value >= (price * amount), 'Exodia: Not enough ETH sent');

        _safeTransferFrom(seller, _msgSender(), id, amount, '');

        addressPaid[_msgSender()] += (price * amount);

        if (addressRefundDeadline[_msgSender()] == 0) {
            addressRefundDeadline[_msgSender()] = block.timestamp + ADDRESS_REFUND_PERIOD;
        }

        emit Buy(id, amount, price, _msgSender());
    }

    function mintDev(
        uint256 id,
        uint256 amount,
        uint256 price
    ) external onlyOwner {
        _mintDev(id, amount, price);
    }

    function refund(uint256 id, uint256 amount) external nonReentrant {
        require(
            addressRefundDeadline[_msgSender()] > block.timestamp,
            'Exodia: Personal refund deadline has passed'
        );

        uint256 price = getPrice(id);

        uint256 refundAmount = price * amount;

        require(
            refundAmount <= addressPaid[_msgSender()],
            'Exodia: Requested refund amount more than paid'
        );

        addressPaid[_msgSender()] -= refundAmount;

        _safeTransferFrom(_msgSender(), owner(), id, amount, '');

        payable(_msgSender()).transfer(refundAmount);

        emit Refund(id, amount, price, _msgSender());
    }

    function setGeneralRefundDeadline() external onlyOwner {
        generalRefundDeadline = block.timestamp + ADDRESS_REFUND_PERIOD;
    }

    function withdraw(uint256 amount) external onlyOwner {
        require(generalRefundDeadline > 0, 'Exodia: withdraw has not yet been enabled');
        require(
            generalRefundDeadline < block.timestamp,
            'Exodia: General refund deadline has not yet passed'
        );

        uint256 withdrawAmount = amount == 0 ? address(this).balance : amount;

        payable(_msgSender()).transfer(withdrawAmount);
    }

    function setSeller(address _seller) external onlyOwner {
        seller = _seller;
    }

    function setPrice(uint256 id, uint256 price) external onlyOwner {
        prices[id] = price;
    }

    function setURI(string memory uri) external onlyOwner {
        _setURI(uri);
    }

    function getPrice(uint256 id) public view returns (uint256) {
        return prices[id];
    }

    function _mintDev(
        uint256 id,
        uint256 amount,
        uint256 price
    ) private {
        _mint(seller, id, amount, '');
        prices[id] = price;

        emit MintDev(id, amount, price);
    }
}
