// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

import "./Ownable.sol";
import "./IMirrorAllocatedEditionsLogic.sol";
import "./IERC721.sol";
import "./IERC165.sol";
import "./IERC2981.sol";
import "./IMirrorOpenSaleV0.sol";
import "./IERC2309.sol";

/**
 * @title MirrorAllocatedEditionsLogic
 * @author MirrorXYZ
 */
contract MirrorAllocatedEditionsLogic is
    Ownable,
    IMirrorAllocatedEditionsLogic,
    IERC721,
    IERC721Events,
    IERC165,
    IERC721Metadata,
    IERC2309,
    IERC2981
{
    /// @notice Token name
    string public override name;

    /// @notice Token symbol
    string public override symbol;

    /// @notice Token baseURI
    string public baseURI;

    /// @notice Token contentHash
    bytes32 public contentHash;

    /// @notice Token supply
    uint256 public totalSupply;

    /// @notice Burned tokens
    mapping(uint256 => bool) internal _burned;

    /// @notice Token owners
    mapping(uint256 => address) internal _owners;

    /// @notice Token balances
    mapping(address => uint256) internal _balances;

    /// @notice Token approvals
    mapping(uint256 => address) internal _tokenApprovals;

    /// @notice Token operator approvals
    mapping(address => mapping(address => bool)) internal _operatorApprovals;

    /// @notice Mirror open sale address
    address public immutable mirrorOpenSale;

    // ============ Royalty Info (ERC2981) ============

    /// @notice Account that will receive royalties
    /// @dev set address(0) to avoid royalties
    address public royaltyRecipient;

    /// @notice Royalty percentage
    uint256 public royaltyPercentage;

    /// @dev Sets zero address as owner since this is a logic contract
    /// @param mirrorOpenSale_ sale contract address
    constructor(address mirrorOpenSale_) Ownable(address(0)) {
        mirrorOpenSale = mirrorOpenSale_;
    }

    // ============ Constructor ============

    /// @dev Initialize contract
    /// @param metadata ERC721Metadata parameters
    /// @param owner_ owner of this contract
    /// @param fundingRecipient_ account that will receive funds from sales
    /// @param royaltyRecipient_ account that will receive royalties
    /// @param royaltyPercentage_ royalty percentage
    /// @param price sale listing price
    /// @param list whether to list on sale contract
    /// @param open whether to list with a closed or open sale
    /// @dev Initialize parameters, mint total suppply to owner. Reverts if called
    /// after contract deployment. If list is true, the open sale contract gets approval
    /// for all tokens.
    function initialize(
        NFTMetadata memory metadata,
        address owner_,
        address payable fundingRecipient_,
        address payable royaltyRecipient_,
        uint256 royaltyPercentage_,
        uint256 price,
        bool list,
        bool open,
        uint256 feePercentage
    ) external override {
        // ensure that this function is only callable during contract construction.
        assembly {
            if extcodesize(address()) {
                revert(0, 0)
            }
        }

        // NFT Metadata
        name = metadata.name;
        symbol = metadata.symbol;
        baseURI = metadata.baseURI;
        contentHash = metadata.contentHash;
        totalSupply = metadata.quantity;

        // Set owner
        _setOwner(address(0), owner_);

        // Royalties
        royaltyRecipient = royaltyRecipient_;
        royaltyPercentage = royaltyPercentage_;

        emit ConsecutiveTransfer(
            // fromTokenId
            0,
            // toTokenId
            metadata.quantity - 1,
            // fromAddress
            address(0),
            // toAddress
            owner_
        );

        _balances[owner_] = totalSupply;

        if (list) {
            IMirrorOpenSaleV0(mirrorOpenSale).register(
                IMirrorOpenSaleV0.SaleConfig({
                    token: address(this),
                    startTokenId: 0,
                    endTokenId: totalSupply - 1,
                    operator: owner_,
                    recipient: fundingRecipient_,
                    price: price,
                    open: open,
                    feePercentage: feePercentage
                })
            );

            _operatorApprovals[owner_][mirrorOpenSale] = true;

            emit ApprovalForAll(
                // owner
                owner_,
                // operator
                mirrorOpenSale,
                // approved
                true
            );
        }
    }

    // ============ ERC721 Methods ============

    function balanceOf(address owner_) public view override returns (uint256) {
        require(
            owner_ != address(0),
            "ERC721: balance query for the zero address"
        );

        return _balances[owner_];
    }

    function ownerOf(uint256 tokenId) public view override returns (address) {
        address _owner = _owners[tokenId];

        // if there is not owner set, and the token is not burned, the operator owns it
        if (_owner == address(0) && !_burned[tokenId]) {
            return owner;
        }

        require(_owner != address(0), "ERC721: query for nonexistent token");

        return _owner;
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        //solhint-disable-next-line max-line-length
        require(
            _isApprovedOrOwner(msg.sender, tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );

        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public override {
        require(
            _isApprovedOrOwner(msg.sender, tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );
        _safeTransfer(from, to, tokenId, _data);
    }

    function approve(address to, uint256 tokenId) public override {
        address owner_ = ownerOf(tokenId);
        require(to != owner_, "ERC721: approval to current owner");

        require(
            msg.sender == owner_ || isApprovedForAll(owner_, msg.sender),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    function getApproved(uint256 tokenId)
        public
        view
        override
        returns (address)
    {
        require(
            _exists(tokenId),
            "ERC721: approved query for nonexistent token"
        );

        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved)
        public
        override
    {
        require(operator != msg.sender, "ERC721: approve to caller");

        _operatorApprovals[msg.sender][operator] = approved;

        emit ApprovalForAll(
            // owner
            msg.sender,
            // operator
            operator,
            // approved
            approved
        );
    }

    function isApprovedForAll(address owner_, address operator_)
        public
        view
        override
        returns (bool)
    {
        return _operatorApprovals[owner_][operator_];
    }

    // ============ ERC721 Metadata Methods ============

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        return string(abi.encodePacked(baseURI, _toString(tokenId)));
    }

    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked(baseURI, "metadata"));
    }

    function getContentHash(uint256) public view returns (bytes32) {
        return contentHash;
    }

    // ============ Burn Method ============

    function burn(uint256 tokenId) public {
        require(
            _isApprovedOrOwner(msg.sender, tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );

        _burn(tokenId);
    }

    // ============ ERC2981 Methods ============

    /// @notice Get royalty info
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        receiver = royaltyRecipient;
        royaltyAmount = (_salePrice * royaltyPercentage) / 10_000;
    }

    function setRoyaltyInfo(
        address payable royaltyRecipient_,
        uint256 royaltyPercentage_
    ) external override onlyOwner {
        royaltyRecipient = royaltyRecipient_;
        royaltyPercentage = royaltyPercentage_;

        emit RoyaltyChange(
            // oldRoyaltyRecipient
            royaltyRecipient,
            // oldRoyaltyPercentage
            royaltyPercentage,
            // newRoyaltyRecipient
            royaltyRecipient_,
            // newRoyaltyPercentage
            royaltyPercentage_
        );
    }

    // ============ IERC165 Method ============

    function supportsInterface(bytes4 interfaceId)
        public
        pure
        override
        returns (bool)
    {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IERC165).interfaceId ||
            interfaceId == type(IERC2981).interfaceId;
    }

    // ============ Internal Methods ============

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal {
        require(
            ownerOf(tokenId) == from,
            "ERC721: transfer of token that is not own"
        );

        require(
            to != address(0),
            "ERC721: transfer to the zero address (use burn instead)"
        );

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;

        _owners[tokenId] = to;
        _balances[to] += 1;

        emit Transfer(
            // from
            from,
            // to
            to,
            // tokenId
            tokenId
        );
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        return !_burned[tokenId];
    }

    function _burn(uint256 tokenId) internal {
        address owner_ = ownerOf(tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner_] -= 1;

        delete _owners[tokenId];

        _burned[tokenId] = true;

        emit Transfer(
            // from
            owner_,
            // to
            address(0),
            // tokenId
            tokenId
        );
    }

    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal {
        _transfer(from, to, tokenId);
        require(
            _checkOnERC721Received(from, to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        returns (bool)
    {
        require(_exists(tokenId), "ERC721: query for nonexistent token");

        address owner_ = ownerOf(tokenId);

        return (spender == owner_ ||
            getApproved(tokenId) == spender ||
            isApprovedForAll(owner_, spender));
    }

    function _approve(address to, uint256 tokenId) internal {
        _tokenApprovals[tokenId] = to;

        emit Approval(
            // owner
            ownerOf(tokenId),
            // approved
            to,
            // tokenId
            tokenId
        );
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (_isContract(to)) {
            try
                IERC721Receiver(to).onERC721Received(
                    msg.sender,
                    from,
                    tokenId,
                    _data
                )
            returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert(
                        "ERC721: transfer to non ERC721Receiver implementer"
                    );
                } else {
                    // solhint-disable-next-line no-inline-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/7f6a1666fac8ecff5dd467d0938069bc221ea9e0/contracts/utils/Address.sol
    function _isContract(address account) internal view returns (bool) {
        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    // From https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Strings.sol
    function _toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}
