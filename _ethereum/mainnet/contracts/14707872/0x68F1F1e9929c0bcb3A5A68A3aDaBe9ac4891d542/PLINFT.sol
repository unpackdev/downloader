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
    bool public isActiveSale = false;
    string public name = "PLINFT Passes";
    string public symbol = "PLN";
    uint256 public mintPrice = 0.1 ether;
    uint256 private _currentTokenID = 0;
    uint256 private _publicSupply = 1;
    address private plinftWallet;

    constructor() ERC1155("ipfs://QmPy6WWsano2q1mr5CR6E4mGK599kMJ1UZFwZ8bVBnjrni/{id}.json") {
        _mint(msg.sender, _currentTokenID, 1, "");
    }

    function contractURI() public pure returns (string memory) {
        return "https://ipfs.io/ipfs/QmXJEW3t5RfWMWPSWd4orck5526ZfqqbdnCno3qD4whpXT";
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

    function setPublicSupply (uint256 total) external onlyOwner {
        _publicSupply = total;
    }

    function publicSupplyRemaining() external view onlyOwner returns (uint256) {
        return _publicSupply;
    }

    function setMintPrice(uint256 newMintPrice) external onlyOwner {
        mintPrice = newMintPrice;
    }

    function mintItem(address _address, uint256 tokenId) external payable
    {
        require(isActiveSale, "Sale is not active.");
        require(msg.value == mintPrice, "Transaction value did not equal the mint price.");
        _mint(_address, tokenId, 1, "");
    }

    function mintBatch(address[] calldata _addresses, uint256[] calldata tokenIds, uint256[] calldata tokensPerAddress) external payable onlyOwner
    {
        for (uint256 i = 0; i < _addresses.length; i++) {
            _mintBatch(_addresses[i], tokenIds, tokensPerAddress, "");
        }
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
                "ipfs://QmPy6WWsano2q1mr5CR6E4mGK599kMJ1UZFwZ8bVBnjrni/",
                Strings.toString(_tokenId),
                ".json"));
    }

    function setPlinftWallet(address _plinftWallet) public onlyOwner {
        plinftWallet = _plinftWallet;
    }

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
