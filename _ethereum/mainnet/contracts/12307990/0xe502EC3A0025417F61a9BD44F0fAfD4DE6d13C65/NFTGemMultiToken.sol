// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import "./Strings.sol";
import "./SafeMath.sol";
import "./ERC1155Pausable.sol";
import "./ERC1155Holder.sol";
import "./Controllable.sol";
import "./INFTGemMultiToken.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract NFTGemMultiToken is ERC1155Pausable, ERC1155Holder, INFTGemMultiToken, Controllable {
    using SafeMath for uint256;
    using Strings for string;

    // allows opensea to
    address private constant OPENSEA_REGISTRY_ADDRESS = 0xa5409ec958C83C3f309868babACA7c86DCB077c1;
    address[] private proxyRegistries;
    address private registryManager;

    mapping(uint256 => uint256) private _totalBalances;
    mapping(address => mapping(uint256 => uint256)) private _tokenLocks;

    mapping(address => uint256[]) private _heldTokens;
    mapping(uint256 => address[]) private _tokenHolders;

    /**
     * @dev Contract initializer.
     */
    constructor() ERC1155("https://metadata.bitgem.co/") {
        _addController(msg.sender);
        registryManager = msg.sender;
        proxyRegistries.push(OPENSEA_REGISTRY_ADDRESS);
    }

    function lock(uint256 token, uint256 timestamp) external override {
        require(_tokenLocks[_msgSender()][token] < timestamp, "ALREADY_LOCKED");
        _tokenLocks[_msgSender()][timestamp] = timestamp;
    }

    function unlockTime(address account, uint256 token) external view override returns (uint256 theTime) {
        theTime = _tokenLocks[account][token];
    }

    /**
     * @dev Returns the metadata URI for this token type
     */
    function uri(uint256 _id) public view override(ERC1155) returns (string memory) {
        require(_totalBalances[_id] != 0, "NFTGemMultiToken#uri: NONEXISTENT_TOKEN");
        return Strings.strConcat(ERC1155Pausable(this).uri(_id), Strings.uint2str(_id));
    }

    /**
     * @dev Returns the total balance minted of this type
     */
    function allHeldTokens(address holder, uint256 _idx) external view override returns (uint256) {
        return _heldTokens[holder][_idx];
    }

    /**
     * @dev Returns the total balance minted of this type
     */
    function allHeldTokensLength(address holder) external view override returns (uint256) {
        return _heldTokens[holder].length;
    }

    /**
     * @dev Returns the total balance minted of this type
     */
    function allTokenHolders(uint256 _token, uint256 _idx) external view override returns (address) {
        return _tokenHolders[_token][_idx];
    }

    /**
     * @dev Returns the total balance minted of this type
     */
    function allTokenHoldersLength(uint256 _token) external view override returns (uint256) {
        return _tokenHolders[_token].length;
    }

    /**
     * @dev Returns the total balance minted of this type
     */
    function totalBalances(uint256 _id) external view override returns (uint256) {
        return _totalBalances[_id];
    }

    /**
     * @dev Returns the total balance minted of this type
     */
    function allProxyRegistries(uint256 _idx) external view override returns (address) {
        return proxyRegistries[_idx];
    }

    /**
     * @dev Returns the total balance minted of this type
     */
    function getRegistryManager() external view override returns (address) {
        return registryManager;
    }

    /**
     * @dev Returns the total balance minted of this type
     */
    function setRegistryManager(address newManager) external override {
        require(msg.sender == registryManager, "UNAUTHORIZED");
        require(newManager != address(0), "UNAUTHORIZED");
        registryManager = newManager;
    }

    /**
     * @dev Returns the total balance minted of this type
     */
    function allProxyRegistriesLength() external view override returns (uint256) {
        return proxyRegistries.length;
    }

    /**
     * @dev Returns the total balance minted of this type
     */
    function addProxyRegistry(address registry) external override {
        require(msg.sender == registryManager, "UNAUTHORIZED");
        proxyRegistries.push(registry);
    }

    /**
     * @dev Returns the total balance minted of this type
     */
    function removeProxyRegistryAt(uint256 index) external override {
        require(msg.sender == registryManager, "UNAUTHORIZED");
        require(index < proxyRegistries.length, "INVALID_INDEX");
        proxyRegistries[index] = proxyRegistries[proxyRegistries.length - 1];
        delete proxyRegistries[proxyRegistries.length - 1];
    }

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-free listings.
     */
    function isApprovedForAll(address _owner, address _operator) public view override returns (bool isOperator) {
        // Whitelist OpenSea proxy contract for easy trading.
        for(uint256 i = 0; i < proxyRegistries.length; i++) {
            ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistries[i]);
            if (address(proxyRegistry.proxies(_owner)) == _operator) {
                return true;
            }
        }
        return ERC1155.isApprovedForAll(_owner, _operator);
    }

    /**
     * @dev mint some amount of tokens. Only callable by token owner
     */
    function mint(
        address account,
        uint256 tokenHash,
        uint256 amount
    ) external override onlyController {
        _mint(account, uint256(tokenHash), amount, "0x0");
    }

    /**
     * @dev internal mint overridden to manage token holders and held tokens lists
     */
    function _mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual override {
        super._mint(account, id, amount, data);
    }

    /**
     * @dev internal minttbatch should account for managing lists
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._mintBatch(to, ids, amounts, data);
    }

    /**
     * @dev mint some amount of tokens. Only callable by token owner
     */
    function burn(
        address account,
        uint256 tokenHash,
        uint256 amount
    ) external override onlyController {
        _burn(account, uint256(tokenHash), amount);
    }

    /**
     * @dev internal burn overridden to track lists
     */
    function _burn(
        address account,
        uint256 id,
        uint256 amount
    ) internal virtual override {
        super._burn(account, id, amount);
    }

    /**
     * @dev internal burnBatch should account for managing lists
     */
    function _burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual override {
        super._burnBatch(account, ids, amounts);
    }

    /**
     * @dev intercepting token transfers to manage a list of zero-token holders
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            // prevent send if tokens are locked
            if (from != address(0)) {
                require(_tokenLocks[from][ids[i]] <= block.timestamp, "TOKEN_LOCKED");
            }

            // if this is not a mint then remove the held token id from lists if
            // this is the last token if this type the sender owns
            if (from != address(0) && balanceOf(from, ids[i]) - amounts[i] == 0) {
                // remove from heldTokens
                for (uint256 j = 0; j < _heldTokens[from].length; j++) {
                    if (_heldTokens[from][j] == ids[i]) {
                        _heldTokens[from][j] = _heldTokens[from][_heldTokens[from].length - 1];
                        delete _heldTokens[from][_heldTokens[from].length - 1];
                    }
                }
                // remove from tokenHolders
                for (uint256 j = 0; j < _tokenHolders[ids[i]].length; j++) {
                    if (_tokenHolders[ids[i]][j] == from) {
                        _tokenHolders[ids[i]][j] = _tokenHolders[ids[i]][_tokenHolders[ids[i]].length - 1];
                        delete _tokenHolders[ids[i]][_tokenHolders[ids[i]].length - 1];
                    }
                }
            }

            // if this is not a burn and receiver does not yet own token then
            // add that account to the token for that id
            if (to != address(0) && balanceOf(to, ids[i]) == 0) {
                _heldTokens[to].push(ids[i]);
                _tokenHolders[ids[i]].push(to);
            }

            // inc and dec balances for each token type
            if (from == address(0)) {
                _totalBalances[uint256(ids[i])] = _totalBalances[uint256(ids[i])].add(amounts[i]);
            }
            if (to == address(0)) {
                _totalBalances[uint256(ids[i])] = _totalBalances[uint256(ids[i])].sub(amounts[i]);
            }
        }
    }
}
