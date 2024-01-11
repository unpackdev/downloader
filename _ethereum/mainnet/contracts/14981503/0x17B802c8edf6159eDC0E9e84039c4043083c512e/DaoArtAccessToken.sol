// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./ERC721Enumerable.sol";
import "./IERC721Metadata.sol";
import "./AccessControl.sol";
import "./Ownable.sol";

contract DaoArtAccessToken is AccessControl, Ownable, ERC721Enumerable {
    string private contractUri;
    address payable private wallet;
    mapping(uint256 => string) public tokenUris;
    uint256 public startPrice;
    uint256 public step;
    uint256 public stepIncrease;
    uint256 public tokensSupply;
    uint256 public tokensCount = 0;

    /*
     * @dev constructor
     * @param _contractUri - new contract uri
     * @param _wallet - wallet to get payments (also get admin permission)
     * @param _startPrice - start price
     * @param _step - tokens step
     * @param _stepIncrease - step increase
     * @param _tokensSupply - total supply of tokens
    */
    constructor(
        string memory _contractUri,
        address payable _wallet,
        uint256 _startPrice,
        uint256 _step,
        uint256 _stepIncrease,
        uint256 _tokensSupply
    ) ERC721("DAO-Art.eth Access token", "DAOART") Ownable() {
        contractUri = _contractUri;
        wallet = _wallet;
        startPrice = _startPrice;
        step = _step;
        stepIncrease = _stepIncrease;
        tokensSupply = _tokensSupply;
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(DEFAULT_ADMIN_ROLE, _wallet);
        _transferOwnership(_wallet);
    }

    /*
     * @dev Set wallet to get payments (also get admin permission)
    */
    function setWallet(address payable _wallet) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setWallet(_wallet);
    }

    /// @dev for Ownable compatability
    function transferOwnership(address newOwner) public virtual override onlyRole(DEFAULT_ADMIN_ROLE) {
        _setWallet(payable(newOwner));
    }

    /// @dev for Ownable compatability
    function renounceOwnership() public virtual override onlyRole(DEFAULT_ADMIN_ROLE) {
        revokeRole(DEFAULT_ADMIN_ROLE, wallet);
        _transferOwnership(address(0));
        wallet = payable(address(0));
    }

    /*
     * @dev Set token price params
     * @param _startPrice - start price
     * @param _step - tokens step
     * @param _stepIncrease - step increase
     * @param _tokensSupply - total supply of tokens
    */
    function setTokenParams(
        uint256 _startPrice,
        uint256 _step,
        uint256 _stepIncrease,
        uint256 _tokensSupply
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        startPrice = _startPrice;
        step = _step;
        stepIncrease = _stepIncrease;
        tokensSupply = _tokensSupply;
    }

    /**
     * @dev Change contract metadata uri.
     *
     * @param _contractUri - new contract uri
    */
    function setContractUri(string memory _contractUri) external onlyRole(DEFAULT_ADMIN_ROLE) {
        contractUri = _contractUri;
    }

    /*
     * @dev Buy dao art access token
     *
     * @param id - id of token to mint (must equal to tokensCount)
     * @param metaUri - uri to token metadata
    */
    function buyToken(uint256 id, string memory metaUri) external payable {
        require(wallet != address(0), "DaoArtToken: sale stopped");
        require(balanceOf(_msgSender()) == 0, "DaoArtToken: token already owned for this address");
        require(id == tokensCount, "DaoArtToken: wrong new token id");
        require(id < tokensSupply, "DaoArtToken: all tokens sold");
        uint256 resultPrice = startPrice + stepIncrease * (tokensCount / step);
        require(msg.value == resultPrice, "DaoArtToken: wrong transaction value");
        require(wallet.send(resultPrice), "DaoArtToken: transfer wei failed");

        tokenUris[id] = metaUri;
        _safeMint(_msgSender(), id);
        tokensCount++;
    }

    /// @dev get all token params with one method
    function getTokenParams() external view returns (
        uint256 _startPrice,
        uint256 _step,
        uint256 _stepValue,
        uint256 _totalSupply,
        uint256 _currentSupply
    ) {
        return (startPrice, step, stepIncrease, tokensSupply, tokensCount);
    }

    /// @dev supports interface for inheritance conflict resolving.
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721Enumerable, AccessControl) returns (bool) {
        return ERC721Enumerable.supportsInterface(interfaceId) ||
        AccessControl.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return tokenUris[tokenId];
    }

    /**
     * @dev Contract metadata URI for OpenSea integration
    */
    function contractURI() public view returns (string memory) {
        return contractUri;
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address,
        address,
        uint256
    ) public virtual override {
        revert("DaoArtToken: transfer not allowed");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address,
        address,
        uint256
    ) public virtual override {
        revert("DaoArtToken: transfer not allowed");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override {
        revert("DaoArtToken: transfer not allowed");
    }

    /*
     * @dev Set wallet to get payments (also get admin permission)
    */
    function _setWallet(address payable _wallet) internal {
        require(_wallet != address(0), "DaoArtToken: new wallet is the zero address");
        revokeRole(DEFAULT_ADMIN_ROLE, wallet);
        wallet = _wallet;
        grantRole(DEFAULT_ADMIN_ROLE, _wallet);
        _transferOwnership(_wallet);
    }
}