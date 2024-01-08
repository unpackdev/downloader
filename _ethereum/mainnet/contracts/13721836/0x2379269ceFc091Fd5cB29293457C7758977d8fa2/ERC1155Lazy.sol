// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;
pragma abicoder v2;

import "./ERC1155Upgradeable.sol";
import "./RoyaltiesV2Impl.sol";
import "./RoyaltiesV2Upgradeable.sol";
import "./Initializable.sol";
import "./Mint1155Validator.sol";
import "./ERC1155BaseURI.sol";

abstract contract ERC1155Lazy is Initializable, ERC1155BaseURI, Mint1155Validator,
RoyaltiesV2Upgradeable, RoyaltiesV2Impl
{
    using SafeMathUpgradeable for uint256;

    event Supply(uint256 tokenId, uint256 value);
    event Creators(uint256 tokenId, address[] creators);

    mapping(uint256 => uint256) public prices;
    mapping(uint256 => uint256) public releaseDates;
    mapping(uint256 => address[]) public creators;
    mapping(uint256 => uint256) private supply;
    mapping(uint256 => uint256) private minted;
    mapping(address => bool) private whitelist;

    uint256 public minPrice;

    function __ERC1155Lazy_init(string memory _baseURI) internal initializer {
        // ERC1155BaseURI
        _setBaseURI(_baseURI);
        // Mint1155Validator
        __Mint1155Validator_init();
        // RoyaltiesV2Upgradeable
        __RoyaltiesV2Upgradeable_init_unchained();
        minPrice = 230082033517790; // 1 USD
        _registerInterface(0x6db15a0f);
    }

    function _withdraw(address payable owner) internal {
        owner.transfer(address(this).balance);
    }

    function _setMinPrice(uint256 price) internal {
        minPrice = price;
    }

    function _addAccountToWhitelist(address account) internal {
        require(account != address(0), "invalid account");
        whitelist[account] = true;
    }

    function _removeAccountFromWhitelist(address account) internal {
        require(account != address(0), "invalid account");
        whitelist[account] = false;
    }

    function _isInWhitelist(address account) internal view returns (bool) {
        return whitelist[account];
    }

    function _getNow() internal view virtual returns (uint256) {
        return block.timestamp;
    }

    function setPriceForToken(uint256 _tokenID, uint256 _price, uint256 _releaseDateTimestamp)
    external
    payable
    {
        require(
            _isInWhitelist(_msgSender()),
            "Invalid account for setting token price"
        );
        require(_price != 0, "Invalid price");
        require(_releaseDateTimestamp != 0, "Invalid release date");
        require(_price >= minPrice, "Token price must be at least the min price");

        prices[_tokenID] = _price;
        releaseDates[_tokenID] = _releaseDateTimestamp;
    }

    function mintAndTransfer(
        LibERC1155LazyMint.Mint1155Data memory data,
        address to,
        uint256 _amount
    ) public payable virtual {
        address sender = _msgSender();

        address minter = address(data.tokenId >> 96);

        require(minter == data.creators[0], "tokenId incorrect");
        require(data.creators.length == data.signatures.length);

        require(data.supply != 0, "supply incorrect");
        require(_amount != 0, "amount incorrect");
        require(bytes(data.uri).length != 0, "uri should be set");
        if (!_isInWhitelist(_msgSender())) {
            require(prices[data.tokenId] > 0, "The token price is not set");
            require(releaseDates[data.tokenId] > 0, "Release date is not set");
            require(
                _getNow() >= releaseDates[data.tokenId],
                "The token release date has not come"
            );
            require(
                msg.value >= minPrice,
                "The payment sent must be at least the min price"
            );
            require(
                msg.value >= prices[data.tokenId],
                "The payment sent must be at least the registered token price"
            );
        }

        if (supply[data.tokenId] == 0) {
            for (uint256 i = 0; i < data.creators.length; i++) {
                if (data.creators[i] != minter) validate(sender, data, i);
            }

            _saveSupply(data.tokenId, data.supply);
            _saveFees(data.tokenId, data.royalties);
            _saveCreators(data.tokenId, data.creators);
            _setTokenURI(data.tokenId, data.uri);
        }

        _mint(to, data.tokenId, _amount, "");
    }

    function _mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual override {
        uint256 newMinted = amount.add(minted[id]);
        require(newMinted <= supply[id], "more than supply");
        minted[id] = newMinted;
        super._mint(account, id, amount, data);
    }

    function _saveSupply(uint256 tokenId, uint256 _supply) internal {
        require(supply[tokenId] == 0);
        supply[tokenId] = _supply;
        emit Supply(tokenId, _supply);
    }

    function _saveCreators(uint256 tokenId, address[] memory _creators)
    internal
    {
        creators[tokenId] = _creators;
        emit Creators(tokenId, _creators);
    }

    function getCreators(uint256 _id) external view returns (address[] memory) {
        return creators[_id];
    }

    uint256[50] private __gap;
}
