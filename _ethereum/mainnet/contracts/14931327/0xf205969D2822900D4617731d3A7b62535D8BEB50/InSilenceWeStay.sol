// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**********************************************
 * We went down into the silent garden.
 * Dawn is the time when nothing breathes,
 * the hour of silence. Everything is transfixed,
 * only the light moves.
 **********************************************/

import "./Ownable.sol";
import "./ERC721A.sol";

contract InSilenceWeStay is ERC721A, Ownable {
    using Strings for uint;
    string public baseURI = "ipfs://QmarTyikPPRUN5WwzijrkPUi7GZ3Vd3heoMjwtj7HWesbw/";
    bool public Shhhh = true;
    uint public price = 0.004 ether;
    uint public maxPerTx = 20;
    uint public maxPerFree = 1;
    uint public totalFree = 3333;
    uint public maxSupply = 3333;

    mapping(address => uint256) private _mintedFreeAmount;

    constructor(uint256 _initPreMint) ERC721A("In Silence We Stay", "Shhhh"){
        _safeMint(msg.sender, _initPreMint);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI set of nonexistent token"
        );

        return string(abi.encodePacked(baseURI, _tokenId.toString(), ".json"));
    }

    function silencer(bool value) external onlyOwner {
        Shhhh = value;
    }

    /**
     * Does not everything depend on
     * our interpretation of the silence around us?
     */

    function mint(uint256 count) external payable {
        uint256 cost = price;
        bool isFree = ((totalSupply() + count < totalFree + 1) &&
        (_mintedFreeAmount[msg.sender] + count <= maxPerFree));

        if (isFree) {
            cost = 0;
            _mintedFreeAmount[msg.sender] += count;
        }
        require(!Shhhh, 'Shhhh... not yet.');
        require(msg.value >= count * cost, "Shhhhh... that is not it!");
        require(totalSupply() + count <= maxSupply, "Shhhhh... its over!");
        require(count <= maxPerTx, "Shhhh...that is too much!");

        _safeMint(msg.sender, count);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseUri(string memory baseuri_) public onlyOwner {
        baseURI = baseuri_;
    }

    function setPrice(uint256 price_) external onlyOwner {
        price = price_;
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    /**
     * All I want is blackness. Blackness and silence.
     */
}