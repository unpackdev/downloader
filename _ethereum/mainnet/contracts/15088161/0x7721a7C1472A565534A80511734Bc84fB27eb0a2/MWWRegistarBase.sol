// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4 <0.9.0;

import "./Ownable.sol";
import "./SafeERC20.sol";
import "./ERC20.sol";
import "./MWWDomain.sol";

abstract contract MWWRegistarBase is Ownable {
    using SafeERC20 for ERC20;

    struct PlanInfo {
        string name;
        uint256 usdPrice;
    }

    MWWDomain public domainContract;

    mapping(address => bool) private acceptableTokens;
    mapping(uint8 => PlanInfo) private availablePlans;
    uint8[] private planIds;

    event MWWPurchase(address planOwner, uint256 timestamp);

    constructor(address[] memory _acceptableTokens) {
        for (uint256 i = 0; i < _acceptableTokens.length; i++) {
            acceptableTokens[_acceptableTokens[i]] = true;
        }
    }

    function withdraw(
        address tokenAddress,
        uint256 amount,
        address destination
    ) public onlyOwner {
        require(amount > 0, "Amount can't be zero");
        require(destination != address(0), "Destination can't be zero");
        require(destination != address(this), "Can't send to this contract");

        if (tokenAddress == address(0)) {
            (bool ok, ) = destination.call{value: amount}("");
            require(ok, "Failed to withdraw funds");
        } else {
            require(acceptableTokens[tokenAddress], "Token not accepted");
            ERC20(tokenAddress).safeTransfer(destination, amount);
        }
    }

    function setDomainContract(address _address) public onlyOwner {
        domainContract = MWWDomain(_address);
    }

    function addAcceptableToken(address tokenAddress) public onlyOwner {
        acceptableTokens[tokenAddress] = true;
    }

    function removeAcceptableToken(address tokenAddress) public onlyOwner {
        delete acceptableTokens[tokenAddress];
    }

    function addPlan(
        string memory _name,
        uint256 _usdPrice,
        uint8 _planId
    ) public onlyOwner {
        require(_usdPrice != 0, "usdPrice can't be 0");
        // If usdPrice is 0, we can assume nobody has added that plan before.
        require(availablePlans[_planId].usdPrice == 0, "Plan already exists");

        availablePlans[_planId] = PlanInfo(_name, _usdPrice);
        planIds.push(_planId);
    }

    function removePlan(uint8 _index, uint8 planId) public onlyOwner {
        planIds[_index] = planIds[planIds.length - 1];
        planIds.pop();
        delete availablePlans[planId];
    }

    function purchaseWithNative(
        uint8 planId,
        address planOwner,
        uint256 duration,
        string memory domain,
        string memory ipfsHash
    ) public payable returns (MWWStructs.Domain memory) {
        require(
            address(domainContract) != address(0),
            "Subscription contract not set"
        );
        require(availablePlans[planId].usdPrice != 0, "Plan does not exists");

        (uint256 amount, uint256 timestamp) = getNativeConvertedValue(
            availablePlans[planId].usdPrice
        );

        require(timestamp > block.timestamp - 3 hours, "Price is outdated");

        uint256 finalPrice = getProportionalPriceForDuration(duration, amount);

        require(msg.value >= finalPrice, "Value is lower then plan price");

        return _purchase(planId, planOwner, duration, domain, ipfsHash);
    }

    function purchaseWithToken(
        address tokenAddress,
        uint8 planId,
        address planOwner,
        uint256 duration,
        string calldata domain,
        string calldata ipfsHash
    ) public payable returns (MWWStructs.Domain memory) {
        require(
            address(domainContract) != address(0),
            "Subscription contract not set"
        );
        require(availablePlans[planId].usdPrice != 0, "Plan does not exists");
        require(acceptableTokens[tokenAddress], "Token not accepted");

        ERC20 token = ERC20(tokenAddress);
        uint256 finalPrice = getProportionalPriceForDuration(
            duration,
            availablePlans[planId].usdPrice * 10**token.decimals()
        );

        token.safeTransferFrom(msg.sender, address(this), finalPrice);

        return _purchase(planId, planOwner, duration, domain, ipfsHash);
    }

    function _purchase(
        uint8 planId,
        address planOwner,
        uint256 duration,
        string memory domain,
        string memory ipfsHash
    ) private returns (MWWStructs.Domain memory) {
        MWWStructs.Domain memory subs = domainContract.subscribe(
            msg.sender,
            planId,
            planOwner,
            duration,
            domain,
            ipfsHash
        );

        emit MWWPurchase(planOwner, block.timestamp);

        return subs;
    }

    function getAvailablePlans() public view returns (PlanInfo[] memory) {
        PlanInfo[] memory plans = new PlanInfo[](planIds.length);

        for (uint256 i = 0; i < planIds.length; i++) {
            plans[i] = availablePlans[planIds[i]];
        }
        return plans;
    }

    function getProportionalPriceForDuration(
        uint256 duration,
        uint256 yearlyPrice
    ) private pure returns (uint256) {
        uint256 proportion = (duration * 10**8) / 31_540_000;
        return (yearlyPrice * proportion) / (10**8);
    }

    function getNativeConvertedValue(uint256 usdPrice)
        public
        view
        virtual
        returns (uint256 amountInNative, uint256 timestamp);
}
