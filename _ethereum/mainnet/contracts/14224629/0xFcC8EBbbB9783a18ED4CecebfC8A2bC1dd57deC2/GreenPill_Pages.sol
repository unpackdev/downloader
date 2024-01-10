pragma solidity >=0.8.0 <0.9.0;

//SPDX-License-Identifier: MIT

import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./Strings.sol";
import "./Counters.sol";
import "./base64.sol";

contract GreenPill_Pages is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    /*///////////////////////////////////////////////////////////////
                            TOKEN STORAGE
    //////////////////////////////////////////////////////////////*/

    Counters.Counter private _tokenIds;

    uint256 public price = 0.1337 ether;

    uint256 public constant pledgeLimitPerUser = 1;

    mapping(address => uint256) public pledgeLimit;

    address immutable gitcoin = 0xde21F729137C5Af1b01d73aF1dC21eFfa2B8a0d6;

    address immutable owocki = 0x00De4B13153673BCAE2616b67bf822500d325Fc3;

    bool public pledgeOpen;

    //address[] public pledgers;

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

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    bytes32 public constant AUTOGRAPH_TYPEHASH =
        keccak256(
            "signature(address sender,address recipient,string pledge,string timestamp,string msg)"
        );

    // Prevent replay
    mapping(uint256 => bool) private usedNonces;

    /*///////////////////////////////////////////////////////////////
                              STRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor() ERC721("GreenPill Pages", "GP") {
        transferOwnership(0xb010ca9Be09C382A9f31b79493bb232bCC319f01);

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*///////////////////////////////////////////////////////////////
                             MINT LOGIC
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
    function pledge() public payable {
        require(
            pledgeLimit[msg.sender] < pledgeLimitPerUser,
            "One pledge per address"
        );

        require(pledgeOpen == true, "Pledging is currently closed");
        require(msg.value >= price, "Min pledge is 0.1337 ETH");

        (bool success, ) = gitcoin.call{value: msg.value}("");
        require(success, "could not send");

        pledgeLimit[msg.sender] = pledgeLimit[msg.sender] + 1;
        //pledgers.push(msg.sender);

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
        require(balanceOf(msg.sender) < 1, "One per Address");

        /* require(!usedNonces[_nonce]);
        usedNonces[_nonce] = true; */

        //test

        (uint8 v, bytes32 r, bytes32 s) = splitSignature(_signature);

        bytes32 hashStruct = keccak256(
            abi.encode(
                AUTOGRAPH_TYPEHASH,
                // Will be wockis address in live v
                owocki,
                // Signature will be invalid if it isn't to caller
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

        // Will be wockis address in live v
        require(signer == owocki, "MyFunction: invalid signature");
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
                '<svg xmlns="http://www.w3.org/2000/svg" width="7.94in" height="10.59in" viewBox="-35 -25 571.46 762.2">',
                '<circle cx="255.76" cy="99.98" r="99.48" fill="#f6cf46" stroke="#000" stroke-miterlimit="10"/><g><path d="M233.66,179c.2,19.13,17.69,31.14,33.65,27.52,7.41-1.67,13-5.68,17.65-11.49,6.86-8.63,13.79-17.2,20.68-25.81Q317.33,154.6,329,140c4.8-6,7.36-12.8,6.57-20.46-1.26-12.29-7.75-20.74-19.65-24.61-11-3.59-22.5-.1-30.22,9.08-3.18,3.79-6.21,7.71-9.31,11.58-11.9,14.83-23.75,29.69-35.69,44.48C236.21,165.61,233.58,171.77,233.66,179Z" transform="translate(-30.92 -49.36)" fill="#fff"/><path d="M233.66,179c-.08-7.2,2.55-13.36,7-18.9,11.94-14.79,23.79-29.65,35.69-44.48,3.1-3.87,6.13-7.79,9.31-11.58,7.72-9.18,19.21-12.67,30.22-9.08,11.9,3.87,18.39,12.32,19.65,24.61.79,7.66-1.77,14.47-6.57,20.46q-11.7,14.58-23.35,29.19C298.75,177.8,291.82,186.37,285,195c-4.61,5.81-10.24,9.82-17.65,11.49C251.35,210.11,233.86,198.1,233.66,179Zm30.71-42.21c-8.09,10.36-16.3,20-23.43,30.3-5,7.2-4.35,15.43-.38,23.29a10.9,10.9,0,0,0,7.62,6c10.15,2.43,18.7-.28,25.35-8.29s13.22-16.43,19.81-24.67a25.9,25.9,0,0,0,1.41-2.28Zm33.46,20.84c7.89-10,15.69-19.11,22.6-28.86,5.31-7.48,5.08-15.89.93-24.11a10.42,10.42,0,0,0-7.17-5.82c-10.15-2.51-18.68.1-25.4,8.09-4.83,5.75-9.42,11.69-14.11,17.56-2.27,2.85-4.52,5.71-7.06,8.92Zm-37.9,44.66c8.86.25,15.8-3.18,21.19-10,6-7.65,12.13-15.22,18.19-22.84a23.88,23.88,0,0,0,1.44-2.23c-1.63-2.57-2.91-1.67-4.21-.05-5,6.22-10.15,12.31-14.93,18.69-5.59,7.46-11.94,13.71-21.39,15.88C260.13,201.69,260.08,201.93,259.93,202.26Zm69.75-86.92c0,8.65-3.87,15.58-9.24,22-5,6-9.83,12.17-14.71,18.29-1.17,1.47-2.25,3-3.25,4.37.78,1.86,1.74,2.43,3.09,1.29a17.65,17.65,0,0,0,2.25-2.47c5.41-6.71,10.83-13.42,16.18-20.18a42.38,42.38,0,0,0,4.07-5.9A21.3,21.3,0,0,0,329.68,115.34Z" transform="translate(-30.92 -49.36)"/><path d="M264.37,136.76l30.38,24.36a25.9,25.9,0,0,1-1.41,2.28c-6.59,8.24-13.08,16.56-19.81,24.67s-15.2,10.72-25.35,8.29a10.9,10.9,0,0,1-7.62-6c-4-7.86-4.6-16.09.38-23.29C248.07,156.72,256.28,147.12,264.37,136.76Z" transform="translate(-30.92 -49.36)" fill="#01e2ac"/><path d="M297.83,157.6l-30.21-24.22c2.54-3.21,4.79-6.07,7.06-8.92,4.69-5.87,9.28-11.81,14.11-17.56,6.72-8,15.25-10.6,25.4-8.09a10.42,10.42,0,0,1,7.17,5.82c4.15,8.22,4.38,16.63-.93,24.11C313.52,138.49,305.72,147.61,297.83,157.6Z" transform="translate(-30.92 -49.36)" fill="#5bf1cd"/><path d="M259.93,202.26c.15-.33.2-.57.29-.59,9.45-2.17,15.8-8.42,21.39-15.88,4.78-6.38,9.95-12.47,14.93-18.69,1.3-1.62,2.58-2.52,4.21.05a23.88,23.88,0,0,1-1.44,2.23c-6.06,7.62-12.17,15.19-18.19,22.84C275.73,199.08,268.79,202.51,259.93,202.26Z" transform="translate(-30.92 -49.36)" fill="#12c094"/><path d="M329.68,115.34a21.3,21.3,0,0,1-1.61,17.38,42.38,42.38,0,0,1-4.07,5.9c-5.35,6.76-10.77,13.47-16.18,20.18a17.65,17.65,0,0,1-2.25,2.47c-1.35,1.14-2.31.57-3.09-1.29,1-1.35,2.08-2.9,3.25-4.37,4.88-6.12,9.67-12.31,14.71-18.29C325.81,130.92,329.66,124,329.68,115.34Z" transform="translate(-30.92 -49.36)" fill="#12c094"/></g>',
                '<text transform="translate(0 282.85)" font-size="18" font-family="ArialMT, Arial">{<tspan x="0" y="28.8">"signer": 0x00De4B13153673BCAE2616b67bf822500d325Fc3,</tspan>',
                '<tspan x="0" y="57.6">"timestamp": ',
                tokens[id].timestamp,
                ',</tspan><tspan x="0" y="86.4" xml:space="preserve">"recipient": 0x',
                tokens[id].recipient,
                ',</tspan><tspan x="0" y="115.2">"pledge": ',
                tokens[id].sigValue,
                ' ETH,</tspan><tspan x="0" y="144">"version": 0,</tspan><tspan x="0" y="172.8">},</tspan><tspan x="0" y="230.4">"msg": ',
                tokens[id].writtenMsg,
                '</tspan></text></svg>'
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
                    keccak256(bytes("GreenPill_Pages")),
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
