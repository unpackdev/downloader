// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./Counters.sol";
import "./base64.sol";


interface DamienInterface{
  function getDamien() external view returns (string memory);
}

contract LoveLetters is Ownable, ERC721Enumerable {

    DamienInterface private _damienContract;

    using Counters for Counters.Counter;
    //Relevant mappings
    Counters.Counter private _tokenIdTracker;
    // initilization inputs
    uint256 private _price;
    uint256 public maxSupply;


    mapping(uint256 => string) private tokenIdToLetter;
    mapping(uint256 => string) private tokenIdToSenderName;
    mapping(uint256 => string) private tokenIdToRecipientName;

    address public constant staffVaultAddress =
        0x8Cd4af5786685a458e7A16CF456887364eB6277d;

    event LetterWritten(
        uint256 letterid,
        address author_address,
        address to_address,
        string author_name,
        string recipient_name,
        string content
    );

    function toString(uint256 value) internal pure returns (string memory) {
    // Inspired by OraclizeAPI's implementation - MIT license
    // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    //Constructor
    constructor(
        string memory name_,
        string memory symbol_,
        uint256 maxSupply_,
        uint256 price_,
        address damienAddress_
    ) ERC721(name_, symbol_) {
        maxSupply = maxSupply_;
        _price = price_;
        _damienContract = DamienInterface(damienAddress_);
         _tokenIdTracker.increment();
    }

    function mint(address to) internal {
        _safeMint(to, _tokenIdTracker.current());
        _tokenIdTracker.increment();
    }

    function writeLetter(
        string memory letter,
        address to,
        string memory recipientName,
        string memory senderName
    ) public payable {
        require(to != msg.sender);
        require(msg.value >= _price);
        require(totalSupply() + 1 <= maxSupply);
        tokenIdToLetter[_tokenIdTracker.current()] = letter;
        tokenIdToRecipientName[_tokenIdTracker.current()] = recipientName;
        tokenIdToSenderName[_tokenIdTracker.current()] = senderName;
        mint(to);

        emit LetterWritten(
            _tokenIdTracker.current() - 1,
            msg.sender,
            to,
            senderName,
            recipientName,
            letter
        );
    }


    function readLetter(uint256 tokenId) public view returns (string memory) {
        return string(tokenIdToLetter[tokenId]);
    }

    function withdrawAll() public payable onlyOwner {
        uint256 balance = address(this).balance;
        payable(staffVaultAddress).transfer(balance);
    }


    //tokenURI function
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        string[11] memory parts;
        parts[
            0
        ] = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 239" preserveAspectRatio="xMinYMin meet" fill="none" xmlns:v="https://vecta.io/nano"><defs><style>@font-face{font-family:"Damion";src:url(';


        parts[1] = _damienContract.getDamien();

        parts[2] = ') format("woff"); font-weight:normal;font-style:normal;}</style></defs><style><![CDATA[.B,.d{font-family:Damion}.C{fill:#3116da}.D,.d{font-size:12px}]]></style><path d="M256 0H0V239H256V0Z" fill="#000"/><path d="M192.4.3c-1 .4-1.7 1-2.4 2.6-.6 1.3-1.3 2.2-2 2.5-.3.1-1.7.3-3.2.4l-2.7.1-.8-.5c-1-.7-1.6-1.5-2-3-.2-.6-.6-1-.8-1.2-.2-.1-1 0-1.8.1-1.7.3-3 1-3 1.8 0 1.5-2.4 3-5 3-1.6 0-2.8-.3-6.6-1.6l-4-1.3c-.4-.1-.8.1-1.5 1-1.3 1.2-2.8 1.8-4.7 1.8-2.3 0-4.3-1-5.2-2.3-.5-.7-1.7-1.2-3-1.2-1.4 0-2 .3-3.2 1.7-1.4 1.5-2.3 2-4.5 2-1.3 0-2-.1-2.8-.4-1.4-.6-2.8-2-2.8-2.6 0-.8-1-1.5-2.3-1.5-.6 0-1.5.1-2 .2-1 .2-1 .3-1.3 1.3-.5 1.3-1.2 2-2.5 2.5-3 1.2-7 .3-8-1.8l-.7-1c-.3-.3-2-.3-3.4 0-1 .2-1.3.3-2 1.3-1.3 1.5-2 1.8-4.6 1.8-2.5 0-3.4-.3-4.8-1.6-.7-.7-1-1-2.2-1.2-1-.3-1.5-.2-2.6 0-.8.2-1.5.5-1.7.7-.6.7-3 1.8-4 2-1.4.2-3.5-.1-4.5-.7-.4-.2-1-1-1.4-1.6C81.4 2 81 1.8 80 2.6c-.4.3-1.5.7-2.3 1s-2 .6-2.7 1c-2.4 1-4.8 1.2-6.6.8-1.2-.3-2.5-1-2.5-1.4 0-.7-1-1.5-2.2-2-2-.7-4.2-.1-4.2 1 0 .6-1.4 1.7-2.7 2-2 .6-4.5.4-6-.6-.3-.2-1-.7-1.2-1-.8-1-2-1.4-3.5-1.4-1.6 0-2 .2-3.2 1.6-.4.5-1.2 1-1.7 1.3-.8.4-1 .4-2.8.3-4-.2-4.5-.5-5-2-.6-1.6-.8-1.7-2.6-1.7-2.2 0-3 .4-4.5 2-.7.8-1.5 1.4-2 1.6-1 .4-3.2.5-4.7.1C18 4.8 16 3.4 16 3c0-.5-1-.8-3-.8-2 0-2.4.1-2.4.7 0 .8-4.5 3.5-6 3.5-.2 0-.8-.2-1.2-.4s-1-.4-1-.4c-.1 0-.6.4-1 1C1 7.2 1 7.7.7 9.2c-.1 1.2 0 2 .2 2.2.2.3 1.2.8 2.3 1.3 1.3.5 2.2 1 2.5 1.5.6.8 1 3.2.4 4-.2.2-1.4 1-2.7 1.8C1.2 21 1 21.2 1 22c-.2 1 .3 2.3 1 2.5.3.1 1.2.4 2 .8 2 1 2.6 2 2.6 4 0 1.7-.4 2.2-2.8 3.4-1.8 1-2.2 1.4-2.2 3 0 .7.1 1 .7 1.2.4.2.8.4 1 .4.7 0 2 .7 2.5 1.4.7 1 1 2.7.6 3.6-.4 1-2.3 2.5-3.8 2.8-1 .2-1.2.4-1.7 1.3-.3.6-.6 1.4-.7 1.8L0 49h1.5c2 0 3.5.5 4.3 1.6C7 52 6.4 54 4.2 56c-1.8 1.6-2.2 2.2-2.5 3.2-.3 1 0 1.8 1 2 2.2.6 3 1 3.4 1.5.7 1 1 2 .4 3.2-.5 1.3-.6 1.3-2.5 3-1.6 1.2-2 2-1.7 3 .2.8 1 1.4 2 1.6 1.2.3 1.8 1 2 2.3.3 2-1 3.2-3 3.2-2.6 0-3 .7-2 3.3 1 2.3 1 2.6 2 2.8 1 .2 2 1 2.6 2 1.4 2.2-.1 4.8-3 5.4-2.7.5-3 1-1.7 2.7.7 1 1 1.4 2.4 2 2 1 2.3 1.3 2.6 2 1 2.3-.3 4.5-3 5.7-1 .5-1.8 1.4-1.8 2.4 0 1 .5 1.3 2 2 3.7 1.4 4 4 1 6-1 .6-1.3 1-1.7 2-1 2.4-.5 3.7 2 4.5 1 .3 1.7 1.4 1.8 3 .1 1 0 1.3-.7 2.2-.6.7-1 1-2 1.5-2 .7-2.3 1-2.3 2.4s.6 2 2.4 2.8c2 1 3 2.2 2.8 3.8-.1.5-.3 1.2-.6 1.5-.6.8-2.3 2-3.4 2.6-1.2.5-1.3.7-1.3 1.5 0 .7.4 1 3.2 3 1.8 1 2.3 3.5 1.2 5.3-.5.7-1.3 1-2.4 1-1 0-1.5.4-1.7 1.6l-.3 2c-.1.8.1 1 1.2 1.3 1.7.3 3.2 2 3.4 3.7.2 1.6-.2 2.3-2 3.2-1.8 1-2 1.4-2.6 3.2-.4 1.4-.2 2 .5 1.8.6-.2 2.7.8 3.6 1.8.5.5.6.8.6 2 0 .7-.1 1.6-.3 1.8-.2.3-1 1-2 1.7-1.8 1.3-3 2.6-3.2 3.8-.2.7.1 1 1.6 1.2 1 .2 2.6 1.2 3 2 .6 1 1 2.5.6 3.4-.4 1-1.8 2-3.5 2.4-1.2.3-1.5.4-1.8 1-.7 1.2.2 2.5 2 3 1.8.6 2.8 1.4 3.3 2.5.8 2-.6 4.4-3 4.8-2.4.4-3 1.4-2.3 3.2.4 1 .6 1 2 1.8 2 1 3 1.6 3.4 2.3.5.7.5 2.6-.1 3.5-.4.7-1 1-3.7 1.7-1.2.3-1.4.5-1.6 1.8-.2 1.6.1 2 2.4 3 2.5 1 3 1.8 3 4 0 1.8-.2 2-2.3 3.2-1.7 1-2.6 1.8-3 2.7-.3 1 0 1.2 1.7 1.7 1.5.4 3.4 1.6 3.4 2.2 0 .1.6 1 1.4 1.6a9 9 0 0 1 1.6 1.8c.3.7.8 1 2 1.4 1.6.4 2.3.2 4-1.7 2.2-2 2.4-2.3 4.3-2.4 2.5-.2 3.2.3 4 3 .3 1 .5 1 1 1.3 1 .3 4 .2 5-.2.4-.1 1.3-1 2-1.6 2.2-2.2 2.6-2.4 5-2.4 2 0 2.2 0 3 .5 1 .7 2.3 2.2 2.4 3.3.2 1 .8 1.3 2.4 1.2 1.5-.2 2.4-1 3.5-2.6 1-1.4 1-1.6 2-2 1.2-.4 2-.5 3.8-.2 2.3.4 3.7 1.3 4 3 .2.7.6 1 1.6 1.4 1.2.4 2.3.6 3.4.3 1-.2 1-.3 1.4-1.8.2-1 1.4-2.4 2.4-2.6.4-.1 1.5-.2 2.5-.3 1.4-.1 2 0 2.8.2 1.5.5 1.8.8 2.4 2.3l.5 1.3h1c2.3 0 3.2-.3 4.8-1.8 1.7-1.5 2.8-2 4.2-2.3 1.8-.2 2.6 0 4.5 1.4 2 1.4 3.3 2 5 2.2 1.3.2 1.5.1 2-1 .7-1.5 3-2.6 5.7-2.6 2.3 0 4.5 1 4.5 2 0 .7.6 1.8 1.2 2 .7.3 2 .3 3 0a16 16 0 0 0 4.3-3.3c1-.8 4.3-1 5.4-.1.3.2 1 .8 1.4 1.5 1 1.2 1 1.2 2.3 1.4.8.1 2 .1 2.5.1 1.2-.1 1.6-.4 3.4-2 1.5-1.5 3.2-1.8 5.6-1.3 1 .2 1.3.5 2 1.2 1.8 2 4 3 6 2.4 1-.3 1.2-.4 2-2 .5-1 2.2-1.6 4-1.8 2.8-.2 5.2.8 5.5 2.3.1.4.3 1 .4 1a15 15 0 0 0 2.1.6c1 .2 1.8.5 1.8.6s.3.2.6.1c.5-.1.6-.2.7-1 .3-2 2.8-3.6 5.5-3.6 1.8 0 2.4.3 3 1.6.8 2 2.7 3 5.4 3 1.8 0 2-.2 2.3-1 .5-2 4.2-4 7-3.7 1.2.1 3 1.5 3.6 2.6.3.5.8 1 1.3 1.2 1.8.8 3.5 1.3 4 1.3.2-.1.4-.5.5-1 .3-1.8 1.7-3.2 3.6-3.6 1.2-.2 3.8-.2 4.5 0 1 .4 2.3 1.4 3 2.4.7 1 1.6 1.5 3.6 1.7 1.3.1 1.3.1 2.4-2 .5-1 2-2 3.3-2.3 2-.5 5 .2 5.8 1.4.2.3.4 1 .5 1.8.2 1.4 1 2.3 2 2.7 1.4.5 1.7.4 3-1.6 1.5-2 3.6-4 5-4.2 1-.2 4.3.2 5 .5.2.1.7.8 1 1.4 1 1.5 1.8 2.2 3.2 2.6 1.3.4 2.2.3 2.6-.3 2-3 2-3.2 3.2-3.8 1.6-.7 3.5-.7 5.4 0 1.8.7 2.4.6 2.4-.4 0-1-.8-2-2.2-2.8-1-.6-1.3-.8-1.8-2-.5-1.4-.6-1.5-.2-2.4.5-1.3 1.4-2 3.7-2.5l2-.5v-1c.1-1.4-.2-1.8-2.4-3.2-2-1.3-2.8-2-3-3-.2-1 .2-2 1-2.7.3-.2 1.4-.7 2.8-1 2.7-.7 2.8-1 1.7-2.7-.7-1-1-1.3-2.6-2.2-1.2-.7-2-1.3-2.4-1.8-.6-1-.8-2.3-.4-3.3.3-1 1.7-1.8 3-2 2.6-.5 2.5-.4 2.4-1.8-.1-.7-.2-1.6-.2-2 0-.8-.1-1-2.4-2.6l-2.4-1.7V190c0-1.4 0-1.4 1-2 1-.7 2.5-1 4.5-1 1.6 0 1.8-.2 1-1-.2-.2-.4-.7-.4-1 0-1-1-2-2.2-2.3-3-.7-4.4-2-4.4-4 0-2 1.5-3.3 4.3-3.5 1.7-.1 2-.4 2-1-.3-1-1.5-2.7-1.8-2.7-.5 0-3-2-3.4-2.7-.2-.4-.5-1.5-.5-2.5-.1-2-.1-2 2.7-2.8 1.8-.4 2-.6 2.3-2 .3-1.7-.7-3-3.4-4-1-.4-1.3-.6-1.7-1.2-.8-1.5-.4-2.7 1.7-4.5 1.4-1 2-2.5 1.8-3.7-.1-.6-.5-1-1.5-2-2.6-2.2-3.2-3.5-2-5.2.6-1 1.7-1.4 4-1.7 2.4-.4 2.5-.4 2.3-3-.1-1.7-.3-2.3-.6-2.5-.2-.1-1-.2-2-.2-1.3 0-1.6-.1-2.2-.5-2-1.5-2-4-.1-5.6.3-.2 1-.6 1.8-.7 1.4-.3 1.7-.7 1.7-1.7 0-1.3-.8-2.4-2.2-3-2-.8-2.5-1.3-2.7-2.5-.2-1.3.2-2.5 1-3.2.7-.5 3-1.4 3.8-1.4s1-1 .8-2.5a3 3 0 0 0-2.6-2.4c-2.8-.6-4-3-2.5-5.2.8-1.2 1.4-1.5 3.3-1.6.8-.1 1.6-.2 1.8-.4.6-.3.8-1.6.3-2.7-.4-.8-.8-1.2-2.6-2.3-1.2-.8-2.3-1.6-2.5-1.8-.3-.3-.4-1-.4-2 0-1.3.1-1.6.5-2 .3-.2.5-.3.6-.2.3.2 2-.1 2.8-.7 1.4-1 1.7-2.7.7-4-.2-.3-1-.7-2.2-1-2.3-.8-2.6-1.2-2.7-3.4-.1-2 1-3.6 2.5-3.6 1 0 2.3-.6 2.6-1.3.5-1 0-2-1.2-3-.6-.5-1.5-1-2-1.2-1-.3-1.8-1.3-2.2-2.8-.6-2 .4-3.3 3-4 2-.5 3-1.6 3-3 0-.7-1-1.3-3-2.2-2-.8-2.7-1.6-2.7-3.5 0-1.2.1-1.5.8-2.2.7-.8 1-1 2.3-1.2 2-.4 3-1 3-1.7 0-.4-.2-1-.4-1.6-.5-1-.6-1-3-1.8-1.6-.5-2-1-2.3-3-.2-1.4-.2-1.7.2-2.5.3-.5.8-1 1.2-1.5.7-.6 1-.6 2-.6 2 0 2.2-.1 2-2.4-.2-1.7-.3-2-.8-2.3-.3-.2-1-.4-1.2-.4-2.3 0-4-2.3-3.4-4.6.4-1.3 1-1.7 3-2.3 2.8-.7 3-1 2.3-2.7-.4-1-.8-1.2-3.7-3l-1-.8v-2c-.1-2-.1-2 .5-2.5.3-.3 1.4-.8 2.4-1.2 2.2-1 3-1.7 2.4-2.8-.3-.7-.6-1-3.6-2.2-1.2-.5-2-1.8-2.2-3.2-.1-1 0-1.3.7-2.4l.8-1.2-.8-.2c-.4-.1-1.3-.3-2-.4-1.3-.1-1.7-.3-3.5-2-1.5-1.4-2.6-1.8-4.3-1.6-1 .1-2.2 1-2.2 1.8 0 .6-1.2 1.4-2.7 1.8-1.6.3-2.3.3-4 0-1.7-.4-3-1.2-3.4-2.2-.3-1-1-1-3-1-2 0-2.7.2-3 1-.5 1.4-1.5 2-3.8 2.5-2.7.4-5.3-.4-6.2-2-1-1.6-1.6-1.8-4-1-1 .3-1.8.7-3 1.7-1.5 1-2 1.3-3 1.4-1.4.1-3 0-4-.4-1.4-.6-3-3-2.7-4 .1-.3 0-.7-.2-1-.4-.6-1.5-.7-2.8-.2z" fill="#fff"/><text xml:space="preserve" style="white-space:pre" letter-spacing="0em" class="B C D"><tspan x="18" y="58.9">Dear  </tspan></text><text fill="#000" xml:space="preserve" style="white-space:pre" letter-spacing="0em" class="B D"><tspan x="46.7" y="58.9">';

        parts[3] = tokenIdToRecipientName[tokenId];

        parts[
            4
        ] = ',</tspan></text><text xml:space="preserve" style="white-space:pre" letter-spacing="0em" class="B C D"><tspan x="18" y="200.9">Love,</tspan></text><text fill="#000" xml:space="preserve" style="white-space:pre" letter-spacing="0em" class="B D"><tspan x="18" y="216.9">';

        parts[5] = tokenIdToSenderName[tokenId];

        parts[
            6
        ] = '</tspan></text><path d="M19 22.6l5.6-3.7 5 3.7-3.2 3-7.4-3z" fill="#e4a649"/><path d="M43 23.2L36.2 19l-2 6.7 8.6-2.5z" fill="#b5f42e"/><path d="M19 31.4L36.2 19l-3 12.5H19z" fill="#e6f15f"/><path d="M19 30.5v-7.7l7.7 2.7-7.7 5z" fill="#bb3030"/><path d="M30.3 40L19 31.4h8.6l2.7 8.7z" fill="#801ecd"/><path d="M43 31.4H28.5L31 40 43 31.4z" class="C"/><path d="M33.3 31.4l1.7-6 8-2.7v8.6h-9.6z" fill="#42da51"/><path d="M36 18l-5.6 4-5.6-4-7 4.4v8.7L30.5 41 43 31.2v-8.7L36 18zm-11 7.7l-5.8 4v-6l5.8 2zm5.3-2l4.6-3.3-2.6 9.8H20.7l9.7-6.6h0zm6-3.8l4.3 2.8-5.5 2 1.2-4.7zm-9 11.7l2 6.8-8.6-6.8h6.8zm1.4 0h11.6L30.8 39l-2-7.5zm12.8-1.4h-7.8l1-4 6.7-2.3v6.4zm-12.3-7.4l-2.8 2-6.3-2 4.6-3 4.5 3.2z" fill="#000"/><text xml:space="preserve" style="white-space:pre" font-size="24" letter-spacing="0em" class="B C"><tspan x="50" y="36.2">#';

        parts[7] = toString(tokenId);

        parts[
            8
        ] = '</tspan></text><foreignObject class="d" x="18" y="68.9" width="220px" height="110px"><div xmlns="http://www.w3.org/1999/xhtml" style="text-overflow: ellipsis; display: -webkit-box; color: rgba(0,0,0,0.7); -webkit-line-clamp: 6; -webkit-box-orient: vertical">I love you because ';

        parts[9] = tokenIdToLetter[tokenId];

        parts[
            10
        ] = '</div></foreignObject><path d="M218 18h24v24h-24zm0 179h24v24h-24z" class="C"/></svg>';
        string memory output = string(
            abi.encodePacked(
                parts[0],
                parts[1],
                parts[2],
                parts[3],
                parts[4],
                parts[5],
                parts[6],
                parts[7],
                parts[8]
            )
        );
        output = string(abi.encodePacked(output, parts[9], parts[10]));


        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "Letter #',
                        toString(tokenId),
                        '", "description": "On-chain Letters of Love", "image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(output)),
                        '"}'
                    )
                )
            )
        );
        output = string(
            abi.encodePacked("data:application/json;base64,", json)
        );

        return output;
    }



  }
