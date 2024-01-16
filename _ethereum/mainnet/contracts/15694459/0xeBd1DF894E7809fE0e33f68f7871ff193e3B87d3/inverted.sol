// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./ERC721.sol";
import "./Address.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./IERC2981.sol";
import "./Strings.sol";

import "./renderer.sol";

contract inverted is ERC721, Ownable, IERC2981 {
    uint256 public constant maxSupply = 427;
    uint256 public royalty;
    renderer public r;

    uint256 total;
    mapping(address => bool) minted;

    constructor() ERC721("inverted", "nvrtd") {}

    function transformAddress(address addr) public pure returns (address) {
        return address(~uint160(addr));
    }

    function mint(address inverted) public {
        require(transformAddress(msg.sender) == inverted, "inverted");
        require(!minted[msg.sender], "already minted");
        require(total < maxSupply, "too late");
        _mint(msg.sender, uint256(uint160(inverted)));
        minted[msg.sender] = true;
        ++total;
    }

    function setRenderer(renderer _renderer) public onlyOwner {
        r = _renderer;
    }

    function tokenURI(uint256 id)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_ownerOf[id] != address(0), "not minted");
        return r.tokenURI(id);
    }

    function setRoyalty(uint256 _royalty) public onlyOwner {
        royalty = _royalty;
    }

    function royaltyInfo(uint256 id, uint256 salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        require(_ownerOf[id] != address(0), "not minted");
        return (address(this), (salePrice * royalty) / 1000);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    receive() external payable {}

    function withdraw() public onlyOwner {
        Address.sendValue(payable(msg.sender), address(this).balance);
    }

    function withdrawToken(address token) public onlyOwner {
        IERC20(token).transfer(
            msg.sender,
            IERC20(token).balanceOf(address(this))
        );
    }
}
