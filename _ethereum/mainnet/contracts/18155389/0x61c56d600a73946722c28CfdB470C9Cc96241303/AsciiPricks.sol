// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import "./ERC721A.sol";
import "./MerkleProofLib.sol";
import "./Base64.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract AsciiPricks is ERC721A, Ownable {
    using Strings for uint256;

    error SaleIsPaused();
    error MaxSupplyReached();
    error MaxPerWalletReached();
    error NoDicFound();
    error InvalidProof();
    error MustMintMoreThanZero();
    error ToughLuckMate();

    mapping(uint256 => uint256) private tokenSeed; //TokenID to TokenSeed
    uint256 public MAX_SUPPLY = 8004;
    bytes32 private merkleRoot;
    mapping(address => bool) private founderWallets;
    bool public saleIsActive = false;
    uint8 public MAX_PER_WALLET = 10;

    struct Color {
        string value;
        string name;
    }

    struct Trait {
        string content;
        string name;
        Color color;
    }

    Color[] colors = [
            Color("#08f7fe", "Glowy Blue"),
            Color("#09fbd3", "Glowy Green"),
            Color("#fe53bb", "Glowy Pink"),
            Color("#f5d300", "Glowy Yellow"),
            Color("#ffacfc", "Bubblegum Pink"),
            Color("#f148fb", "Neon Pink"),
            Color("#7122fa", "Neon Purple"),
            Color("#560a86", "Dark Purple"),
            Color("#ffe3f1", "Light Pink"),
            Color("#fe1c80", "Retro Pink"),
            Color("#ff5f01", "Retro Orange"),
            Color("#ce0000", "Retro Red"),
            Color("#fcf340", "Bokeh Yellow"),
            Color("#7fff00", "Bokeh Green"),
            Color("#fb33db", "Bokeh Pink"),
            Color("#0310ea", "Bokeh Blue"),
            Color("#fcf340", "Plain Yellow"),
            Color("#7fff00", "Plain Green"),
            Color("#fb33db", "Bright Pink"),
            Color("#0310ea", "Plain Blue"),
            Color("#f7ef8a", "Golden")
            ];

    constructor(bytes32 _root, address[] memory wallets, uint32 quantity) ERC721A("ASCII Pricks", "PRICK") {
        merkleRoot = _root;
        for (uint256 i = 0; i < wallets.length;) {
            for (uint256 j = 0; j < 50;) {
                tokenSeed[_totalMinted() + j] = uint256(
                    keccak256(abi.encodePacked(block.timestamp, wallets[i], _totalMinted() + j)) << 108 >> 216
                );
                unchecked { ++j; }
            }

            _mintERC2309(wallets[i], quantity);

            unchecked { ++i; }
        }
    }

    function alMint(bytes32[] calldata _proof, uint32 qty) external payable {
        if (qty == 0) revert MustMintMoreThanZero();
        if (_totalMinted() + qty > MAX_SUPPLY) revert MaxSupplyReached();
        if (_numberMinted(msg.sender) + qty > MAX_PER_WALLET) revert MaxPerWalletReached();

        bytes32 leaf = keccak256((abi.encodePacked(msg.sender)));

        if (!MerkleProofLib.verify(_proof, merkleRoot, leaf)) {
            revert InvalidProof();
        }

        for (uint256 i = 0; i < qty; ) {
            tokenSeed[_totalMinted() + i] = uint256(
                keccak256(abi.encodePacked(block.timestamp, msg.sender, _totalMinted() + i)) << 108 >> 216
            );
            unchecked { ++i; }
        }

        _mint(msg.sender, qty);
    }

    function mint(uint32 qty) external payable {
        if (qty == 0) revert MustMintMoreThanZero();
        if (!saleIsActive) revert SaleIsPaused();
        if (_totalMinted() + qty > MAX_SUPPLY) revert MaxSupplyReached();
        if (_numberMinted(msg.sender) + qty > MAX_PER_WALLET) revert MaxPerWalletReached();

        for (uint256 i = 0; i < qty; ) {
            tokenSeed[_totalMinted() + i] = uint256(
                keccak256(abi.encodePacked(block.timestamp, msg.sender, _totalMinted() + i)) << 108 >> 216
            );
            unchecked { ++i; }
        }

        _mint(msg.sender, qty);
    }

    function flipSaleState() external onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function withdraw() external payable onlyOwner {
        (bool os,)= payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

    function getSeed(uint256 tokenId) public view returns (uint256) {
        if (!_exists(tokenId)) revert NoDicFound();
        return tokenSeed[tokenId];
    }

    /*
    XX    FamilyJewls       90% normal / 10% other
    YY    Fur               75% without / 25% with
    ZZ    length            Linear scale from 0 to 127 - Max len 12
    AA    Tip               Split in 3 get one of 3
    */
    function tokenURI(uint256 tokenId) public override view returns (string memory) {
        uint256 seed = tokenSeed[tokenId];
        Trait memory famjewls = setFamilyJewls(uint8(seed >> 32));           //up to 255
        Trait memory fur = setFur(uint8(seed << 224 >> 248));       //up to 255
        Trait memory length = setLoveDepth(uint8(seed << 240 >> 249)); //up to 127
        Trait memory tip = setTip(uint8(seed << 248 >> 248));     //up to 255
        Trait memory style = setStyle(seed);

        string memory rawSvg = string(
            abi.encodePacked(
                '<svg width="350" height="350" viewBox="0 0 350 350" xmlns="http://www.w3.org/2000/svg">',
                '<rect width="100%" height="100%" fill="#0C090A"/>',
                '<text x="50%" y="50%" font-family="Roboto" font-weight="700" font-size="30" text-anchor="middle" letter-spacing="1">',
                famjewls.content,
                fur.content,
                length.content,
                tip.content,
                '</text>',
                style.content,
                '</svg>'
            )
        );

        string memory encodedSvg = Base64.encode(bytes(rawSvg));
        string memory description = 'Prick';

        return string(
            abi.encodePacked(
                'data:application/json;base64,',
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            '{',
                            '"name":"PRICKS #', tokenId.toString(), '",',
                            '"description":"', description, '",',
                            '"image": "', 'data:image/svg+xml;base64,', encodedSvg, '",',
                            '"attributes": [{"trait_type": "Tip", "value": "', tip.color.name, ' ', tip.name,'"},',
                            '{"trait_type": "How deep is your love", "value": "', length.color.name,'"},',
                            '{"trait_type": "Fur", "value": "', fur.color.name, ' ', fur.name,'"},',
                            '{"trait_type": "Family Jewls", "value": "', famjewls.color.name, ' ', famjewls.name,'"},',
                            '{"trait_type": "Style", "value": "', style.name,'"}'
                            ']',
                            '}')
                    )
                )
            )
        );
    }

    function setFamilyJewls(uint8 seed) private view returns (Trait memory) {
        Color memory color = setColor(uint8(seed >> 1));
        string memory content;
        string memory name;
        if (seed < 299) {
            content = "8";
            name = "Regular Joe";
        } else {
            content = "d";
            name = "That Lucky Ball";
        }

        return Trait(string(abi.encodePacked('<tspan fill="', color.value, '">', content, '</tspan>')), name, color);
    }

    function setFur(uint8 seed) private view returns (Trait memory) {
        Color memory color;
        string memory content;
        string memory name;
        if (seed > 32 && seed < 223) {
            content = "";
            name = "No Fur";
            color = Color("#0C090A", "");
        } else {
            color = setColor(uint8(seed >> 1));
            content = "#";
            name = "Comfy Fur";
        }

        return Trait(string(abi.encodePacked('<tspan fill="', color.value, '">', content, '</tspan>')), name, color);
    }

    function setLoveDepth(uint8 seed) private view returns (Trait memory) {
        Color memory color = setColor(seed);
        string memory content = "";
        for (uint8 i = 0; i < seed;) {
            if (i % 10 == 0) {
                content = string(abi.encodePacked(content, "="));
            }

            unchecked {
                ++i;
            }
        }

        return Trait(string(abi.encodePacked('<tspan fill="', color.value, '">', content, '</tspan>')), "How deep is your love", color);
    }

    function setTip(uint8 seed) private view returns (Trait memory) {
        Color memory color = setColor(uint8(seed >> 1));
        string memory content;
        string memory name;
        if (seed < 85) {
            content = "D";
            name = "Rounded";
        } else if (seed < 170) {
            content = "()";
            name = "Splashed";
        } else {
            content = ">";
            name = "Arrow";
        }

        return Trait(string(abi.encodePacked('<tspan fill="', color.value, '">', content, '</tspan>')), name, color);
    }

    function setStyle(uint256 seed) private pure returns (Trait memory style) {
        uint256 animation = seed % 100;

        if (animation < 60) {   // 60%
            style.content = '';
            style.name = 'Lousy picture';
        } else if (animation >= 60 && animation < 80) {   // 20%
            style.content = '<style>text {animation: rotate-up 1s steps(5) infinite alternate, rotate-down 0.5s ease-out infinite alternate;transform-origin: center;}@keyframes rotate-up {from {transform: rotate(25deg);}to {transform: rotate(-45deg);}}@keyframes rotate-down {from {transform: rotate(-45deg);}to {transform: rotate(25deg);}}</style>';
            style.name = 'Shake';
        } else if (animation >= 80 && animation < 95) {   // 15%
            style.content = '<style>text {animation: heli 1.5s infinite;transform-origin: 5% 50%;display: inline-block;}@keyframes heli {0% {transform: rotate(720deg);}}</style>';
            style.name = 'Helicopter';
        } else {   // 5%
            style.content = '<style>text {animation: move 0.2s cubic-bezier(.44,.05,.55,.95) infinite alternate;transform-origin: center;}@keyframes move {from {transform: translateX(-20px);}to {transform: translateX(20px);}}</style>';
            style.name = 'Getting lucky';
        }

        return style;
    }

    function setColor(uint8 seed) public view returns (Color memory) {
        uint8 index = seed % uint8(colors.length);

        return colors[index];
    }

    function setMerkleRoot(bytes32 _root) external onlyOwner {
        merkleRoot = _root;
    }

    function getMerkleRoot() view external returns (bytes32) {
        return merkleRoot;
    }
}
