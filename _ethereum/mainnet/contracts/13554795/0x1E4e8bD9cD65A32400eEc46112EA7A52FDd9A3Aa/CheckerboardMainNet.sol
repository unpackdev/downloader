// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Upgradeable.sol";
import "./CountersUpgradeable.sol";
import "./StringsUpgradeable.sol";
import "./Initializable.sol";

contract CheckerboardMainNet is Initializable, ERC721Upgradeable {

    event BuyChessByMaticEvent(address ownerAddr, uint256 tokenId, uint256 level);
    event buyChessSidechainStep2Event(address buyer, uint256 tokenId, uint256 level);
    event buyChessMainchainStep1Event(address buyer, uint256 tokenId, uint256 level);

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyAdmin() {
        require(adminMap[msg.sender]);
        _;
    }

    address public owner;
    mapping(uint256 => uint256) _tokenLevels;    uint256 public soldEth;
    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private _tokenIds;
    using StringsUpgradeable for uint256;
    mapping(address => bool) adminMap;
    mapping(uint256 => bool) public withdrawnTokens;
    string private _tokenBaseUri;
    CountersUpgradeable.Counter private _tokenNum;

    function initialize() initializer public {
        __ERC721_init("Numbre", "NBR");
        soldEth = 0;
        owner = msg.sender;
    }

    function addAdmin(address admin) public onlyOwner {
        adminMap[admin] = true;
    }

    function setTokenBaseUri(string memory newTokenBaseUri) public onlyAdmin {
        _tokenBaseUri = newTokenBaseUri;
    }

    function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
    {
        return string(abi.encodePacked(_tokenBaseUri, tokenId.toString(), ".json"));
    }

    // polygon
    function deposit(address user, bytes calldata depositData)
    external
    {
        require(adminMap[msg.sender], "access deny");
        // deposit single
        if (depositData.length == 32) {
            uint256 tokenId = abi.decode(depositData, (uint256));
            withdrawnTokens[tokenId] = false;
            inner_mint(user, tokenId, _tokenLevels[tokenId]);
            // deposit batch
        } else {
            uint256[] memory tokens = abi.decode(depositData, (uint256[]));
            uint256 length = tokens.length;
            for (uint256 i; i < length; i++) {
                withdrawnTokens[tokens[i]] = false;
                inner_mint(user, tokens[i], _tokenLevels[tokens[i]]);
            }
        }
    }

    function withdraw(uint256 tokenId) external {
        require(msg.sender == ownerOf(tokenId), "access deny");
        withdrawnTokens[tokenId] = true;
        _burn(tokenId);
    }

    function mint(address user, uint256 _tokenId) external onlyAdmin {
        _safeMint(user, _tokenId);
        _tokenLevels[_tokenId] = 1;
        emit BuyChessByMaticEvent(user, _tokenId, 1);
    }

    function mint(address user, uint256 _tokenId, bytes calldata metaData) external onlyAdmin {
        _safeMint(user, _tokenId, metaData);
        _tokenLevels[_tokenId] = 1;
        emit BuyChessByMaticEvent(user, _tokenId, 1);
    }

    function inner_mint(address user, uint256 _tokenId, uint256 level) internal {
        _safeMint(user, _tokenId);
        _tokenLevels[_tokenId] = level;
        emit BuyChessByMaticEvent(user, _tokenId, level);
    }

    function exists(uint256 tokenId) external view returns (bool) {
        return _exists(tokenId);
    }

    function totalSupply() public view returns (uint256) {
        return _tokenNum.current();
    }

    function buyChessSidechainStep2(uint256 tokenId, uint256 level) public payable {
        require(msg.value == soldEth, "value not enough");
        emit buyChessSidechainStep2Event(msg.sender, tokenId, level);
    }

    function buyChessMainchainStep1() public payable {
        require(msg.value == soldEth, "value not enough");
        _tokenIds.increment();
        uint256 tokenId = _tokenIds.current() + 10000000;
        inner_mint(msg.sender, tokenId, 1);
        emit buyChessMainchainStep1Event(msg.sender, tokenId, 1);
    }

    function setSoldEth(uint256 newSoldEth) public onlyOwner {
        soldEth = newSoldEth;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) override internal virtual {
        if (from == address(0)){
            _tokenNum.increment();
        }
        if (to == address(0)){
            _tokenNum.decrement();
        }
    }
}

