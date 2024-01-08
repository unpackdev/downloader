pragma solidity 0.8.6;

import "ERC721.sol";
import "Ownable.sol";
import "ReentrancyGuard.sol";
import "Strings.sol";
import "Base64.sol";

/**
       //////////////////   \\\            ///    ///////////\\\    ///         \\\    //////////////   ////////////\\\
       /////////////////     \\\          ///    /////////////\\\   ///          ///   /////////////    /////////////\\\
       ///          ///       \\\        ///     ///          ///   ///          ///   ///              ///          ///
       ///         ///         \\\      ///      ///         ///    ///          ///   ///              ///         ///
       ///        ///           \\\    ///       ///        ///     ///          ///   ///              ///        ///
       ///                       \\\  ///        ///       ///      ///          ///   ///              ///       ///
       ///                        \\v///         ////////////       ////////////////   //////////////   ////////////
       ///                         \///          ///////////        ////////////////   /////////////    ///////////
       ///         \\\             ///           ///                ///          ///   ///              ///      \\\
       ///          \\\           ///            ///                ///          ///   ///              ///       \\\
       ///           \\\         ///             ///                ///          ///   ///         ///  ///        \\\
       ///\\\\\\\\\\\\\\\       ///              ///                ///          ///   //////////////   ///         \\\
       ///\\\\\\\\\\\\\\\\     ///               ///                ///         ///    /////////////    ///          \\\

       "Personal worth is not what a person is worth
       I can give a dollar to every person on Earth"
       - Kanye West, DONDA, Pure Souls

       "So nerdy but the flow wordy
       Brain-freezin' with the flow slurpie"
       - Childish Gambino, Sway in the Morning, Freestyle

       "Don't get offended by this, but that's the market y'all missed
       That's the target I'll hit and that's the heart of my pitch
       I wanna do this whole thing different"
       - Lil Dicky, Professional Rapper, Professional Rapper

       CYPHER ON-CHAIN
       2021
**/

