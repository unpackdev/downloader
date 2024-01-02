// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./StringConvertor.sol";
import "./Dates.sol";
import "./ResolverCache.sol";
import "./OpenFundMarketStorage.sol";
import "./INavOracle.sol";
import "./Strings.sol";
import "./SVGBackgroundGenerator.sol";

abstract contract OpenFundSVGBase is ResolverCache {

    using StringConvertor for uint256;
    using StringConvertor for bytes;

	bytes32 internal constant CONTRACT_OPEN_FUND_MARKET = "OpenFundMarket"; 

    address public svgBackgroundGenerator;

    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "only owner");
        _;
    }

    function initialize(address resolver_, address svgBackgroundGenerator_, address owner_) external initializer {
		__ResolverCache_init(resolver_);
        svgBackgroundGenerator = svgBackgroundGenerator_;
        owner = owner_;
    }

    function generateSVG(address payable_, uint256 tokenId_) external virtual view returns (string memory);

    function _generateBackground(address sft_, uint256 slot_) internal view virtual returns (string memory) {
        return SVGBackgroundGenerator(svgBackgroundGenerator).generateBackground(sft_, slot_);
    }

    function _formatValue(uint256 value, uint8 decimals) internal pure returns (bytes memory) {
        if(value < (10 ** decimals)) {
            return value.toDecimalsString(decimals).trimRight(decimals - 6);
        } else {
            return value.toDecimalsString(decimals).trimRight(decimals - 2).addThousandsSeparator();
        }
    }

	function _resolverAddressesRequired() internal view virtual override returns (bytes32[] memory addressNames) {
		addressNames = new bytes32[](1);
		addressNames[0] = CONTRACT_OPEN_FUND_MARKET;
	}

	function _market() internal view virtual returns (address) {
		return getRequiredAddress(CONTRACT_OPEN_FUND_MARKET, "OFS_SVG: Market not set");
	}

}