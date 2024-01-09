//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.6;


import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./IERC721.sol";
import "./IProxyRegistry.sol";

// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%#%##%#####((#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@#@%(((#%##((///(/(((#(((@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@*,((#((###(((((((#((((#((/((*//@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@#((/((##(#(/##//(/#//*/*/////*@**@/@*@#@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@&&#((#######(((((*////*//*/*(/(//(/*@***/&%@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@#/((######(/*(/((***/#((//((##///***//#(*//%/@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@&/*/*/((//##(/((####((((##*//(/**/*//***///*@***/#@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@%#((##(#(((((/(#((((///(*/******/*/****//*/**@****@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@##((#(((**////*,*///(/*/**/**/////*/*/**//(*/*/(/@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@%((((*((****/*/,****/*/**/****//////**/(*/**/***/*%&@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@##(////((*,@&*,,(%@(((((((//***//(/%&(*&((//(///*/*(@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@(*/*/(,*@@@/,@%@@@@((((((((//**@&@@&&@@@@(((/*///**%@@@@@@@@@@@@@
// @@@@@@@@@@@@@@%&(#/,,(@@((((((#&@@((//((//*((@@@((((((@@@((/(//(**#@@@@@@@@@@@@@
// @@@@@@@@@@@@@@##//*((&@@@.. **@@@@(((((///(/(@@@@   .@@@@(((((((**@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@*/,**(@@@@ /@(.#@&/((((((////#@@@ %& .@@@@#(((/****@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@#@/(((@@@&     .@@(//*//***((@&@@ @@.,@@@@@/((/*/*(@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@#/*(((/#@@&@@@@@@(/**%@@***/((@@@@@@(&@@/(((((**/@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@#%/(((((((//(((((//*,*@*****/*/@%%(((((((((((**(@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@%(%@@((@(*/(*/*.* ,,****,*/ **/(/*/@***(((((**/@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@&#@@@(&@@@/******(#//  /*/*******,@***(%(@((#@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@%@/*/////**/* /***/**,//*@*%&@@(@%@#@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@&@**/**/#/*///****/*//**&@@@@/@%@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@&@@@@@@@@*//*****///***********@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@********************@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@ GHRIFTERS GONNA GHRIFT THE GRIFTERS @@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ @0SXV @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@



contract GhriftersToken is ERC721, ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    Counters.Counter public _tokenIds;

    constructor() ERC721("Ghrifters", "GHRIFTERS") {
        proxyRegistry = IProxyRegistry(
            0xa5409ec958C83C3f309868babACA7c86DCB077c1
        );
    }

    mapping(uint256 => address) previousOwner;
    mapping(uint256 => address) firstOwner;

    address public asyncTokenContract =
        0xc143bbfcDBdBEd6d454803804752a064A622C1F3;

    uint256 private tokenPrice = 22000000000000000; //0.022 Eth
    uint256 private maxCap = 666;
    string public baseUri =
        "https://ipfs.io/ipfs/QmTvbiwsuRwa7BcW4m8tCJEQk7uo53pSNK5gKRw8XKVEKE/";

    // OpenSea's Proxy Registry
    IProxyRegistry public immutable proxyRegistry;

    bool grifterPresalesPaused = true;
    bool allSalesPaused = true;
    bool metadataLocked = false;

    function randomMint(uint256 amountToMint) public payable {
        require(allSalesPaused == false, "Sales is not open");
        uint256 currentToken = _tokenIds.current();
        require(amountToMint < 11, "Can't mint too much at once!");
        require(currentToken + amountToMint < maxCap, "Limit reached");
        require(
            msg.value == tokenPrice.mul(amountToMint),
            "That is not the right price!"
        );

        for (uint256 i = 0; i < amountToMint; i++) {
            uint256 availToken = availableToken(_tokenIds.current());
            firstOwner[availToken] = msg.sender;
            _safeMint(msg.sender, availToken);
            _tokenIds.increment();
        }
    }

    function availableToken(uint256 tokenId) public returns (uint256) {
        if (_exists(tokenId)) {
            _tokenIds.increment();
            return _tokenIds.current();
        }

        return _tokenIds.current();
    }

    function publicMint(uint256 tokenId) public payable virtual {
        require(allSalesPaused == false, "Sales is not open");
        require(msg.value == tokenPrice, "That is not the right price!");

        firstOwner[tokenId] = msg.sender;
        _safeMint(msg.sender, tokenId);
    }

    function grifterMint(uint256 tokenId) public payable virtual {
        require(
            IERC721Enumerable(asyncTokenContract).ownerOf(tokenId) ==
                msg.sender,
            "Need to hold corresponding XCOPY Grifter to mint during presale"
        );

        require(grifterPresalesPaused == false, "Sales is not open");
        require(msg.value == tokenPrice, "That is not the right price!");

        firstOwner[tokenId] = msg.sender;
        _safeMint(msg.sender, tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, toString(tokenId)))
                : "";
    }

    function devMint(address to, uint256 tokenId) public onlyOwner {
        _safeMint(to, tokenId);
    }

    function toggleGrifterSales() public onlyOwner {
        grifterPresalesPaused = !grifterPresalesPaused;
    }

    function toggleSales() public onlyOwner {
        allSalesPaused = !allSalesPaused;
    }

    function customBurn(uint256 tokenId) public {
        require(ownerOf(tokenId) == msg.sender, "You don't own this Ghrifter");
        previousOwner[tokenId] = msg.sender;
        _transfer(
            msg.sender,
            0x000000000000000000000000000000000000dEaD,
            tokenId
        );
    }

    function withdrawFunds() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function getFirstOwner(uint256 tokenId) public view returns (address) {
        return firstOwner[tokenId];
    }

    function getPreviousOwner(uint256 tokenId) public view returns (address) {
        return previousOwner[tokenId];
    }

    function setBaseUri(string memory newUri) public onlyOwner {
        require(metadataLocked == false, "Metadata are locked");
        baseUri = newUri;
    }

    function lockMetadata() public onlyOwner {
        require(metadataLocked == false, "Metadata are already locked");
        metadataLocked = true;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseUri;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @notice Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        if (proxyRegistry.proxies(owner) == operator) {
            return true;
        }
        return super.isApprovedForAll(owner, operator);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

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
}
