// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "./Ownable.sol";
import "./ERC1155P.sol";

contract ZokioVerseSBT is ERC1155P, Ownable {
    error ExceedMaxPerWallet();
    error WrongValueSent();
    error FailedToWithdraw();
    error NotLive();
    error ExceedMaxSupply();
    error CannotApprove();
    error CannotTransfer();

    event Soulbound(uint256 indexed id, bool bounded);

    /// @notice Token id
    uint256 public constant ZOKIO_SBT_ID = 1;

    /// @notice Token base uri
    string internal _uri;

    /// @notice Mint start time
    uint256 public startsAt = 1703116800;

    /// @notice Mint end time
    uint256 public endsAt = 1703203200;

    /// @notice Max mints per wallet
    uint256 public maxPerWallet = 5;

    /// @notice Token unit price
    uint256 public price = 0.04 ether;

    /// @notice Max supply of token
    uint256 public maxSupply = 1000;

    /// @notice Total minted supply of token
    uint256 public totalMinted = 0;

    /// @notice Total burned tokens
    uint256 public numBurned = 0;

    /// @notice Soulbound token associations
    mapping(uint256 => bool) private soulbounds;

    constructor(string memory zokioUri) ERC1155P() {
        _initializeOwner(msg.sender);
        _uri = zokioUri;
        setSoulbound(ZOKIO_SBT_ID, true);
    }

    /// @dev Returns the name of the token.
    function name() public view virtual override returns(string memory){
        return "ZokioVerseSBT";
    }

    /// @dev Returns the symbol of the token.
    function symbol() public view virtual override returns(string memory){
        return "ZKSBT";
    }

    /**
    * @notice Public mint
    * @param amount The amount of nfs to send
    */
    function mint(uint256 amount) external payable {
        if (block.timestamp < startsAt || block.timestamp > endsAt) revert NotLive();
        if (amount + _numberMinted(msg.sender, ZOKIO_SBT_ID) > maxPerWallet) revert ExceedMaxPerWallet();
        if (msg.value != price * amount) revert WrongValueSent();
        if (amount + totalMinted > maxSupply) revert ExceedMaxSupply();
        totalMinted += amount;
        _mint(msg.sender, ZOKIO_SBT_ID, amount, "");
    }

    /**
    * @notice Burn token
    * @param amount The amount of nfs to burn
    */
    function burn(uint256 amount) external payable {
        numBurned += amount;
        _burn(msg.sender, ZOKIO_SBT_ID, amount);
    }

    /**
    * @dev This just ignores the token id
    * @notice Returns the total supply of a token id
    * @param tokenId The token id to consider for supply
    */
    function totalSupply(uint256 tokenId) external view returns (uint256) {
        return totalMinted - numBurned;
    }

    /**
    * @notice Owner mint
    * @param to Address to send to
    * @param amount The amount of nfs to send
    */
    function ownerMint(address to, uint256 amount) external onlyOwner {
        if (amount + totalMinted > maxSupply) revert ExceedMaxSupply();
        totalMinted += amount;
        _mint(to, ZOKIO_SBT_ID, amount, "");
    }

    /// @dev Just return a single templated string
    function uri(uint256 id) public view override returns (string memory){
        return _uri;
    }

    /**
    * @notice Set new uri
    * @param uri_ A templated uri string
    */
    function setBaseUri(string calldata uri_) external onlyOwner {
        _uri = uri_;
    }

    /**
    * @notice Set a mint configuration window
    * @param _startsAt The mint start time
    * @param _endsAt The mint end time
    * @param _price The mint price
    * @param _maxSupply The mint max supply
    * @param _maxPerWallet The mint max per wallet
    */
    function setMintConfig(uint256 _startsAt, uint256 _endsAt, uint256 _price, uint256 _maxSupply, uint256 _maxPerWallet) external onlyOwner {
        startsAt = _startsAt;
        endsAt = _endsAt;
        price = _price;
        maxSupply = _maxSupply;
        maxPerWallet = _maxPerWallet;
    }

    /// @notice Withdraw the eths
    function withdraw() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        if (!success) revert FailedToWithdraw();
    }

    /// @dev Returns true if a token type `id` is soulbound.
    function isSoulbound(uint256 id) public view virtual returns (bool) {
        return soulbounds[id];
    }

    /**
    * @notice Set whether a token is soulbound or not
    * @param id The token id to bound
    * @param soulbound Is it soulbound?
    */
    function setSoulbound(uint256 id, bool soulbound) public onlyOwner {
        soulbounds[id] = soulbound;
        emit Soulbound(id, soulbound);
    }

    /// @dev Prevent any listings
    function setApprovalForAll(address operator, bool approved) public override {
        revert CannotApprove();
    }

    /// @dev Prevent transfers to addresses outside of zero addy
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, id, amount, data);
        if (isSoulbound(id) && from != address(0) && to != address(0)) {
            revert CannotTransfer();
        }
    }

    /// @dev Prevent transfers to addresses outside of zero addy
    function _beforeBatchTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeBatchTokenTransfer(operator, from, to, ids, amounts, data);
        for (uint256 i = 0; i < ids.length; ++i) {
            if (isSoulbound(ids[i]) && from != address(0) && to != address(0)) {
                revert CannotTransfer();
            }
        }
    }
}
