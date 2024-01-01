// SPDX-License-Identifier: MIT

pragma solidity ^0.8.21;

import "./ERC2981.sol";
import "./ERC721AQueryable.sol";
import "./OperatorFilterer.sol";
import "./Ownable.sol";

error BurningNotAllowed();

abstract contract ERC721AOpensea is
    ERC2981,
    ERC721AQueryable,
    OperatorFilterer,
    Ownable
{
    event TokenRoyaltyUpdated(uint256 tokenId, address royaltyAddress, uint96 royaltyAmount);
    event DefaultRoyaltyUpdated(address royaltyAddress, uint96 royaltyAmount);
    event TokenBurned(address indexed owner, uint256 tokenId);
    event BurnStatusChanged(bool burnActive);

    bool public operatorFilteringEnabled;
    bool public allowBurning;

    constructor(address _initialOwner) Ownable(_initialOwner) {
        _registerForOperatorFiltering();
        operatorFilteringEnabled = true;
        allowBurning = false;
    }

    function setDefaultRoyalty(
        address receiver,
        uint96 feeNumerator
    ) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);

        emit DefaultRoyaltyUpdated(receiver, feeNumerator);
    }

    function setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) external onlyOwner {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);

        emit TokenRoyaltyUpdated(tokenId, receiver, feeNumerator);
    }

    function setAllowBurning(bool _allowBurning) external onlyOwner {
        allowBurning = _allowBurning;
        
        emit BurnStatusChanged(allowBurning);
    }

    function burn(uint256 tokenId) external {
        if (!allowBurning) {
            revert BurningNotAllowed();
        }

        _burn(tokenId, true);

        emit TokenBurned(msg.sender, tokenId);
    }

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override(IERC721A, ERC721A) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    )
        public
        payable
        override(IERC721A, ERC721A)
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(IERC721A, ERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(IERC721A, ERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override(IERC721A, ERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    // function supportsInterface(
    //     bytes4 interfaceId
    // ) public view virtual override(IERC721A, ERC721A, ERC2981) returns (bool) {
    //     return ERC721A.supportsInterface(interfaceId);
    // }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(IERC721A, ERC721A, ERC2981) returns (bool) {
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }

    function setOperatorFilteringEnabled(bool value) public onlyOwner {
        operatorFilteringEnabled = value;
    }

    function _operatorFilteringEnabled() internal view override returns (bool) {
        return operatorFilteringEnabled;
    }

    function _isPriorityOperator(
        address operator
    ) internal pure override returns (bool) {
        return operator == address(0x1E0049783F008A0085193E00003D00cd54003c71);
    }
}
