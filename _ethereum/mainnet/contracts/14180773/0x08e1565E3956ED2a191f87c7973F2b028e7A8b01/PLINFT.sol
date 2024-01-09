// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC1155.sol";
import "./ERC1155Pausable.sol";
import "./ERC1155Supply.sol";
import "./draft-EIP712.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./PullPayment.sol";
import "./Strings.sol";

contract PLINFT is
Ownable,
ERC1155,
ERC1155Pausable,
ERC1155Supply,
PullPayment
{
    mapping (bytes32 => uint256) public uriToTokenId;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;
    mapping(address => bool) private _paidWhitelist;
    mapping(address => bool) private _freeWhitelist;
    mapping(address => bool) private _minted;
    bool public isActiveSale = false;
    bool public isPublicSale = false;
    string public name = "PLINFT Passes";
    string public symbol = "PLN";
    uint256 public constant MINT_PRICE = 0.08 ether;
    uint256 private _currentTokenID = 0;
    uint256 private _publicSupply = 1;

    //plinft wallet to withdraw funds
    address private plinftWallet;

    constructor() ERC1155("ipfs://bafybeibfwqneymsb6caodywrkbiknmcaanuth7pb5gotmjrtyqvojrkmii/{id}.json") {
        _mint(msg.sender, _currentTokenID, 1, "");
    }

    function contractURI() public pure returns (string memory) {
        return "https://ipfs.io/ipfs/QmV5Dc8Y61q3xCNYxJU7H4cTtWM8RANBCtM7KQnPEXPM6J";
    }

    function create() external onlyOwner {
        _incrementTokenTypeId();
        _mint(msg.sender, _currentTokenID, 1, "");
    }

    function _incrementTokenTypeId() private  {
        _currentTokenID++;
    }

    function setIsActiveSale(bool _isActiveSale) external onlyOwner {
        isActiveSale = _isActiveSale;
    }

    function setIsPublicSale(bool _isPublicSale) external onlyOwner {
        isPublicSale = _isPublicSale;
    }

    function setPublicSupply (uint256 total) external onlyOwner {
        _publicSupply = total;
    }

    function publicSupplyRemaining() external view onlyOwner returns (uint256) {
        return _publicSupply;
    }

    function setPaidWhitelist(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            _paidWhitelist[addresses[i]] = true;
        }
    }

    function resetMinted(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            _minted[addresses[i]] = false;
        }
    }

    function setFreeWhitelist(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            _freeWhitelist[addresses[i]] = true;
        }
    }

    function isOnPaidWhitelist(address _address) public view returns (bool) {
        return _paidWhitelist[_address];
    }

    function isOnFreeWhiteList(address _address) public view returns (bool) {
        return _freeWhitelist[_address];
    }

    function mintItem(address _address, uint256 tokenId) external payable
    {
        bool paidMinter = isOnPaidWhitelist(_address);
        bool freeMinter = isOnFreeWhiteList(_address);
        require(paidMinter || freeMinter, "Not on the whitelist.");
        require(isActiveSale, "Sale is not active.");
        require(!_minted[msg.sender], "Exceeded maximum number of tokens.");
        if (paidMinter) {
            require(msg.value == MINT_PRICE, "Transaction value did not equal the mint price.");
        }
        _minted[msg.sender] = true;
        _mint(_address, tokenId, 1, "");
    }

    function publicMint(address _address, uint256 tokenId) external payable
    {
        require(isActiveSale, "Sale is not active.");
        require(isPublicSale, "Public sale is not active.");
        require(!_minted[msg.sender], "Exceeded maximum number of tokens.");
        require(msg.value == MINT_PRICE, "Transaction value did not equal the mint price.");
        require(_publicSupply > 0, "PLINFT Passes are sold out!");
        _minted[msg.sender] = true;
        _publicSupply -= 1;
        _mint(_address, tokenId, 1, "");
    }

    function pause() public virtual onlyOwner {
        _pause();
    }

    function unpause() public virtual onlyOwner {
        _unpause();
    }

    function uri(uint256 _tokenId) public override  view returns (string memory) {
        require(exists(_tokenId), "This token does not exist.");
        return string(
            abi.encodePacked(
                "ipfs://bafybeibfwqneymsb6caodywrkbiknmcaanuth7pb5gotmjrtyqvojrkmii/",
                Strings.toString(_tokenId),
                ".json"));
    }

    function setPlinftWallet(address _plinftWallet) public onlyOwner {
        plinftWallet = _plinftWallet;
    }

    //Withdraws fund to plinft wallet. Please set it before calling this funciton.
    function withdrawAll() public onlyOwner {
        require(plinftWallet != address(0), 'Plinft wallet address is not available');
        uint256 balance = address(this).balance;
        payable(plinftWallet).transfer(balance);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override(ERC1155, ERC1155Pausable, ERC1155Supply) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}
