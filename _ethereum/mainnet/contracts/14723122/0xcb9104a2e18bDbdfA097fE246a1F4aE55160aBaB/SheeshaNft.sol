//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ISheeshaToken.sol";
import "./ISheeshaRetroSHVault.sol";
import "./ISheeshaRetroLPVault.sol";

import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./Context.sol";
import "./Counters.sol";
import "./draft-EIP712.sol";
import "./SignatureChecker.sol";

contract SheeshaNft is
    Context,
    Ownable,
    EIP712,
    ERC721Enumerable {
    using Counters for Counters.Counter;

    string public constant NAME = "Sheesha NFT 1";
    string public constant SYMBOL = "SNFT1";
    bytes32 public constant MINT_ENCODED_TYPE = 0x9fbaf603dd43becf4c85ea2a23c81877f448d8bcc46919c69630f38fa36b445b;

    Counters.Counter private _tokenIdTracker;
    string private _uri;
    ISheeshaToken private _sheesha;
    ISheeshaRetroSHVault private _shvault;
    ISheeshaRetroLPVault private _lpvault;
    address private _signer;
    mapping(address => bool) public minters;

    event Blocked(address, address);
    event Unblocked(address, address);
    event SetUri(address, string);
    event SetSigner(address, address);

    constructor(
        string memory uri_,
        address shvault_,
        address lpvault_,
        address signer_) 
        ERC721(NAME, SYMBOL) EIP712(NAME, "1") {
        _shvault = ISheeshaRetroSHVault(shvault_);
        _lpvault = ISheeshaRetroLPVault(lpvault_);
        _sheesha = ISheeshaToken(_shvault.sheesha());
        setUri(uri_);
        setSigner(signer_);
    }

    function setUri(string memory uri_) public onlyOwner {
        _uri = uri_;
        emit SetUri(_msgSender(), uri_);
    }

    function setSigner(address signer_) public onlyOwner {
        _signer = signer_;
        emit SetSigner(_msgSender(), signer_);
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "SNFT: URI query for nonexistent token");
        return _uri;
    }

    /**
     * @dev Safely mints token `type` and transfers it to `to`.
     *
     * Emits a {Transfer} event.
     */
    function mint(address to, uint256 deadline, bytes memory signature) external {
        require(deadline > block.timestamp, "SNFT: missed deadline");
        bytes32 hash = _hashTypedDataV4(keccak256(abi.encode(MINT_ENCODED_TYPE, to, deadline)));
        require(SignatureChecker.isValidSignatureNow(_signer, hash, signature), "SNFT: invalid signature");
        _mint(to);
    }

    function _mint(address to) internal virtual {
        require(!minters[to], "SNFT: already minted");
        require(_sheesha.isUserExisting(to) &&
            (_stakedSHOf(to) > 0 || _stakedLPOf(to) > 0),
            "SNFT: not alowed");
        minters[to] = true;
        uint256 tokenId = _tokenIdTracker.current();
        _tokenIdTracker.increment();
        _safeMint(to, tokenId);
    }

    /**
     * @dev Check if can user mint.
     * @param to Address to mint
     */
    function canMint(address to) public view returns (bool) {
        return !minters[to] &&
            _sheesha.isUserExisting(to) &&
            (_stakedSHOf(to) > 0 || _stakedLPOf(to) > 0);
    }

    function _stakedSHOf(address member) internal view returns (uint256 stakeOf_) {
        (stakeOf_,) = _shvault.userInfo(0, member);
    }

    function _stakedLPOf(address member) internal view returns (uint256 stakeOf_) {
        (stakeOf_,,,) = _lpvault.userInfo(0, member);
    }
}