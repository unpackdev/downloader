// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./IERC721.sol";
import "./SafeMath.sol";
import "./ERC721Tradable.sol";

/**
 * @title PixlBros NFT
 * a contract for non-fungible PixlBros.
 */
contract PixlBros is ERC721Tradable {
    using SafeMath for uint256;
    string public BROS_PROVENANCE = "";

    string private _baseTokenURI = "ipfs://Qmb1cbdwzbcKDb3WsMJx2xujUeq4EvSa8WC4GNiJv9tG8a/";
    string private _contractURI = "ipfs://Qmb1cbdwzbcKDb3WsMJx2xujUeq4EvSa8WC4GNiJv9tG8a/contract/metadata";
    string private _ipfsTokenURI = "ipfs://Qmb1cbdwzbcKDb3WsMJx2xujUeq4EvSa8WC4GNiJv9tG8a/";
    address private _creator;
    uint256 private constant MAX_TOKENS_PER_PURCHASE = 16;
    uint256 private price = 80000000000000000; // 0.08000 Ether

    bool public isSaleActive = true;

    /*
     * Enforce the existence of only 8205 = BROS.
     */
    uint256 MAX_TOKENS = 8205;

    constructor(address _proxyRegistryAddress)
    ERC721Tradable("PixlBros", "BROS", _proxyRegistryAddress)
    {
        _creator = msg.sender;
    }

    function baseTokenURI() override public view returns (string memory) {
        return _baseTokenURI;
    }

    function ipfsTokenURI() override public view returns (string memory) {
        return _ipfsTokenURI;
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function changeBaseTokenURI(string memory _uri) public onlyCreator {
        _baseTokenURI = _uri;
    }

    function changeContractURI(string memory _uri) public onlyCreator {
        _contractURI = _uri;
    }

    function changeIpfsTokenURI(string memory _uri) public onlyCreator {
        _ipfsTokenURI = _uri;
    }

    function flipSaleStatus() public onlyCreator {
        isSaleActive = !isSaleActive;
    }

    function setPrice(uint256 _newPrice) public onlyCreator {
        price = _newPrice;
    }

    function getPrice() public view returns (uint256){
        return price;
    }

    function renounce() public onlyCreator {
        require(totalSupply() < MAX_TOKENS, "Renounce: not all tokens are generated");
        _baseTokenURI = "";
        isSaleActive = false;
        _creator = address(0);
        renounceOwnership();
    }

    function buy(uint256 _count) public payable {
        uint256 totalSupply = totalSupply();

        require(isSaleActive, "Sale is not active");
        require(_count > 0 && _count <= MAX_TOKENS_PER_PURCHASE, "Exceeds maximum tokens you can purchase in a single transaction");
        require(totalSupply + _count <= MAX_TOKENS, "Exceeds maximum tokens available for purchase");
        require(msg.value >= price.mul(_count), "Ether value sent is not correct");

        for (uint256 i = 0; i < _count; i++) {
            _safeMint(msg.sender, totalSupply + i);
        }
    }

    function reserve(uint256 _supply) public {
        uint256 totalSupply = totalSupply();
        require(totalSupply + _supply <= MAX_TOKENS, "Exceeds maximum tokens available");
        for (uint256 i = 0; i < _supply; i++) {
            _safeMint(_creator, totalSupply + i);
        }
    }

    function tokensByOwner(address _owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }

    /*
    * Set provenance once it's calculated
    */
    function setProvenanceHash(string memory provenanceHash) public onlyCreator {
        BROS_PROVENANCE = provenanceHash;
    }

    /**
     * @dev Returns the address of the creator.
     */
    function creator() public view virtual returns (address) {
        return _creator;
    }

    modifier onlyCreator() {
        require(creator() == _msgSender(), "NFT: caller is not the creator");
        _;
    }

    function withdraw() public onlyCreator {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function withdrawERC20(address _tokenContract, uint256 _amount) external onlyCreator {
        IERC20 tokenContract = IERC20(_tokenContract);
        tokenContract.transfer(msg.sender, _amount);
    }

    function withdrawERC721(address _tokenContract, uint256 _tokenId) external onlyCreator {
        IERC721 tokenContract = IERC721(_tokenContract);
        tokenContract.transferFrom(address(this), msg.sender, _tokenId);
    }

    function airdrop(address[] memory _dests, uint256[] memory _tokenIds) onlyCreator public returns (uint256) {
        uint256 i = 0;
        while (i < _dests.length) {
            transferFrom(msg.sender, _dests[i], _tokenIds[i]);
            i += 1;
        }
        return (i);
    }
}
