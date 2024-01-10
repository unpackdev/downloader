// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AccessControl.sol";
import "./IERC20.sol";
import "./ERC721.sol";
import "./Ownable.sol";

contract NFTFactory is ERC721, AccessControl, Ownable {

    address public mktWallet;
    uint256 public maxSupply;
    uint256 public remaining;
    string public uri;
    // IERC20 private token;

    event NFTminted(address indexed newOwner, uint256 indexed tokenId);

    constructor(
        string memory _uri,
        uint256 _maxSupply,
        string memory _name,
        string memory _symbol,
        // address _tokenAddress,
        address _mktWallet
    ) ERC721(_name, _symbol) {
        uri = _uri;
        maxSupply = _maxSupply;
        remaining = _maxSupply;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        // token = IERC20(_tokenAddress);
        mktWallet = _mktWallet;
    }

    function safeMint(address _to, uint256 _tokenId) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(remaining > 0, "Sold out");
        _safeMint(_to, _tokenId);
        emit NFTminted(_to, _tokenId);
        remaining -= 1;
    }

    function _baseURI() internal view override returns (string memory) {
        return uri;
    }

    function getURI() public view returns (string memory) {
        return uri;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
