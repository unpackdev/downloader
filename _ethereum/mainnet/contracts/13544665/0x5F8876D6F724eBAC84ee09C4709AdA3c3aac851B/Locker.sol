pragma solidity >=0.6.2 <0.8.0;
import "./IERC20.sol";
import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./ERC1155Receiver.sol";
import "./IERC1155.sol";

import "./Ownable.sol";

contract Locker is IERC721Receiver, ERC1155Receiver, Ownable {
    bytes4 private constant _KIP17_RECEIVED = 0x6745782b;
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;
    bytes4 private constant _KIP7_RECEIVED = 0x9d188c22;
    bytes4 private constant _ERC1155_RECEIVED =
        bytes4(keccak256('onERC1155Received(address,address,uint256,uint256,bytes)'));

    event NFTReceived(address operator, address from, uint256 tokenId, bytes data);
    event KIP7Received(address operator, address from, uint256 tokenId, bytes data);
    event ERC1155Received(address operator, address from, uint256 tokenId, uint256 amount, bytes data);

    constructor(address owner) public {
        _transferOwnership(owner);
    }

    function transferCurrency(
        address to,
        address currencyAddr,
        uint256 amount
    ) external onlyOwner returns (bool) {
        IERC20 currency = IERC20(currencyAddr);
        currency.transfer(to, amount);
        return true;
    }

    function transferNFT(
        address to,
        address nftAddr,
        uint256 tokenId
    ) external onlyOwner returns (bool) {
        IERC721 nft = IERC721(nftAddr);
        nft.safeTransferFrom(address(this), to, tokenId);
        return true;
    }

    function transferNFT(
        address to,
        address nftAddr,
        uint256 tokenId,
        uint256 nftType,
        uint256 amount
    ) external onlyOwner returns (bool) {
        if (nftType == 0) {
            IERC721 nft = IERC721(nftAddr);
            nft.safeTransferFrom(address(this), to, tokenId);
        } else {
            IERC1155 nft = IERC1155(nftAddr);
            nft.safeTransferFrom(address(this), to, tokenId, amount, '');
        }

        return true;
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes memory data
    ) public override returns (bytes4) {
        emit NFTReceived(operator, from, tokenId, data);
        return _ERC721_RECEIVED;
    }

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) public override returns (bytes4) {
        emit ERC1155Received(operator, from, id, value, data);
        return _ERC1155_RECEIVED;
    }

    function onERC1155BatchReceived(
        address _operator,
        address _from,
        uint256[] calldata _ids,
        uint256[] calldata _values,
        bytes calldata _data
    ) public override returns (bytes4) {
        return bytes4(keccak256('onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)'));
    }
}
