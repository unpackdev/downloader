// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./ERC1155Upgradeable.sol";
import "./IERC1155Upgradeable.sol";
import "./StringsUpgradeable.sol";
// import "./IERC165Upgradeable.sol";
import "./IResource.sol";

contract Resource is
    ERC1155Upgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable,
    IResource
{
    using StringsUpgradeable for uint256;
    string public name;
    string public symbol;

    mapping (address => bool) public override genesisMinter;
    address public stash;
    string public baseUri;

    function initialize(
        string memory name_,
        string memory symbol_,
        string memory uri_
    ) external initializer {
        __ERC1155_init(uri_);
        __Pausable_init();
        __Ownable_init();
        name = name_;
        symbol = symbol_;
    }

    modifier onlyGenesisMinter() {
        require(
            genesisMinter[_msgSender()],
            "caller is not genesis minter"
        );
        _;
    }

    function setGenesisMinter(address minter, bool state) external onlyOwner {
        genesisMinter[minter] = state;
    }

    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes32 nonce
    ) public override onlyGenesisMinter nonReentrant whenNotPaused {
        _mint(to, id, amount, "");
        if (msg.sender == stash) {
            emit StashMinted(to, id, amount, nonce);
        }
    }

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts
    ) public override onlyGenesisMinter nonReentrant whenNotPaused {
        _mintBatch(to, ids, amounts, "");
    }

    function burn(address account, uint256 id, uint256 value) external override {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not token owner or approved"
        );

        _burn(account, id, value);
        if (msg.sender == stash) {
            emit StashBurned(account, id, value);
        }
    }

    function burnBatch(address account, uint256[] memory ids, uint256[] memory values) external override {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not token owner or approved"
        );

        _burnBatch(account, ids, values);
    }

    function setStash(address stash_) external onlyOwner {
        stash = stash_;
    }

    //  function setBaseUri(string memory uri_) external onlyOwner {
    //     _setURI(uri_);
    // }

    function setBaseURI(string calldata _uri) external onlyOwner {
        baseUri = _uri;
    }

    function uri(uint256 tokenId) public view override returns (string memory) {
        return bytes(baseUri).length > 0 ? string(abi.encodePacked(baseUri, tokenId.toString())) : "";
    }


    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    uint256[47] private __gap;
}