// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC1155.sol";
import "./IERC1155Receiver.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./Strings.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract Papillon is ERC1155, IERC1155Receiver, Ownable, Pausable {
    using Strings for uint256;

    address proxyRegistryAddress;

    address private artist = 0x82eB534E1e9104Ea836a3ec62d9930cDB39d705f;

    address private developer = 0x3F40A7496cEd41be4ECA48E2C11324Cb7e0805B3;

    uint256 private _defaultPrice = 1.5 ether;

    uint256 public saleStart;

    string public constant name = "Papillon by Philippe Pasqua";

    string public constant contractURI =
        "ipfs://bafybeih2i6qybvzzblqavc4lpnu4bqcheaz7dkeo3fa6shmkpzpqev5l3i/_metadata.json";

    mapping(uint256 => uint256) tokenIdToPrice;

    modifier saleActive() {
        require(saleStart != 0 && block.timestamp >= saleStart);
        _;
    }

    constructor(
        address _proxyRegistryAddress,
        uint256[] memory tokenIds,
        uint256[] memory amounts,
        uint256 startTime
    ) ERC1155("ipfs://bafybeih2i6qybvzzblqavc4lpnu4bqcheaz7dkeo3fa6shmkpzpqev5l3i/") {
        proxyRegistryAddress = _proxyRegistryAddress;
        saleStart = startTime;
        _mintBatch(address(this), tokenIds, amounts, "");
    }

    function buy(uint256 id) public payable saleActive {
        require(balanceOf(address(this), id) > 0, "Token not available");
        require(balanceOf(msg.sender, id) < 2, "You already own 2 tokens");
        require(msg.value == tokenPrice(id), "Ether value sent is not correct");

        _safeTransferFrom(address(this), msg.sender, id, 1, "");
    }

    /**
     * @notice Buy several tokens in one batch, although max 2 per tokenId per address
     */
    function buyBatch(uint256[] memory ids, uint256[] memory amounts) public payable saleActive {
        uint256 price = 0;
        for (uint256 i = 0; i < ids.length; i += 1) {
            uint256 balanceSender = balanceOf(address(msg.sender), ids[i]);
            // max 2 tokens per address
            uint256 canBuy = balanceSender > 2 ? 0 : 2 - balanceSender;
            // check how many tokens are available, if more than canBuy set to canBuy
            uint256 available = balanceOf(address(this), ids[i]) > canBuy ? canBuy : balanceOf(address(this), ids[i]);
            // edit amount if too high
            amounts[i] = available < amounts[i] ? available : amounts[i];
            // calculate price on edited amount
            price += tokenPrice(ids[i]) * amounts[i];
        }
        // if calculated price is 0, that means that the selected ids were not available
        require(price > 0, "Tokens not available");
        require(msg.value >= price, "Ether value sent is not correct");

        // Send back money if we got too much
        if (price < msg.value) {
            (bool ok, ) = payable(msg.sender).call{ value: msg.value - price }("");
            require(ok);
        }
        _safeBatchTransferFrom(address(this), msg.sender, ids, amounts, "");
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function setDefaultTokenPrice(uint256 price) public onlyOwner {
        _defaultPrice = price;
    }

    /**
     * @notice Use to set another price than default for specific tokenId
     */
    function setTokenPrice(uint256 id, uint256 price) public onlyOwner {
        tokenIdToPrice[id] = price;
    }

    function tokenPrice(uint256 id) public view returns (uint256) {
        return tokenIdToPrice[id] == 0 ? _defaultPrice : tokenIdToPrice[id];
    }

    function setSaleStart(uint256 startIn) public onlyOwner {
        saleStart = startIn > 0 ? block.timestamp + startIn : 0;
    }

    function saleStarted() public view returns (bool) {
        return saleStart != 0 && block.timestamp >= saleStart;
    }

    function uri(uint256 id) public view virtual override returns (string memory) {
        string memory baseURI = super.uri(id);
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, id.toString())) : "";
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function mint(
        address account,
        uint256 id,
        uint256 amount
    ) public onlyOwner {
        _mint(account, id, amount, "");
    }

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts
    ) public onlyOwner {
        _mintBatch(to, ids, amounts, "");
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function withdraw() public onlyOwner {
        require(artist != address(0), "Artist not set");
        require(developer != address(0), "Developer not set");

        uint256 amount = address(this).balance;

        uint256 devShare = amount / 5;
        uint256 artistShare = amount - devShare;

        (bool successArtist, ) = artist.call{ value: artistShare }("");
        (bool successDev, ) = developer.call{ value: devShare }("");
        require(successArtist && successDev, "Failed to send money");
    }

    function setArtist(address _artist) public onlyOwner {
        artist = _artist;
    }

    function setDeveloper(address _developer) public onlyOwner {
        developer = _developer;
    }

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-free listings.
     */
    function isApprovedForAll(address _owner, address _operator) public view override returns (bool isOperator) {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(_owner)) == _operator) {
            return true;
        }

        return ERC1155.isApprovedForAll(_owner, _operator);
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external pure override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}
