// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";

import "./Ownable.sol";
import "./SafeMath.sol";

contract ILikeTurtles is ERC721, ERC721Enumerable, Ownable {
    using SafeMath for uint256;

    string public LICENSE_TEXT = "";
    bool licenseLocked = false;

    string public BASE_URI = "";
    bool baseUriLocked = false;

    uint256 public constant MAX_TURTLES = 1000;

    uint256 public constant turtlePrice = 20000000000000000; // 0.02 ETH
    uint public constant maxTurtlePurchase = 20;
    bool public saleIsActive = false;

    // Turtles for the team, giveaways, prizes, etc.
    uint public turtleReserve = 35;

    event licenseIsLocked(string _licenseText);
    event baseUriIsLocked(string _baseUri);

    constructor() ERC721("I Like Turtles", "TURTLE") { }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function reserveTurtles(address _to, uint256 _reserveAmount) public onlyOwner {
        uint supply = totalSupply();
        require(_reserveAmount > 0 && _reserveAmount <= turtleReserve, "Not enough turtles left for the team.");
        for (uint i = 0; i < _reserveAmount; i++) {
            _safeMint(_to, supply + i);
        }
        turtleReserve = turtleReserve.sub(_reserveAmount);
    }

    function _baseURI() internal override view virtual returns (string memory) {
        return BASE_URI;
    }

    function lockBaseUri() public onlyOwner {
        baseUriLocked =  true;
        emit baseUriIsLocked(BASE_URI);
    }

    function changeBaseUri(string memory _baseUri) public onlyOwner {
        require(baseUriLocked == false, "Base URI has already been locked.");
        BASE_URI = _baseUri;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool){
        return super.supportsInterface(interfaceId);
    }

    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function tokensOfOwner(address _owner) external view returns(uint256[] memory ) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }

    function tokenLicense(uint _id) public view returns(string memory) {
        require(_id < totalSupply(), "Choose a turtle within range.");
        return LICENSE_TEXT;
    }

    function lockLicense() public onlyOwner {
        licenseLocked =  true;
        emit licenseIsLocked(LICENSE_TEXT);
    }

    function changeLicense(string memory _license) public onlyOwner {
        require(licenseLocked == false, "License has already been locked.");
        LICENSE_TEXT = _license;
    }

    function mintTurtle(uint numberOfTokens) public payable {
        require(saleIsActive, "Sale must be active to mint turtles.");
        require(numberOfTokens > 0 && numberOfTokens <= maxTurtlePurchase, "Can only mint a maximum of 20 turtles at a time.");
        require(totalSupply().add(numberOfTokens) <= MAX_TURTLES, "Purchase would exceed max supply of turtles.");
        require(msg.value >= turtlePrice.mul(numberOfTokens), "Ether value sent is not correct.");

        for(uint i = 0; i < numberOfTokens; i++) {
            uint mintIndex = totalSupply();
            if (totalSupply() < MAX_TURTLES) {
                _safeMint(msg.sender, mintIndex);
            }
        }
    }
}