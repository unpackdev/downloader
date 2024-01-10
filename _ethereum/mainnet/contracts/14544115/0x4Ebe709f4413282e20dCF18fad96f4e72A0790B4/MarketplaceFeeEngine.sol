// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./SafeMath.sol";
import "./OwnableUpgradeable.sol";

contract MarketplaceFeeEngine is OwnableUpgradeable {
    using SafeMath for uint256;

    uint256 public platformFee;
    address payable public feeReceipient;
    mapping(bytes32 => mapping(address => bool)) public validCollections;
    mapping(bytes32 => address payable[]) public marketplaceRecipients;
    mapping(bytes32 => uint256[]) public marketplaceFees;

    function initialize(address payable _feeRecipient, uint256 _platformFee)
        public
        initializer
    {
        __Ownable_init();
        feeReceipient = _feeRecipient;
        platformFee = _platformFee;
    }

    function setFeeReceipient(address payable _feeRecipient)
        external
        onlyOwner
    {
        feeReceipient = _feeRecipient;
    }

    function setPlatformFee(uint256 _platformFee) external onlyOwner {
        platformFee = _platformFee;
    }

    function setMarketplaceFee(
        string calldata marketplace,
        address payable[] calldata recipients,
        uint256[] calldata fees
    ) external onlyOwner {
        require(recipients.length == fees.length, "length mismatch");
        bytes32 id = keccak256(abi.encodePacked(marketplace));
        marketplaceRecipients[id] = recipients;
        marketplaceFees[id] = fees;
    }

    function addMarketplaceCollections(
        string calldata marketplace,
        address[] calldata collections
    ) external onlyOwner {
        bytes32 id = keccak256(abi.encodePacked(marketplace));
        for (uint256 i = 0; i < collections.length; i++) {
            validCollections[id][collections[i]] = true;
        }
    }

    function removeMarketplaceCollections(
        string calldata marketplace,
        address[] calldata collections
    ) public onlyOwner {
        bytes32 id = keccak256(abi.encodePacked(marketplace));
        for (uint256 i = 0; i < collections.length; i++) {
            validCollections[id][collections[i]] = false;
        }
    }

    function getMarketplaceFeeByName(
        string calldata marketplace,
        address collection,
        uint256 value
    ) public view returns (address payable[] memory, uint256[] memory) {
        bytes32 id = keccak256(abi.encodePacked(marketplace));
        return getMarketplaceFee(id, collection, value);
    }

    function getMarketplaceFee(
        bytes32 id,
        address collection,
        uint256 value
    ) public view returns (address payable[] memory, uint256[] memory) {
        if (
            validCollections[id][collection] && marketplaceFees[id].length > 0
        ) {
            return (
                marketplaceRecipients[id],
                _computeAmounts(value, marketplaceFees[id])
            );
        }
        address payable[] memory recipients = new address payable[](1);
        recipients[0] = feeReceipient;
        uint256[] memory fees = new uint256[](1);
        fees[0] = platformFee;
        return (recipients, _computeAmounts(value, fees));
    }

    function _computeAmounts(uint256 value, uint256[] memory fees)
        private
        pure
        returns (uint256[] memory)
    {
        uint256[] memory amounts = new uint256[](fees.length);
        uint256 totalAmount;
        for (uint256 i = 0; i < fees.length; i++) {
            amounts[i] = value.mul(fees[i]).div(10000);
            totalAmount = totalAmount.add(amounts[i]);
        }
        require(totalAmount < value, "invalid fee amount");
        return amounts;
    }
}
