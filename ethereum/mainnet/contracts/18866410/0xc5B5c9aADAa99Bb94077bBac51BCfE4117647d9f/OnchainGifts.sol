// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17 .0;

import "./ERC721A.sol";
import "./NFTEventsAndErrors.sol";
import "./Utils.sol";
import "./Constants.sol";
import "./LibString.sol";
import "./LibPRNG.sol";
import "./SVG.sol";
import "./AllowList.sol";

/// @title onchain gifts
/// @notice generative onchain gifts to celebrate the holiday season.
contract OnchainGifts is ERC721A, NFTEventsAndErrors, Constants, AllowList {
    using LibString for uint16;
    using LibPRNG for LibPRNG.PRNG;

    bool public publicMintEnabled;
    uint16 internal immutable _allowListMintMaxTotal;
    uint8 internal immutable _allowListMintMaxPerWallet;
    mapping(address user => uint8 minted) internal _allowListMinted;

    bytes32 internal _revealedSeed;

    string[] internal _GIFTS = [
        "1f388",
        "1f366",
        "1f32e",
        "1f95e",
        "1f3ae",
        "1f3b3",
        "1f3c2",
        "1f6f9",
        "1f3a3",
        "1f3be",
        "1f3c8",
        "1f996",
        "1f995",
        "1f314",
        "1f680",
        "1f319",
        "26fa",
        "1f419",
        "1f988",
        "1f422",
        "1f407",
        "1f98d",
        "1f40e",
        "1f408",
        "1f415",
        "1f308",
        "1f302",
        "1f6f7",
        "1f30b",
        "1f420",
        "1f6a2",
        "1f3c4",
        "1f3d6",
        "26f5",
        "1f697",
        "1f483",
        "1f47e",
        "1f0cf",
        "1f3af",
        "1f34d",
        "1f3a1",
        "1f349",
        "1f353",
        "1f384",
        "1f344",
        "1f33b",
        "1f41b",
        "1f3b8",
        "1f3b7",
        "1f681"
    ];
    string[] internal _GIFT_TRAITS = [
        unicode"🎈",
        unicode"🍦",
        unicode"🌮",
        unicode"🥞",
        unicode"🎮",
        unicode"🎳",
        unicode"🏂",
        unicode"🛹",
        unicode"🎣",
        unicode"🎾",
        unicode"🏈",
        unicode"🦖",
        unicode"🦕",
        unicode"🌔",
        unicode"🚀",
        unicode"🌙",
        unicode"⛺",
        unicode"🐙",
        unicode"🦈",
        unicode"🐢",
        unicode"🐇",
        unicode"🦍",
        unicode"🐎",
        unicode"🐈",
        unicode"🐕",
        unicode"🌈",
        unicode"🌂",
        unicode"🛷",
        unicode"🌋",
        unicode"🐠",
        unicode"🚢",
        unicode"🏄",
        unicode"🏖️",
        unicode"⛵️",
        unicode"🚗",
        unicode"💃",
        unicode"👾",
        unicode"🃏",
        unicode"🎯",
        unicode"🍍",
        unicode"🎡",
        unicode"🍉",
        unicode"🍓",
        unicode"🎄",
        unicode"🍄",
        unicode"🌻",
        unicode"🐛",
        unicode"🎸",
        unicode"🎷",
        unicode"🚁"
    ];

    constructor(
        bytes32 allowListMerkleRoot,
        uint16 allowListMintMaxTotalVal,
        uint8 allowListMintMaxPerWalletVal
    )
        AllowList(allowListMerkleRoot)
        ERC721A("onchain gifts", "GIFT")
    {
        _allowListMintMaxTotal = allowListMintMaxTotalVal;
        _allowListMintMaxPerWallet = allowListMintMaxPerWalletVal;
    }

    /// @notice Update public mint enabled.
    /// @param enabled public mint enabled.
    function updatePublicMintEnabled(bool enabled) external onlyOwner {
        publicMintEnabled = enabled;
    }

    /// @notice Mint tokens for allowlist minters.
    /// @param proof proof
    /// @param amount amount of tokens to mint
    function mintAllowList(bytes32[] calldata proof, uint8 amount) external onlyAllowListed(proof) {
        // Checks
        unchecked {
            if (_totalMinted() + amount > _allowListMintMaxTotal) {
                // Check allowlist mint total is not exceeding max allowed to be minted during allowlist phase
                revert AllowListMintCapExceeded();
            }

            if (_allowListMinted[msg.sender] + amount > _allowListMintMaxPerWallet) {
                // Check wallet is not exceeding max allowed during allowlist phase
                revert AllowListMintCapPerWalletExceeded();
            }
        }

        // Effects

        // Increase allowlist minted by amount
        unchecked {
            _allowListMinted[msg.sender] += amount;
        }

        // Perform mint
        _coreMint(msg.sender, amount);
    }

    /// @notice Mint tokens.
    /// @param amount amount of tokens to mint
    function mintPublic(uint8 amount) external payable {
        // Checks
        if (!publicMintEnabled) {
            // Check public mint enabled
            revert PublicMintNotEnabled();
        }

        unchecked {
            if (amount * PRICE != msg.value) {
                // Check payment by sender is correct
                revert IncorrectPayment();
            }
        }

        _coreMint(msg.sender, amount);
    }

    function _coreMint(address to, uint8 amount) internal {
        // Checks
        uint256 nextTokenIdToBeMinted = _nextTokenId();

        unchecked {
            if (MAX_SUPPLY + 1 < nextTokenIdToBeMinted + amount) {
                // Check max supply not exceeded
                revert MaxSupplyReached();
            }
            if (_revealedSeed != bytes32(0)) {
                // Check not already revealed
                revert AlreadyRevealed();
            }
        }

        // Perform mint
        _mint(to, amount);
    }

    function reveal() external onlyOwner {
        if (_revealedSeed != bytes32(0)) {
            revert AlreadyRevealed();
        }
        _revealedSeed = keccak256(abi.encodePacked(block.prevrandao));
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    /// @notice Withdraw all ETH from the contract.
    function withdraw() external {
        (bool success,) = _VAULT_ADDRESS.call{ value: address(this).balance }("");
        require(success);
    }

    /// @notice Get art inner color hue.
    /// @param tokenId token id
    /// @return hue
    function getInnerColorHue(uint256 tokenId) public view returns (uint16 hue) {
        LibPRNG.PRNG memory prng;
        prng.seed(keccak256(abi.encodePacked(_revealedSeed, tokenId, uint256(1001))));
        return uint16(prng.uniform(360));
    }

    /// @notice Get art text.
    /// @param tokenId token id
    /// @return art text encoded, art text emoji
    function artText(uint256 tokenId) public view returns (string memory, string memory) {
        if (_revealedSeed == bytes32(0)) {
            return ("&#x1f381;", unicode"🎁");
        }

        LibPRNG.PRNG memory prng;
        prng.seed(keccak256(abi.encodePacked(_revealedSeed, tokenId)));
        uint256 giftIndex = prng.uniform(_GIFTS.length);
        return (string.concat("&#x", _GIFTS[giftIndex], ";"), _GIFT_TRAITS[giftIndex]);
    }

    /// @notice Get animation script.
    /// @return animation script
    function animationScript() public view returns (string memory) {
        string memory script = "<script>let g=[";
        unchecked {
            for (uint256 i; i < _GIFTS.length;) {
                script = string.concat(script, '"&#x', _GIFTS[i], ';"', i + 1 < _GIFTS.length ? "," : "");
                ++i;
            }
            script = string.concat(
                script,
                '],r=!1,s=t=>new Promise((e=>setTimeout(e,t)));let z=document.getElementById("gift");let og=z.innerHTML;document.addEventListener("click",(async()=>{if(r)return;let t=!0;for(let t=0;t<g.length;t++)z.innerHTML=g[t],await s(100);z.innerHTML=og,t=!1}));</script>'
            );
        }
        return script;
    }

    /// @notice Get art svg for token.
    /// @param tokenId token id
    /// @return art
    function art(uint256 tokenId) public view returns (string memory) {
        (string memory artTextEncoded,) = artText(tokenId);
        return string.concat(
            '<svg xmlns="http://www.w3.org/2000/svg" width="100%" height="100%" viewBox="0 0 400 400" fill="none"><rect width="400" height="400" fill="#ea4630" rx="5%" /><rect x="40" y="40" width="320" height="320" fill="green" rx="5%" /><rect x="80" y="80" width="240" height="240" fill="hsla(',
            getInnerColorHue(tokenId).toString(),
            ',50%,86%,100%)" rx="2.5%" /><text id="gift" x="200" y="210" text-anchor="middle" font-size="82" alignment-baseline="middle" stroke-width="2" stroke="#000" style="user-select: none">',
            artTextEncoded,
            "</text></svg>"
        );
    }

    /// @notice Get token uri for token.
    /// @param tokenId token id
    /// @return tokenURI
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) {
            revert URIQueryForNonexistentToken();
        }

        string memory artSvg = art(tokenId);
        (, string memory artTextTrait) = artText(tokenId);

        return Utils.formatTokenURI(
            tokenId,
            string.concat("data:image/svg+xml;base64,", Utils.encodeBase64(bytes(artSvg))),
            string.concat(
                "data:text/html;base64,",
                Utils.encodeBase64(
                    bytes(
                        string.concat(
                            '<html style="overflow:hidden"><body style="margin:0">',
                            artSvg,
                            animationScript(),
                            "</body></html>"
                        )
                    )
                )
            ),
            string.concat(
                "[",
                Utils.getTrait("Gift", artTextTrait, false, true),
                Utils.getTrait("Inner hue", getInnerColorHue(tokenId).toString(), true, false),
                "]"
            )
        );
    }
}
