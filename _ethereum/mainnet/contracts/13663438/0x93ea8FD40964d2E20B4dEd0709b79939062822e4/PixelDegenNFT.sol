// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./ERC721.sol";
import "./IMintable.sol";
import "./Minting.sol";

contract PixelDegenNFT is ERC721, IMintable, Ownable {
    using Strings for uint256;

    address public imx;

    uint256 private currentSupply;
    string public baseTokenURI;
    
    event PixelDegenMinted(address to, uint256 id);

    constructor(
        string memory _name,
        string memory _symbol,
        address _imx,
	    string memory _baseUri
    ) ERC721(_name, _symbol) {
	    setBaseTokenURI(_baseUri);
	    imx = _imx;
    }
    
    modifier onlyIMX() {
        require(msg.sender == imx, "PixelDegenNFT::onlyIMX: Function can only be called by IMX smart contract.");
        _;
    }

    function mintFor(
        address user,
        uint256 quantity,
        bytes calldata mintingBlob
    ) external override onlyIMX {
        require(quantity == 1, "PixelDegenNFT::mintFor: invalid quantity, needs to be 1.");
        (uint256 id, ) = Minting.split(mintingBlob);
	    require(id>=0 && id<=6999, "PixelDegenNFT::mintFor: the id is out of range (0 to 6999).");
	    
        _safeMint(user, id);
	    currentSupply = currentSupply + 1;
        emit PixelDegenMinted(user, id);
    }

    function totalSupply() public view returns (uint256) {
        return currentSupply;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseTokenURI(string memory uri) public onlyOwner {
        baseTokenURI = uri;
    }
}
