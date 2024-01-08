//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;

import "./base64.sol";
import "./Strings.sol";

contract MetamaticiansAttributes {
    using Strings for string;
    using Strings for uint256;

    constructor() {}

    string[] private metamaticians = [
        "Pythagoras",
        "Euler",
        "Markov",
        "Euclid",
        "Newton",
        "Archimedes",
        "Einstein",
        "Turing",
        "Pascal",
        "Thales",
        "Fibonacci",
        "Hypatia",
        "Plato",
        "Descartes",
        "Lovelace",
        "DaVinci",
        "Aristotle",
        "Fermat",
        "Neumann",
        "Abel",
        "Hamilton",
        "Eudoxus",
        "Cardano",
        "Galilei",
        "Grassmann",
        "Selberg",
        "Maxwell",
        "Laplace",
        "Bayes",
        "Babbage",
        "Boole",
        "Hilbert",
        "Khwarizmi",
        "Magnus",
        "Whitehead",
        "Wiles",
        "Cayley",
        "Aryabhata",
        "Cauchy",
        "Banneker",
        "Riemann",
        "Russell",
        "Brahmagupta",
        "Taylor",
        "Bernoulli",
        "Democritus",
        "Diophantus",
        "Halley",
        "Lorenz",
        "Witten",
        "Lasker",
        "Galois",
        "Klein",
        "Brunelleschi",
        "Hardy",
        "Monge",
        "Cantor",
        "Peano",
        "Leibniz",
        "Frege",
        "Hopper",
        "Perelman",
        "Hipparchus",
        "Napier",
        "Nash",
        "Venn",
        "Wallis",
        "Fourier",
        "Lagrange",
        "Robinson",
        "Godel",
        "Hui",
        "Madhava",
        "Escher",
        "Khayyam",
        "Cohen",
        "Ptolemy",
        "Pacioli",
        "Germain",
        "Ramanujan",
        "Kolmogorov",
        "Lobachevsky",
        "Gauss",
        "Chebyshev",
        "Berkovich",
        "Smirnov",
        "Gelfand",
        "Alexandrov",
        "Kurosh",
        "Friedmann",
        "Heng",
        "Xing",
        "Jingrun",
        "Luogeng",
        "Zhen",
        "Song",
        "Yau",
        "Bose",
        "Rao",
        "Bhaskara",
        "Karmarkar"
    ];

    string[] private suffixes = [
        "The Counter",
        "The Multiplier",
        "The Divider",
        "The Curver",
        "The Boxer",
        "The Calculator",
        "The Coordinator",
        "The Denominator",
        "The Equator",
        "The Formulator",
        "The Flipper",
        "The Mediator",
        "The Modular",
        "The Negative",
        "The Positive",
        "The Numerator",
        "The Obtuse",
        "The Acute",
        "The Even",
        "The Odd",
        "The Operator",
        "The Plane",
        "The Prime",
        "The Product",
        "The Proper",
        "The Protractor",
        "The Ranger",
        "The Sloper",
        "The Rooter",
        "The Symmetrical",
        "The Tangent",
        "The Uniform"
    ];

    string[] private greeks = [
        "&#916;",
        "&#915;",
        "&#920;",
        "&#957;",
        "&#929;"
    ];

    string[] private greekNames = [
        "Delta",
        "Gamma",
        "Theta",
        "Vega",
        "Rho"
    ];

    function getName(uint pieceOfPie) public view returns (string memory) {
        uint index = pieceOfPie / 1000000;
        return metamaticians[index % metamaticians.length];
    }

    function getSuffix(uint pieceOfPie) public view returns (string memory) {
        uint index = (pieceOfPie / 10000) % 100;
        return suffixes[index % suffixes.length];
    }

    function getGreek(uint pieceOfPie) public view returns (string memory) {
        uint index = (pieceOfPie / 100) % 100;
        return greeks[index % greeks.length];
    }

    function getGreekName(uint pieceOfPie) public view returns (string memory) {
        uint index = (pieceOfPie / 100) % 100;
        return greekNames[index % greeks.length];
    }

    function getSVG(uint256 pieceOfPi, uint256 tokenId) public view returns (string memory) {
        string memory name = getName(pieceOfPi);
        string memory suffix = getSuffix(pieceOfPi);
        string memory greek = getGreek(pieceOfPi);

        string memory svg = string(
                abi.encodePacked(
                    "<svg id='metamatician-", tokenId.toString(), "' xmlns='http://www.w3.org/2000/svg' xml:space='preserve' fill-rule='evenodd' clip-rule='evenodd' image-rendering='optimizeQuality' shape-rendering='geometricPrecision' text-rendering='geometricPrecision' viewBox='0 0 1000 1000'>",
                        "<defs><style>.str4{stroke:#47e975;stroke-width:2.66684}.str1{stroke-width:2.66646}.str1,.str2,.str3{stroke:#47e975}.str2{stroke-width:2.66684}.str3{stroke-width:2.66797}.fil1{fill:none}.fil4{fill:#2b2a29}</style></defs>",
                        "<g id='Layer_x0020_1'>",
                            "<path fill='#1c1c26' stroke='#2b2a29' stroke-width='.8' d='M0 0h1000v1000H0z'/>",
                            "<g id='_358226056'>",
                            "<path id='_342623352' d='m286.3 497.4-2.8-154.6 52.8-128.2 84.5-43.6 157.8-1.2 85.3 44.8 52.3 129.9-1.7 152.9' class='fil1 str1'/>",
                            "<path d='m453.9 602.8 47.1 43.7 44.2-44.2' class='fil1 str1'/>",
                            "<path d='m337.6 492.9 25.8-20.4 49.8-.4 34 20.4-53.9 23.5z' class='fil1 str2'/>",
                            "<path d='m363.3 587.7 86.1 57.2M286 499.2l19.2 140.7m57.5-53.4 9.6 143.5-65.4-88.4' class='fil1 str3'/>",
                            "<path d='M449.1 644.2 334.4 770.1l-28-129.1m193.3-108.1-44 71.9zm-51.2 111.6 102.1.1m-96.8-40-4.7 40.8' class='fil1 str3'/>",
                            "<path d='m414.4 728.4 59.8-27.7 24.7 6.5' class='fil1 str1'/>",
                            "<path d='m499.4 728.7-83.3-.1 83 31.7m-58.3 94-67.9-124.6m-39.3 41 103.3 83.6' class='fil1 str3'/>",
                            "<path d='m661.9 492.9-25.8-20.4-49.8-.4-34 20.4 53.9 23.5z' class='fil1 str2'/>",
                            "<path d='m715 497.9-20.8 142-57.2-52.8-8.5 141.5 64-87m-191.7-109 43 72.2zM635.5 586l-84.4 59.8m-7.6-39.3 7.5 39.3m-51 82.9 83.4-.1-84.8 32.2m60.1 93.5L628.9 728m37.1 42.2-103.4 84.1m-122.3-.1 59.9 33.2m.9-.9 58.8-32.9M413.3 471.8l-9.2-56m36.7 439.6 56.7-30.8 63.4 28.6' class='fil1 str3'/>",
                            "<path d='m421.4 171.5 78.2 122.4 78.1-124.1M403.6 416.1l-121.3-74.5m80.5 243.7 137.9-50.5 136.8 50.5m-275.3 1.2 31.6-69m243.7 68.4L607 518.7m-158-25.9 51.7 41.4 50-42' class='fil1 str1'/>",
                            "<path d='m406.2 414.9 95.1 121 88.2-124.1m-226.7 58.6-79.3-129.3' class='fil1 str1'/>",
                            "<path d='M394.7 518.4 501 535.6l108.1-16.1M284.3 344.8l137.4-174.1m293.1 177.6L577.4 170.1M404.5 414.6l16.1-242.8m168.9 240.3L578 168.9m56.9 304.4 80.5-129.4M586.1 471l4-56.9m-1.2-1.8 125.9-66.1M283.6 498.9l54.1-6.9m375.3 4.6-50.6-4.1M414.1 727.4h-42.6m213.2 1.1 45.4-1.1m35.7 43.1 27.6-132.2M405 414.6l185-1.7M336.9 213.2l68.4 200.6m183.3-1.8 74.1-197.1M404 414.7l96-123.8L589.9 413m-90.8 294.1 27.1-6 59.2 27.9m-135.7-83.2 24.7 55.9' class='fil1 str1'/>",
                            "<path d='m525 701.1 25.9-56.3 115.8 126' class='fil1 str1'/>",
                            "<path fill='#47e975' fill-rule='nonzero' d='M498.8 826.1V644.8h2.7v181.3z'/>",
                            "<path d='m362.8 585.5-57.3 55' class='fil1 str1'/>",
                            "</g>",
                            "<text id='name-suffix' x='50%' y='7%' fill='#fff' dominant-baseline='hanging' font-family='courier' font-size='3em' text-anchor='middle'>", name, " ",  suffix, "</text>",
                            "<path fill='#efefef' fill-rule='nonzero' d='M710.7 912.3h-40.1v5.1h5.9v29.9h5.8v-29.9h16v29.9h5.8v-29.9h6.6z'/>",
                            "<text id='greek' x='8.5%' y='93.5%' fill='#47E975' dominant-baseline='middle' font-family='courier' font-size='3em' text-anchor='middle'>", greek, "</text>",
                            "<text id='pieceOfPi' x='83.5%' y='93.5%' fill='#fff' dominant-baseline='middle' font-family='courier' font-size='3em' text-anchor='middle'>", pieceOfPi.toString(), "</text>",
                            "<path d='m517.8 357.6-17.6-30.5-17.7 30.5zm-21.5 37.7-17.6-30.5-17.7 30.5zm42.9 0-17.6-30.5-17.7 30.5z' class='fil1 str4'/>",
                            "<circle cx='455.2' cy='604.5' r='4.6' class='fil4 str4'/>",
                            "<circle cx='500.1' cy='534.4' r='4.6' class='fil4 str4'/>",
                            "<circle cx='579' cy='171.5' r='4.6' class='fil4 str4'/>",
                            "<circle cx='447.8' cy='493' r='4.6' class='fil4 str4'/>",
                            "<circle cx='413.8' cy='472.2' r='4.6' class='fil4 str4'/>",
                            "<circle cx='363.5' cy='472.5' r='4.6' class='fil4 str4'/>",
                            "<circle cx='286.2' cy='497.5' r='4.6' class='fil4 str4'/>",
                            "<circle cx='284.5' cy='346.9' r='4.6' class='fil4 str4'/>",
                            "<circle cx='714.4' cy='497.5' r='4.6' class='fil4 str4'/>",
                            "<circle cx='714.4' cy='346.9' r='4.6' class='fil4 str4'/>",
                            "<circle cx='663' cy='213.8' r='4.6' class='fil4 str4'/>",
                            "<circle cx='337.4' cy='213.6' r='4.6' class='fil4 str4'/>",
                            "<circle cx='421' cy='171.5' r='4.6' class='fil4 str4'/>",
                            "<circle cx='305.8' cy='640.2' r='4.6' class='fil4 str4'/>",
                            "<circle cx='393.3' cy='517.1' r='4.6' class='fil4 str4'/>",
                            "<circle cx='363.2' cy='585.7' r='4.6' class='fil4 str4'/>",
                            "<circle cx='607.5' cy='518.4' r='4.6' class='fil4 str4'/>",
                            "<circle cx='551.4' cy='490.8' r='4.6' class='fil4 str4'/>",
                            "<circle cx='585.7' cy='471.9' r='4.6' class='fil4 str4'/>",
                            "<circle cx='635.4' cy='473.2' r='4.6' class='fil4 str4'/>",
                            "<circle cx='661.4' cy='491.8' r='4.6' class='fil4 str4'/>",
                            "<circle cx='560' cy='852.8' r='4.6' class='fil4 str4'/>",
                            "<circle cx='500.2' cy='887.1' r='4.6' class='fil4 str4'/>",
                            "<circle cx='415.7' cy='727.1' r='4.6' class='fil4 str4'/>",
                            "<circle cx='373' cy='727.1' r='4.6' class='fil4 str4'/>",
                            "<circle cx='334' cy='770.1' r='4.6' class='fil4 str4'/>",
                            "<circle cx='439.8' cy='853.8' r='4.6' class='fil4 str4'/>",
                            "<circle cx='693.9' cy='640.2' r='4.6' class='fil4 str4'/>",
                            "<circle cx='636.4' cy='585.7' r='4.6' class='fil4 str4'/>",
                            "<circle cx='500' cy='291.5' r='4.6' class='fil4 str4'/>",
                            "<circle cx='405.1' cy='414.5' r='4.6' class='fil4 str4'/>",
                            "<circle cx='580.8' cy='728.1' r='4.6' class='fil4 str4'/>",
                            "<circle cx='448.9' cy='645.4' r='4.6' class='fil4 str4'/>",
                            "<circle cx='525.6' cy='700.8' r='4.6' class='fil4 str4'/>",
                            "<circle cx='473.7' cy='700.5' r='4.6' class='fil4 str4'/>",
                            "<circle cx='589.7' cy='412.3' r='4.6' class='fil4 str4'/>",
                            "<circle cx='500.2' cy='645' r='4.6' class='fil4 str4'/>",
                            "<circle cx='500.2' cy='706.9' r='4.6' class='fil4 str4'/>",
                            "<circle cx='500.2' cy='728.1' r='4.6' class='fil4 str4'/>",
                            "<circle cx='500.2' cy='759.8' r='4.6' class='fil4 str4'/>",
                            "<circle cx='500.2' cy='826.2' r='4.6' class='fil4 str4'/>",
                            "<circle cx='551.4' cy='645' r='4.6' class='fil4 str4'/>",
                            "<circle cx='665.2' cy='769.4' r='4.6' class='fil4 str4'/>",
                            "<circle cx='629.3' cy='727.8' r='4.6' class='fil4 str4'/>",
                            "<circle cx='338.4' cy='491.8' r='4.6' class='fil4 str4'/>",
                            "<circle cx='543' cy='604.5' r='4.6' class='fil4 str4'/>",
                        "</g>",
                    "</svg>"
                )
            );

        string memory encodedJson = Base64.encode(bytes(svg));
        string memory output = string(abi.encodePacked("data:image/svg+xml;base64,", encodedJson));
        return output;
    }
}
