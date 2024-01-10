// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "./Encoding.sol";
import "./Base64.sol";
import "./BokkyPooBahsDateTimeContract.sol";

contract Metadata {
    BokkyPooBahsDateTimeContract dates;
    mapping(uint => string) MAJOR_CHORDS;
    mapping(uint => string) JAZZ_MINOR_CHORDS;
    mapping(uint => string) DIMINISHED_CHORDS;
    constructor(BokkyPooBahsDateTimeContract d) {
        dates = d;

        MAJOR_CHORDS[1] = unicode'Maj7';
        MAJOR_CHORDS[2] = unicode'm7';
        MAJOR_CHORDS[4] = unicode'Maj7 ♯11';
        MAJOR_CHORDS[5] = unicode'7';

        JAZZ_MINOR_CHORDS[1] = unicode'm (Maj7)';
        JAZZ_MINOR_CHORDS[2] = unicode'sus7';
        JAZZ_MINOR_CHORDS[4] = unicode'7 ♯11';
        JAZZ_MINOR_CHORDS[5] = unicode'7 ♭13';

        DIMINISHED_CHORDS[1] = unicode'7 ♭9';
        DIMINISHED_CHORDS[2] = unicode'dim7';
        DIMINISHED_CHORDS[4] = unicode'dim7';
        DIMINISHED_CHORDS[5] = unicode'7 ♭9';

    }

    function getStats(int32[] memory ethPriceData) public pure returns (uint32, uint32, uint, uint) {
        uint sum = 0;
        uint32 hi = 0;
        uint32 lo = type(uint32).max;
        uint numValues = 0;
        for (uint i = 0; i < ethPriceData.length; i++) {
            uint32 price = uint32(ethPriceData[i]);
            sum += uint32(price);

            if (price > 0) {
                if (price > hi) {
                    hi = price;
                }
                if (price < lo) {
                    lo = price;
                }
                numValues++;
            }
        }
        uint mean = 0; 
        uint vari = 0; 
        if (numValues > 0) {
            mean = sum/numValues;
            uint deviations = 0;
            for (uint i = 0; i < ethPriceData.length; i++) {
                if (ethPriceData[i] > 0) {
                    int256 delta = ethPriceData[i] - int32(int256(mean));
                    deviations += uint256(delta*delta);
                }
            }
            vari = deviations/numValues;

        }
        return (hi,lo,mean,vari);
    }

    function getVibeAndChordStrings(int32 open, int32 close, uint mean, uint variance) internal view returns (string memory, string memory, string memory) {
        string memory volaStr = '';
        uint vola = 0;
        uint mode = 0;
        if (mean > 0) {
            vola = 100*variance/mean;
        }
        if (vola < 50) {
            mode = 1;
            volaStr = 'Normal';
        } else if (vola < 75) {
            mode = 2;
            volaStr = 'High';
        } else if (vola < 100) {
            mode = 4;
            volaStr = 'Very high';
        } else {
            mode = 5;
            volaStr = 'Extreme';
        }

        int32 delta = close - open;
        int32 increase = 0;
        if (open > 0) {
            increase = 100*delta/open; /*pct*/
        }
        string memory vibeStr = '';
        string memory chordStr = '';

        if (increase < -5) {
            vibeStr = "DOOM";
            chordStr = DIMINISHED_CHORDS[mode];
        } else if (increase < 5) {
            vibeStr = "HODL";
            chordStr = JAZZ_MINOR_CHORDS[mode];
        } else {
            vibeStr = "MOON";
            chordStr = MAJOR_CHORDS[mode];
        }
        

        return (vibeStr, chordStr, volaStr);
    }

    function getAttributes(int32[] memory ethPriceData, uint fromTimestamp) external view returns (string memory) {
        (uint32 high, uint32 low, uint mean, uint variance) = getStats(ethPriceData);

        int32 open = 0;
        int32 close = 0;
         for (uint i = 0; i < ethPriceData.length; i++) {
            if (open == 0) {
                open = ethPriceData[i];
            }
            if (ethPriceData[i] > 0) {
                close = ethPriceData[i];
            }
        }
            
        (string memory vibeStr, string memory chordStr, string memory volaStr) = getVibeAndChordStrings(open, close, mean, variance); 
        return string(
            abi.encodePacked(
                '[',
                '{',
                    '"display_type": "date",',
                    '"trait_type": "Date (UTC)",',
                    '"value": ', Encoding.uint2str(fromTimestamp),
                '},',
                '{',
                    '"trait_type": "Vibe",',
                    '"value": "', vibeStr, '"',
                '},',
                '{',
                    '"trait_type": "Volatility",',
                    '"value": "', volaStr, '"',
                '},',
                '{',
                    '"trait_type": "Chord",',
                    '"value": "', chordStr, '"',
                '},',
                '{',
                    '"trait_type": "High",',
                    '"value": ', Encoding.uint2str(high),
                '},',
                '{',
                    '"trait_type": "Low",',
                    '"value": ', Encoding.uint2str(low),
                '}',

                ']'
            ));
    }

    function getAnimationUrl(string memory ethPriceDataString, string memory btcPriceDataString) public pure returns (string memory) {
        return string(
                abi.encodePacked(
                    'ar://ef9QIeEVW94Rb-GM_bb-jISEXzp21aLlN9wyhCbxFng/?',
                    // Arweave version of 'https://degenblues.xyz/projects/degen-blues/r?'
                    'ETH=', ethPriceDataString,
                    '&BTC=', btcPriceDataString
                )
            );
    }

    function getNameForTokenId(uint256 tokenId) public pure returns (string memory) {
        if (tokenId == 0) {
            return "Degen Blues Edition Zero";
        } else {
            return string(
                abi.encodePacked(
                    "Degen Blues #",
                    Encoding.uint2str(tokenId)
                )
            );
        }
    }

    function dateToString(uint timestamp) public view returns (string memory) {
        uint year = dates.getYear(timestamp);
        uint month = dates.getMonth(timestamp);
        uint day = dates.getDay(timestamp);

        string memory displayDate = string(
            abi.encodePacked(
                Encoding.uint2str(month), '/', Encoding.uint2str(day), '/', Encoding.uint2str(year)
            ));
        return displayDate;
    }

    function descriptionForTokenId(uint256 tokenId, uint fromTimestamp) external view returns (string memory) {
        string memory displayDate = dateToString(fromTimestamp);

        return (tokenId == 0) ? 
            'Edition Zero is a one-of-a-kind NFT from the Degen Blues connection. The melody is dynamically generated on-chain Ethereum price data from the last 48 hours. Refresh metadata every 30 minutes to hear a fresh melody.' :
            string(
                abi.encodePacked(
                    'Degen Blues is a collection of NFTs dynamically generated from on-chain price data. This melody was generated based on movements of the Ethereum price on ',
                    displayDate,
                    '.'
                )
            );
    }
}