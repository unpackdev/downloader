// SPDX-License-Identifier: MIT
pragma solidity =0.8.7;

import "./ERC1155.sol";
import "./ERC1155Burnable.sol";
import "./ERC1155Supply.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract FFMarketItem1155 is
    ERC1155,
    Ownable,
    ERC1155Burnable,
    ERC1155Supply,
    ReentrancyGuard
{
    string public name;
    string public symbol;
    mapping(uint256 => string) private _uris;
    bool public mintPaused = false;
    bool public burnApprovalToggled = false;

    event BurnEvent(address indexed _from, uint256 id, uint256 value);

    constructor() ERC1155("Founder Marketplace Item") {
        name = "Founder Marketplace Item";
        symbol = "FMI";
    }

    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external onlyOwner {
        require(!mintPaused, "mint is paused");
        require(id > 0, "0 is reserved for non erc1155");
        _mint(to, id, amount, data);
    }

    function singleBurn(
        address from,
        uint256 id,
        uint256 amount
    ) external nonReentrant {
        if (burnApprovalToggled) {
            require(
                from == _msgSender() || isApprovedForAll(from, _msgSender()),
                "ERC1155: caller is not approved"
            );
        } else {
            require(from == _msgSender(), "caller is not owner");
        }

        require(balanceOf(from, id) > amount, "insufficient balance");

        _burn(from, id, amount);
        emit BurnEvent(from, id, amount);
    }

    function mintPause(bool _flag) external onlyOwner {
        mintPaused = _flag;
    }

    // The following functions are overrides required by Solidity.
    function uri(uint256 tokenId) public view override returns (string memory) {
        return (_uris[tokenId]);
    }

    function setTokenUri(uint256 tokenId, string memory myUri)
        public
        onlyOwner
    {
        _uris[tokenId] = myUri;
    }

    function burnApprovalToggle(bool _flag) public onlyOwner {
        burnApprovalToggled = _flag;
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155, ERC1155Supply) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}
