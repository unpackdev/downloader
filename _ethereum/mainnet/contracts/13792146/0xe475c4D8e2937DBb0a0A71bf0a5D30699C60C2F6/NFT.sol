//SPDX-License-Identifier: Unlicensed
pragma solidity >= 0.8.0;

import "./ERC721Enumerable.sol";
import "./ERC721.sol";
import "./IERC721.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./Strings.sol";
import "./EnumerableSet.sol";

contract NFT is ERC721Enumerable, Ownable {
    using Strings for uint256;

    mapping(uint256 => string)  public tokenURIs;

    using EnumerableSet for EnumerableSet.AddressSet;
    // onlyOwner can change controllers and transfer it's ownership
    EnumerableSet.AddressSet controller;

    event controllerEvent(address _address, bool mode);
    event tokenMetadataUriChanged(uint256 _tokenId, string _metadataURI);

    constructor(
        string memory _name,
        string memory _symbol
    ) ERC721(_name, _symbol) {
    }


    function TokenExists(uint256 _tokenId) external view returns (bool) {
        return _exists(_tokenId);
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        return tokenURIs[_tokenId];
    }

    //// Controllers
    function mint(address _receiver, uint256 _tokenId, string memory _metadataURI) external onlyAllowed {
        tokenURIs[_tokenId] = _metadataURI;
        _mint(_receiver, _tokenId);
    }

    function safeMint(address _receiver, uint256 _tokenId, string memory _metadataURI) external onlyAllowed {
        tokenURIs[_tokenId] = _metadataURI;
        _safeMint(_receiver, _tokenId);
    }

    function UpdateTokenURI(uint256 _tokenId, string memory _metadataURI) public onlyAllowed {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        tokenURIs[_tokenId] = _metadataURI;
        emit tokenMetadataUriChanged( _tokenId, _metadataURI);
    }

    //// Admin
    function setController(address _controller, bool _mode) public onlyOwner {
        if(_mode) {
            controller.add(_controller);
        } else {
            controller.remove(_controller);
        }
        emit controllerEvent(_controller, _mode);
    }

    function getControllerLength() public view returns (uint256) {
        return controller.length();
    }

    function getControllerAt(uint256 _index) public view returns (address) {
        return controller.at(_index);
    }

    function getControllerContains(address _addr) public view returns (bool) {
        return controller.contains(_addr);
    }

    function getControllers() public view returns (address[] memory) {
        return controller.values();
    }


    //// Modifiers
    modifier onlyAllowed() {
        require(
            msg.sender == owner() || controller.contains(msg.sender),
            "NFT: Not Authorised"
        );
        _;
    }


    //// blackhole prevention methods / drain
    function drain() external onlyAllowed {
        payable(owner()).transfer(address(this).balance);
    }

    function retrieveERC20(address _tracker, uint256 amount) external onlyAllowed {
        IERC20(_tracker).transfer(msg.sender, amount);
    }

    function retrieve721(address _tracker, uint256 id) external onlyAllowed {
        IERC721(_tracker).transferFrom(address(this), msg.sender, id);
    }
}
