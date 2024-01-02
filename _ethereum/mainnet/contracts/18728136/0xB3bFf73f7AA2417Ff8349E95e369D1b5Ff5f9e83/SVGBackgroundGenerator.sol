// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./OwnControl.sol";
import "./ResolverCache.sol";
import "./OpenFundMarketStorage.sol";
import "./OpenFundRedemptionDelegate.sol";
import "./OpenFundRedemptionConcrete.sol";

contract SVGBackgroundGenerator is OwnControl, ResolverCache {

    struct SVGColorInfo {
        uint256 strategyCount;
        string backgroundColor;
        string[] patternColors;
    }

    event SetSVGColorInfo(address sft, uint256 slot, SVGColorInfo svgColorInfo);

	bytes32 internal constant CONTRACT_OPEN_FUND_MARKET = "OpenFundMarket"; 

    mapping(address => mapping(uint256 => SVGColorInfo)) internal _svgColorInfos;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() { 
        _disableInitializers();
    }

    function initialize(address resolver_, address owner_, SVGColorInfo calldata defaultColorInfo_) external initializer {
		__ResolverCache_init(resolver_);
        __OwnControl_init(owner_);
        _setSVGColorInfo(address(0), 0, defaultColorInfo_);
	}
    
    function generateBackground(address sft_, uint256 slot_) external view virtual returns (string memory background_) {
        (address shareAddress, uint256 shareSlot) = _getShareAddressAndSlot(sft_, slot_);
        SVGColorInfo storage colorInfo = _svgColorInfos[shareAddress][shareSlot];
        if (colorInfo.strategyCount == 0) {
            colorInfo = _svgColorInfos[address(0)][0];
        }

        bytes memory outline = abi.encodePacked(
            '<rect width="600" height="400" rx="20" fill="white" />',
            '<rect x="0.5" y="0.5" width="599" height="399" rx="20" stroke="#F9F9F9" />',
            '<mask id="m_3525_1" style="mask-type:alpha" maskUnits="userSpaceOnUse" x="300" y="0" width="300" height="400">',
                '<path d="M300 0H580C590 0 600 8 600 20V380C600 392 590 400 580 400H300V0Z" fill="white" />',
            '</mask>'
        );

        bytes memory figure;

        if (colorInfo.strategyCount == 1) {
            figure = abi.encodePacked(
                abi.encodePacked(
                    '<defs>',
                        abi.encodePacked(
                            '<linearGradient id="p_3525_1" x1="540" y1="120" x2="360" y2="275" gradientUnits="userSpaceOnUse">',
                                '<stop stop-color="', colorInfo.patternColors[0], '" />',
                                '<stop offset="1" stop-color="', colorInfo.patternColors[1], '" />',
                            '</linearGradient>'
                        ),
                    '</defs>'
                ),
                abi.encodePacked(
                    '<g mask="url(#m_3525_1)">',
                        '<rect x="300" width="300" height="400" fill="', colorInfo.backgroundColor, '" />',
                        '<circle cx="450" cy="200" r="115" fill="url(#p_3525_1)"></circle>',
                    '</g>'
                )
            );

        } else if (colorInfo.strategyCount == 2) {
            figure = abi.encodePacked(
                abi.encodePacked(
                    '<defs>',
                        abi.encodePacked(
                            '<linearGradient id="p_3525_1" x1="410" y1="180" x2="565" y2="70" gradientUnits="userSpaceOnUse">',
                                '<stop offset="0.1" stop-color="', colorInfo.patternColors[0], '" />',
                                '<stop offset="0.9" stop-color="', colorInfo.patternColors[1], '" />',
                            '</linearGradient>'
                        ),
                        abi.encodePacked(
                            '<linearGradient id="p_3525_2" x1="370" y1="346" x2="480" y2="205" gradientUnits="userSpaceOnUse">',
                                '<stop offset="0.06" stop-color="', colorInfo.patternColors[2], '" />',
                                '<stop offset="0.9" stop-color="', colorInfo.patternColors[3], '" />',
                            '</linearGradient>'
                        ),
                    '</defs>'
                ),
                abi.encodePacked(
                    '<g mask="url(#m_3525_1)">',
                        '<rect x="300" width="300" height="400" fill="', colorInfo.backgroundColor, '" />',
                        '<circle cx="489" cy="125" r="77" fill="url(#p_3525_1)"></circle>',
                        '<circle cx="411" cy="269" r="77" fill="url(#p_3525_2)"></circle>',
                    '</g>'
                )
            );

        } else if (colorInfo.strategyCount == 3) {
            figure = abi.encodePacked(
                abi.encodePacked(
                    '<defs>',
                        abi.encodePacked(
                            '<linearGradient id="p_3525_1" x1="330" y1="340" x2="460" y2="60" gradientUnits="userSpaceOnUse">',
                                '<stop stop-color="', colorInfo.patternColors[0], '" />',
                                '<stop offset="1" stop-color="', colorInfo.patternColors[1], '" />',
                            '</linearGradient>'
                        ),
                        abi.encodePacked(
                            '<linearGradient id="p_3525_2" x1="450" y1="220" x2="560" y2="60" gradientUnits="userSpaceOnUse">',
                                '<stop stop-color="', colorInfo.patternColors[2], '" />',
                                '<stop offset="1" stop-color="', colorInfo.patternColors[3], '" />',
                            '</linearGradient>'
                        ),
                        abi.encodePacked(
                            '<linearGradient id="p_3525_3" x1="460" y1="340" x2="550" y2="240" gradientUnits="userSpaceOnUse">',
                                '<stop stop-color="', colorInfo.patternColors[4], '" />',
                                '<stop offset="1" stop-color="', colorInfo.patternColors[5], '" />',
                            '</linearGradient>'
                        ),
                    '</defs>'
                ),
                abi.encodePacked(
                    '<g mask="url(#m_3525_1)">',
                        '<rect x="300" width="300" height="400" fill="', colorInfo.backgroundColor, '" />',
                        '<path d="M333 292A55 55 0 0 0 443 292V108A55 55 0 0 0 333 108Z" fill="url(#p_3525_1)"/>',
                        '<path d="M457 165A55 55 0 0 0 567 165V108A55 55 0 0 0 457 108Z" fill="url(#p_3525_2)"/>',
                        '<circle cx="512" cy="292" r="55" fill="url(#p_3525_3)"></circle>',
                    '</g>'
                )
            );

        } else {
            figure = abi.encodePacked(
                abi.encodePacked(
                    '<defs>',
                        abi.encodePacked(
                            '<linearGradient id="p_3525_1" x1="410" y1="40" x2="360" y2="140" gradientUnits="userSpaceOnUse">',
                                '<stop stop-color="', colorInfo.patternColors[0], '" />',
                                '<stop offset="1" stop-color="', colorInfo.patternColors[1], '" />',
                            '</linearGradient>'
                        ),
                        abi.encodePacked(
                            '<linearGradient id="p_3525_2" x1="585" y1="125" x2="460" y2="-14" gradientUnits="userSpaceOnUse">',
                                '<stop stop-color="', colorInfo.patternColors[0], '" />',
                                '<stop offset="1" stop-color="', colorInfo.patternColors[1], '" />',
                            '</linearGradient>'
                        ),
                        abi.encodePacked(
                            '<linearGradient id="p_3525_3" x1="315" y1="200" x2="440" y2="65" gradientUnits="userSpaceOnUse">',
                                '<stop stop-color="', colorInfo.patternColors[0], '" />',
                                '<stop offset="1" stop-color="', colorInfo.patternColors[1], '" />',
                            '</linearGradient>'
                        ),
                        abi.encodePacked(
                            '<linearGradient id="p_3525_4" x1="490" y1="120" x2="540" y2="220" gradientUnits="userSpaceOnUse">',
                                '<stop stop-color="', colorInfo.patternColors[0], '" />',
                                '<stop offset="1" stop-color="', colorInfo.patternColors[1], '" />',
                            '</linearGradient>'
                        ),
                        abi.encodePacked(
                            '<linearGradient id="p_3525_5" x1="410" y1="195" x2="360" y2="300" gradientUnits="userSpaceOnUse">',
                                '<stop stop-color="', colorInfo.patternColors[0], '" />',
                                '<stop offset="1" stop-color="', colorInfo.patternColors[1], '" />',
                            '</linearGradient>'
                        ),
                        abi.encodePacked(
                            '<linearGradient id="p_3525_6" x1="585" y1="280" x2="460" y2="140" gradientUnits="userSpaceOnUse">',
                                '<stop stop-color="', colorInfo.patternColors[0], '" />',
                                '<stop offset="1" stop-color="', colorInfo.patternColors[1], '" />',
                            '</linearGradient>'
                        ),
                        abi.encodePacked(
                            '<linearGradient id="p_3525_7" x1="315" y1="360" x2="440" y2="220" gradientUnits="userSpaceOnUse">',
                                '<stop stop-color="', colorInfo.patternColors[0], '" />',
                                '<stop offset="1" stop-color="', colorInfo.patternColors[1], '" />',
                            '</linearGradient>'
                        ),
                        abi.encodePacked(
                            '<linearGradient id="p_3525_8" x1="490" y1="270" x2="540" y2="375" gradientUnits="userSpaceOnUse">',
                                '<stop stop-color="', colorInfo.patternColors[0], '" />',
                                '<stop offset="1" stop-color="', colorInfo.patternColors[1], '" />',
                            '</linearGradient>'
                        ),
                    '</defs>'
                ),
                abi.encodePacked(
                    '<g mask="url(#m_3525_1)">',
                        '<rect x="300" width="300" height="400" fill="', colorInfo.backgroundColor, '" />',
                        '<circle cx="367" cy="83" r="35" fill="url(#p_3525_1)"></circle>',
                        '<path d="M444 48A35 35 0 0 0 444 118H533A 35 35 0 0 0 533 48Z" fill="url(#p_3525_2)" />',
                        '<path d="M367 126A35 35 0 0 0 367 196H456A 35 35 0 0 0 456 126Z" fill="url(#p_3525_3)" />',
                        '<circle cx="533" cy="161" r="35" fill="url(#p_3525_4)"></circle>',
                        '<circle cx="367" cy="239" r="35" fill="url(#p_3525_5)"></circle>',
                        '<path d="M444 204A35 35 0 0 0 444 274H533A 35 35 0 0 0 533 204Z" fill="url(#p_3525_6)" />',
                        '<path d="M367 282A35 35 0 0 0 367 352H456A 35 35 0 0 0 456 282Z" fill="url(#p_3525_7)" />',
                        '<circle cx="533" cy="317" r="35" fill="url(#p_3525_8)"></circle>',
                    '</g>'
                )
            );
        }

        return string(abi.encodePacked(outline, figure));
    }

    function setSVGColorInfo(address sft_, uint256 slot_, SVGColorInfo calldata svgColorInfo_) external virtual onlyOwner {
        _setSVGColorInfo(sft_, slot_, svgColorInfo_);
    }

    function getSVGColorInfo(address sft_, uint256 slot_) public view virtual returns (SVGColorInfo memory colorInfo) {
        (address shareAddress, uint256 shareSlot) = _getShareAddressAndSlot(sft_, slot_);
        colorInfo = _svgColorInfos[shareAddress][shareSlot];
        if (colorInfo.strategyCount == 0) {
            colorInfo = _svgColorInfos[address(0)][0];
        }
    }

    function _setSVGColorInfo(address sft_, uint256 slot_, SVGColorInfo calldata svgColorInfo_) internal virtual {
        _svgColorInfos[sft_][slot_] = svgColorInfo_;
        emit SetSVGColorInfo(sft_, slot_, svgColorInfo_);
    }

    function _getShareAddressAndSlot(address sftAddress_, uint256 sftSlot_) 
        internal 
        view 
        virtual 
        returns (address, uint256) 
    {
        string memory contractType = BaseSFTDelegateUpgradeable(sftAddress_).contractType();
        if (keccak256(abi.encodePacked(contractType)) == keccak256(abi.encodePacked("Open Fund Shares"))) {
            return (sftAddress_, sftSlot_);
        } else {
            OpenFundRedemptionConcrete concrete = OpenFundRedemptionConcrete(OpenFundRedemptionDelegate(sftAddress_).concrete());
            OpenFundRedemptionConcrete.RedeemInfo memory redeemInfo = concrete.getRedeemInfo(sftSlot_);
            (OpenFundMarketStorage.PoolSFTInfo memory poolSFTInfo, ,,,,,,,,) = OpenFundMarketStorage(_market()).poolInfos(redeemInfo.poolId);
            return (poolSFTInfo.openFundShare, poolSFTInfo.openFundShareSlot);
        }
    }

	function _resolverAddressesRequired() internal view virtual override returns (bytes32[] memory addressNames) {
		addressNames = new bytes32[](1);
		addressNames[0] = CONTRACT_OPEN_FUND_MARKET;
	}

	function _market() internal view virtual returns (address) {
		return getRequiredAddress(CONTRACT_OPEN_FUND_MARKET, "SVG_BGG: Market not set");
	}

}