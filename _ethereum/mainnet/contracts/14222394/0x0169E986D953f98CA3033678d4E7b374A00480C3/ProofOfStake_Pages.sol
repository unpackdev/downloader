pragma solidity >=0.8.0 <0.9.0;

//SPDX-License-Identifier: MIT

import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./Strings.sol";
import "./Counters.sol";
import "./base64.sol";

contract ProofOfStake_Pages is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    /*///////////////////////////////////////////////////////////////
                            TOKEN STORAGE
    //////////////////////////////////////////////////////////////*/

    Counters.Counter private _tokenIds;

    bool public pledgeOpen;

    uint256 internal constant price = 0.1337 ether;

    uint256 internal constant pledgeLimitPerUser = 1;

    uint256 internal constant publisherSplit = 10;

    mapping(address => uint256) public pledgeLimit;

    //prettier-ignore
    address internal immutable gitcoin = 0xde21F729137C5Af1b01d73aF1dC21eFfa2B8a0d6;

    //prettier-ignore
    address internal immutable sevenStories = 0xa62bA93BeFab6bb76B8fbc732c9135460bD23D25;

    struct Token {
        string recipient;
        string sigValue;
        string timestamp;
        string writtenMsg;
    }

    Token[] private tokens;

    /*///////////////////////////////////////////////////////////////
                               EVENTS
    //////////////////////////////////////////////////////////////*/

    event Pledge(address indexed pledgee, uint256 indexed pledgeValue);

    /*///////////////////////////////////////////////////////////////
                           EIP-712 STORAGE
    //////////////////////////////////////////////////////////////*/

    //prettier-ignore
    address internal immutable vitalik = 0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045;

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    bytes32 public constant AUTOGRAPH_TYPEHASH =
        keccak256(
            "signature(address sender,address recipient,string pledge,string timestamp,string msg)"
        );

    /*///////////////////////////////////////////////////////////////
                              STRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor() ERC721("Proof Of Stake Pages", "PoSp") {
        transferOwnership(0xb010ca9Be09C382A9f31b79493bb232bCC319f01);

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*///////////////////////////////////////////////////////////////
                             PLEDGE LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Toggles Pledging On / Off
     */
    function togglePledging() public onlyOwner {
        pledgeOpen == false ? pledgeOpen = true : pledgeOpen = false;
    }

    /**
     * @notice Pledges ETH to GTC & "whitelists" pledger
     */
    //prettier-ignore
    function pledge() public payable {
        require(
            pledgeLimit[msg.sender] < pledgeLimitPerUser,
            "One pledge per address"
        );
        require(pledgeOpen == true, "Pledging is currently closed");
        require(msg.value >= price, "Min Pledge is 0.1337 ETH");

        uint sShare = (msg.value * publisherSplit) / 100;

        (bool success, ) = gitcoin.call{value: msg.value - sShare}("");
        require(success, "could not send");

        (bool success2, ) = sevenStories.call{value: sShare}("");
        require(success2, "could not send");

        pledgeLimit[msg.sender] = pledgeLimit[msg.sender] + 1;

        emit Pledge(msg.sender, msg.value);
    }

    /**
     * @notice Allows a single mint if msg.sender has a valid signed msg
     */
    //prettier-ignore
    function mintIfSigned(
        bytes calldata _signature,
        string calldata _sigValue,
        string calldata _timestamp,
        string calldata _message
    ) external {
        require(balanceOf(msg.sender) < 1, "UNIQUE: One per Address");

        (uint8 v, bytes32 r, bytes32 s) = splitSignature(_signature);

        bytes32 hashStruct = keccak256(
            abi.encode(
                AUTOGRAPH_TYPEHASH,
                // Will be wockis address in live v
                vitalik,
                // Signature will be invalid if it isn't to caller &&
                // EIP712: "Addresses are encoded as uint160"
                uint160(msg.sender),
                // EIP712: "values bytes and string are encoded as a keccak256 hash"
                keccak256(bytes(_sigValue)),
                keccak256(bytes(_timestamp)),
                keccak256(bytes(_message))
            )
        );

        bytes32 hash = keccak256(
            abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR(), hashStruct)
        );
        address signer = ecrecover(hash, v, r, s);

        require(signer == vitalik, "MyFunction: invalid signature");
        require(signer != address(0), "ECDSA: invalid signature");

        _tokenIds.increment();
        uint256 id = _tokenIds.current();

        tokens.push(
            Token({
                recipient: toAsciiString(msg.sender),
                sigValue: _sigValue,
                timestamp: _timestamp,
                writtenMsg: _message
            })
        );

            _mint(msg.sender, id);
    }

    /*///////////////////////////////////////////////////////////////
                            TOKEN LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice SOULBOUND: Block transfers.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721Enumerable) {
        require(
            from == address(0) || to == address(0),
            "SOULBOUND: Non-Transferable"
        );
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @notice SOULBOUND: Block approvals.
     */
    function setApprovalForAll(address operator, bool _approved)
        public
        virtual
        override(ERC721)
    {
        revert("SOULBOUND: Non-Approvable");
    }

    /**
     * @notice SOULBOUND: Block approvals.
     */
    function approve(address to, uint256 tokenId)
        public
        virtual
        override(ERC721)
    {
        revert("SOULBOUND: Non-Approvable");
    }

    /**
     * @notice Generate SVG using tParams by index
     */
    function generateSVG(uint256 id) private view returns (string memory) {
        // prettier-ignore

        return string(
            abi.encodePacked(
                '<svg xmlns="http://www.w3.org/2000/svg" width="8.42in" height="11.38in" viewBox="0 0 606.27 819.53">',
                '<defs><style>.a{fill:none;stroke:#d9c8db;stroke-miterlimit:10;stroke-width:2px;}.b{font-size:60px;fill:#e96b5d;}.b,.q{font-family:BodoniSvtyTwoOSITCTT-Bold, "Bodoni 72 Oldstyle";font-weight:700;}.c,.e,.h,.j,.k,.s,.t{letter-spacing:0.02em;}.d,.l,.q{fill:#9b4a8d;}.d{letter-spacing:0.02em;}.e{fill:#9b4a8c;}.f,.g,.h,.o{fill:#0cb6ea;}.f,.g{font-size:55px;font-family:BodoniSvtyTwoOSITCTT-BookIt, "Bodoni 72 Oldstyle";font-weight:400;font-style:italic;}.f{letter-spacing:0.02em;}.i,.k{fill:#50ae58;}.i,.r,.u,.v{letter-spacing:0.02em;}.j,.m{fill:#f18a14;}.n,.r,.t{fill:#336d36;}.p{fill:#6d302c;}.q{font-size:30px;}.s,.u{fill:#000;}</style></defs><rect width="100%" height="100%" fill="white"/><rect class="a" x="21.87" y="169.54" width="562.52" height="562.52"/><text class="b" transform="translate(74.59 50.94)"><tspan class="c">P</tspan><tspan class="d" x="35.04" y="0">R</tspan><tspan class="c" x="74.46" y="0">O</tspan><tspan class="d" x="118.26" y="0">O</tspan><tspan class="e" x="162.06" y="0">F </tspan><tspan class="f" x="207.24" y="0">o</tspan><tspan class="g" x="233.75" y="0">f</tspan><tspan class="h" x="248.54" y="0" xml:space="preserve"></tspan><tspan class="i" x="269.06" y="0">ST</tspan><tspan class="j" x="336.38" y="0">AK</tspan><tspan class="k" x="420.86" y="0">E</tspan></text><polygon class="l" points="302.87 85.41 301.8 89.02 301.8 193.94 302.87 195 351.57 166.21 302.87 85.41"/><polygon class="m" points="302.87 85.41 254.17 166.21 302.87 195 302.87 144.08 302.87 85.41"/><polygon class="n" points="302.87 204.22 302.27 204.95 302.27 242.32 302.87 244.07 351.6 175.45 302.87 204.22"/><polygon class="o" points="302.87 244.07 302.87 204.22 254.17 175.45 302.87 244.07"/><polygon class="p" points="302.87 195 351.56 166.21 302.87 144.08 302.87 195"/><polygon class="l" points="254.17 166.21 302.87 195 302.87 144.08 254.17 166.21"/><text class="q" transform="translate(184.82 767.07)"></text>',
                '<text transform="translate(75 352.85)" font-size="16" font-family="ArialMT, Arial">{<tspan x="0" y="28.8">"signer": 0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045,</tspan>',
                '<tspan x="0" y="57.6">"timestamp": ',
                tokens[id].timestamp,
                ',</tspan><tspan x="0" y="86.4" xml:space="preserve">"recipient": 0x',
                tokens[id].recipient,
                ',</tspan><tspan x="0" y="115.2">"pledge": ',
                tokens[id].sigValue,
                ' ETH,</tspan><tspan x="0" y="144">"version": 0,</tspan><tspan x="0" y="172.8">},</tspan><tspan x="0" y="230.4">"msg": ',
                tokens[id].writtenMsg,
                '</tspan></text><g><path d="M311.65,811.87H281.86V741h52.37v70.87H311.84a18.63,18.63,0,0,1,1.61-4c-1,.83-2.14.63-3.24.58a1.53,1.53,0,0,1-1.35-1.59c-.08-1.17.3-1.9,1.09-2.15l.09,0h2.55v1.53h-1.94a.61.61,0,0,0-.46.3c-.07.33.23.34.46.36a2.59,2.59,0,0,0,2.24-.65,4,4,0,0,1,1-.76c1-.51,1-1.52,1.32-2.42H309v-3.24h1.46v1.62h2.2v-1.54h1.44v1.55c1.29.18,1.29.18,1.71-1,0-.13.09-.25.14-.37.25-.74.5-1.49.79-2.32l-7.69.86V797l6.46-.67-6.46-.6v-1.59a2.3,2.3,0,0,1,.39,0c2.62.31,5.23.63,7.86.93.13,0,.38,0,.41-.11.27-.71.52-1.44.79-2.24h-9.45v-3.25h1.4v1.65h2.2V789.6h1.45v1.56h3.1v-1.64h1.42v2.68h.09l9.61-27.43-9.68-3.11c0,.54-.37.5-.66.52-1,.05-2,.07-3.06.09-.41,0-.67.12-.62.64h4.27v1.6h-8.23a.68.68,0,0,0-.51.22c-.29.68-.52,1.38-.77,2.06a1.85,1.85,0,0,1,1.35-.66h6.83a1.36,1.36,0,0,1,1.4,1,4.11,4.11,0,0,1,0,1.6,1.39,1.39,0,0,1-1.48,1.2q-3.39,0-6.78,0a1.45,1.45,0,0,1-1.5-1.24,8.94,8.94,0,0,1-.11-1.27l-14,38.26.57.21,12,4.36C308.85,810.81,310.25,811.34,311.65,811.87ZM286.19,759.2h43.46V744.92H286.19Zm27.63,9.2H317c.14,0,.29-.21.44-.33a3.25,3.25,0,0,0-.42-.31,1,1,0,0,0-.34,0H311a2.47,2.47,0,0,0-.54,0,.38.38,0,0,0-.22.23.38.38,0,0,0,.11.3,1.09,1.09,0,0,0,.47.09Zm1.69-7.81-4-1.24-.41,1.29c.91,0,1.89-.25,2.37,1,.41-1,1.26-.87,2-1Zm-5.13,2.27h2.53c0-.44-.15-.61-.55-.59s-.92,0-1.37,0S310.36,762.41,310.38,762.86Z" transform="translate(-0.05)" fill="#fff"/><path d="M311.65,811.87l-4.21-1.58-12-4.35-.57-.22,14-38.25a9.06,9.06,0,0,0,.1,1.27,1.46,1.46,0,0,0,1.5,1.24q3.39,0,6.78,0a1.39,1.39,0,0,0,1.48-1.2,3.92,3.92,0,0,0,0-1.6,1.35,1.35,0,0,0-1.4-1h-6.82a1.79,1.79,0,0,0-1.36.66c.25-.69.49-1.39.77-2.06.06-.13.33-.22.51-.22h8.24V762.9h-4.28c-.05-.52.22-.63.62-.64,1,0,2,0,3.07-.1.28,0,.66,0,.66-.52l9.67,3.12q-4.83,13.77-9.6,27.43h-.1v-2.68h-1.42v1.65h-3.1v-1.57h-1.45v1.56h-2.19V789.5h-1.4v3.25h9.46c-.28.8-.52,1.53-.8,2.24,0,.08-.28.13-.41.11l-7.86-.93a2.76,2.76,0,0,1-.38,0v1.6l6.45.59-6.46.68v1.61l7.71-.86c-.29.83-.54,1.58-.8,2.32,0,.12-.09.24-.14.37-.41,1.16-.41,1.16-1.71,1v-1.55h-1.44v1.56H310.5v-1.62H309v3.24h6.16c-.36.9-.35,1.9-1.33,2.42a4.42,4.42,0,0,0-1,.75,2.59,2.59,0,0,1-2.24.66c-.22,0-.52,0-.45-.36a.57.57,0,0,1,.45-.3c.64,0,1.28,0,1.95,0v-1.53h-2.55a.19.19,0,0,0-.1,0c-.79.25-1.16,1-1.08,2.14a1.52,1.52,0,0,0,1.34,1.59c1.11.06,2.27.26,3.25-.57a19.19,19.19,0,0,0-1.61,4Zm3.9-27.33c-2.06.3-4.12.59-6.16.9a.46.46,0,0,0-.35.23c0,.68,0,1.37,0,2.06h9.55v-1.32h-7c.41-.09.85-.13,1.27-.18,1.82-.23,3.63-.45,5.44-.7a.41.41,0,0,0,.27-.26c0-.65,0-1.31,0-2H309v1.26Zm-3-8.9c-.82,0-1.62,0-2.4,0a1.25,1.25,0,0,0-1.19,1,5.08,5.08,0,0,0,0,1.74,1.24,1.24,0,0,0,1.15,1,4.14,4.14,0,0,0,3.71-.91c.18-.17.39-.31.57-.47a2.73,2.73,0,0,1,2.34-.83c.26,0,.69-.16.71.3s-.45.32-.72.33c-.62,0-1.23,0-1.86,0v1.57c.89,0,1.74.06,2.59,0a1.43,1.43,0,0,0,1.29-1.4,2,2,0,0,0-.87-2.24,2.4,2.4,0,0,0-.59-.13,4.31,4.31,0,0,0-4,1.24c-.09.1-.22.15-.31.25a2.59,2.59,0,0,1-2.39.74c-.17,0-.44-.16-.46-.29-.06-.33.23-.34.47-.34h1.94Zm-3.52-4.72v4h1.41v-1.24h8.1v-1.58h-8.13v-1.17Z" transform="translate(-0.05)"/><path d="M286.19,759.2V744.92h43.46V759.2Zm26.39-11.08v-1.59h-2.15a1.51,1.51,0,0,0-1.54,1.44c-.17,1.16.22,2.16,1.05,2.29,1.24.19,2.53.34,3.62-.61.45-.41.93-.73,1.39-1.11a3.06,3.06,0,0,1,2.28-.41.3.3,0,0,1,0,.58,2,2,0,0,1-.54,0H314.9v1.54c.91,0,1.81.07,2.68,0s1.24-.83,1.22-1.89-.44-1.69-1.22-1.85a.62.62,0,0,1-.19,0,4.45,4.45,0,0,0-4.07,1.24c-.12.12-.28.19-.39.31a2.56,2.56,0,0,1-2.27.67c-.23,0-.54,0-.46-.35,0-.13.3-.28.46-.29.61,0,1.24,0,1.91,0Zm4.62,5.2h-3.1v-1.57h-1.46v1.58h-2.17v-1.65h-1.4v3.24h9.52v-3.28H317.2Zm1.4,3.35h-9.53v1.51h9.53Z" transform="translate(-0.05)"/><path d="M313.82,768.4h-3.06a1,1,0,0,1-.47-.1.34.34,0,0,1-.11-.29.34.34,0,0,1,.22-.23,1.94,1.94,0,0,1,.54,0h5.77a.78.78,0,0,1,.34,0,2.1,2.1,0,0,1,.41.31c-.14.12-.29.33-.44.33-1.07,0-2.14,0-3.21,0Z" transform="translate(-0.05)"/><path d="M315.52,760.59c-.77.13-1.62,0-2,1-.47-1.2-1.46-.92-2.37-1l.42-1.29Z" transform="translate(-0.05)"/><path d="M310.38,762.86c0-.45.15-.64.61-.6s.92,0,1.37,0,.59.15.55.59Z" transform="translate(-0.05)"/><path d="M315.55,784.54H309v-1.26h9.58v2a.4.4,0,0,1-.26.26c-1.82.25-3.63.47-5.44.7-.42,0-.85.09-1.28.18h6.95v1.32H309v-2.06c0-.09.22-.22.35-.24Z" transform="translate(-0.05)" fill="#fff"/><path d="M312.59,775.64v1.58h-1.93c-.24,0-.53,0-.47.34,0,.12.28.27.46.29a2.59,2.59,0,0,0,2.39-.74c.09-.1.22-.16.3-.25a4.42,4.42,0,0,1,4-1.24,1.92,1.92,0,0,1,.57.15,2,2,0,0,1,.87,2.23,1.45,1.45,0,0,1-1.29,1.41c-.83.07-1.71,0-2.59,0v-1.54h1.86c.27,0,.73.17.71-.33s-.44-.26-.7-.3a2.72,2.72,0,0,0-2.34.82c-.18.17-.41.31-.57.48a4.16,4.16,0,0,1-3.71.91,1.24,1.24,0,0,1-1.15-1,4.63,4.63,0,0,1,0-1.74,1.25,1.25,0,0,1,1.19-1C311,775.61,311.77,775.64,312.59,775.64Z" transform="translate(-0.05)" fill="#fff"/><path d="M309.07,770.92h1.38v1.16h8.13v1.59h-8.1v1.24h-1.41Z" transform="translate(-0.05)" fill="#fff"/><path d="M312.57,748.12c-.67,0-1.3,0-1.92,0a.58.58,0,0,0-.46.29c-.07.33.24.32.46.35a2.56,2.56,0,0,0,2.27-.67c.12-.12.28-.19.39-.31a4.4,4.4,0,0,1,4.07-1.24.71.71,0,0,1,.2,0c.77.16,1.2.82,1.21,1.85s-.41,1.81-1.21,1.89-1.77,0-2.68,0v-1.54h1.79a1.87,1.87,0,0,0,.53,0,.3.3,0,0,0,0-.58,3,3,0,0,0-2.28.41c-.46.38-.94.72-1.38,1.11-1.09,1-2.38.8-3.63.61-.82-.13-1.23-1.13-1.05-2.29a1.51,1.51,0,0,1,1.54-1.44h2.15Z" transform="translate(-0.05)" fill="#fff"/><path d="M317.19,753.32v-1.68h1.39v3.28h-9.51v-3.24h1.4v1.65h2.18v-1.58h1.45v1.57Z" transform="translate(-0.05)" fill="#fff"/><path d="M318.6,756.67v1.51h-9.53v-1.51Z" transform="translate(-0.05)" fill="#fff"/></g></svg>'
            )
        );
    }

    /**
     * @notice Generate SVG, b64 encode it, construct an ERC721 token URI.
     */
    function constructTokenURI(uint256 id)
        private
        view
        returns (string memory)
    {
        // prettier-ignore

        uint256 cID = id - 1;

        string memory pageSVG = Base64.encode(bytes(generateSVG(cID)));

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"signed_to":"0x',
                                tokens[cID].recipient,
                                '", "timestamp":"',
                                tokens[cID].timestamp,
                                '", "pledge":"',
                                tokens[cID].sigValue,
                                '", "message":"',
                                tokens[cID].writtenMsg,
                                '", "image": "',
                                "data:image/svg+xml;base64,",
                                pageSVG,
                                '"}'
                            )
                        )
                    )
                )
            );
    }

    /**
     * @notice Receives json from constructTokenURI
     */
    // prettier-ignore
    function tokenURI(uint256 id)
        public
        view
        override
        returns (string memory)
    {
        //require(id <= limit, "non-existant");
        require(_exists(id), "not exist");
        return constructTokenURI(id);
    }

    /*///////////////////////////////////////////////////////////////
                             SIG LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice https://eips.ethereum.org/EIPS/eip-712
     */
    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return
            block.chainid == INITIAL_CHAIN_ID
                ? INITIAL_DOMAIN_SEPARATOR
                : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256(
                        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                    ),
                    keccak256(bytes("ProofOfStake_Pages")),
                    keccak256(bytes("0")),
                    block.chainid,
                    address(this)
                )
            );
    }

    function splitSignature(bytes memory sig)
        private
        pure
        returns (
            uint8 v,
            bytes32 r,
            bytes32 s
        )
    {
        require(sig.length == 65);

        assembly {
            // first 32 bytes, after the length prefix.
            r := mload(add(sig, 32))
            // second 32 bytes.
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes).
            v := byte(0, mload(add(sig, 96)))
        }

        return (v, r, s);
    }

    /*///////////////////////////////////////////////////////////////
                             TYPE LOGIC
    //////////////////////////////////////////////////////////////*/

    function toAsciiString(address x) internal pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint256 i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint256(uint160(x)) / (2**(8 * (19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2 * i] = char(hi);
            s[2 * i + 1] = char(lo);
        }
        return string(s);
    }

    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }
}
