pragma solidity ^0.8.3;
// SPDX-License-Identifier: UNLICENSED

import "./SafeMath.sol";
import "./IERC2981.sol";
import "./ERC165Storage.sol";
import "./IERC165.sol";
import "./ERC1155.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./SafeMath.sol";
import "./MinterRole.sol";

contract NewkinoERC1155TokenForGala is IERC2981, ERC165Storage, Ownable, IERC1155MetadataURI, ERC1155, MinterRole {
    using Strings for uint256;
    using SafeMath for uint256;

    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    string public name;
    string public symbol;

    /// @dev royalty percent of 2nd sale. ex: 1 = 1%.
    uint256 public constant royaltyPercent = 5;

    // id => creator
    mapping (uint256 => address) public creators;

    // address => tokenId => quantity
    mapping (address => mapping(uint => uint)) public mintQuantities;

    //Token URI prefix
    string public tokenURIPrefix;

    /**
     * @dev Constructor Function
     * @param _name name of the token ex: Rarible
     * @param _symbol symbol of the token ex: RARI
     * @param _tokenURIPrefix token URI Prefix
    */
    constructor(string memory _name, string memory _symbol, string memory _tokenURIPrefix) ERC1155(_tokenURIPrefix) {
        name = _name;
        symbol = _symbol;
        tokenURIPrefix = _tokenURIPrefix;
        addAdmin(_msgSender());
        addMinter(_msgSender());
        _registerInterface(_INTERFACE_ID_ERC2981);
    }

    // Creates a new token type and assings _initialSupply to minter
    function safeMint(address _beneficiary, uint256 _id, uint256 _supply) internal {
        require(creators[_id] == address(0x0), "Token is already minted");
        require(_supply != 0, "Supply should be positive");

        creators[_id] = msg.sender;

        _mint(_beneficiary, _id, _supply, "");
    }

    /**
     * @dev public function to set the token URI prefix.
     * @param _tokenURIPrefix string URI prefix to assign
     */
    function _setTokenURIPrefix(string memory _tokenURIPrefix) public onlyAdmin {
        tokenURIPrefix = _tokenURIPrefix;
    }

    function setMintQuantities(address minter, uint tokenId, uint quantity) external onlyAdmin {
        require(minter != address(0), "minter address is not valid");
        require(tokenId >=1 && tokenId <=5, "tokenId should be from 1 to 5");
        require(quantity > 0, "quantity should be over 0");
        mintQuantities[minter][tokenId] = quantity;
    }

    function uri(uint256 _id) override(ERC1155, IERC1155MetadataURI) virtual public view returns (string memory) {
        return bytes(tokenURIPrefix).length > 0 ? string(abi.encodePacked(tokenURIPrefix, _id.toString())) : "";
    }

    function claim(uint256[] calldata _tokenIds, uint256[] calldata _supplies) external {
        require(_tokenIds.length == _supplies.length, "length should be the same");
        for(uint i = 0; i < _tokenIds.length; i++)
            require(mintQuantities[msg.sender][_tokenIds[i]] == _supplies[i], "supply is not valid");
        for(uint i = 0; i < _tokenIds.length; i++) {
            safeMint(msg.sender, _tokenIds[i], _supplies[i]);
            mintQuantities[msg.sender][_tokenIds[i]] = 0;
        }
    }

    function royaltyInfo(uint256 tokenId, uint256 salePrice) external view override(IERC2981) returns (address receiver, uint256 royaltyAmount) {
        receiver = creators[tokenId];
        royaltyAmount = salePrice.mul(royaltyPercent).div(100);
    }

    function supportsInterface(bytes4 interfaceId) public view override(IERC165, ERC165Storage, ERC1155, AccessControl) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            interfaceId == type(IAccessControl).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}