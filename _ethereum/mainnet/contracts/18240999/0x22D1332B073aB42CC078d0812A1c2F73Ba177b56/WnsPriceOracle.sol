// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface WnsAddressesInterface {
    function owner() external view returns (address);
    function getWnsAddress(string memory _label) external view returns(address);
}


pragma solidity 0.8.7;

abstract contract WnsImpl {
    WnsAddressesInterface wnsAddresses;

    constructor(address addresses_) {
        wnsAddresses = WnsAddressesInterface(addresses_);
    }

    function setAddresses(address addresses_) public {
        require(msg.sender == owner(), "Not authorized.");
        wnsAddresses = WnsAddressesInterface(addresses_);
    }

    function owner() public view returns (address) {
        return wnsAddresses.owner();
    }

    function getWnsAddress(string memory _label) public view returns (address) {
        return wnsAddresses.getWnsAddress(_label);
    }

    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }
}

pragma solidity ^0.8.0;

interface AggregatorV3Interface {
    function latestAnswer() external view returns (int256);
}

pragma solidity ^0.8.7;

abstract contract WnsPrimaryDomains is WnsImpl {
    mapping(string => uint256) primaryDomains;

    struct PremiumStruct {
        string domain;
        uint256 tier;
    }

    function addPremiumDomains(PremiumStruct[] memory premiumStruct) public onlyOwner {
        for (uint256 i = 0; i < premiumStruct.length; i++) {
            require(premiumStruct[i].tier > 0 && premiumStruct[i].tier <= 7, "Invalid tier");
            primaryDomains[premiumStruct[i].domain] = premiumStruct[i].tier;
        }
    }

    function removePremiumDomains(string[] memory domains) public onlyOwner {
        for (uint256 i = 0; i < domains.length; i++) {
            primaryDomains[domains[i]] = 0;
        }
    }

    function getPrimaryDomainTier(string memory domain) internal view returns (uint256) {
        return primaryDomains[domain];
    }
}

pragma solidity ^0.8.7;

abstract contract WnsTiers is WnsPrimaryDomains {
    function getDomainTier(string memory domain) public view returns (uint256) {
        uint256 length = bytes(domain).length;

        if (length < 3) {
            return 0;
        } else {
            uint256 primaryDomainTier = getPrimaryDomainTier(domain);
            if (primaryDomainTier != 0) {
                return primaryDomainTier;
            } else {
                uint256 tier = getLengthTier(length);
                return tier;
            }
        }
    }

    function getLengthTier(uint256 length) internal pure returns (uint256) {
        if (length < 3) {
            return 0;
        } else if (length == 3) {
            return 3;
        } else if (length == 4) {
            return 4;
        } else if (length == 5) {
            return 5;
        } else if (length >= 6 && length <= 10) {
            return 6;
        } else {
            return 7;
        }
    }
}

pragma solidity ^0.8.7;

abstract contract WnsTierPrices is WnsImpl  {
    mapping(uint256 => uint256) tierPrices;

    struct Tiers {
        uint256 tier;
        uint256 price;
    }

    constructor() {
        _setTierPrices([
            Tiers({tier: 1, price: 5000}),
            Tiers({tier: 2, price: 2500}),
            Tiers({tier: 3, price: 1000}),
            Tiers({tier: 4, price: 250}),
            Tiers({tier: 5, price: 100}),
            Tiers({tier: 6, price: 50}),
            Tiers({tier: 7, price: 25})
        ]);
    }

    function setTierPrices(Tiers[7] memory tiers) public onlyOwner {
        _setTierPrices(tiers);
    }

    function _setTierPrices(Tiers[7] memory tiers) internal {
        for (uint256 i = 0; i < tiers.length; i++) {
            tierPrices[tiers[i].tier] = tiers[i].price;
        }
    }

    function getTierPrice(uint256 tier) public view returns (uint256) {
        return tierPrices[tier];
    }

    function getAllTierPrices() public view returns (uint256[7] memory) {
        uint256[7] memory prices;

        for (uint256 i = 0; i < 7; i++) {
            prices[i] = getTierPrice(i + 1);
        }

        return prices;
    }
}

pragma solidity ^0.8.7;

abstract contract EthPriceOracle is WnsImpl {
    AggregatorV3Interface internal ethPriceOracle;

    constructor(address address_) {
        ethPriceOracle = AggregatorV3Interface(address_);
    }

    function setEthPriceOracle(address address_) public onlyOwner  {
        ethPriceOracle = AggregatorV3Interface(address_);
    }

    function getEthPrice() public view returns (uint256) {
        return uint256(ethPriceOracle.latestAnswer());
        //return 181395532974;
    }
}

pragma solidity ^0.8.7;

contract WnsPriceOracle is WnsTiers, WnsTierPrices, EthPriceOracle {

    constructor() WnsImpl(0xf3e15b3235b71685180e521FDC6c2Da3c2d9Dc82) EthPriceOracle(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419) {}

    function getDomainPrice(string memory domain) public view returns (uint256) {
        return getTierPrice(getDomainTier(domain));
    }

    function getDomainPriceEth(string memory domain) public view returns (uint256) {
        uint256 usdPrice = getTierPrice(getDomainTier(domain));
        uint256 ethPrice = uint256(getEthPrice());
        uint256 cost = usdPrice * ( 1e18 / ethPrice ) * 1e8;
        return cost;
    }
}