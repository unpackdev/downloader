//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.14;

import "./Ownable.sol";
import "./Pausable.sol";
import "./ERC1155Supply.sol";
import "./ERC1155URIStorage.sol";
import "./IERC721.sol";

/// @title La Table du Chef - Booking
/// @author Consultec FZCO, <info@consultec.ae>
contract LaTableDuChefBooking is
    ERC1155Supply,
    ERC1155URIStorage,
    Ownable,
    Pausable
{
    address public _conciergerie;
    address public immutable _nftPass;

    mapping(uint256 => uint256) public _priceByTokenId;
    mapping(uint256 => uint256) public _maxSupplyByTokenId;

    constructor(address conciergerie, address nftPass) ERC1155("") {
        _conciergerie = conciergerie;
        _nftPass = nftPass;
    }

    function name() external pure returns (string memory) {
        return "LaTableDuChefBooking";
    }

    function symbol() external pure returns (string memory) {
        return "LTDCB";
    }

    function uri(uint256 tokenId)
        public
        view
        virtual
        override(ERC1155, ERC1155URIStorage)
        returns (string memory)
    {
        return ERC1155URIStorage.uri(tokenId);
    }

    function setURI(uint256 tokenId, string memory tokenURI)
        external
        onlyOwner
    {
        _setURI(tokenId, tokenURI);
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _setBaseURI(baseURI);
    }

    function setConciergerie(address conciergerie) external onlyOwner {
        _conciergerie = conciergerie;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function setConfigByTokenId(
        uint256 id,
        uint256 max,
        uint256 price
    ) external onlyOwner {
        _maxSupplyByTokenId[id] = max;
        _priceByTokenId[id] = price;
    }

    function setBatchConfigByTokenIds(
        uint256[] calldata ids,
        uint256[] calldata prices,
        uint256[] calldata supplies
    ) external onlyOwner {
        require(
            (ids.length == supplies.length) &&
                (supplies.length == prices.length),
            "!length"
        );
        for (uint256 i = 0; i < ids.length; i++) {
            _priceByTokenId[ids[i]] = prices[i];
            _maxSupplyByTokenId[ids[i]] = supplies[i];
        }
    }

    function getConfigByTokenId(uint256 id)
        external
        view
        returns (uint256, uint256)
    {
        return (_priceByTokenId[id], _maxSupplyByTokenId[id]);
    }

    function publicMint(
        address to,
        uint256 amount,
        uint256 id
    ) external payable whenNotPaused {
        unchecked {
            require(
                msg.value >= _priceByTokenId[id] * uint16(amount),
                "!ether"
            );
        }
        mint(to, id, amount);
    }

    function ownerMint(
        address to,
        uint256 amount,
        uint256 id
    ) external onlyOwner {
        mint(to, id, amount);
    }

    function mint(
        address to,
        uint256 id,
        uint256 amount
    ) private {
        unchecked {
            require(
                totalSupply(id) + uint16(amount) <= _maxSupplyByTokenId[id],
                "!supply"
            );
        }
        _mint(to, id, uint16(amount), new bytes(0));
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override(ERC1155, ERC1155Supply) {
        require(
            (to != _conciergerie) ||
                (IERC721(_nftPass).balanceOf(_msgSender()) >= 1),
            "!pass"
        );
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function withdraw() external onlyOwner {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = payable(owner()).call{value: address(this).balance}(
            ""
        );
        require(success, "!transfer");
    }
}
