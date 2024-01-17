// File: contracts/Plane.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./Strings.sol";
import "./SafeMath.sol";
import "./base64.sol";
import "./IPlaneMetadata.sol";



// ................................................. .:^:...::^:.. ................
// ..................................................!.        .:^:................
// .................i...............................?             .:^^:............
// .................................................~^                :^^:.........
// ....................................n.............^?.                 ^~........
// ...............:::::::...........................^~.                   !^.......
// ............^~^:.....::^^:.....................^~.                    .7:.......
// ..........^~.            :^~^:...............^~.             ::.    .^~:........
// .........!^                 .^~^:.........:^!.             :!^:^^^^^^:....l.....
// :::::::::?                     .^~~::.:.:~!:             :!^:.:......:::::::::::
// :::::::::?                        .^~~^~!:             :!^::::::::::::::::::::::
// ::o::::::^7.                         .::             :!~:::::v::::::::::::::::::
// :::::::::::!~:                                     :!~::::::::::::::::::::::::::
// ::::::::::i:^~!~:                                :!~:::::::::::::::::n::::::::::
// :::::::::::::::^~!~^.                           :?~^::::::::::::::::::::::::::::
// ^^^^^^^^^^^^^^^^^:^~!!^.                          .^!!~^:^^^^^^^^^^^^^^^^^^^^^^^
// ^^^^^g^^^^^^^^^^^^^^^^^~!!^.                          .:~!~^^^^^^m^^^^^^^^^^^^e^
// ^^^^^^^^^^^^^^^^^^^^^^^^^!J:                             :~!!~^^^^^^^^^^^^^^^^^^
// ^^^m^^^^^^^^^^^^^^^^^^^~7^                                  .~!!~^^^^o^^^^^^^^^^
// ^^^^^^^^^^^^^^^^^^^^^~7~                                       .!7^^^^^^^^^^^^^^
// ~~~~~~~~~~~~~r~~~~^!7~             .!7^.                         :J~~~~~~~~~~~~~
// ~~~~~~~~~~~~~~~~~~?~             .!7~~!77~.                       ~7~~~~~~y~~~~~
// ~~~~~~~~~~~~~~~~77              ~?!~~~~~~!77~:                    ?!~~~~~~~~~~~~
// ~~~~~s~~~~~~~~~~Y             ~?!~~~~~~~~~~~!77!:                77~~~~~~~~~~~~~
// !!!!!!!!!!!!!!!~?~          ~?7~~!!!!!!!!e!!!~~!777^.         .~?!~!!!!!!!!!!!!!
// !!!!!!!!!!!!!!!!~7?~:.  .:~?7!!!!!!!!!!!!!!!!!!!!!!777!~^^^~!77!!!!!!!!!t!!!!!!!
// !!!!!h!!!!!!!!!!!!!7777777!!!!!!!!!!!!!!!!1!!!!!!!!!!!!!777!!!!!!!!!!!!!!!9!!!!!
// !!!!!!!!!!!!9!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
// 777787777777777777777777777777777777777777r7777777777777777777777777777777777777
// 777777777777777777i7777777777777777777777777777777777777777777777777p77777777777


contract Planes is ERC721, ERC721Enumerable, ERC721Burnable, ReentrancyGuard, Ownable {

    event MintedEvent(uint8 num);

    uint256 public maxSupply = 1333;
    uint256 public reserved = 50;
    uint256 public maxMintsPerWallet = 20;
    mapping (uint => bytes32) public fingerprints;
    mapping (address => uint8) public mintedTokensPerWallet;
    uint256 public price = 0.02 ether;
    address _metadataAddr;
    bool public saleStarted;
    bool burnEnabled;
    string _contractURI;

    constructor() ERC721("Skies, BlockMachine", "SKIES") {}

    function getSeed(uint256 tokenId) public view returns (string memory) {
        return string(abi.encodePacked(address(this), fingerprints[tokenId], tokenId));
    }

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        require(_exists(tokenId), "Token does not exist");
        require(address(_metadataAddr) != address(0), "No metadata address");

        IPlaneMetadata metadata = IPlaneMetadata(_metadataAddr);
        string memory tokenSeed = getSeed(tokenId);
        return metadata.genMetadata(tokenSeed, tokenId);
    }

    function contractURI() public view returns (string memory) {
        return "ipfs://QmXmU5wKQByEqK6AxYTmvBrqbpJjUAb7VdzPGzCAPxMwpd";
    }

    function setContractURI(string memory uri) external onlyOwner {
        _contractURI = uri;
    }

    function mintTokens(uint8 num) external nonReentrant payable {
        require(saleStarted, "Not live");
        require(!Address.isContract(msg.sender), "No contracts");
        require(totalSupply() + num <= maxSupply - reserved, "Sold out");
        require(num * price <= msg.value, "Wrong price");

        require(mintedTokensPerWallet[msg.sender] + num <= maxMintsPerWallet, "Maxed per wallet");
        mintN(num, msg.sender);
        
        emit MintedEvent(num);
    }

    function mintN(uint8 num, address receiver) private {
        for (uint256 i; i < num; i++) {
            uint tokenId = totalSupply();
            _safeMint(receiver, tokenId);
            fingerprints[tokenId] = keccak256(abi.encodePacked(block.number, receiver));
        }
        mintedTokensPerWallet[msg.sender] = mintedTokensPerWallet[msg.sender] + num;
    }

    function mintForOwner(uint8 num, address receiver) external nonReentrant onlyOwner {
        require(num <= reserved, "Exceed reserved");

        mintN(num, receiver);
        
        reserved = reserved - num;
        emit MintedEvent(num);
    }

    function setMetadata(address metadataAddr) external onlyOwner {
        _metadataAddr = metadataAddr;
    }

    function setPrice(uint256 _newPrice) external onlyOwner {
        price = _newPrice;
    }

    function flipSaleStarted(bool state) external onlyOwner {
        saleStarted = state;
    }

    function setNumReserved(uint256 n) external onlyOwner {
        reserved = n;
    }

    function setMaxSupply(uint256 max) external onlyOwner {
        maxSupply = max;
    }

    function setMaxMintsPerWallet(uint16 max) external onlyOwner {
        maxMintsPerWallet = max;
    }

    function withdraw() public onlyOwner {
        uint256 _balance = address(this).balance;
        require(payable(msg.sender).send(_balance));
    }

    function enableBurn(bool state) external onlyOwner {
        burnEnabled = state;
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        require(to != address(0) || burnEnabled, "burn disabled");
        super._beforeTokenTransfer(from, to, tokenId);
    }

}
