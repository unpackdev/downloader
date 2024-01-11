pragma solidity ^0.8.0;

import "./IERC721Metadata.sol";
import "./IERC721.sol";
import "./EnumerableSet.sol";
import "./IERC165.sol";
import "./GreetingLib.sol";

contract GreetingCard is IERC721Metadata {
    using EnumerableSet for EnumerableSet.AddressSet;

    address private nftOwner;
    bool private done = false;

    EnumerableSet.AddressSet private signers;

    event Signed(address from);

    constructor(address to) {
        nftOwner = to;
        emit Transfer(address(0), to, 1);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override
        returns (bool)
    {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IERC165).interfaceId;
    }

    function name() external view override returns (string memory) {
        return "Baby Card";
    }

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view override returns (string memory) {
        return "GreetingCard";
    }

    function balanceOf(address owner) external view override returns (uint256) {
        return owner == nftOwner ? 1 : 0;
    }

    function ownerOf(uint256 tokenId) external view override returns (address) {
        require(tokenId == 1, "inexistent token");
        return nftOwner;
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external override {
        revert();
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external override {
        revert();
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external override {
        revert();
    }

    function approve(address to, uint256 tokenId) external override {
        revert();
    }

    function setApprovalForAll(address operator, bool _approved)
        external
        override
    {
        revert();
    }

    function getApproved(uint256 tokenId)
        external
        view
        override
        returns (address)
    {
        return address(0);
    }

    function isApprovedForAll(address, address)
        external
        view
        override
        returns (bool)
    {
        return false;
    }

    receive() external payable {
        require(!done);
        require(signers.add(msg.sender));
        emit Signed(msg.sender);
    }

    function withdraw() external {
        require(msg.sender == nftOwner);
        payable(nftOwner).transfer(address(this).balance);
        done = true;
    }

    /**
     * @dev return tokenURI, image SVG data in it.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(tokenId == 1);
        return GreetingLib.tokenURI(signers);
    }
}
