// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IBootlegNFT.sol";
import "./IERC20Upgradeable.sol";
import "./IERC721Upgradeable.sol";
import "./IERC721ReceiverUpgradeable.sol";
import "./AddressUpgradeable.sol";
import "./StringsUpgradeable.sol";
import "./ContextUpgradeable.sol";
import "./ERC165Upgradeable.sol";
import "./Initializable.sol";
import "./OwnableUpgradeable.sol";

contract BootlegNFT is OwnableUpgradeable, ERC165Upgradeable, IBootlegNFT {
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;


    // Mapping owner address to token count
    mapping (address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping (uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;


    IERC20Upgradeable public bootToken;
    string public baseTokenUri;

    // Minting fees
    uint256 private _initialMintingFee;

    uint256 private _feeIncrement;

    uint256 private _feeMultiplier;

    uint256 private _feeCap;

    uint256 private _currentMintingFee;


    uint256 public numCopies; // How many times an original NFT can be copied
    uint256 public numCopiesBatch; // How many NFTs can be minted at once

    struct TokenData {
        address owner;
        address originalContract;
        uint256 originalTokenId;
        uint256 chainId;
    }

    mapping(uint256 => TokenData) private _tokens;
    uint256 private _tokenIdIndex;

    mapping(string => uint256) private _mintedTokensCounter;

    function initialize(IERC20Upgradeable bootToken_, string memory name_, string memory symbol_, string memory baseTokenUri_, uint256 numCopies_, uint256 numCopiesBatch_, uint256 initialMintingFee_, uint256 feeIncrement_, uint256 feeMultiplier_, uint256 feeCap_) public initializer {
        __BootlegNFT_init(bootToken_, name_, symbol_, baseTokenUri_, numCopies_, numCopiesBatch_, initialMintingFee_, feeIncrement_, feeMultiplier_, feeCap_);
    }

    function __BootlegNFT_init(IERC20Upgradeable bootToken_, string memory name_, string memory symbol_, string memory baseTokenUri_, uint256 numCopies_, uint256 numCopiesBatch_, uint256 initialMintingFee_, uint256 feeIncrement_, uint256 feeMultiplier_, uint256 feeCap_) internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
        __ERC165_init_unchained();
        __BootlegNFT_init_unchained(bootToken_, name_, symbol_, baseTokenUri_, numCopies_, numCopiesBatch_, initialMintingFee_, feeIncrement_, feeMultiplier_, feeCap_);
    }

    function __BootlegNFT_init_unchained(IERC20Upgradeable bootToken_, string memory name_, string memory symbol_, string memory baseTokenUri_, uint256 numCopies_, uint256 numCopiesBatch_, uint256 initialMintingFee_, uint256 feeIncrement_, uint256 feeMultiplier_, uint256 feeCap_) internal initializer {
        bootToken = bootToken_;
        _name = name_;
        _symbol = symbol_;
        baseTokenUri = baseTokenUri_;
        numCopies = numCopies_;
        numCopiesBatch = numCopiesBatch_;
        _initialMintingFee = initialMintingFee_;
        _feeIncrement = feeIncrement_;
        _feeMultiplier = feeMultiplier_;
        _feeCap = feeCap_;

        _currentMintingFee = _initialMintingFee;

    }

    /**
  * @dev See {IERC721Metadata-name}.
  */
    function name() public view override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = baseTokenUri;
        return bytes(baseURI).length > 0
        ? string(abi.encodePacked(baseURI, tokenId.toString()))
        : '';
    }


    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return interfaceId == type(IERC721Upgradeable).interfaceId
        || interfaceId == type(IERC721MetadataUpgradeable).interfaceId
        || super.supportsInterface(interfaceId);
    }

    function ownerOf(uint256 id) public view override returns (address owner) {
        TokenData memory tokenData = _tokens[id];
        require(tokenData.owner != address(0), "BootlegNFT: owner query for nonexistent token");
        return _tokens[id].owner;
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view override returns (uint256) {
        require(owner != address(0), "BootlegNFT: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IBootlegNFT-getTokenInfo}.
     */
    function getTokenInfo(uint256 tokenId) external view override returns (address owner, address originalContractAddress, uint256 originalTokenId, uint256 chainId) {
        require(_exists(tokenId), "BootlegNFT: operator query for nonexistent token");
        return (_tokens[tokenId].owner, _tokens[tokenId].originalContract, _tokens[tokenId].originalTokenId, _tokens[tokenId].chainId);
    }


    /**
     * @dev See {IBootlegNFT-getMintedCopiesAmount}.
     */
    function getMintedCopiesAmount(address originalContractAddress, uint256 originalTokenId) external view override returns (uint256 copiesMinted) {
        // Check if the token exits
        string memory uniqueTokenId = string(abi.encodePacked(originalContractAddress, originalTokenId.toString()));
        return _mintedTokensCounter[uniqueTokenId];
    }

    /**
     * @dev See {IBootlegNFT-getMintingPrice}.
     */
    function getMintingPrice() external view override returns (uint256 mintingPrice) {
        return _currentMintingFee;
    }

    /**
     * @dev Calculates new minting price, based on the `_initialMintingFee`, `_feeIncrement`, `_feeMultiplier` and `_feeCap` state variables.
     */
    function _calculateMintingPrice() internal {
        if (_currentMintingFee < _feeCap) {
            _currentMintingFee = _currentMintingFee + _feeIncrement;
            _currentMintingFee = _currentMintingFee * _feeMultiplier;
        }
    }


    /**
     * @dev See {IBootlegNFT-getInitialMintingFee}.
     */
    function getInitialMintingFee() external view override returns (uint256 initialMintingFee) {
        return _initialMintingFee;
    }


    /**
      * @dev See {IBootlegNFT-mint}.
      */
    function mint(address originalContractAddress, uint256 originalTokenId, uint256 chainId) external override returns (uint256 tokenId) {
        require(bootToken.balanceOf(msg.sender) >= _currentMintingFee, "BootlegNFT: Not enough BOOT to mint NFT.");

        // Check if the token exits
        string memory uniqueTokenId = string(abi.encodePacked(originalContractAddress, originalTokenId.toString()));

        require(_mintedTokensCounter[uniqueTokenId] < numCopies, "BootlegNFT: Token already minted maximum amount of times!");
        require(bootToken.allowance(address(msg.sender), address(this)) > _currentMintingFee);

        require(bootToken.allowance(address(msg.sender), address(this)) >= _currentMintingFee, "BootlegNFT: BOOT token transfer not allowed.");
        bool transferFromResult = bootToken.transferFrom(address(msg.sender), address(this), _currentMintingFee);
        require(transferFromResult == true, "BootlegNFT: BOOT token transfer failed");


        uint256 tokenId = _tokenIdIndex;
        TokenData storage token = _tokens[tokenId];

        token.owner = msg.sender;
        token.originalContract = originalContractAddress;
        token.originalTokenId = originalTokenId;
        token.chainId = chainId;
        _balances[msg.sender] += 1;
        _mintedTokensCounter[uniqueTokenId] += 1;

        // Recalculate the new minting price..
        _calculateMintingPrice();

        _tokenIdIndex = _tokenIdIndex + 1;


        emit Transfer(address(0), msg.sender, tokenId);
        return tokenId;
    }

    /**
      * @dev See {IBootlegNFT-mintBatch}.
      */
    function mintBatch(address[] memory originalContractAddresses, uint256[] memory originalTokenIds, uint256 chainId) external override {
        require(originalContractAddresses.length > 0, "BootlegNFT: No original contract addresses provided");
        require(originalContractAddresses.length == originalTokenIds.length, "BootlegNFT: Input parameter length mismatch");
        require(originalContractAddresses.length <= numCopiesBatch, "BootlegNFT: Cannot mint more than 'numCopiesBatch' different NFTs at once");

        uint256 totalMintingFee = _currentMintingFee * originalContractAddresses.length;

        require(bootToken.balanceOf(msg.sender) >= totalMintingFee, "BootlegNFT: Not enough BOOT to mint NFT.");

        require(bootToken.allowance(address(msg.sender), address(this)) >= _currentMintingFee, "BootlegNFT: BOOT token transfer not allowed.");
        bool transferFromResult = bootToken.transferFrom(address(msg.sender), address(this), totalMintingFee);
        require(transferFromResult == true, "BootlegNFT: BOOT token transfer failed");

        uint256 startingTokenId = _tokenIdIndex;
        for(uint256 i  = 0; i < originalContractAddresses.length; i++) {

            // Check if the token exits
            string memory uniqueTokenId = string(abi.encodePacked(originalContractAddresses[i], originalTokenIds[i].toString()));

            require(_mintedTokensCounter[uniqueTokenId] < numCopies, "BootlegNFT: Token already minted maximum amount of times!");

            uint256 tokenId = _tokenIdIndex;
            TokenData storage token = _tokens[tokenId];

            token.owner = msg.sender;
            token.originalContract = originalContractAddresses[i];
            token.originalTokenId = originalTokenIds[i];
            token.chainId = chainId;
            _balances[msg.sender] += 1;
            _mintedTokensCounter[uniqueTokenId] += 1;

            _tokenIdIndex = _tokenIdIndex + 1;

        }
        // Recalculate the new minting price..
        _calculateMintingPrice();

        emit ConsecutiveTransfer(startingTokenId, _tokenIdIndex - 1, address(0), msg.sender);
    }



    /**
    * @dev See {IERC721-approve}.
    */
    function approve(address to, uint256 tokenId) public override {
        address owner = BootlegNFT.ownerOf(tokenId);
        require(to != owner, "BootlegNFT: approval to current owner");

        require(_msgSender() == owner || BootlegNFT.isApprovedForAll(owner, _msgSender()),
            "BootlegNFT: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view override returns (address) {
        require(_exists(tokenId), "BootlegNFT: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "BootlegNFT: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "BootlegNFT: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "BootlegNFT: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "BootlegNFT: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _tokens[tokenId].owner != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        require(_exists(tokenId), "BootlegNFT: operator query for nonexistent token");
        address owner = BootlegNFT.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || BootlegNFT.isApprovedForAll(owner, spender));
    }


    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(address from, address to, uint256 tokenId) internal {
        require(BootlegNFT.ownerOf(tokenId) == from, "BootlegNFT: transfer of token that is not own");
        require(to != address(0), "BootlegNFT: transfer to the zero address");

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _tokens[tokenId].owner = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(BootlegNFT.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
    private returns (bool)
    {
        if (to.isContract()) {
            try IERC721ReceiverUpgradeable(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721ReceiverUpgradeable(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("BootlegNFT: transfer to non ERC721Receiver implementer");
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


    /**
     * @dev Withdraw the boot tokens accumulated from sales.
     */
    function withdrawBootTokens() external onlyOwner {
        bootToken.transfer(payable(owner()), bootToken.balanceOf(payable(address(this))));
    }

    // 17 storage slots used
    uint256[33] private __gap;
}
