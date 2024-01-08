// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import "./IERC721.sol";
import "./IERC2309.sol";
import "./ITreasuryConfig.sol";
import "./IMirrorTreasury.sol";
import "./InitializedGovernable.sol";
import "./Pausable.sol";
import "./Reentrancy.sol";
import "./DroppableEditionsStorage.sol";
import "./IDroppableEditionsLogic.sol";
import "./IProxyRegistry.sol";

/**
 * @title DroppableEditionsLogic
 * @author MirrorXYZ
 */
contract DroppableEditionsLogic is 
    DroppableEditionsStorage,
    InitializedGovernable,
    Pausable,
    IDroppableEditionsLogicEvents,
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

    constructor(
        address owner_,
        address governor_,
        address proxyRegistry_
    ) InitializedGovernable(owner_, governor_) Pausable(true) {
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
        require(!purchased[recipient], "already purchased");
        // Check that enough funds have been sent to purchase an edition.
        require(msg.value >= price, "insufficient funds");
        // Track and update token id.
        tokenId = allocation + nonAllocatedPurchases;
        // Check that there are still tokens available to purchase.
        require(tokenId < quantity, "sold out");
        // Mint a new token for the sender, using the `tokenId`.
        purchased[recipient] = true;
        _mint(recipient, tokenId);
        emit EditionPurchased(tokenId, msg.value, msg.sender, recipient);

        nonAllocatedPurchases += 1;
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
        require(
            owner_ != address(0),
            "zero address"
        );

        return _balances[owner_];
    }

    function burn(uint256 tokenId) public {
        require(
            _isApprovedOrOwner(msg.sender, tokenId),
            "not approved"
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
            "not approved"
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
            "not approved"
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
        require(to != owner, "current owner");

        require(
            msg.sender == owner || isApprovedForAll(owner, msg.sender),
            "not approved"
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
            "nonexistent"
        );

        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address approver, bool approved)
        public
        override
    {
        require(approver != msg.sender, "approve to caller");

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

    // ============ Drop Distribution Methods ============

    function purchaseWithProof(
        address account,
        uint256 allocation,
        uint256 price,
        uint256 index,
        bytes32[] calldata merkleProof
    ) external payable {
        require(price * allocation <= msg.value, "insufficient funds");

        require(
            !isClaimed(index, account),
            "already claimed"
        );

        setClaimed(index, account);

        require(
            verifyProof(
                merkleProof,
                merkleRoot,
                getNode(index, price, account, allocation)
            ),
            "invalid proof"
        );

        // "MINT"
        indexToClaimer[currentIndexId] = account;
        currentIndexId += 1;
        claimerToAllocation[account] = allocation;
        claimedTokens += allocation;
        _balances[account] += allocation;

        emit ConsecutiveTransfer(
            nextTokenId,
            nextTokenId + allocation - 1,
            address(0),
            account
        );

        nextTokenId += allocation;
    }

    function ownerOf(uint256 tokenId)
        public
        view
        override
        returns (address owner)
    {
        
        // Check if we are referring to a token that was preallocated.
        if (tokenId < allocation) {
            // It may have not been claimed.
            require(tokenId < claimedTokens, "nonexistent");

            // Check if this token was allocated but then burned.
            require(!burned[tokenId], "nonexistent");

            // Check if this token was allocated and then transferred.
            if (_owners[tokenId] != address(0)) {
                // The token was allocated, but then transferred.
                return _owners[tokenId];
            }
            
            // The token has been claimed and not transferred!
            // We need to find the claimer from this tokenId.
            uint256 indexTracker;
            for (uint256 i = 0; i < currentIndexId; i++) {
                address claimer = indexToClaimer[i];
                indexTracker += claimerToAllocation[claimer];
                if (tokenId < indexTracker) {
                    return claimer;
                }
            }
        }
        
        owner = _owners[tokenId];

        require(owner != address(0), "nonexistent");
    }


    function isClaimed(uint256 index, address account)
        public
        view
        returns (bool)
    {
        return claimed[getClaimHash(index, account)];
    }

    function setClaimed(uint256 index, address account) private {
        claimed[getClaimHash(index, account)] = true;
    }

    function getClaimHash(uint256 index, address account)
        private
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(index, account));
    }

    function getNode(uint256 index, uint256 price, address account, uint256 allocation)
        private
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(account, allocation, price, index));
    }

    // From https://github.com/protofire/zeppelin-solidity/blob/master/contracts/MerkleProof.sol
    function verifyProof(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) private pure returns (bool) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(
                    abi.encodePacked(computedHash, proofElement)
                );
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(
                    abi.encodePacked(proofElement, computedHash)
                );
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
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
            "insufficient balance"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "recipient reverted");
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

    /**
     * @dev Base URI for computing {tokenURI}. Empty by default, can be overriden
     * in child contracts.
     */
    function _baseURI() internal pure returns (string memory) {
        return "";
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
            "non ERC721Receiver"
        );
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        returns (bool)
    {
        require(
            _exists(tokenId),
            "nonexistent"
        );
        address owner = ownerOf(tokenId);
        return (spender == owner ||
            getApproved(tokenId) == spender ||
            isApprovedForAll(owner, spender));
    }

    function _mint(address to, uint256 tokenId) internal {
        require(to != address(0), "zero address");
        require(!_exists(tokenId), "already minted");

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
            "token not owned"
        );
        require(
            to != address(0),
            "zero address"
        );

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        if (_balances[from] > 0) {
            _balances[from] -= 1;
        }

        _owners[tokenId] = to;
        _balances[to] += 1;

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
                        "non ERC721Receiver"
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