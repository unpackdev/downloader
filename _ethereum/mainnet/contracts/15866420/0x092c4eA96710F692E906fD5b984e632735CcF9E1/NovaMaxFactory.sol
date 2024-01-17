// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./CloneFactory.sol";
import "./NovaMax.sol";

contract NovaMaxFactory is CloneFactory, Ownable {

    address public template;
    address[] public cloned;

    event NovaMaxCreated(address indexed instance, address creator);

    constructor(address template_) {
        template = template_;
    }

    function resetTemplate(address template_) external onlyOwner {
        template = template_;
    }

    function cloneFromTemplate(
        string memory tokenName,
        string memory tokenSymbol,
        uint256 tokenTotalSupply,
        uint256 totalAmountCap_,
        uint256 minAmount_,
        uint256 startTimestamp_,
        uint256 endTimestamp_,
        uint256 lockDuration_,
        uint256 annualizedRateOfReturn_,
        address targetTokenAddress_
    ) external returns (address) {
        address instance = createClone(template);

        NovaMax(payable(instance)).init(
            _msgSender(),
            tokenName,
            tokenSymbol,
            tokenTotalSupply,
            totalAmountCap_,
            minAmount_,
            startTimestamp_,
            endTimestamp_,
            lockDuration_,
            annualizedRateOfReturn_,
            targetTokenAddress_
        );

        cloned.push(instance);

        emit NovaMaxCreated(instance, _msgSender());

        return instance;
    }
}
