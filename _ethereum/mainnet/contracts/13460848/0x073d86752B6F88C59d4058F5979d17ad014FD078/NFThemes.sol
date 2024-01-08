//Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721](https://docs.openzeppelin.com/contracts/3.x/erc721)
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./ERC721URIStorage.sol";

contract NFThemes is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    // Constants
    address WITHDRAW_WALLET = 0x88832EA5997BD53fB6a134a7F4CfD959cc42Aded;
    address[] GIVEAWAY_ADDRESSES = [
        0x88832EA5997BD53fB6a134a7F4CfD959cc42Aded,
        0x4BDb31EbBE2eFe4213fbD327cc4ece52B65377FE,
        0x4481E4880A78B738b4fb49B4C1DBb9055DE20945,
        0x710975f0485D4E54F0Ad00085D8754e232525db5,
        0x8BA01A96A1b096D721f97E3a144f7DBB6f839Aa3,
        0x8BA01A96A1b096D721f97E3a144f7DBB6f839Aa3,
        0xD6B972013Fe0c61A0d118601BF02276f16a0a32f,
        0x44d95694319836c62CD025aB4456d95c56598D00,
        0x44d95694319836c62CD025aB4456d95c56598D00,
        0x96645F4417F901b26e206B977fBab45ed08BBcE8,
        0x96645F4417F901b26e206B977fBab45ed08BBcE8,
        0x1E75754896e6947Ecf0b94a524F889826b7E77aA,
        0x34fcafeEDb28a6EEF980f70842D0C32d85a82B8F,
        0xFD9F05ccFA4BF52EF2Fb8C6bb2Ce41e81b19b8F5,
        0x66c69C342ade1ab665074E5307837dB74Ef4fbE9,
        0xA5ece55aC3c92709c996855B7aD9ecaEFd8aDaB0,
        0x37Ac57fb4b4356784C33dDa8dd0f8b039A3f732D
    ];
    
    // Config
    mapping(address => bool) presaleAddresses;
    uint256 maxSupply = 4999;
    bool isfullMintActive = false;
    uint256 priceWei = 100000000000000000; // 0.1 ETH
    string
        private _nfthemeBaseURI = "https://gateway.pinata.cloud/ipfs/QmQdyy34Ps5YSspC2ZdqoA2PCF4aQfPxxMRi4jJ79DTku2/";

    constructor() ERC721("NFThemes", "nfthemes") {
        // Initialize presale
        presaleAddresses[0x88832EA5997BD53fB6a134a7F4CfD959cc42Aded] = true;
        presaleAddresses[0x92e3aBaF9351aa3D5D9FBC8264774e11Ab32405f] = true;
        presaleAddresses[0xff97E35d3745667e677A5e2443E7259D3c90f2b4] = true;
        presaleAddresses[0x410b1d0c8796ABD01D0E5CE8f4ed3C7D3107E835] = true;
        presaleAddresses[0x6E3aFdd4758C98eb2A5C43cb0bC4dfE81d5F11FC] = true;
        presaleAddresses[0xCba9Aa49C32e8B85a486e305c4E23DD37e76B046] = true;
        presaleAddresses[0x6E3aFdd4758C98eb2A5C43cb0bC4dfE81d5F11FC] = true;
        presaleAddresses[0xFD9F05ccFA4BF52EF2Fb8C6bb2Ce41e81b19b8F5] = true;
        presaleAddresses[0x5d6C87cAFB94CF9Efb3d23FcEb978749dd0ae87a] = true;
        presaleAddresses[0xFFE524a3715595A4586c5406586Fb9f35A926798] = true;
        presaleAddresses[0x58013a0030Bb030C4f109e38e0493A7D3D4a141c] = true;
        presaleAddresses[0xD6B972013Fe0c61A0d118601BF02276f16a0a32f] = true;
        presaleAddresses[0x8BA01A96A1b096D721f97E3a144f7DBB6f839Aa3] = true;
        presaleAddresses[0x44d95694319836c62CD025aB4456d95c56598D00] = true;
        presaleAddresses[0x96645F4417F901b26e206B977fBab45ed08BBcE8] = true;
        presaleAddresses[0x1E75754896e6947Ecf0b94a524F889826b7E77aA] = true;
        presaleAddresses[0x34fcafeEDb28a6EEF980f70842D0C32d85a82B8F] = true;
        presaleAddresses[0x66c69C342ade1ab665074E5307837dB74Ef4fbE9] = true;
        presaleAddresses[0x4BDb31EbBE2eFe4213fbD327cc4ece52B65377FE] = true;
        presaleAddresses[0x4481E4880A78B738b4fb49B4C1DBb9055DE20945] = true;
        presaleAddresses[0x710975f0485D4E54F0Ad00085D8754e232525db5] = true;
        presaleAddresses[0xD8A0Ef31cfe154871c08c1ad5AA3c732a65D863C] = true;
        presaleAddresses[0x07c6C1345283Ee03D1960ec82250aD554470D0ED] = true;
        presaleAddresses[0x8d1Fa00f78a1058d6b810FC0Aed4B7b5f6138899] = true;
        presaleAddresses[0xc09beAB678A58B3739665fe84163c44dBb63579b] = true;
        presaleAddresses[0x7b8FA8d82B5Ed1ead174D25Ed26cC49744177fF3] = true;
        presaleAddresses[0x002043f4E5a8E95d5602CC74abb23312Ed67d696] = true;
        presaleAddresses[0x3245A3D259e575bDFDb775615995D497B249B6CE] = true;
        presaleAddresses[0x37Ac57fb4b4356784C33dDa8dd0f8b039A3f732D] = true;
        presaleAddresses[0x4010a28C7e5e70EF8C399c5597995aa4adFfcFd5] = true;
        presaleAddresses[0xDb440692BB26B194e82Cb3b710Fb271A877e7409] = true;
        presaleAddresses[0x43e1f5B962F9205Bbc22c8A8E9984BD324782437] = true;
        presaleAddresses[0x6E3aFdd4758C98eb2A5C43cb0bC4dfE81d5F11FC] = true;
        presaleAddresses[0xF1889F20420C99E79cB54b63BB24b9d0d8dFc24B] = true;
        presaleAddresses[0x3B6fb4B4765B8bF8F8BE60f032fb974a7b23Bcdf] = true;
        presaleAddresses[0x27c298483b00CDdE4147ab4961A1E5e359014487] = true;
        presaleAddresses[0x95f13aFb12867BC8C84b2Ca25A10aC6Cf8805b35] = true;
        presaleAddresses[0x6E071fE733ea84710FCa3E78194a1E8Ecbf3b1e6] = true;
        presaleAddresses[0xB8331601F59bC8734efe302d7754C530C8d81df1] = true;
        presaleAddresses[0xBdA120754741620f6EEe6c0FF4021199Fc946eF9] = true;
        presaleAddresses[0xA5ece55aC3c92709c996855B7aD9ecaEFd8aDaB0] = true;
        presaleAddresses[0x6866b9b6Ee721F37B161501C56F457DE38796D0c] = true;
        presaleAddresses[0x6Efbb6AD655D8da3CBadB595A0bb3D28CCf9Ad7C] = true;
        presaleAddresses[0x8B4C4181E102BA9c6F8aBd88046ef380F01Ce093] = true;
        presaleAddresses[0x954Cfc3B0cD64C88Ea075F676262e5f93E071b9E] = true;
        presaleAddresses[0xC2287A3184E1920cd3417eCC37b3a2d7739B00AC] = true;
        presaleAddresses[0xE0f30486128c4dF8d7bBCe85358d0d86B9257C3f] = true;
        presaleAddresses[0xE31D69dCeA42B49Ae9ECb19A47d39042f3F96A7b] = true;
        presaleAddresses[0x6fb417bdB22201b31e1149a435c1D8e63fDBdc15] = true;

        // Giveaway
        for (uint i=0; i<GIVEAWAY_ADDRESSES.length; i++) {
            _mintNFTheme(GIVEAWAY_ADDRESSES[i]);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) private pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
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

    function _mintNFTheme(address recipient) private returns (uint256) {
        _tokenIds.increment();

        uint256 newItemId = _tokenIds.current();
        _mint(recipient, newItemId);

        string memory tokenURI = string(
            abi.encodePacked(_nfthemeBaseURI, toString(newItemId), ".json")
        );
        _setTokenURI(newItemId, tokenURI);

        return newItemId;
    }

    function mint(address recipient) public payable returns (uint256) {
        require(isfullMintActive, "Minting is not active");
        require(msg.value >= priceWei, "Not enough ETH sent; check price!");
        require(
            _tokenIds.current() < maxSupply,
            "Minting would exceed maximum supply"
        );

        return _mintNFTheme(recipient);
    }

    function presaleMint(address recipient) public payable returns (uint256) {
        require(msg.value >= priceWei, "Not enough ETH sent; check price!");
        require(
            _tokenIds.current() < maxSupply,
            "Minting would exceed maximum supply"
        );
        require(presaleAddresses[recipient], "Minter address not in presale");

        return _mintNFTheme(recipient);
    }

    function setFullMintActive(bool active) public onlyOwner {
        isfullMintActive = active;
    }

    function setPriceWei(uint256 _price) public onlyOwner {
        priceWei = _price;
    }

    // Withdraw ETH from the contract
    function withdraw(uint256 _value) public onlyOwner {
        // Call returns a boolean value indicating success or failure.
        // This is the current recommended method to use.
        (bool sent, bytes memory data) = WITHDRAW_WALLET.call{value: _value}(
            ""
        );
        require(sent, "Failed to send Ether");
    }

    function setBaseURI(string memory newBaseURI) public onlyOwner {
        _nfthemeBaseURI = newBaseURI;
        uint256 tokenId;
        for (uint256 i=0; i<_tokenIds.current(); i++) {
            tokenId = i + 1;
            string memory tokenURI = string(
                abi.encodePacked(newBaseURI, toString(tokenId), ".json")
            );
            _setTokenURI(tokenId, tokenURI);
        }
    }

    function setMaxSupply(uint256 _supply) public onlyOwner {
        maxSupply = _supply;
    }

    function addPresaleAddress(address _newPresaleAddress) public onlyOwner {
        presaleAddresses[_newPresaleAddress] = true;
    }
}