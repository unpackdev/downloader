// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Tradable.sol";

/**
 * @title Creature
 * Creature - a contract for my non-fungible creatures.
 */
contract Creature is ERC721Tradable {

    uint256 constant private MAX_TOKENS_PER_KIND = 100_000;
    bool public activeContract = true;
    IERC721Enumerable[] public contracts;
    uint256 public price = 0.03 ether;
    string public baseUrl = "ipfs://QmdvUpogAwdD3wgjo6ZVvr9u4b1KVgn4YnCPwXfQicdyeX/";
    address constant private walletAddress = 0xD0e527F82cc5dee8018b74aDC1E728d0D8e654D5;

    struct Set {
        address[] values;
        mapping (address => bool) is_in;
    }
    Set my_set;


    constructor(
        //string memory name,
        //string memory symbol,
        //address[] memory _contracts,
        address _proxyRegistryAddress)
        ERC721Tradable("Metaverse bar", "MB", _proxyRegistryAddress)
    {
    /*
        contracts = new IERC721Enumerable[](_contracts.length);
        for (uint256 i = 0; i < _contracts.length; i++) {
            contracts[i] = IERC721Enumerable(_contracts[i]);
        }
    */
        // _reserve();
    }

    function addtoset(address a) private {
             my_set.values.push(a);
             my_set.is_in[a] = true;
    }

    function deladd(address a) private {
             my_set.is_in[a] = false;
    }

    function ifWhitelist(address a) public view returns (bool) {
         if (!my_set.is_in[a])
           return false;
         if (my_set.is_in[a]==false)
           return false;
         return true;
    }

    function setActiveStatus(bool _isactive) external onlyOwner {
        activeContract = _isactive;
    }

    function getActiveStatus() external view returns (bool) {
        return activeContract;
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function setWhitelist(address[] memory _adds) external onlyOwner {
        for (uint256 i = 0; i < _adds.length; i++) {
            addtoset(_adds[i]);
        }
    }

    function getWhitelist() external onlyOwner view returns (address[] memory) {
        return my_set.values;
    }

    function setContracts(address[] memory _contracts) external onlyOwner {
        contracts = new IERC721Enumerable[](_contracts.length);
        for (uint256 i = 0; i < _contracts.length; i++) {
            contracts[i] = IERC721Enumerable(_contracts[i]);
        }
    }

    function setBaseUrl(string memory _url) external onlyOwner {
        baseUrl = _url;
    }

    function toTokenId(uint kind, uint256 externTokenId) private pure returns (uint256) {
        return MAX_TOKENS_PER_KIND * kind + externTokenId;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(address(walletAddress)), balance);
    }

    function getMintable(address owner) public view returns (uint256[] memory) {
        uint256[][] memory tokensByKind = new uint256[][](contracts.length);
        uint256 total = 0;
        for (uint256 k = 0; k < contracts.length; k++) {
            tokensByKind[k] = getMintableFor(k, owner);
            total += tokensByKind[k].length;
        }
        uint256[] memory tokens = new uint256[](total);
        uint256 idx = 0;
        for (uint256 k = 0; k < contracts.length; k++) {
            for (uint256 i = 0; i < tokensByKind[k].length; i++) {
                tokens[idx++] = tokensByKind[k][i];
            }
        }
        return tokens;
    }

    function getMintableFor(uint kind, address owner) public view returns (uint256[] memory) {
        IERC721Enumerable cont = contracts[kind];
        uint256 count = cont.balanceOf(owner);
        uint256[] memory tokens = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            try cont.tokenOfOwnerByIndex(owner, i) returns (uint256 externTokenId) {
                uint256 tokenId = toTokenId(kind, externTokenId);
                tokens[i] = _exists(tokenId) ? type(uint256).max : tokenId;
            } catch Error(string memory) {
                // concurrent transfer-out, pass
            }
        }
        return tokens;
    }

    // mint all tokens to the owner
    // function _reserve() private {
    //     address payable sender = msgSender();
    //     for (uint256 i = 0; i < maxNftSupply; i++) {
    //         _safeMint(sender, i, "");
    //     }
    // }

    function buy(uint256 tokenId) public payable {
        require(activeContract, "Contract is not active");
        uint kind = tokenId / MAX_TOKENS_PER_KIND;
        require(kind < contracts.length, "TokenId error");
        uint extTokenId = tokenId % MAX_TOKENS_PER_KIND;
        require(contracts[kind].ownerOf(extTokenId) == msgSender(), "You do not own the item");
        if (!ifWhitelist(msgSender())){
            require(msg.value >= price - 100, "not enough payment");
        }
        else{
            deladd(msgSender());
        }
        _safeMint(msgSender(), tokenId);
    }

    function baseTokenURI() override public view returns (string memory) {
        return baseUrl;
    }
}
