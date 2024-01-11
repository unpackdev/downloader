// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./Counters.sol";

contract NFT is ERC721A, Ownable, Pausable {
    using Counters for Counters.Counter;

    uint256 public immutable totalNFTSupply;
    uint256 public constant _maxCountMintPublic = 2;
    string private _baseURIAddress;
    address private immutable _wallet;


    mapping(address => uint256) private _walletMintCount;

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _totalSupply,
        address wallet_,
        string memory baseURIAddress_
    ) ERC721A(_name, _symbol) {
        totalNFTSupply = _totalSupply;
        _wallet = wallet_;
        _baseURIAddress = baseURIAddress_;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }


    function changeBaseURI(string memory baseURI_) public onlyOwner {
        _baseURIAddress = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIAddress;
    }

    function getCountWalletNft() public view returns (uint) {
        return _walletMintCount[_msgSender()];
    }

    function ownerMint(address _to, uint256 _count) public payable onlyOwner {
        require((totalSupply() + _count) <= totalNFTSupply, "Total supply exceeded. Use less amount.");
        _safeMint(_to, _count);
    }


    function publicMint(uint256 _count) public whenNotPaused payable {
        require((getCountWalletNft() + _count) <= _maxCountMintPublic, "You cant by nft.");
        require((totalSupply() + _count) <= totalNFTSupply, "Total supply exceeded. Use less amount.");
        _walletMintCount[_msgSender()] += _count;

        _safeMint(_msgSender(), _count);
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
}
