// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @artist: Anna Ridler
/// @author: manifold.xyz

import "./PRBMathSD59x18.sol";
import "./Trigonometry.sol";
import "./BokkyPooBahsDateTimeLibrary.sol";

import "./DynamicArweaveHash.sol";
import "./IERC721CreatorExtensionApproveTransfer.sol";

contract AnnoOxypetalum is DynamicArweaveHash, IERC721CreatorExtensionApproveTransfer {
    using PRBMathSD59x18 for int256;

    uint256 private _baseTokenId;
    uint8 private _seasonOnLastTransfer;

    // Seasons
    uint8 constant private _WINTER = 0;
    uint8 constant private _SPRING = 1;
    uint8 constant private _SUMMER = 2;
    uint8 constant private _FALL = 3;
    
    // Constants
    int256 constant private _DAY_IN_SECONDS = 86400000000000000000000;
    int256 constant private _JULIAN_EPOCH = 2440587500000000000000000;
    int256 constant private _JULIAN_2000 = 2451545000000000000000000;
    int256 constant private _JULIAN_CENTURY = 36525000000000000000000;
    
    int256 immutable _D2R = PRBMathSD59x18.pi().div(180000000000000000000);

    // In-memory Arrays
    function _springConstants() private pure returns (int256[5] memory) {
        int256[5] memory constants = 
            [int(2451623809840000000000000), 
            365242374040000000000000, 
            51690000000000000, 
            -4110000000000000, 
            -570000000000000];
        return constants;
    }

    function _summerConstants() private pure returns (int256[5] memory) {
        int256[5] memory constants = 
            [int(2451716567670000000000000), 
            365241626030000000000000, 
            3250000000000000, 
            8880000000000000, 
            -300000000000000];
        return constants;
    }

    function _fallConstants() private pure returns (int256[5] memory) {
        int256[5] memory constants = 
            [int(2451810217150000000000000),
            365242017670000000000000,
            -115750000000000000,
            3370000000000000,
            780000000000000];
        return constants;
    }

    function _winterConstants() private pure returns (int256[5] memory) {
        int256[5] memory constants = 
            [int(2451900059520000000000000),
            365242740490000000000000,
            -62230000000000000,
            -8230000000000000,
            320000000000000];
        return constants;
    }

    function _termsConstants() private pure returns (int256[3][24] memory) {
        int256[3][24] memory constants = 
            [
                [int(485000000000000000000), 324960000000000000000, 1934136000000000000000],
                [int(203000000000000000000), 337230000000000000000, 32964467000000000000000],
                [int(199000000000000000000), 342080000000000000000, 20186000000000000000],
                [int(182000000000000000000), 27850000000000000000, 445267112000000000000000],
                [int(156000000000000000000), 73140000000000000000, 45036886000000000000000],
                [int(136000000000000000000), 171520000000000000000, 22518443000000000000000],
                [int(77000000000000000000), 222540000000000000000, 65928934000000000000000],
                [int(74000000000000000000), 296720000000000000000, 3034906000000000000000],
                [int(70000000000000000000), 243580000000000000000, 9037513000000000000000],
                [int(58000000000000000000), 119810000000000000000, 33718147000000000000000],
                [int(52000000000000000000), 297170000000000000000, 150678000000000000000],
                [int(50000000000000000000), 21020000000000000000, 2281226000000000000000],
                [int(45000000000000000000), 247540000000000000000, 29929562000000000000000],
                [int(44000000000000000000), 325150000000000000000, 31555956000000000000000],
                [int(29000000000000000000), 60930000000000000000, 4443417000000000000000],
                [int(18000000000000000000), 155120000000000000000, 67555328000000000000000],
                [int(17000000000000000000), 288790000000000000000, 4562452000000000000000],
                [int(16000000000000000000), 198040000000000000000, 62894029000000000000000],
                [int(14000000000000000000), 199760000000000000000, 31436921000000000000000],
                [int(12000000000000000000), 95390000000000000000, 14577848000000000000000],
                [int(12000000000000000000), 287110000000000000000, 31931756000000000000000],
                [int(12000000000000000000), 320810000000000000000, 34777259000000000000000],
                [int(9000000000000000000), 227730000000000000000, 1222114000000000000000],
                [int(8000000000000000000), 15450000000000000000, 16859074000000000000000]
            ];
        return constants;
    }

    constructor(address creator) ERC721SingleCreatorExtension(creator) {}

    function supportsInterface(bytes4 interfaceId) public view virtual override(DynamicArweaveHash, IERC165) returns (bool) {
        return interfaceId == type(IERC721CreatorExtensionApproveTransfer).interfaceId || super.supportsInterface(interfaceId);
    }

    function mint(address to) public virtual onlyOwner returns(uint256) {
        require(_baseTokenId == 0, "Already minted");
        _baseTokenId = _mint(to);
        return _baseTokenId;
    }

    function setApproveTransfer(address creator, bool enabled) public override onlyOwner {
        IERC721CreatorCore(creator).setApproveTransferExtension(enabled);
    }

    function approveTransfer(address, address, uint256) public override returns (bool) {
        require(msg.sender == _creator, "Invalid requester");
        _seasonOnLastTransfer = _currentSeason();
        return true;
    }

    function tokenURI(address, uint256 tokenId) external view override returns (string memory) {
        return string(abi.encodePacked(
            'data:application/json;utf8,{"name":"',_getName(),
                                         '", "description":"',_getDescription(),
                                         '", "image":"https://arweave.net/',_getImageHash(tokenId),
                                         '", "animation_url":"https://arweave.net/',_getAnimationHash(tokenId),
                                         '", "attributes":[',
                                            _wrapTrait("Artist", "Anna Ridler"),
                                         ']',
                                         '}'));
    }


    function _getName() internal pure override returns(string memory) {
        return "Anno oxypetalum";
    }

    function _getDescription() internal pure override returns(string memory) {
        return 
            "Anno oxypetalum (literally \\\"the year of the pointed petals\\\") is a clock made of the flowers of "
            "night-blooming cacti, tracking the amount of light across one year. Each flower represents 10 minutes, "
            "each second approximately 2 days. Over the course of the piece the flowers fade in and out as the light "
            "ebbs and flows across the seasons. The timing of dawn and dusk is precisely accurate for London starting "
            "at the 2021 winter solstice. A third level of time is also incorporated into the work - when the piece "
            "is sold, the smart contract is programmed to start the video at the beginning of the season in which it "
            "was sold. The smart contract is able to accurately compute the solstices and equinoxes until the year "
            "3000. It is inspired by plants\' chrono-biological clocks, by which they bloom and close at fixed times "
            "of day. Plants behave this way regardless of external stimuli -  a night-blooming cactus, for example, "
            "will only bloom at night, even if it is exposed to darkness during the daytime and light at night; a "
            "morning glory moved into permanent darkness will still flower in the mornings. The work call backs to "
            "Carl Linnaeus\' idea of a horologium florae or floral clock, proposed in his Philosophia Botanica in "
            "1751 after observing the phenomenon of certain flowers opening and closing at set times of the day, "
            "and harkens back to an earlier, medieval way of delineating time according to the amount of daylight "
            "present, before the advent of modern timekeeping.";
    }

    function _getImageHash(uint256) internal view override returns(string memory) {
        return imageArweaveHashes[_seasonOnLastTransfer];
    }

    function _getAnimationHash(uint256) internal view override returns(string memory) {
        return animationArweaveHashes[_seasonOnLastTransfer];
    }

    function _wrapTrait(string memory trait, string memory value) internal pure returns(string memory) {
        return string(abi.encodePacked(
            '{"trait_type":"',
            trait,
            '","value":"',
            value,
            '"}'
        ));
    }

    function _currentSeason() private view returns (uint8) {
        int256 year = _timestampToYear(block.timestamp);
        int256 month = _timestampToMonth(block.timestamp);
        int256 julianDay = _timestampToJulianDay(block.timestamp);
        int256[3][24] memory terms = _termsConstants();

        if (month < 3) {
            return _WINTER;
        } else if (month == 3) {
            return julianDay < _springEquinox(year, terms) ? _WINTER : _SPRING;
        } else if (month < 6) {
            return _SPRING;
        } else if (month == 6) {
            return julianDay < _summerSolstice(year, terms) ? _SPRING : _SUMMER;
        } else if (month < 9) {
            return _SUMMER;
        } else if (month == 9) {
            return julianDay < _fallEquinox(year, terms) ? _SUMMER : _FALL;
        } else if (month < 12) {
            return _FALL;
        }
        return julianDay < _winterSolstice(year, terms) ? _FALL : _WINTER;
    }

    function _springEquinox(int256 year, int256[3][24] memory terms) private view returns (int256) {
        return _eventJulianDay(year - 2000000000000000000000, _springConstants(), terms);
    }

    function _summerSolstice(int256 year, int256[3][24] memory terms) private view returns (int256) {
        return _eventJulianDay(year - 2000000000000000000000, _summerConstants(), terms);
    }

    function _fallEquinox(int256 year, int256[3][24] memory terms) private view returns (int256) {
        return _eventJulianDay(year - 2000000000000000000000, _fallConstants(), terms);
    }

    function _winterSolstice(int256 year, int256[3][24] memory terms) private view returns (int256) {
        return _eventJulianDay(year - 2000000000000000000000, _winterConstants(), terms);
    }

    function _eventJulianDay(int256 year, int256[5] memory eventConstants, int256[3][24] memory terms) private view returns (int256) {
        int256 J0 = _horner(year.mul(1000000000000000), eventConstants);
        int256 T = _J2000Century(J0);
        int256 W = _D2R.mul(T).mul(35999373000000000000000) - _D2R.mul(2470000000000000000);
        int256 dL = 1000000000000000000 + Trigonometry.cos(uint(W)).mul(33400000000000000) + Trigonometry.cos(uint(W.mul(2000000000000000000))).mul(700000000000000);
        int256 S = 0;
        for (uint256 i = 24; i > 0; i--) {
            int256[3] memory t = terms[i-1];
            S += t[0].mul(Trigonometry.cos(uint((t[1] + T.mul(t[2])).mul(_D2R))));
        }
        return J0 + S.div(dL).mul(10000000000000);
    }

    function _horner(int256 x, int256[5] memory c) private pure returns (int256) {
        uint256 i = c.length - 1;
        int256 y = c[i];
        while (i > 0) {
            i--;
            y = y.mul(x) + c[i];
        }
        return y;
    }

    function _J2000Century(int256 jde) private pure returns (int256) {
        return (jde - _JULIAN_2000).div(_JULIAN_CENTURY);
    }

     function _timestampToYear(uint256 timestamp) private pure returns (int256) {
        return PRBMathSD59x18.fromInt(int(BokkyPooBahsDateTimeLibrary.getYear(timestamp)));
    }

    function _timestampToMonth(uint256 timestamp) private pure returns (int256) {
        return int(BokkyPooBahsDateTimeLibrary.getMonth(timestamp));
    }

    function _timestampToJulianDay(uint256 timestamp) private pure returns (int256) {
        return PRBMathSD59x18.fromInt(int(timestamp)).div(_DAY_IN_SECONDS) + _JULIAN_EPOCH;
    }
}