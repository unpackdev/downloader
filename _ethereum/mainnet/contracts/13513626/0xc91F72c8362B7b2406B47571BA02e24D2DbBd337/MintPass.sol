//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ERC1155Supply.sol";
import "./ERC165Storage.sol";
import "./Counters.sol";
import "./AccessControl.sol";
import "./IERC2981.sol";
import "./IMintPass.sol";

contract MintPass is ERC1155Supply, AccessControl, IERC2981, ERC165Storage, IMintPass {

    bytes32 public constant MINT_ROLE = keccak256("MINT");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER");
    bytes32 public constant URI_ROLE = keccak256("URI");

    mapping(uint256 => string) uris;


    address royaltyAddress;
    uint256 royaltyPercentage;

    constructor(string memory uri_, address royaltyAddress_, uint256 royaltyPercentage_) ERC1155(uri_) {
        require(royaltyPercentage_ <= 10000, "royaltyPercentage_ must be lte 10000.");
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _setupRole(MINT_ROLE, _msgSender());
        _setupRole(BURNER_ROLE, _msgSender());
        _setupRole(URI_ROLE, _msgSender());

        _setRoleAdmin(MINT_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(BURNER_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(URI_ROLE, DEFAULT_ADMIN_ROLE);

        royaltyAddress = royaltyAddress_;
        royaltyPercentage = royaltyPercentage_;

        _registerInterface(type(IERC2981).interfaceId);
        _registerInterface(type(IERC1155).interfaceId);
        _registerInterface(type(ERC1155Supply).interfaceId);
        _registerInterface(type(AccessControl).interfaceId);

    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Storage, IERC165, ERC1155, AccessControl) returns (bool) {
        return ERC165Storage.supportsInterface(interfaceId);
    }

    function burn(
        address account,
        uint256 id,
        uint256 amount
    ) public onlyRole(BURNER_ROLE) {
        ERC1155Supply._burn(account, id, amount);
    }

    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts
    ) public onlyRole(BURNER_ROLE) {
        ERC1155Supply._burnBatch(account, ids, amounts);
    }

    function mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public onlyRole(MINT_ROLE) {
        ERC1155Supply._mint(account, id, amount, data);

    }

    function mintBatch(
        address[] memory tos,
        uint256[] memory ids,
        uint256 amount,
        bytes memory data
    ) public onlyRole(MINT_ROLE) {
        require(tos.length == ids.length, "address list and id list must be equal");
        for (uint i = 0; i > tos.length; i++ ) {
            ERC1155Supply._mint(tos[i], ids[i], amount, data);
        }
    }


    function mintMultiple(
        address[] calldata to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public onlyRole(MINT_ROLE){
        for (uint i = 0; i < to.length; i++) {
            ERC1155Supply._mint(to[i], id, amount, data);
        }
    }

    function royaltyInfo(uint256 tokenId, uint256 salePrice) external view override returns (address royaltyReceiver, uint256 royaltyAmount) {
        royaltyReceiver = royaltyAddress;
        royaltyAmount = salePrice * royaltyPercentage / 10000;
    }

    function setURI(uint256 tokenId, string memory uri) external onlyRole(URI_ROLE) {
        uris[tokenId] = uri;
    }

    function setURIDefault(string memory uri) external onlyRole(URI_ROLE) {
       _setURI(uri);
    }

    function uri(uint256 tokenId) public view virtual override(ERC1155) returns (string memory) {
        if (bytes(uris[tokenId]).length > 0) {
            return uris[tokenId];
        }
        return super.uri(tokenId);
    }

    function setRoyaltyInfo(address royaltyAddress_, uint256 royaltyPercentage_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(royaltyPercentage_ <= 10000, "royaltyPercentage must be lt 10000");
        royaltyAddress = royaltyAddress_;
        royaltyPercentage = royaltyPercentage_;
    }
}