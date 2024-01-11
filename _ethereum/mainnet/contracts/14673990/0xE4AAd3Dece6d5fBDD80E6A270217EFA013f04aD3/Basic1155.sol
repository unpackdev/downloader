// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC1155.sol";
import "./ERC1155Burnable.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

string constant NAME = "Spirit Animals by Hamid Sardar";
string constant SYMBOL = "HAMID";
string constant IPFSURL = "QmbLSmJudDE3DLMiVeMpWK9gDsQNabCyKzX9tMHrBB5e3R";

contract BasicERC1155 is ERC1155, ERC1155Burnable, Ownable {
    address proxyRegistryAddress;
    mapping(uint256 => uint256) public price;
    mapping(uint256 => uint256) public supply;
    mapping(uint256 => uint256) public maxSupply;
    mapping(uint256 => mapping(address => uint256)) private _Buyers;
    mapping(uint256 => bool) private minted;
    bool private _requireAllowlist = false;
    bool private _mintingEnabled = true;
    string contractURL;

    string public name = NAME;
    string public symbol = SYMBOL;

    constructor(address _proxyRegistryAddress) ERC1155("") {
        proxyRegistryAddress = _proxyRegistryAddress;
        contractURL = string(
            abi.encodePacked("ipfs://", IPFSURL, "/metadata.json")
        );
        _setURI(string(abi.encodePacked("ipfs://", IPFSURL, "/{id}.json")));
    }

    function _getNextEditionID(uint256 _type) internal view returns (uint256) {
        return supply[_type];
    }

    function mint(address _to, uint8 _type) external onlyOwner {
        require(
            supply[_type] < maxSupply[_type],
            "Not enough left to mint that many items"
        );
        _mint(_to, _type, 1, "");
        supply[_type] += 1;
    }

    function buy(uint256 _type) external payable {
        require(_mintingEnabled == true, "Minting not enabled yet");
        require(msg.value >= price[_type], "Not enough ether to cover cost");
        require(
            supply[_type] < maxSupply[_type],
            "Not enough left to mint that many items"
        );
        _mint(msg.sender, _type, 1, "");
        supply[_type] += 1;
    }

    function setPrice(uint256 _type, uint256 _price) external onlyOwner {
        price[_type] = _price;
    }

    function setMaxSupply(uint256 _type, uint256 _supply) external onlyOwner {
        maxSupply[_type] = _supply;
    }

    function toggleMinting(bool enabled) public onlyOwner {
        _mintingEnabled = enabled;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function setURI(string memory _uri) public onlyOwner {
        _setURI(_uri);
    }

    function setProxyAddress(address _a) public onlyOwner {
        proxyRegistryAddress = _a;
    }

    function getProxyAddress() public view onlyOwner returns (address) {
        return proxyRegistryAddress;
    }

    function contractURI() public view returns (string memory) {
        return contractURL;
    }

    function setContractURI(string memory _contractURL) public onlyOwner {
        contractURL = _contractURL;
    }

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-free listings.
     */
    function isApprovedForAll(address _owner, address _operator)
        public
        view
        override
        returns (bool isOperator)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(_owner)) == _operator) {
            return true;
        }

        return ERC1155.isApprovedForAll(_owner, _operator);
    }
}
