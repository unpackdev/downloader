    // contracts/SVGGenerator.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./FireGenerator.sol";

library FireGenerator2 {
    string constant part0 =
    '<svg xmlns="http://www.w3.org/2000/svg" version="1.1" width="1200" height="1200" id="astro">'
    "<style>"
    ".f1 {"
    "animation: fc1 2s 0.14s cubic-bezier(0.5, 0.07, 0.64, 1) infinite;"
    "}"
    ".f2 {"
    "animation: fc2 2s 0.28s cubic-bezier(0.5, 0.07, 0.64, 1) infinite;"
    "}"
    ".f3 {"
    "animation: fc3 2s 0.42s cubic-bezier(0.5, 0.07, 0.64, 1) infinite;"
    "}"
    ".f4 {"
    "animation: fc4 2s 0.56s cubic-bezier(0.5, 0.07, 0.64, 1) infinite;"
    "}"
    ".f5 {"
    "animation: fc5 2s 0.7s cubic-bezier(0.5, 0.07, 0.64, 1) infinite;"
    "}"
    ".f6 {"
    "animation: fc6 2s 0.84s cubic-bezier(0.5, 0.07, 0.64, 1) infinite;"
    "}"
    ".f7 {"
    "animation: fc7 2s 0.98s cubic-bezier(0.5, 0.07, 0.64, 1) infinite;"
    "}"
    ".f8 {"
    "animation: fc8 2s 1.12s cubic-bezier(0.5, 0.07, 0.64, 1) infinite;"
    "}"
    ".f9 {"
    "animation: fc9 2s 1.26s cubic-bezier(0.5, 0.07, 0.64, 1) infinite;"
    "}"
    ".f10 {"
    "animation: fc10 2s 1.4s cubic-bezier(0.5, 0.07, 0.64, 1) infinite;"
    "}"
    ".f11 {"
    "animation: fc11 2s 1.54s cubic-bezier(0.5, 0.07, 0.64, 1) infinite;"
    "}"
    ".f12 {"
    "animation: fc12 2s 1.68s cubic-bezier(0.5, 0.07, 0.64, 1) infinite;"
    "}"
    ".f13 {"
    "animation: fc13 2s 1.82s cubic-bezier(0.5, 0.07, 0.64, 1) infinite;"
    "}"
    ".f14 {"
    "animation: fc14 2s 1.96s cubic-bezier(0.5, 0.07, 0.64, 1) infinite;"
    "}"
    ".f15 {"
    "animation: fc15 2s 2.1s cubic-bezier(0.5, 0.07, 0.64, 1) infinite;"
    "}"
    ".r1 {"
    "animation: fr1 2s 0.5s cubic-bezier(0.5, 0.07, 0.64, 1) infinite;"
    "}"
    ".r2 {"
    "animation: fr2 2s 1s cubic-bezier(0.5, 0.07, 0.64, 1) infinite;"
    "}"
    ".r3 {"
    "animation: fr3 2s 1.5s cubic-bezier(0.5, 0.07, 0.64, 1) infinite;"
    "}"
    ".r4 {"
    "animation: fr4 2s 2s cubic-bezier(0.5, 0.07, 0.64, 1) infinite;"
    "}"
    ".r5 {"
    "animation: fr5 1.5s 0.5s cubic-bezier(0.5, 0.07, 0.64, 1) infinite;"
    "}"
    ".r6 {"
    "animation: fr6 1.5s 1s cubic-bezier(0.5, 0.07, 0.64, 1) infinite;"
    "}"
    ".r7 {"
    "animation: fr7 1.5s 1.5s cubic-bezier(0.5, 0.07, 0.64, 1) infinite;"
    "}"
    ".r8 {"
    "animation: fr8 1.5s 2s cubic-bezier(0.5, 0.07, 0.64, 1) infinite;"
    "}"
    "@keyframes fc1 {"
    "0% {"
    "transform: translate(0, 0) scale(1);"
    "}"
    "100% {"
    "transform: translate(552px, 350px) scale(0);"
    "}"
    "}"
    "@keyframes fc2 {"
    "0% {"
    "transform: translate(0, 0) scale(1);"
    "}"
    "100% {"
    "transform: translate(652px, 350px) scale(0);"
    "}"
    "}"
    "@keyframes fc3 {"
    "0% {"
    "transform: translate(0, 0) scale(1);"
    "}"
    "100% {"
    "transform: translate(564px, 350px) scale(0);"
    "}"
    "}"
    "@keyframes fc4 {"
    "0% {"
    "transform: translate(0, 0) scale(1);"
    "}"
    "100% {"
    "transform: translate(577px, 350px) scale(0);"
    "}"
    "}"
    "@keyframes fc5 {"
    "0% {"
    "transform: translate(0, 0) scale(1);"
    "}"
    "100% {"
    "transform: translate(679px, 350px) scale(0);"
    "}"
    "}"
    "@keyframes fc6 {"
    "0% {"
    "transform: translate(0, 0) scale(1);"
    "}"
    "100% {"
    "transform: translate(563px, 350px) scale(0);"
    "}"
    "}"
    "@keyframes fc7 {"
    "0% {"
    "transform: translate(0, 0) scale(1);"
    "}"
    "100% {"
    "transform: translate(591px, 350px) scale(0);"
    "}"
    "}"
    "@keyframes fc8 {"
    "0% {"
    "transform: translate(0, 0) scale(1);"
    "}"
    "100% {"
    "transform: translate(668px, 350px) scale(0);"
    "}"
    "}"
    "@keyframes fc9 {"
    "0% {"
    "transform: translate(0, 0) scale(1);"
    "}"
    "100% {"
    "transform: translate(546px, 350px) scale(0);"
    "}"
    "}"
    "@keyframes fc10 {"
    "0% {"
    "transform: translate(0, 0) scale(1);"
    "}"
    "100% {"
    "transform: translate(586px, 350px) scale(0);"
    "}"
    "}"
    "@keyframes fc11 {"
    "0% {"
    "transform: translate(0, 0) scale(1);"
    "}"
    "100% {"
    "transform: translate(604px, 350px) scale(0);"
    "}"
    "}"
    "@keyframes fc12 {"
    "0% {"
    "transform: translate(0, 0) scale(1);"
    "}"
    "100% {"
    "transform: translate(641px, 350px) scale(0);"
    "}"
    "}"
    "@keyframes fc13 {"
    "0% {"
    "transform: translate(0, 0) scale(1);"
    "}"
    "100% {"
    "transform: translate(549px, 350px) scale(0);"
    "}"
    "}"
    "@keyframes fc14 {"
    "0% {"
    "transform: translate(0, 0) scale(1);"
    "}"
    "100% {"
    "transform: translate(638px, 350px) scale(0);"
    "}"
    "}"
    "@keyframes fc15 {"
    "0% {"
    "transform: translate(0, 0) scale(1);"
    "}"
    "100% {"
    "transform: translate(629px, 350px) scale(0);"
    "}"
    "}"
    "@keyframes fr1 {"
    "0% {"
    "transform: translate(288px, 631px) scale(0.3);"
    "}"
    "100% {"
    "transform: translate(0px, -450px) scale(1);"
    "}"
    "}"
    "@keyframes fr2 {"
    "0% {"
    "transform: translate(264px, 599px) scale(0.3);"
    "}"
    "100% {"
    "transform: translate(0px, -450px) scale(1);"
    "}"
    "}"
    "@keyframes fr3 {"
    "0% {"
    "transform: translate(257px, 576px) scale(0.3);"
    "}"
    "100% {"
    "transform: translate(0px, -450px) scale(1);"
    "}"
    "}"
    "@keyframes fr4 {"
    "0% {"
    "transform: translate(295px, 614px) scale(0.3);"
    "}"
    "100% {"
    "transform: translate(0px, -450px) scale(1);"
    "}"
    "}"
    "@keyframes fr5 {"
    "0% {"
    "transform: translate(585px, 611px) scale(0.3);"
    "}"
    "100% {"
    "transform: translate(0px, -450px) scale(1);"
    "}"
    "}"
    "@keyframes fr6 {"
    "0% {"
    "transform: translate(611px, 601px) scale(0.3);"
    "}"
    "100% {"
    "transform: translate(0px, -450px) scale(1);"
    "}"
    "}"
    "@keyframes fr7 {"
    "0% {"
    "transform: translate(607px, 591px) scale(0.3);"
    "}"
    "100% {"
    "transform: translate(0px, -450px) scale(1);"
    "}"
    "}"
    "@keyframes fr8 {"
    "0% {"
    "transform: translate(597px, 626px) scale(0.3);"
    "}"
    "100% {"
    "transform: translate(0px, -450px) scale(1);"
    "}"
    "}"
    "</style>"
    "<defs>"
    '<radialGradient id="darkLight">'
    '<stop offset="0%" stop-color="#484848"/>'
    '<stop offset="3%" stop-color="#1b1b1b"/>'
    '<stop offset="8%" stop-color="#000000"/>'
    "</radialGradient>"
    '<linearGradient id="goldBody" gradientTransform="rotate(60)">'
    '<stop offset="0%" stop-color="#';
    //insert color
    string constant part1 = '"/><stop offset="100%" stop-color="#';
    //insert color
    string constant part2 =
    '"/>'
    "</linearGradient>";

    string constant part2_0_gen0_fire = 
    '<filter id="light0">'
    '<feDropShadow dx="0" dy="0" stdDeviation="2" flood-color="#e37da2" />'
    '</filter>'
    '<filter id="light1">'
    '<feDropShadow dx="0" dy="0" stdDeviation="2" flood-color="#e37da2" />'
    '</filter>'
    '<filter id="light2">'
    '<feGaussianBlur in="SourceGraphic" stdDeviation="1" />'
    '<feDropShadow dx="0" dy="0" stdDeviation="6" flood-color="#e37da2" />'
    '</filter>'
    '<filter id="light3">'
    '<feDropShadow dx="0" dy="0" stdDeviation="10" flood-color="#e37da2" />'
    '</filter>'
    '<filter id="light4">'
    '<feGaussianBlur in="SourceGraphic" stdDeviation="1" />'
    '<feDropShadow dx="0" dy="0" stdDeviation="40" flood-color="#e37da2" />'
    '</filter>';
    string constant part2_0_gen0_earth = 
    '<linearGradient id="gradient" gradientTransform="rotate(60)">'
    '<stop offset="0%" stop-color="hsl(211,54.4%,62.2%)" />'
    '<stop offset="100%" stop-color="hsl(121,54.4%,62.2%)" />'
    '</linearGradient>';
    string constant part2_0_gen0_wind = 
    '<linearGradient id="gradient" gradientTransform="rotate(60)">'
    '<stop offset="0%" stop-color="hsl(49,26%,63%)" />'
    '<stop offset="70%" stop-color="hsl(49,56%,43%)" />'
    '<stop offset="100%" stop-color="hsl(49,56%,43%)" />'
    '</linearGradient>';
    string constant part2_0_gen0_water = 
    '<linearGradient id="gradient" gradientTransform="rotate(60)">'
    '<stop offset="0%" stop-color="#f19cbc" />'
    '<stop offset="100%" stop-color="#e37da2" />'
    '</linearGradient>';
    string constant part2_0_gen1 = ""; 
    string constant part2_1 = '<filter id="goo">'
    '<feGaussianBlur in="SourceGraphic" stdDeviation="10" result="blur"/>'
    '<feColorMatrix in="blur" mode="matrix" values="1 0 0 0 0  0 1 0 0 0  0 0 1 0 0  0 0 0 18 -8" result="goo"/>'
    '<feBlend in="SourceGraphic" in2="goo"/>'
    "</filter>"
    '<clipPath id="centerCut">'
    '<circle cy="600" cx="600" r="140" stroke-width="120"/>'
    '</clipPath>'
    "</defs>";
    string constant part2_2_gen0_fire = '<circle cx="300" cy="300" r="1300" fill="#000">';
    string constant part2_2_gen0_earth = part2_2_gen0_fire;
    string constant part2_2_gen0_wind = '<circle cx="300" cy="300" r="1300" fill="url(#darkLight)">';
    string constant part2_2_gen0_water = part2_2_gen0_fire;
    string constant part2_2_gen1 = part2_2_gen0_earth;

    string constant part2_3 = '<animateTransform attributeType="xml" attributeName="transform" type="rotate" from="0 600 600" to="360 600 600" begin="0" dur="5s" repeatCount="indefinite"/>'
    "</circle>";
    //begin draw border lines
    string constant part_3_0_gen0_fire = '<g stroke="#e37da2" stroke-width="4" filter="url(#light0)">'
    '<rect width="1180" height="1180" x="10" y="10" stroke-width="4" fill="none" rx="18" />'
    '<line x1="29.999" y1="30" x2="29.999" y2="1170" stroke-linecap="round" stroke-linejoin="round" />'
    '<line x1="1169.999" y1="30" x2="1169.999" y2="1170" stroke-linecap="round" stroke-linejoin="round" />'
    '<line x1="600.499" y1="-555.5" x2="600.499" y2="583.5" stroke-linecap="round" stroke-linejoin="round" transform="translate(600.499000, 30.000000) scale(1, -1) rotate(90.000000) translate(-600.499000, -14.000000) " />'
    '<line x1="599.999" y1="600" x2="599.999" y2="1740" stroke-linecap="round" stroke-linejoin="round" transform="translate(599.999000, 1170.000000) scale(1, -1) rotate(90.000000) translate(-600.999000, -1170.000000) " />'
    '<g transform="translate(53.499000, 54.000000) rotate(-225.000000) translate(-53.499000, -54.000000) translate(31.999000, 20.000000)">'
    '<path d="M21.9097997,3.90608266 C26.170933,11.4659076 29.3361359,16.8171723 31.4028127,19.9615071 C32.9627669,22.3348914 34.7148315,24.4510487 36.3239968,26.389261 C38.7190073,29.2740105 41,31.6442511 41,34.0392981 C41,41.2737911 34.4771874,51.5925095 21.975433,65.1048441 C8.85845251,51.5900759 2,41.2762436 2,34.0392981 C2,31.7153744 4.5038242,29.0498098 6.98866431,26.00804 C8.54822997,24.0989273 10.194636,22.0782507 11.5931101,19.9677281 C13.7720223,16.679399 17.2108112,11.3245551 21.9097997,3.90608266 Z" />'
    '<path d="M21.4337465,24.2580374 C28.7435807,32.3258207 32.6464466,38.4941032 32.6464466,42.8636851 C32.6464466,47.2328868 28.7426179,53.3864682 21.431484,61.425663 C13.7581494,53.3849828 9.64644661,47.2355107 9.64644661,42.8636851 C9.64644661,38.4909332 13.7581469,32.3256763 21.4337465,24.2580374 Z" />'
    '</g>'
    '<g transform="translate(1146.499000, 54.000000) scale(-1, 1) rotate(-225.000000) translate(-1146.499000, -54.000000) translate(1124.999000, 20.000000)">'
    '<path d="M21.9097997,3.90608266 C26.170933,11.4659076 29.3361359,16.8171723 31.4028127,19.9615071 C32.9627669,22.3348914 34.7148315,24.4510487 36.3239968,26.389261 C38.7190073,29.2740105 41,31.6442511 41,34.0392981 C41,41.2737911 34.4771874,51.5925095 21.975433,65.1048441 C8.85845251,51.5900759 2,41.2762436 2,34.0392981 C2,31.7153744 4.5038242,29.0498098 6.98866431,26.00804 C8.54822997,24.0989273 10.194636,22.0782507 11.5931101,19.9677281 C13.7720223,16.679399 17.2108112,11.3245551 21.9097997,3.90608266 Z" />'
    '<path d="M21.4337465,24.2580374 C28.7435807,32.3258207 32.6464466,38.4941032 32.6464466,42.8636851 C32.6464466,47.2328868 28.7426179,53.3864682 21.431484,61.425663 C13.7581494,53.3849828 9.64644661,47.2355107 9.64644661,42.8636851 C9.64644661,38.4909332 13.7581469,32.3256763 21.4337465,24.2580374 Z" />'
    '</g>'
    '<g transform="translate(1146.499000, 1146.000000) scale(-1, -1) rotate(-225.000000) translate(-1146.499000, -1146.000000) translate(1124.999000, 1112.000000)">'
    '<path d="M21.9097997,3.90608266 C26.170933,11.4659076 29.3361359,16.8171723 31.4028127,19.9615071 C32.9627669,22.3348914 34.7148315,24.4510487 36.3239968,26.389261 C38.7190073,29.2740105 41,31.6442511 41,34.0392981 C41,41.2737911 34.4771874,51.5925095 21.975433,65.1048441 C8.85845251,51.5900759 2,41.2762436 2,34.0392981 C2,31.7153744 4.5038242,29.0498098 6.98866431,26.00804 C8.54822997,24.0989273 10.194636,22.0782507 11.5931101,19.9677281 C13.7720223,16.679399 17.2108112,11.3245551 21.9097997,3.90608266 Z" />'
    '<path d="M21.4337465,24.2580374 C28.7435807,32.3258207 32.6464466,38.4941032 32.6464466,42.8636851 C32.6464466,47.2328868 28.7426179,53.3864682 21.431484,61.425663 C13.7581494,53.3849828 9.64644661,47.2355107 9.64644661,42.8636851 C9.64644661,38.4909332 13.7581469,32.3256763 21.4337465,24.2580374 Z" />'
    '</g>'
    '<g transform="translate(53.499000, 1146.000000) scale(1, -1) rotate(-225.000000) translate(-45.499000, -1138.000000) translate(23.999000, 1104.000000)">'
    '<path d="M21.9097997,3.90608266 C26.170933,11.4659076 29.3361359,16.8171723 31.4028127,19.9615071 C32.9627669,22.3348914 34.7148315,24.4510487 36.3239968,26.389261 C38.7190073,29.2740105 41,31.6442511 41,34.0392981 C41,41.2737911 34.4771874,51.5925095 21.975433,65.1048441 C8.85845251,51.5900759 2,41.2762436 2,34.0392981 C2,31.7153744 4.5038242,29.0498098 6.98866431,26.00804 C8.54822997,24.0989273 10.194636,22.0782507 11.5931101,19.9677281 C13.7720223,16.679399 17.2108112,11.3245551 21.9097997,3.90608266 Z" />'
    '<path d="M21.4337465,24.2580374 C28.7435807,32.3258207 32.6464466,38.4941032 32.6464466,42.8636851 C32.6464466,47.2328868 28.7426179,53.3864682 21.431484,61.425663 C13.7581494,53.3849828 9.64644661,47.2355107 9.64644661,42.8636851 C9.64644661,38.4909332 13.7581469,32.3256763 21.4337465,24.2580374 Z" />'
    '</g>'
    '</g>'
    //fire's breath circle
    '<circle cy="600" cx="600" r="457" fill="#000" filter="url(#light4)">'
    '<animate attributeName="opacity" values="0.3;1;0.3" dur="2s" repeatCount="indefinite" filter="url(#light4)" />'
    '</circle>'
    '<circle cy="600" cx="600" r="457" fill="#000" filter="url(#light4)">'
    '<animate attributeName="opacity" values="0.3;1;0.3" dur="2s" repeatCount="indefinite" filter="url(#light4)"/>'
    '</circle>'
    '<circle cy="600" cx="600" r="457" fill="#000" filter="url(#light4)">'
    '<animate attributeName="opacity" values="0.3;1;0.3" dur="2s" repeatCount="indefinite" filter="url(#light4)"/>'
    '</circle>'
    ;
    string constant part_3_0_gen0_earth = 
    '<g stroke="url(#gradient)">'
    '<rect width="1180" height="1180" x="10" y="10" stroke-width="4" fill="none" rx="18" />'
    '<path d="M30,30 H60 V80 H30 V1120 H60 V1170 H30 V1140 H80 V1170 H1120 V1140 H1170 V1170 H1140 V1120 H1170 V80 H1140 V30 H1170 V60 H1120 V30 H80 V60 H30 V30 Z" stroke-width="4" fill="none" />'
    '</g>';
    string constant part_3_0_gen0_water = 
    '<g stroke="#4fb3bf" stroke-width="4">'
    '<rect width="1180" height="1180" x="10" y="10" stroke-width="4" fill="none" rx="18" />'
    '<line x1="29.999" y1="89" x2="29.999" y2="1110" stroke-linecap="round" stroke-linejoin="round" />'
    '<line x1="1169.999" y1="89" x2="1169.999" y2="1110" stroke-linecap="round" stroke-linejoin="round" />'
    '<line x1="599.999" y1="-481" x2="599.999" y2="541" stroke-linecap="round" stroke-linejoin="round" transform="translate(599.999000, 30.000000) scale(1, -1) rotate(90.000000) translate(-599.999000, -30.000000) " />'
    '<line x1="599.999" y1="659" x2="599.999" y2="1681" stroke-linecap="round" stroke-linejoin="round" transform="translate(599.999000, 1170.000000) scale(1, -1) rotate(90.000000) translate(-599.999000, -1170.000000) " />'
    '<g transform="translate(30.000000, 30.000000)">'
    '<circle stroke-linejoin="round" cx="13" cy="59" r="13" />'
    '<circle stroke-linejoin="round" cx="59" cy="59" r="13" />'
    '<circle stroke-linejoin="round" cx="59" cy="13" r="13" />'
    '<path d="M13,46 C23.4255706,46 31.0922373,50.3333333 36,59 C40.9077627,67.6666667 48.5744294,72 59,72" />'
    '<path d="M36,21 C46.4255706,21 54.0922373,25.3333333 59,34 C63.9077627,42.6666667 71.5744294,47 82,47" transform="translate(59.000000, 34.000000) rotate(-270.000000) translate(-59.000000, -34.000000) " />'
    '</g>'
    '<g transform="translate(66.000000, 1134.000000) scale(1, -1) translate(-66.000000, -1134.000000) translate(30.000000, 1098.000000)">'
    '<circle stroke-linejoin="round" cx="13" cy="59" r="13" />'
    '<circle stroke-linejoin="round" cx="59" cy="59" r="13" />'
    '<circle stroke-linejoin="round" cx="59" cy="13" r="13" />'
    '<path d="M13,46 C23.4255706,46 31.0922373,50.3333333 36,59 C40.9077627,67.6666667 48.5744294,72 59,72" />'
    '<path d="M36,21 C46.4255706,21 54.0922373,25.3333333 59,34 C63.9077627,42.6666667 71.5744294,47 82,47" transform="translate(59.000000, 34.000000) rotate(-270.000000) translate(-59.000000, -34.000000) " />'
    '</g>'
    '<g transform="translate(1134.000000, 66.000000) scale(-1, 1) translate(-1126.000000, -58.000000) translate(1090.000000, 22.000000)">'
    '<circle stroke-linejoin="round" cx="13" cy="59" r="13" />'
    '<circle stroke-linejoin="round" cx="59" cy="59" r="13" />'
    '<circle stroke-linejoin="round" cx="59" cy="13" r="13" />'
    '<path d="M13,46 C23.4255706,46 31.0922373,50.3333333 36,59 C40.9077627,67.6666667 48.5744294,72 59,72" />'
    '<path d="M36,21 C46.4255706,21 54.0922373,25.3333333 59,34 C63.9077627,42.6666667 71.5744294,47 82,47" transform="translate(59.000000, 34.000000) rotate(-270.000000) translate(-59.000000, -34.000000) " />'
    '</g>'
    '<g transform="translate(1134.000000, 1134.000000) scale(-1, -1) translate(-1118.000000, -1118.000000) translate(1082.000000, 1082.000000)">'
    '<circle stroke-linejoin="round" cx="13" cy="59" r="13" />'
    '<circle stroke-linejoin="round" cx="59" cy="59" r="13" />'
    '<circle stroke-linejoin="round" cx="59" cy="13" r="13" />'
    '<path d="M13,46 C23.4255706,46 31.0922373,50.3333333 36,59 C40.9077627,67.6666667 48.5744294,72 59,72" />'
    '<path d="M36,21 C46.4255706,21 54.0922373,25.3333333 59,34 C63.9077627,42.6666667 71.5744294,47 82,47" transform="translate(59.000000, 34.000000) rotate(-270.000000) translate(-59.000000, -34.000000) " />'
    '</g>'
    '</g>';
    string constant part_3_0_gen0_wind = 
    '<g stroke="url(#gradient)" stroke-width="4">'
    '<rect width="1180" height="1180" x="10" y="10" stroke-width="4" fill="none" rx="18" />'
    '<line x1="29.999" y1="90" x2="29.998" y2="1110" stroke-linecap="round" stroke-linejoin="round" />'
    '<line x1="1169.999" y1="90" x2="1169.998" y2="1110" stroke-linecap="round" stroke-linejoin="round" />'
    '<line x1="599.999" y1="-481" x2="599.998" y2="541" stroke-linecap="round" stroke-linejoin="round" transform="translate(599.999000, 30.000000) scale(1, -1) rotate(90.000000) translate(-599.999000, -30.000000) " />'
    '<line x1="599.999" y1="659" x2="599.998" y2="1681" stroke-linecap="round" stroke-linejoin="round" transform="translate(599.999000, 1170.000000) scale(1, -1) rotate(90.000000) translate(-599.999000, -1170.000000) " />'
    '<g transform="translate(29.999000, 30.000000)">'
    '<path d="M0,60 C6.95638942,59.7567892 11.866387,55.8626531 14.7299928,48.3175919 C17.5935986,40.7725306 22.3502677,37 29,37" stroke-linecap="round" stroke-linejoin="round" />'
    '<path d="M30,23 C36.9563894,22.7567892 41.866387,18.8626531 44.7299928,11.3175919 C47.5935986,3.77253063 52.3502677,0 59,0" stroke-linecap="round" stroke-linejoin="round" />'
    '<circle cx="29.001" cy="30" r="7" />'
    '<path d="M42.1077896,16.2445146 C38.698469,12.9949978 34.0827128,11 29.001,11 C18.5075898,11 10.001,19.5065898 10.001,30 M16.8997613,44.6485395 C20.1863254,47.366665 24.4029198,49 29.001,49 C39.4944102,49 48.001,40.4934102 48.001,30" stroke-linecap="round" />'
    '</g>'
    '<g transform="translate(1140.499000, 60.000000) scale(-1, 1) translate(-1132.499000, -52.000000) translate(1102.999000, 22.000000)">'
    '<path d="M0,60 C6.95638942,59.7567892 11.866387,55.8626531 14.7299928,48.3175919 C17.5935986,40.7725306 22.3502677,37 29,37" stroke-linecap="round" stroke-linejoin="round" />'
    '<path d="M30,23 C36.9563894,22.7567892 41.866387,18.8626531 44.7299928,11.3175919 C47.5935986,3.77253063 52.3502677,0 59,0" stroke-linecap="round" stroke-linejoin="round" />'
    '<circle cx="29.001" cy="30" r="7" />'
    '<path d="M42.1077896,16.2445146 C38.698469,12.9949978 34.0827128,11 29.001,11 C18.5075898,11 10.001,19.5065898 10.001,30 M16.8997613,44.6485395 C20.1863254,47.366665 24.4029198,49 29.001,49 C39.4944102,49 48.001,40.4934102 48.001,30" stroke-linecap="round" />'
    '</g>'
    '<g transform="translate(1140.499000, 1140.000000) scale(-1, -1) translate(-1132.499000, -1132.000000) translate(1102.999000, 1102.000000)">'
    '<path d="M0,60 C6.95638942,59.7567892 11.866387,55.8626531 14.7299928,48.3175919 C17.5935986,40.7725306 22.3502677,37 29,37" stroke-linecap="round" stroke-linejoin="round" />'
    '<path d="M30,23 C36.9563894,22.7567892 41.866387,18.8626531 44.7299928,11.3175919 C47.5935986,3.77253063 52.3502677,0 59,0" stroke-linecap="round" stroke-linejoin="round" />'
    '<circle cx="29.001" cy="30" r="7" />'
    '<path d="M42.1077896,16.2445146 C38.698469,12.9949978 34.0827128,11 29.001,11 C18.5075898,11 10.001,19.5065898 10.001,30 M16.8997613,44.6485395 C20.1863254,47.366665 24.4029198,49 29.001,49 C39.4944102,49 48.001,40.4934102 48.001,30" stroke-linecap="round" />'
    '</g>'
    '<g transform="translate(59.499000, 1140.000000) scale(1, -1) translate(-51.499000, -1132.000000) translate(21.999000, 1102.000000)">'
    '<path d="M0,60 C6.95638942,59.7567892 11.866387,55.8626531 14.7299928,48.3175919 C17.5935986,40.7725306 22.3502677,37 29,37" stroke-linecap="round" stroke-linejoin="round" />'
    '<path d="M30,23 C36.9563894,22.7567892 41.866387,18.8626531 44.7299928,11.3175919 C47.5935986,3.77253063 52.3502677,0 59,0" stroke-linecap="round" stroke-linejoin="round" />'
    '<circle cx="29.001" cy="30" r="7" />'
    '<path d="M42.1077896,16.2445146 C38.698469,12.9949978 34.0827128,11 29.001,11 C18.5075898,11 10.001,19.5065898 10.001,30 M16.8997613,44.6485395 C20.1863254,47.366665 24.4029198,49 29.001,49 C39.4944102,49 48.001,40.4934102 48.001,30" stroke-linecap="round" />'
    '</g>'
    '</g>';
    
    
    string constant part_3_0_gen1 = 
    '<g stroke="#989898">'
    '<rect width="1180" height="1180" x="10" y="10" stroke-width="4" fill="none"/>'
    '<path d="M30,30 H60 V80 H30 V1120 H60 V1170 H30 V1140 H80 V1170 H1120 V1140 H1170 V1170 H1140 V1120 H1170 V80 H1140 V30 H1170 V60 H1120 V30 H80 V60 H30 V30 Z" stroke-width="4" fill="none"/>'
    "</g>";

    function svgPart0() public pure returns (string memory) {
        return part0;
    }

    function svgPart1() public pure returns (string memory) {
        return part1;
    }
    function svgPart2(bool gen0, FireGenerator.ElementType elementType) public pure returns (string memory) {
        if (gen0) {
            if(elementType == FireGenerator.ElementType.FIRE) {
                return string(abi.encodePacked(part2, part2_0_gen0_fire, part2_1, part2_2_gen0_fire, part2_3));
            } else if (elementType == FireGenerator.ElementType.EARTH) {
                return string(abi.encodePacked(part2, part2_0_gen0_earth, part2_1, part2_2_gen0_earth, part2_3));
            } else if (elementType == FireGenerator.ElementType.WATER) {
                return string(abi.encodePacked(part2, part2_0_gen0_water, part2_1, part2_2_gen0_earth, part2_3));
            } else /** if (elementType == ElementType.WIND) */ {
                return string(abi.encodePacked(part2, part2_0_gen0_wind, part2_1, part2_2_gen0_wind, part2_3));
            }
        } else /** if(!gen0) */ {
            return string(abi.encodePacked(part2, part2_0_gen1, part2_1, part2_2_gen1, part2_3));
        }
    }
    function svgPart3(bool gen0, FireGenerator.ElementType elementType) public pure returns (string memory) {
        if (gen0) {
            if(elementType == FireGenerator.ElementType.FIRE) {
                return part_3_0_gen0_fire;
            } else if (elementType == FireGenerator.ElementType.EARTH) {
                return part_3_0_gen0_earth;
            } else if (elementType == FireGenerator.ElementType.WATER) {
                return part_3_0_gen0_water;
            } else /** if (elementType == ElementType.WIND) */ {
                return part_3_0_gen0_wind;
            }

        } else /**(!gen0) */ {
            return part_3_0_gen1;
        }
    }
}