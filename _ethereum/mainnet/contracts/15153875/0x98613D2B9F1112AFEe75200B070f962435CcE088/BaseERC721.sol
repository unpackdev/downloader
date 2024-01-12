// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./ERC721.sol";
import "./ERC721A.sol";
import "./Ownable.sol";

contract BaseERC721 is Ownable, ERC721A {
    uint256 public immutable TOTAL_MAX_QTY;
    string private _tokenBaseURI;
    uint256 public mintedQty = 0;
    uint256 public cutoffQty = 0;
    mapping(address => uint256) public minterToTokenQty;

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 TOTAL_MAX_QTY_
    ) ERC721A(name_, symbol_) {
        TOTAL_MAX_QTY = TOTAL_MAX_QTY_;
    }

    function FREE_MINT_MAX_QTY() public view returns (uint256) {
        return TOTAL_MAX_QTY - totalSupply();
    }

    function TOTAL_MINT_MAX_QTY() public view returns (uint256) {
        return TOTAL_MAX_QTY - totalSupply();
    }

    function maxFreeQtyPerWallet() public view returns (uint256) {
        if (cutoffQty == 0) return 0;
        if (mintedQty < cutoffQty) return 3;
        return 1;
    }

    function mint(uint256 _mintQty) external {
        require(totalSupply() + _mintQty <= TOTAL_MAX_QTY, "MAXL");
        require(
            minterToTokenQty[msg.sender] + _mintQty <= maxFreeQtyPerWallet(),
            "MAXF"
        );

        mintedQty += _mintQty;
        minterToTokenQty[msg.sender] += _mintQty;
        _safeMint(msg.sender, _mintQty);
    }

    function gift(address[] calldata receivers) external onlyOwner {
        require(totalSupply() + receivers.length <= TOTAL_MAX_QTY, "MAXG");

        for (uint256 i = 0; i < receivers.length; i++) {
            _safeMint(receivers[i], 1);
        }
    }

    function harakiri(uint256 tokenId) public virtual {
        _burn(tokenId);
    }

    function withdrawAll() external onlyOwner {
        require(address(this).balance > 0, "ZERO");
        payable(msg.sender).transfer(address(this).balance);
    }

    function setCutoffQty(uint256 qty) external onlyOwner {
        cutoffQty = qty;
    }

    function setBaseURI(string calldata URI) external onlyOwner {
        _tokenBaseURI = URI;
    }

    function _startTokenId() internal pure override(ERC721A) returns (uint256) {
        return 1;
    }

    function _baseURI()
        internal
        view
        override(ERC721A)
        returns (string memory)
    {
        return _tokenBaseURI;
    }
}
