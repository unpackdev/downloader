// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC1155.sol";
import "./IERC2981.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract MemoryReality2 is ERC1155, IERC2981, Ownable, Pausable, ReentrancyGuard {
    string public name = "Memory to Reality 2.0";
    string public symbol = "MTR";

    uint256 public price;
    uint256 public royaltyPercent;
    bool public revealed;
    string private placeholderURI;
    string private baseURI;
    uint256 public allowedSupply;
    uint256 public maxSupply;
    uint256 private currentTokenId;
    string public contractURL;
    address private proxyRegistryAddress;
    address private primaryRecipient;
    address private secondaryRecipient;
    mapping(address => uint256) private minted;
    
    constructor(string memory _placeholderURI, string memory _baseURI) ERC1155(string(abi.encodePacked(_baseURI, "{id}.json"))) {
        price = 1000000000000000;
        royaltyPercent = 2000;
        revealed = false;
        placeholderURI = _placeholderURI;
        baseURI = _baseURI;
        allowedSupply = 20;
        maxSupply = 100;
        currentTokenId = 0;
        primaryRecipient = 0xCFbbddDA568a07859Ccc59D0aBE337D68606028C;
        secondaryRecipient = 0xCFbbddDA568a07859Ccc59D0aBE337D68606028C;
    }

    //////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////// Owner Functions ///////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////
    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function setPrice(uint256 _price) public onlyOwner {
        price = _price;
    }

    function setRoyaltyPercent(uint256 _percent) external onlyOwner {
        royaltyPercent = _percent;
    }

    function setPlaceholderURI(string memory _newPlaceholderURI) public onlyOwner {
        placeholderURI = _newPlaceholderURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setRevealed(bool _value) public onlyOwner {
        revealed = _value;
    }

    function addDailyAllowedSupply() public onlyOwner {
        require(allowedSupply + 20 <= maxSupply, "Daily mint limit ended");

        allowedSupply += 20;
    }

    function setAllowedSupply(uint256 _allowedSupply) public onlyOwner {
        require(_allowedSupply <= maxSupply, "Invalid supply provided");
        require(_allowedSupply >= totalSupply(), "Invalid supply provided");

        allowedSupply = _allowedSupply;
    }

    function setContractURI(string memory _contractURL) public onlyOwner {
        contractURL = _contractURL;
    }

    function setPrimaryRecipient(address _recipient) external onlyOwner {
        require(_recipient != address(0), "New recipient is the zero address.");

        primaryRecipient = _recipient;
    }

    function setSecondaryRecipient(address _recipient) external onlyOwner {
        require(_recipient != address(0), "New recipient is the zero address.");

        secondaryRecipient = _recipient;
    }

    function setProxyAddress(address _proxyAddress) public onlyOwner {
        proxyRegistryAddress = _proxyAddress;
    }

    //////////////////////////////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////////////// Mint Functions ///////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////
    function mint() external payable {
        require(currentTokenId + 1 <= allowedSupply, "Daily mint limited");
        require(msg.value >= price, "Not enough to pay for that");

        payable(primaryRecipient).transfer(msg.value);
        
        _mint(msg.sender, currentTokenId, 1, "");

        currentTokenId += 1;
        minted[msg.sender] += 1;
    }

    //////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////// Opensea Functions ///////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////
    function totalSupply() public view returns(uint256) {
        return currentTokenId;
    }

    function contractURI() public view returns (string memory) {
        return contractURL;
    }

    function uri(uint256 _tokenId) override public view returns (string memory) {
        require(_tokenId <= allowedSupply - 1, "NFT does not exist");

        if (revealed) {
            return string(abi.encodePacked(baseURI, Strings.toString(_tokenId), ".json"));
        } else {
            return string(abi.encodePacked(placeholderURI, Strings.toString(_tokenId), ".json"));
        }
    }

    function isApprovedForAll(address _owner, address _operator) public view override returns (bool isOperator) {
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(_owner)) == _operator) {
            return true;
        }

        return super.isApprovedForAll(_owner, _operator);
    }

    function mintedBalanceOf(address _address) public view returns (uint256) {
        return minted[_address];
    }

    //////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////// Royalty Functions ///////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////////////
    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal whenNotPaused override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
    
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view override returns (address receiver, uint256 royaltyAmount) {
        require(_tokenId <= allowedSupply - 1, "NFT does not exist");

        return (secondaryRecipient, (_salePrice * royaltyPercent) / 10000);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, IERC165) returns (bool) {
        return (
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId)
        );
    }
}
