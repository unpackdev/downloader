// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import "./IERC721.sol";
import "./IERC2309.sol";
import "./ITreasuryConfig.sol";
import "./IMirrorTreasury.sol";
import "./Governable.sol";
import "./Pausable.sol";
import "./Reentrancy.sol";
import "./AllocatedEditionsStorage.sol";
import "./IAllocatedEditionsLogic.sol";
import "./IProxyRegistry.sol";

/**
 * @title AllocatedEditions
 * @author MirrorXYZ
 */
contract AllocatedEditionsLogic is 
    AllocatedEditionsStorage,
    Governable,
    Pausable,
    IAllocatedEditionsLogicEvents,
    IERC721,
    IERC721Events,
    IERC165,
    IERC721Metadata,
    IERC2309,
    Reentrancy
{
    /// @notice IERC721Metadata
    string public override name;
    string public override symbol;

    constructor(address owner_, address proxyRegistry_) Governable(owner_) Pausable(true) {
        proxyRegistry = proxyRegistry_;
    }

    // ============ Pause Methods ============

    /// @notice pause purchases
    function pause() public onlyGovernance {
        _pause();
    }

    /// @notice unpause purchases
    function unpause() public onlyGovernance {
        _unpause();
    }

    // ============ Edition Methods ============

    function purchase(address recipient)
        external
        payable
        whenNotPaused
        returns (uint256 tokenId)
    {
        // Check that recipient has not already purchased
        require(!purchased[recipient], "recipient already purchased");
        // Check that enough funds have been sent to purchase an edition.
        require(msg.value >= price, "Insufficient funds sent");
        // Track and update token id.
        tokenId = nextTokenId;
        nextTokenId++;
        // Check that there are still tokens available to purchase.
        require(tokenId < quantity, "This edition is sold out");
        // Mint a new token for the sender, using the `tokenId`.
        purchased[recipient] = true;
        _mint(recipient, tokenId);
        emit EditionPurchased(tokenId, msg.value, msg.sender, recipient);
    }

    // ============ NFT Methods ============

    function supportsInterface(bytes4 interfaceId)
        public
        pure
        override
        returns (bool)
    {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IERC165).interfaceId;
    }

    function balanceOf(address owner_) public view override returns (uint256) {
        if (owner_ == operator) {
            return _balances[owner_] + allocation - allocationsTransferred;
        }

        require(
            owner_ != address(0),
            "ERC721: balance query for the zero address"
        );

        return _balances[owner_];
    }

    function ownerOf(uint256 tokenId)
        public
        view
        override
        returns (address)
    {
        // The owner if the operator if the token hasn't been transferred or
        // bought, and it's within the range of the allocation.
        if (
            _owners[tokenId] == address(0) &&
            tokenId < allocation &&
            !_burned[tokenId]
        ) {
            return operator;
        }

        address _owner = _owners[tokenId];

        require(
            _owner != address(0),
            "ERC721: owner query for nonexistent token"
        );

        return _owner;
    }

    function burn(uint256 tokenId) public {
        require(
            _isApprovedOrOwner(msg.sender, tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );

        _burn(tokenId);
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

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        return string(abi.encodePacked(baseURI, _toString(tokenId)));
    }

    function approve(address to, uint256 tokenId) public override {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            msg.sender == owner || isApprovedForAll(owner, msg.sender),
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

    function setApprovalForAll(address approver, bool approved)
        public
        override
    {
        require(approver != msg.sender, "ERC721: approve to caller");

        _operatorApprovals[msg.sender][approver] = approved;
        emit ApprovalForAll(msg.sender, approver, approved);
    }

    /**
     * @notice OpenSea proxy contracts are approved by default.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        // Approve all OpenSea proxy contracts for easy trading.
        if (IProxyRegistry(proxyRegistry).proxies(owner) == operator) {
            return true;
        }

        return _operatorApprovals[owner][operator];
    }

    /// @notice e.g. https://mirror-api.com/editions/metadata
    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked(baseURI, "metadata"));
    }

    /**
     * @notice The hash of the given content for the NFT. Can be used
     * for IPFS storage, verifying authenticity, etc.
     */
    function getContentHash(uint256) public view returns (bytes32) {
        return contentHash;
    }

    // ============ Operational Methods ============

    function withdrawFunds() external Reentrancy.nonReentrant {
        // Transfer the fee to the treasury.
        // Treasury fee is paid first for efficiency, so we don't have to calculate
        // the fee and the revenue amount. Also prevents a reentrancy attack scenario that
        // avoids paying treasury.
        uint256 fee = feeAmount(address(this).balance);
        IMirrorTreasury(ITreasuryConfig(treasuryConfig).treasury())
            .contribute{value: fee}(fee);

        // Transfer the remaining available balance to the fundingRecipient.
        _sendFunds(fundingRecipient, address(this).balance);
    }

    function feeAmount(uint256 amount) public view returns (uint256) {
        return (feePercentage * amount) / 10000;
    }

    // ============ Admin Methods ============

    function changeBaseURI(string memory baseURI_) public onlyGovernance {
        baseURI = baseURI_;
    }

    // ============ Private Methods ============

    /// @notice from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Strings.sol
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

    function _sendFunds(address payable recipient, uint256 amount) private {
        require(
            address(this).balance >= amount,
            "Insufficient balance for send"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Unable to send value: recipient may have reverted");
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        if (tokenId < allocation && !_burned[tokenId]) {
            return true;
        }

        return _owners[tokenId] != address(0);
    }

    function _burn(uint256 tokenId) internal {
        address owner_ = ownerOf(tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        if (_balances[owner_] > 0) {
            _balances[owner_] -= 1;
        }
        delete _owners[tokenId];

        _burned[tokenId] = true;

        emit Transfer(owner_, address(0), tokenId);
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
        require(
            _exists(tokenId),
            "ERC721: operator query for nonexistent token"
        );
        address owner = ownerOf(tokenId);
        return (spender == owner ||
            getApproved(tokenId) == spender ||
            isApprovedForAll(owner, spender));
    }

    function _mint(address to, uint256 tokenId) internal {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

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

        if (_balances[from] > 0) {
            _balances[from] -= 1;
        }

        _owners[tokenId] = to;

        if (from == operator && tokenId < allocation) {
            allocationsTransferred += 1;
            _balances[to] += 1;
        } else if (to == operator && tokenId < allocation) {
            allocationsTransferred -= 1;
        } else {
            _balances[to] += 1;
        }

        emit Transfer(from, to, tokenId);
    }

    function _approve(address to, uint256 tokenId) internal {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (isContract(to)) {
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

    /// @notice from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/7f6a1666fac8ecff5dd467d0938069bc221ea9e0/contracts/utils/Address.sol
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
}
