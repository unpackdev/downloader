// contracts/SVGGenerator.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./StringLib.sol";
import "./DateUtils.sol";

contract FireGenerator {

    string constant GROUP_START = "<g>";
    string constant GROUP_END = "</g>";
    string constant EMPTY = "";

    //<body>
    //  <signsAndCuspsAndPlanetRelations>
    //     <signLines>
    //     </signLines>
    //     <signTexts>
    //     </signTexts>
    //     <cuspsAndPlanetRelations>
    //     </cuspsAndPlanetRelations>
    //  </signsAndCuspsAndPlanetRelations>
    //  <fire>
    //  </fire>
    //  <circles>
    //  </circles>
    //  <planets> 
    //  </planets>
    //  <centralTexts>
    //  </centralTexts>
    //</body>

    //sign lines
    string constant signLines = 
    '<line x1="942.9036" y1="691.8807" x2="996.0295" y2="706.1158" stroke-width="1"/>'
    '<line x1="942.9036" y1="508.1192" x2="996.0295" y2="493.8841" stroke-width="1"/>'
    '<line x1="851.0229" y1="348.9770" x2="889.9137" y2="310.0862" stroke-width="1"/>'
    '<line x1="691.8807" y1="257.0963" x2="706.1158" y2="203.9704" stroke-width="1"/>'
    '<line x1="508.1192" y1="257.0963" x2="493.8841" y2="203.9704" stroke-width="1"/>'
    '<line x1="348.9770" y1="348.9770" x2="310.0862" y2="310.0862" stroke-width="1"/>'
    '<line x1="257.0963" y1="508.1192" x2="203.9704" y2="493.8841" stroke-width="1"/>'
    '<line x1="257.0963" y1="691.8807" x2="203.9704" y2="706.1158" stroke-width="1"/>'
    '<line x1="348.9770" y1="851.0229" x2="310.0862" y2="889.9137" stroke-width="1"/>'
    '<line x1="691.8807" y1="942.9036" x2="706.1158" y2="996.0295" stroke-width="1"/>'
    '<line x1="851.0229" y1="851.0229" x2="889.9137" y2="889.9137" stroke-width="1"/>'
    '<line x1="508.1192" y1="942.9036" x2="493.8841" y2="996.0295" stroke-width="1"/>';

    string constant signLines_tail = GROUP_END;

    //sign texts
    string constant signTexts = 
    '<text font-size="25" transform="translate(990, 635) rotate(-90)" fill="#ac303e" font-weight="bold" stroke="none">ARIES</text>'
    '<text font-size="25" transform="translate(895, 370) rotate(60)" fill="#e8cc5e" font-weight="bold" stroke="none">TAURUS</text>'
    '<text font-size="25" transform="translate(750, 255) rotate(30)" fill="#026d49" font-weight="bold" stroke="none">GEMINI</text>'
    '<text font-size="25" transform="translate(545, 230) rotate(0)" fill="#2478d2" font-weight="bold" stroke="none">CANCER</text>'
    '<text font-size="25" transform="translate(395, 290) rotate(-30)" fill="#ac303e" font-weight="bold" stroke="none">LEO</text>'
    '<text font-size="25" transform="translate(260, 445) rotate(-60)" fill="#e8cc5e" font-weight="bold" stroke="none">VIRGO</text>'
    '<text font-size="25" transform="translate(210, 565) rotate(90)" fill="#026d49" font-weight="bold" stroke="none">LIBRA</text>'
    '<text font-size="25" transform="translate(235, 750) rotate(60)" fill="#1d81d9" font-weight="bold" stroke="none">SCORPIO</text>'
    '<text font-size="25" transform="translate(335, 895) rotate(30)" fill="#ac303e" font-weight="bold" stroke="none">SAGITTARIUS</text>'
    '<text font-size="25" transform="translate(525, 990) rotate(0)" fill="#e8cc5e" font-weight="bold" stroke="none">CAPRICORN</text>'
    '<text font-size="25" transform="translate(740, 970) rotate(-30)" fill="#026d49" font-weight="bold" stroke="none">AQUARIUS</text>'
    '<text font-size="25" transform="translate(920, 830) rotate(-60)" fill="#2478d2" font-weight="bold" stroke="none">PISCES</text>';

    string constant signTexts_tail = GROUP_END;

    string constant cuspsAndPlanetRelations_tail = GROUP_END;

    string constant fireTemplate =             
    '<g filter="url(#goo)" clip-path="url(#centerCut)" stroke="none" transform="translate(240, 240) scale(0.6)">'
    '<circle class="f1" cy="753" cx="579" r="80" fill="#000000"/>'
    '<circle class="f2" cy="751" cx="622" r="80" fill="#000000"/>'
    '<circle class="f3" cy="770" cx="648" r="80" fill="#000000"/>'
    '<circle class="f4" cy="755" cx="614" r="80" fill="#000000"/>'
    '<circle class="f5" cy="744" cx="591" r="80" fill="#000000"/>'
    '<circle class="f6" cy="748" cx="572" r="80" fill="#000000"/>'
    '<circle class="f7" cy="746" cx="651" r="80" fill="#000000"/>'
    '<circle class="f8" cy="751" cx="604" r="80" fill="#000000"/>'
    '<circle class="f9" cy="734" cx="595" r="80" fill="#000000"/>'
    '<circle class="f10" cy="743" cx="569" r="80" fill="#000000"/>'
    '<circle class="f11" cy="758" cx="559" r="80" fill="#000000"/>'
    '<circle class="f12" cy="731" cx="632" r="80" fill="#000000"/>'
    '<circle class="f13" cy="737" cx="585" r="80" fill="#000000"/>'
    '<circle class="f14" cy="760" cx="616" r="80" fill="#000000"/>'
    '<circle class="f15" cy="752" cx="630" r="80" fill="#000000"/>'
    '<circle class="r1" cy="850" cx="600" r="90" fill="black"/>'
    '<circle class="r2" cy="850" cx="600" r="80" fill="black"/>'
    '<circle class="r3" cy="850" cx="600" r="80" fill="black"/>'
    '<circle class="r4" cy="850" cx="600" r="70" fill="black"/>'
    '<circle class="r5" cy="850" cx="600" r="60" fill="black"/>'
    '<circle class="r6" cy="850" cx="600" r="80" fill="black"/>'
    '<circle class="r7" cy="850" cx="600" r="70" fill="black"/>'
    '<circle class="r8" cy="850" cx="600" r="80" fill="black"/>'        
    '</g>';
    
    string constant circles_body = 
    "</circle>"
    '<circle cx="600" cy="600" r="430" stroke-width="1" fill="none"/>'
    '<circle cx="600" cy="600" r="420" stroke-width="1" fill="none"/>'
    '<circle cx="600" cy="600" r="410" stroke-width="1" fill="none"/>'
    '<circle cx="600" cy="600" r="400" stroke-width="10" fill="none" stroke-dasharray="1 62">'
    '<animateTransform attributeType="xml" attributeName="transform" type="rotate" from="0 600 600" to="360 600 600" begin="0" dur="60s" repeatCount="indefinite"/>'        "</circle>"
    '<circle cx="600" cy="600" r="355" stroke-width="2" fill="none"/>'
    '<circle cx="600" cy="600" r="230" stroke-width="2" fill="none"/>'
    '<circle cy="600" cx="600" r="85" fill="none" stroke-width="8" />'
    '<circle cy="600" cx="600" r="95" fill="none" stroke-width="2" />'
    ;

    string constant circles_tail = GROUP_END;

    //planets container head
    string constant planets_head = GROUP_START;

    //planets container tail
    string constant planets_tail = GROUP_END;
       
    string constant body_tail = GROUP_END; 

    

    function toHexString(uint24 number)
        private
        pure
        returns (string memory str)
    {
        bytes memory HEX = "0123456789ABCDEF";
        bytes memory wholeNumber = new bytes(6);
        for (uint256 i = 0; i < 6; i++) {
            uint256 c = (number >> (4 * i)) & 0xF;
            //c will be between 0 and 15
            wholeNumber[5 - i] = HEX[c];
        }
        str = string(wholeNumber);
    }

    function replace(string memory _str, string memory _replacement)
        private
        pure
        returns (string memory res)
    {
        bytes memory _strBytes = bytes(_str);
        bytes memory pattern = bytes("#0");
        bytes memory _replacementBytes = bytes(_replacement);
        require(_replacementBytes.length == 6, _replacement);
        for (uint256 i = 1; i < _strBytes.length; i++) {
            if (_strBytes[i] == pattern[1]&& _strBytes[i-1] == pattern[0]) {
                for (uint256 j = 0; j < 6; j++) {
                    _strBytes[i + j] = _replacementBytes[j];
                }
                i += 6;
            }
        }
        res = string(_strBytes);
    }

    function pickValueFromArrayByGenAndElement(string[5] memory arraySize5, bool isGen0, ElementType elementType) private pure returns (string memory) {
        require(arraySize5.length == 5, "arraySize5's length is not 5");
        if (isGen0) {
            if (elementType == ElementType.FIRE) {
                return arraySize5[1];
            } else if (elementType == ElementType.EARTH) {
                return arraySize5[2];
            } else if (elementType == ElementType.WATER) {
                return arraySize5[3];
            } else /**if (elementType == ElementType.WIND)*/ {
                return arraySize5[4];
            }
        } else /**if (!isGen0)*/ {
            return arraySize5[0];
        }
    }
    
    function drawSignsAndCuspsInOnGroup(bool isGen0, ElementType elementType, string memory cusps, string memory planetRelationLines) private pure returns (string memory) {
        string[5] memory signsAndCuspsAndPlanetRelations_head = [
            EMPTY,
            '<g filter="url(#light3)">',
            EMPTY,
            EMPTY,
            EMPTY
        ];

        string[5] memory signsAndCuspsAndPlanetRelations_tail = [EMPTY, GROUP_END, EMPTY, EMPTY, EMPTY];

        return string(abi.encodePacked(
            pickValueFromArrayByGenAndElement(signsAndCuspsAndPlanetRelations_head, isGen0, elementType), 
            drawSignLinesInGroup(isGen0, elementType), 
            drawSignTextInGroup(isGen0, elementType), 
            drawCuspsAndPlanetRelationsInGroup(isGen0, elementType, cusps, planetRelationLines), 
            pickValueFromArrayByGenAndElement(signsAndCuspsAndPlanetRelations_tail, isGen0, elementType)
        ));
    }

    function drawSignLinesInGroup(bool isGen0, ElementType elementType) private pure returns (string memory) {
        string[5] memory signLines_head = [
            GROUP_START,
            '<g filter="url(#light2)">',
            GROUP_START,
            GROUP_START,
            GROUP_START
        ];
        return string(abi.encodePacked(
            pickValueFromArrayByGenAndElement(signLines_head, isGen0, elementType), 
            signLines,
            signLines_tail
        ));
    }

    function drawSignTextInGroup(bool isGen0, ElementType elementType) private pure returns (string memory) {
        string[5] memory signTexts_head = [
            GROUP_START,
            GROUP_START,
            GROUP_START,
            '<g><circle cx="600" cy="600" r="382" stroke-width="55" stroke="rgba(79,179,191,0.2)" fill="none" />',
            GROUP_START
        ];
        return string(abi.encodePacked(
            pickValueFromArrayByGenAndElement(signTexts_head, isGen0, elementType), 
            signTexts,
            signTexts_tail
        ));  
    }

    function drawCuspsAndPlanetRelationsInGroup(bool isGen0, ElementType elementType, string memory cusps, string memory planetRelationLines) private pure returns (string memory) {
        string[5] memory cuspsAndPlanetRelations_head = [
            GROUP_START,
            '<g filter="url(#light2)">',
            GROUP_START,
            GROUP_START,
            GROUP_START
        ];
        return string(abi.encodePacked(
            pickValueFromArrayByGenAndElement(cuspsAndPlanetRelations_head, isGen0, elementType), 
            cusps,
            planetRelationLines,
            cuspsAndPlanetRelations_tail
        ));
    }

    function completeChartBody(GenAndElement memory genAndElement, ParamsPart2 memory paramsPart2) public pure returns (string memory) {
        string[5] memory body_head = [
            '<g fill="url(#goldBody)" stroke="url(#goldBody)">',
            '<g stroke="#e37da2" fill="#e37da2">',
            '<g stroke="url(#gradient)" fill="url(#gradient)">',
            '<g stroke="#4fb3bf" fill="#4fb3bf">',
            '<g stroke="url(#gradient)" fill="url(#gradient)">'
        ];
        bool isGen0 = genAndElement.isGen0;
        ElementType elementType = genAndElement.elementType;
        string memory originBodyHead = pickValueFromArrayByGenAndElement(body_head, isGen0, elementType);
        string memory bodyHead = replaceThemeColor(isGen0, elementType, paramsPart2.month, paramsPart2.day, originBodyHead);
        return string(abi.encodePacked(
            bodyHead,
            drawSignsAndCuspsInOnGroup(isGen0, elementType, genAndElement.cuspsBody, paramsPart2.relationLines),
            drawFire(genAndElement.planets),
            drawCircles(isGen0, elementType),
            drawPlanets(genAndElement.planetsBody),
            drawCentralTexts(paramsPart2.centralText),
            body_tail
        ));
    }

    function drawFire(uint16[] memory planets) private pure returns (string memory) {
        //15deg=0.2618
        //FIRE red, EARTH yellow, WIND green, WATER blue
        uint16 red = 0;
        uint16 green = 0;
        uint16 blue = 0;
        uint8[6] memory index = [10, 0, 1, 2, 3, 4];
        for (uint256 i = 0; i < index.length; i++) {
            ElementType elementType = judgeElementTypeByPlanetDegree(planets[index[i]]);
            if (elementType == ElementType.FIRE) {
                red += 43;// 255/6
            } else if (elementType == ElementType.EARTH) {
                red += 43;
                green += 43;
            } else if (elementType == ElementType.WIND) {
                green += 43;
            } else /** if (elementType == ElementType.WATER)*/ {
                blue += 43;
            }
        }
        red = red > 255 ? 255 : red;
        green = green > 255 ? 255 : green;
        blue = blue > 255 ? 255 : blue;
        uint24 color = red * 65536 + green * 256 + blue;
        string memory hexColor = toHexString(color);
        return replace(fireTemplate, hexColor);
    }

    function drawCircles(bool isGen0, ElementType elementType) private pure returns (string memory) {
        string[5] memory circles_head = [
            GROUP_START,
            '<g filter="url(#light2)">',
            GROUP_START,
            GROUP_START,
            GROUP_START
        ];
        string[5] memory circle_first = [
            '<circle cx="600" cy="600" r="450" stroke-width="15" fill="none">''<animateTransform attributeType="xml" attributeName="transform" type="rotate" from="0 600 600" to="360 600 600" begin="0" dur="5s" repeatCount="indefinite"/>',
            '<circle cx="600" cy="600" r="450" stroke-width="15" fill="none">''<animateTransform attributeType="xml" attributeName="transform" type="rotate" from="0 600 600" to="360 600 600" begin="0" dur="5s" repeatCount="indefinite"/>',
            '<circle cx="600" cy="600" r="450" stroke-width="15" fill="none">''<animateTransform attributeType="xml" attributeName="transform" type="rotate" from="0 600 600" to="360 600 600" begin="0" dur="5s" repeatCount="indefinite"/>',
            '<circle cx="600" cy="600" r="450" stroke-width="15" fill="none" stroke-dasharray="260 20">''<animateTransform attributeType="xml" attributeName="transform" type="rotate" from="0 600 600" to="360 600 600" begin="0" dur="30s" repeatCount="indefinite" />',
            '<circle cx="600" cy="600" r="450" stroke-width="15" fill="none">''<animateTransform attributeType="xml" attributeName="transform" type="rotate" from="0 600 600" to="360 600 600" begin="0" dur="5s" repeatCount="indefinite"/>'
        ];
        return string(abi.encodePacked(
            pickValueFromArrayByGenAndElement(circles_head, isGen0, elementType),
            pickValueFromArrayByGenAndElement(circle_first, isGen0, elementType),
            circles_body,
            circles_tail
        ));
    }

    function drawPlanets(string memory planets) private pure returns(string memory) {
        return string(abi.encodePacked(
            planets_head,
            planets,
            planets_tail
        ));
    }

    function drawCentralTexts(string memory centralText) private pure returns(string memory) {
        return centralText;
    }

    function genThemeColorReplacement(bool isGen0, ElementType elementType, uint16 month, uint16 day) private pure returns(string memory) {
        bytes memory birthdayColorInHex = bytes("003c645f0078095b00f0014500c003390140032c01460b280115640500413732004b421f004a252900592c4a00612a560083322b004b23290098641100493d5b00a66416007d1925004e3136009d382400c5484f00b8642300c9463600c3641c00de45130031364d003a643200336432004347320070262d00473c5100e5282a013c283900eb3b2001411c4901072a2301372251013a2138015c2f1d015b503d01544d4101524134015842340056042300361d2300cc474900ce274b00d51526000e321d00de361d002a645b00376450002d6035003664400048304f00560e5a0071104e003f183600422d1c006427270010534e0016575f015a4b5300024f3e015e632900005462000f524c01674c4f00064f5201665039002b4f5100004b3e0010533b00074d3301674d2f0139224a011d1c3301271b31011c4c1a012b152d00f41f4a013e2739010c1e2f012e252b01593130006f21540094245200af224b00be2e4c00c6553e0034474c015b4e6100155759015451500153404700da314400ca343d0046385c00831f38002b604100284f34001f2c57002c133800870a5c00f0013b006e085500ca09520000003601180227000c042000473f4000473d4b00883c29008b2843007128490084263e006c2b3a009d642200a9641d00b7642300b7642500b664200099641e00b76316009c610d00bc315300c9574600dd2932008e241e007b3d2c003d47580041453b003d4c3b00373f48003451190035304200353e28002932250000001c0043071c009b2544008d2029008c5e1400895c0e0099201600205b5000275c49002c643100183f2c000e1b260005225700024d4b011a1c4801031e3201244019003c425b004a3a51003a3849006f0d2c00333c1a00376453003864430034643100285f4300306432002f395e0016574e0025343401633a4a00081a24002b6049001f563d0026643000083727000a2b210160545601573d460156503f01604c4e0155632900c5425400d6313700c4641e00ce642400d5641c00c03f3600bd282d00bb313900bd631700c2641b001e0c6100d42e3a00dc243300d35e1b00dd3b180012565f01381f3a00db314800e61e3801294e1e00055550001c4740000d3337016531310165412c0161534e01503b450166352d015c2f260000001a00c2642400b4642000ca5e1900ca2e3100c5642a00c83a3500cc642100d9452600d2641e00d4621c00d05c1c00df2e1700db2c2c0125261a00f2154700b92f4300c64d3d00326436003964510039644b00235b3f00236431002164300010433d0023644c00296432002a3e3000282e3e0023401e00c5464e00c92c3800d52b3300d4352d012e43110077203d008f2c2600ad62140096641500a96411009d640c00b8293c00b6243900b9641500ef361400a0640a00ed2f1e00f0271a001b3332001a641c000a2c360078203e00cf1f50010a063100396458004c3356003d474e003b4e4100394336001f62470014583d000c563f00094d2f01534e3e012a24290012533d000d4c200012543900125533000e2a3f001b283a001e252b000e382e00173f1e00253131000c2a340012481e000a262000113d180015472b0030642e001c0e52003c054e00f0044600000031015f093b00a50324002d3b3800462b1f00130b3a00a2182b00b415230118022b00170c24015a182a011b1f5000172f3500251f2a00182d180012071e0147071d0025644b00226344001c5c36000e3c340021372400256454002f264e005a013f002c3416002c34130000575601473744000921390165253400ff043200471a4b00581549002c113700d2013100a008190015614e00205b580020422b001e1f2a0034101d0023214d00212a41000c451f002b102000330f1b00293d4b00313c4c0034402800252536001f4129000d5c530008584b000856460019642f0163223600125f57002a40520008213900254140015a0b29013e295001071e3c010b282b01042210012e1d28002d503400421140002b4d2e0029193c001c432a00bd6428");
        if(!isGen0) {
            return EMPTY;
        } else {
            uint256 index = DateUtils.getDayIndexInYear(2012, month, day);

            (uint256 H, uint256 S, uint256 L) = StringLib.parseCompressedHSL(birthdayColorInHex, index);
            string memory birthdayColor = string(abi.encodePacked("hsl(", StringLib.uintToString(H), ",", StringLib.uintToString(S), "%,", StringLib.uintToString(L), "%)"));
            if(elementType == ElementType.FIRE || elementType == ElementType.WATER) {
                return birthdayColor;
            } else {
                if (elementType == ElementType.EARTH) {
                    H = (H + 360 - 90) % 360; /** maintain H > 30, normally minus 90 */
                    string memory res = string(abi.encodePacked(
                        '<stop offset="0%" stop-color="', birthdayColor, '" />'
                        '<stop offset="100%" stop-color="hsl(', StringLib.uintToString(H), ",", StringLib.uintToString(S), "%,", StringLib.uintToString(L), '%)" />'
                    ));
                    return res;
                } else /** if (elementType == ElementType.WIND) */ {
                    S = (S + 30) % 100;
                    L = (L + 100 - 30) % 100; 

                    string memory line_70 = string(abi.encodePacked(
                        '<stop offset="100%" stop-color="hsl(', StringLib.uintToString(H), ",", StringLib.uintToString(S), "%,", StringLib.uintToString(L), '%)" />'
                    ));
                    string memory line_100 = line_70;
                    string memory res = string(abi.encodePacked(
                        '<stop offset="0%" stop-color="', birthdayColor, '" />',
                        line_70, line_100
                    ));
                    return res; 
                }
            }
        }
    }

    function replaceThemeColor(bool isGen0, ElementType elementType, uint16 month, uint16 day, string memory _str) public pure returns (string memory) {
        string[5] memory colorPatternToReplace = [
            EMPTY, 
            "#e37da2", 
            '<stop offset="0%" stop-color="hsl(211,54.4%,62.2%)" /><stop offset="100%" stop-color="hsl(121,54.4%,62.2%)" />', 
            "#4fb3bf", 
            '<stop offset="0%" stop-color="hsl(49,26%,63%)" />''<stop offset="70%" stop-color="hsl(49,56%,43%)" />''<stop offset="100%" stop-color="hsl(49,56%,43%)" />'
        ];
        string memory pattern = pickValueFromArrayByGenAndElement(colorPatternToReplace, isGen0, elementType);
        string memory replacement = genThemeColorReplacement(isGen0, elementType, month, day);
        return bytes(pattern).length == 0 ? _str : StringLib.replace(_str, pattern, replacement);    
    }

    enum ElementType {
        FIRE, EARTH, WIND, WATER
    }

    struct GenAndElement {
        bool isGen0;
        ElementType elementType;
        string cuspsBody;
        string planetsBody;
        uint16[] planets;
    }

    struct ParamsPart2 {
        string relationLines;
        string centralText;
        uint16 month;
        uint16 day;
    }

    /**
    ElementType's 
     */
    function judgeElementTypeByPlanetDegree(uint16 planetRadian) public pure returns (ElementType) {
        uint16 degree30InRadian = 5236;
        uint16 deg15InRadian = 2618;
        uint16 signIndex = (planetRadian + deg15InRadian) / degree30InRadian;
        if (signIndex == 0 || signIndex == 4 || signIndex == 8) {
            return ElementType.FIRE;
        } else if (signIndex == 1 || signIndex == 5 || signIndex == 9) {
            return ElementType.EARTH;
        } else if (signIndex == 2 || signIndex == 6 || signIndex == 10) {
            return ElementType.WIND;
        } else /** if (signIndex == 3 || signIndex = 7 || signIndex == 11) */ {
            return ElementType.WATER;
        }
    }
}