contract Cypher is ERC721, ReentrancyGuard, Ownable {
    uint256 public totalSupply;

    // Track, album, bars length
    uint256 public constant trackLength = 20;
    uint256 public constant albumLength = 10;
    uint256 public constant maxSupply = trackLength*albumLength;
    uint256 private constant barsPerBlock = 4;
    uint256 private immutable maxCharactersPerBar = 40;
    uint256 private immutable minCharactersPerBar = 10;
    
    // Time related constaints
    uint256 public blockStartTime;
    uint256 public albumStartTime;
    uint256 public blockInterval = 5*60;
    uint256 public trackInterval = 1 days + 300;

    // Storage of bars and writers
    mapping(uint256 => string) public tokenIdToBars;
    mapping(uint256 => address) public tokenIdToWriter;

    constructor() public ERC721("Cypher on-chain: EP", "BARS") Ownable() { 
    }

    /******************/
    /*   MINT LOGIC   */
    /******************/
    function mint(string memory user_bars) payable external nonReentrant {
        require(totalSupply < maxSupply, 'Cypher: all blocks minted');
        require(msg.value == 0.01 ether, "Cypher: 0.01 ETH to mint");
        require(balanceOf(msg.sender) <= 2, "Cypher: max 3 per wallet");
        require(block.timestamp >= blockStartTime + blockInterval, "Cypher: next block not yet available");
        require(block.timestamp >= (albumStartTime + (totalSupply / trackLength * trackInterval)), 'Cypher: next track not yet available.');
        
        if(totalSupply == 0){
            require(msg.sender == owner(), "Cypher: only the owner can mint the first block in the first track.");
            albumStartTime = block.timestamp;
        } else {
            require(tokenIdToWriter[totalSupply] != msg.sender, "Cypher: same wallet can't mint twice in a row");
        }

        _cypherValidations(user_bars);
        _mint(msg.sender, ++totalSupply);
        
        tokenIdToBars[totalSupply] = user_bars;
        tokenIdToWriter[totalSupply] = msg.sender;
        blockStartTime = block.timestamp;
    }

    function _cypherValidations(string memory user_bars) internal view {
        bytes memory _bytes = abi.encodePacked(bytes(user_bars), '\n');

        uint256 barCount;
        uint256 lastBarStart;
        uint256 lastLastBarStart;
        uint256 lastBarEnd;
        bool isSpaceOrNewline = false;
        bool prevPrevIsSpaceOrNewLine = true;
        bool prevIsSpaceOrNewline = true;
        bool prevIsComma = false;
        bytes1 char;
        uint8 charInt;

        // To save gas, all validation happens in the same for loop
        for (uint256 i = 0; i < _bytes.length; i++){
            char = _bytes[i];
            charInt = uint8(char);
            isSpaceOrNewline = (charInt == 32 || charInt == 10);

            // Validation: No special characters
            if (! (isSpaceOrNewline || charInt == 44
            || (charInt >= 97 && charInt <= 122) 
            || (charInt >= 65 && charInt <= 90))
                ) {
                require(false, "Cypher: invalid characters");
            }

            // Validation: No adjacent empty characters
            if((isSpaceOrNewline) && (prevIsSpaceOrNewline)){
                require(false, "Cypher: adjacent empty chars");
            }

            if(prevIsComma && !(charInt == 32 && !prevPrevIsSpaceOrNewLine)){
                require(false, "Cypher: comma must be followed by a space and preceded by letters");
            }

            prevIsComma = charInt == 44;

            // Reached new bar: Check per-bar validations
            if (charInt == 10) {
                if (barCount == 0 && totalSupply % trackLength != 0) {
                    require(_rhymeCheckAcrossTokens(totalSupply, _bytes, 0, i-1), "Cypher: first bar must rhyme with prior block's last bar");
                }

                if(barCount == 1 || barCount == 3){
                    require(strictRhymes(_bytes, lastLastBarStart, lastBarEnd-1, _bytes, lastBarStart, i-1), "Cypher: first two bars and last two bars must rhyme");
                }

                barCount = barCount + 1;

                require(i - lastBarStart >= minCharactersPerBar, "Cypher: need >= 10 characters in each bar");
                require(i - lastBarStart <= maxCharactersPerBar, "Cypher: need <= 40 characters in each bar");
                
                lastLastBarStart = lastBarStart;
                lastBarEnd = i;
                lastBarStart = i+1;
            }
            prevPrevIsSpaceOrNewLine = prevIsSpaceOrNewline;
            prevIsSpaceOrNewline = isSpaceOrNewline;
        }

        require(barCount == barsPerBlock, "Cypher: there must be four bars in a block");
    }

    function setBlockInterval(uint256 newInterval) external onlyOwner {
        blockInterval = newInterval;
    }

    function setTrackInterval(uint256 newInterval) external onlyOwner {
        trackInterval = newInterval;
    }

    function withdrawAll() public payable onlyOwner {
        require(payable(_msgSender()).send(address(this).balance));
    }

    function _isVowel(bytes1 char) internal view virtual returns (bool) {
        return (uint8(char) == 97 || uint8(char) == 101 || uint8(char) == 105 || uint8(char) == 111 || uint8(char) == 117 || uint8(char) == 121 || uint8(char) == 65 || uint8(char) == 69 || uint8(char) == 73 || uint8(char) == 79 || uint8(char) == 85 || uint8(char) == 89);
    }

    function lower(bytes1 char) internal view virtual returns (bytes1){
        if(uint8(char) >= 65 && uint8(char) <= 90) {
            return bytes1(uint8(char) + 32);
        } else {
            return char;
        }
    }

    function _rhymeCheckAcrossTokens(uint256 tokenId, bytes memory user_bars, uint256 start, uint256 end) internal view virtual returns (bool) {
        string memory prevBarsString = tokenIdToBars[tokenId];
        bytes memory prev_bars = bytes(prevBarsString);
        uint256 index = prev_bars.length-1;

        while(index >= 0){
            if(prev_bars[index] == '\n'){
                break;
            }
            index -= 1;
        }

        return strictRhymes(prev_bars, index+1, prev_bars.length-1, user_bars, start, end);
    }

    function strictRhymes(bytes memory s1, uint256 s1Start, uint256 s1End, bytes memory s2, uint256 s2Start, uint256 s2End) internal view returns (bool) {
        uint256 s1Ind = s1End;
        uint256 s2Ind = s2End;
        bool vowelSeen = false;
        uint256 consecutive = 0;
        uint256 checked = 0;
        uint256 vowelCt = 10000;
        bool consec = true;

        while(s1Ind >= s1Start && s2Ind >= s2Start){
            bytes1 s1Char = s1[s1Ind];
            bytes1 s2Char = s2[s2Ind];

            if(uint8(s1Char) == 32 || uint8(s2Char) == 32){
                break;
            }

            if(!vowelSeen || vowelSeen && checked < 2) {
                if(lower(s1Char) == lower(s2Char) && consec){
                    consecutive += 1;
                } else {
                    consec = false;
                }
            }

            vowelSeen = vowelSeen || _isVowel(s1Char) || _isVowel(s2Char);

            if(vowelSeen && vowelCt == 10000){
                vowelCt = checked;
            }

            checked += 1;
            
            if(s1Ind == s1Start || s2Ind == s2Start){
                break;
            }
            
            s1Ind -=1;
            s2Ind -=1; 
        }

        if(!vowelSeen || vowelCt == 0){
            return consecutive >= 2 || consecutive >= checked;
        } else {
            return consecutive > vowelCt || consecutive >= checked;
        }
    }

    /*************/
    /* TOKEN URI */
    /*************/
    function tokenURI(uint256 tokenId) public override view returns(string memory) {
        string memory lyric = tokenIdToBars[tokenId];
        string[barsPerBlock] memory bars = splitOnChar(lyric, '\n');
        
        address writer = tokenIdToWriter[tokenId];
        string memory writerAscii = toAsciiString(writer);
        uint256 colorScheme = trackColor(tokenId);

        bytes memory tokenName;
        bytes memory jsonEscapedBars;
        for(uint256 i = 0; i < barsPerBlock; i++){
            tokenName = abi.encodePacked(tokenName, substring(bytes(bars[i]), 0, firstCharIndex(bars[i], ' ')), ' ');
            jsonEscapedBars = abi.encodePacked(jsonEscapedBars, bars[i], i != barsPerBlock - 1 ? '\\n' : '');
        }

        bytes memory jsonSvg = abi.encodePacked(
            '{"name":"',
            '#',
            Strings.toString(tokenId),
            ' - ',
            string(tokenName),
            '", "description":"Cypher on-chain is a smart contract that conducts a rap cypher on Ethereum. Cypher EP is its first collectively written album with 10 tracks. Each track contains 20 blocks, comprised of 4 bars each. A block is an NFT.", ',
            '"bars": "', jsonEscapedBars, '", '
        );

        jsonSvg = abi.encodePacked(jsonSvg, '"attributes": [{',
            '"trait_type": "Track", "value":"',
            Strings.toString(trackNumber(tokenId)),
            '"}, {',
            '"trait_type": "Block", "value":"',
            Strings.toString(trackBlockNumber(tokenId)),
            '"}', 
            ',{',
            '"trait_type": "Writer", "value":"0x',
            writerAscii,
            '"}',
            ']',
            ', "image": "'
            'data:image/svg+xml;base64,',
            Base64.encode(svgImage(tokenId, bars, colorScheme, writer, bytes(writerAscii))),
            '"}'
        );

        return string(
                abi.encodePacked(
                    'data:application/json;base64,',
                        Base64.encode(
                            jsonSvg
                        )
                )
            );
    }                 

    function svgImage(uint256 tokenId, string[barsPerBlock] memory bars, uint256 colorScheme, address writer, bytes memory writerAscii) internal view returns (bytes memory){
        bytes memory writerAddr = abi.encodePacked(tokenIdToWriter[tokenId]);
        
        return abi.encodePacked(
                '<svg version="1.1" shape-rendering="optimizeSpeed" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"',
                ' x="0px" y="0px" width="300" height="300" viewBox="0 0 10 10" xml:space="preserve">',
                styles(),
                svgGrid(colorScheme, writer),
                svgText(colorScheme, writer, bars),
                abi.encodePacked('<text x="0" y="1" fill="', 
                    string(abi.encodePacked('hsl(', Strings.toString(colorScheme),',95%,40%)')),
                    '">Track: ', Strings.toString(trackNumber(tokenId)), 
                    ' - Block: ', Strings.toString(trackBlockNumber(tokenId)), '</text>'),
                '</svg>'
            );
    }

    function styles() internal view returns (string memory) {   
        bytes memory styles = abi.encodePacked('<style type="text/css">', 
            'rect{width: 1px; height: 1px;}text{font-size: 0.42px; alignment-baseline:text-after-edge}',
            '.c1{fill:#000000;}.writerText{font-size: 0.25px;}</style>');
        return string(styles);
    }

    function trackColor(uint256 tokenId) public view returns (uint256){
        uint16[10] memory colorSchemes = [180, 160, 36, 72, 96, 0, 206, 270, 288, 312];
        uint256 h = trackNumber(tokenId) - 1;
        return colorSchemes[h];
    }

    function trackNumber(uint256 tokenId) public view returns (uint256){
        return (tokenId-1)/(trackLength) + 1;
    }

    function trackBlockNumber(uint256 tokenId) public view returns (uint256){
        return ((tokenId-1) % trackLength) + 1;
    }

    function svgText(uint256 colorScheme, address writer, string[barsPerBlock] memory bars) internal view returns (string memory) {
        bytes memory lyricSvgs;

        for (uint256 i = 0; i < barsPerBlock; i++){
            lyricSvgs = abi.encodePacked(lyricSvgs, '<text x="0" y="', Strings.toString(i+1+1), '" fill="white">', bytes(bars[i]), '</text>');
        }

        lyricSvgs = abi.encodePacked(lyricSvgs, 
            '<text x="0" y="6" fill="', 
            string(abi.encodePacked('hsl(', Strings.toString(colorScheme),',95%,40%)')),
            '" class="writerText">0x', toAsciiString(writer), '</text>');
        return string(lyricSvgs);
    }

    function svgGrid(uint256 colorScheme, address writer) internal view returns (string memory) {
        bytes memory rectString;

        rectString = abi.encodePacked(
            svgLyricCanvasRow(0),
            svgLyricCanvasRow(1),
            svgLyricCanvasRow(2),
            svgLyricCanvasRow(3),
            svgLyricCanvasRow(4),
            svgLyricCanvasRow(5)
        );
        
        for(uint256 i=0; i < barsPerBlock; i++){
            rectString = abi.encodePacked(rectString, svgSignatureRow(abi.encodePacked(writer), 6+i, colorScheme));
        }

        return string(rectString);
    }

    function svgSignatureRow(bytes memory writer, uint256 rowIdx, uint256 colorScheme) internal view returns (string memory) {
        bytes memory rectString;
        uint256 addrInd = 0;
        uint256 stepSize = 2;

        // parts of color band that have less variance nearby
        if(colorScheme == 206 || colorScheme == 312 || colorScheme == 270 || colorScheme == 0 || colorScheme == 144){
            stepSize = 3;
        } else if (colorScheme == 72 || colorScheme == 96) {
            stepSize = 5;
        } else {

        }

        for(uint256 i=0; i<10; i++){
            if (writer.length != 0){
                uint256 addrOffset = rowIdx >= 6 ? (rowIdx-6)*(10/5) : 0;
                uint256 walletInt;

                if (i % 2 == 0){
                    walletInt = uint(uint8(writer[addrInd + addrOffset] >> 4));
                } else {
                    walletInt = uint(uint8(writer[addrInd + addrOffset] & 0x0f));
                    addrInd += 1;
                }
                rectString = abi.encodePacked(rectString, 
                    '<rect x="', Strings.toString(i), '" y="', Strings.toString(rowIdx), 
                    '" fill="',string(abi.encodePacked('hsl(', Strings.toString(colorScheme + walletInt*stepSize),',95%,40%)')) ,'"></rect>');
            }
        }

        return string(rectString);
    }

    function svgLyricCanvasRow(uint256 rowIdx) internal view returns (string memory) {
        bytes memory rectString;

        for(uint256 i=0; i<10; i++){
            rectString = abi.encodePacked(rectString, '<rect x="', Strings.toString(i), '" y="', Strings.toString(rowIdx), '" class="c1 s"/>');
        }
        return string(rectString);
    }

    function firstCharIndex (string memory base, bytes1 char) internal view virtual returns (uint) {
        bytes memory _bytes = bytes(base);
        uint256 i = 0; 

        while (i < _bytes.length){
            if (_bytes[i] == char) {
                return i;
            }
            i += 1;
        }
        return 0;
    }

    function splitOnChar(string memory lyric, bytes1 char) internal view returns (string[barsPerBlock] memory bars) {
        bytes memory b_lyrics = bytes(lyric);
        uint256 splits = 0;
        uint256 start_index = 0;

        for(uint256 i = 0; i < b_lyrics.length; i++){
            if (b_lyrics[i] == char) {
                bars[splits] = string(substring(b_lyrics, start_index, i));
                splits += 1;
                start_index = i+1;
            }
        }
        bars[barsPerBlock-1] = string(substring(b_lyrics, start_index, b_lyrics.length));

        return bars;
    }    

    function substring(bytes memory in_string, uint256 start_index, uint256 end_index) internal view virtual returns (bytes memory) {
        bytes memory new_str = new bytes(end_index-start_index);
        for(uint256 i = 0; i < end_index-start_index; i++) {
            new_str[i] = in_string[start_index+i];
        }
        return new_str;
    }

    function toAsciiString(address x) internal view returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint256 i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint(uint160(x)) / (2**(8*(19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2*i] = addressChar(hi);
            s[2*i+1] = addressChar(lo);            
        }
        return string(s);
    }

    function addressChar(bytes1 b) internal view returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }
}
