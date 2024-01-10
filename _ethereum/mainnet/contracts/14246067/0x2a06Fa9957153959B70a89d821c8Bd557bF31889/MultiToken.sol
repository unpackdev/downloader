// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Initializable.sol";

// the erc1155 base contract - the openzeppelin erc1155
import "./ERC1155.sol";
import "./ERC2981.sol";
import "./AddressSet.sol";
import "./UInt256Set.sol";

import "./ProxyRegistry.sol";
import "./ERC1155Owners.sol";
import "./ERC1155Owned.sol";
import "./ERC1155TotalBalance.sol";
import "./ERC1155CommonUri.sol";

import "./Controllable.sol";

import "./IMultiToken.sol";
import "./IERC1155Mint.sol";
import "./IERC1155Burn.sol";
import "./IERC1155Multinetwork.sol";
import "./IERC1155Bridge.sol";

import "./Service.sol";

import "./Strings.sol";

/**
 * @title MultiToken
 * @notice the multitoken contract. All tokens are printed on this contract. The token has all the capabilities
 * of an erc1155 contract, plus network transfer, royallty tracking and assignment and other features.
 */
contract MultiToken is
ERC1155,
ProxyRegistryManager,
ERC1155Owners,
ERC1155Owned,
ERC1155TotalBalance,
IERC1155Multinetwork,
ERC1155CommonUri,
IMultiToken,
ERC2981,
Service,
Controllable
{

    // to work with token holder and held token lists
    using AddressSet for AddressSet.Set;
    using UInt256Set for UInt256Set.Set;

    address internal masterMinter;

    function initialize(address registry) public initializer {
        _serviceRegistry = registry;
    }

    function setMasterController(address _masterMinter) public {
        require(masterMinter == address(0), "master minter must not be set");
        masterMinter = _masterMinter;
        _addController(_masterMinter);
    }

    function addDirectMinter(address directMinter) public {
        require(msg.sender == masterMinter, "only master minter can add direct minters");
        _addController(directMinter);
    }

    /// @notice only allow owner of the contract
    modifier onlyOwner() {
        require(_isController(msg.sender), "You shall not pass");
        _;
    }
    /// @notice only allow owner of the contract
    modifier onlyMinter() {
        require(_isController(msg.sender) || masterMinter == msg.sender, "You shall not pass");
        _;
    }

    /// @notice Mint a specified amount the specified token hash to the specified receiver
    /// @param recipient the address of the receiver
    /// @param tokenHash the token id to mint
    /// @param amount the amount to mint
    function mint(
        address recipient,
        uint256 tokenHash,
        uint256 amount
    ) external override onlyMinter {

        _mint(recipient, tokenHash, amount, "");

    }

    /// @notice mint tokens of specified amount to the specified address
    /// @param recipient the mint target
    /// @param tokenHash the token hash to mint
    /// @param amount the amount to mint
    function mintWithCommonUri(
        address recipient,
        uint256 tokenHash,
        uint256 amount,
        uint256 uriId
    ) external override onlyMinter {

        _mint(recipient, tokenHash, amount, "");
        _setCommonUriOf(tokenHash, uriId);

    }

    function setCommonUri(uint256 uriId, string memory value) external override onlyMinter {

        require(commonURIOwners[uriId] == address(0)
            || commonURIOwners[uriId] == msg.sender
            || _isController(msg.sender), "Only the owner can set the URI");
        _setCommonUri(uriId, value);

    }

    function setCommonUriOf(uint256 uriId, uint256 value) external override onlyMinter {

        require(commonURIOwners[uriId] == address(0)
            || commonURIOwners[uriId] == msg.sender
            || _isController(msg.sender), "Only the owner can set the URI");
        _setCommonUriOf(uriId, value);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256 tokenHash) public view virtual override returns (string memory) {

        string memory curi = _commonUriOf(tokenHash);
        string memory _uriOf = uriOf[tokenHash];

        if(bytes(_uriOf).length > 0) {
            return Strings.strConcat(_uriOf, Strings.uint2str(tokenHash));
        }
        if(bytes(curi).length > 0) {
            return Strings.strConcat(curi, Strings.uint2str(tokenHash));
        }
        return _uri;

    }

    function setUri(uint256 tokenHash, string memory value) external onlyMinter {

        require(uriOwners[tokenHash] == address(0)
            || uriOwners[tokenHash] == msg.sender
            || _isController(msg.sender), "Only the owner can set the URI");
        _setUri(tokenHash, value);

    }

    mapping(uint256 => string) internal uriOf;
    mapping(uint256 => address) internal uriOwners;
    function _setUri(uint256 tokenHash, string memory value) internal {

        uriOf[tokenHash] = value;
        uriOwners[tokenHash] = msg.sender;

    }

    /// @notice burn a specified amount of the specified token hash from the specified target
    /// @param target the address of the target
    /// @param tokenHash the token id to burn
    /// @param amount the amount to burn
    function burn(
        address target,
        uint256 tokenHash,
        uint256 amount
    ) external override onlyMinter {
        _burn(target, tokenHash, amount);
    }

    /// @notice override base functionality to check proxy registries for approvers
    /// @param _owner the owner address
    /// @param _operator the operator address
    /// @return isOperator true if the owner is an approver for the operator
    function isApprovedForAll(address _owner, address _operator)
    public
    view
    override
    returns (bool isOperator) {
        // check proxy whitelist
        bool _approved = _isApprovedForAll(_owner, _operator);
        return _approved || ERC1155.isApprovedForAll(_owner, _operator);
    }

    /// @notice See {IERC165-supportsInterface}. ERC165 implementor. identifies this contract as an ERC1155
    /// @param interfaceId the interface id to check
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, ERC2981) returns (bool) {
        return
            interfaceId == type(IERC1155Multinetwork).interfaceId ||
            interfaceId == type(IERC1155Owners).interfaceId ||
            interfaceId == type(IERC1155Owned).interfaceId ||
            interfaceId == type(IERC1155TotalBalance).interfaceId ||
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /// @notice perform a network token transfer. Transfer the specified quantity of the specified token hash to the destination address on the destination network.
    function networkTransferFrom(
        address from,
        address to,
        uint256 network,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external virtual override {

        address _bridge = IJanusRegistry(_serviceRegistry).get("MultiToken", "NetworkBridge");
        require(_bridge != address(0), "No network bridge found");

        // call the network transfer on the bridge
        IERC1155Multinetwork(_bridge).networkTransferFrom(from, to, network, id, amount, data);

    }

    /// @notice override base functionality to process token transfers so as to populate token holders and held tokens lists
    /// @param operator the operator address
    /// @param from the address of the sender
    /// @param to the address of the receiver
    /// @param ids the token ids
    /// @param amounts the token amounts
    /// @param data the data
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        // let super process this first
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
        //address royaltyPayee = _serviceRegistry.get("MultiToken", "RoyaltyPayee");

        // iterate through all ids in this transfer
        for (uint256 i = 0; i < ids.length; i++) {

            // if this is not a mint then remove the held token id from lists if
            // this is the last token if this type the sender owns
            if (from != address(0) && balanceOf(from, ids[i]) == amounts[i]) {
                // find and delete the token id from the token holders held tokens
                _owned[from].remove(ids[i]);
                _owners[ids[i]].remove(from);
            }

            // if this is not a burn and receiver does not yet own token then
            // add that account to the token for that id
            if (to != address(0) && balanceOf(to, ids[i]) == 0) {
                // insert the token id from the token holders held tokens\
                _owned[to].insert(ids[i]);
                _owners[ids[i]].insert(to);
            }

            // when a mint occurs, increment the total balance for that token id
            if (from == address(0)) {
                _totalBalances[uint256(ids[i])] =
                    _totalBalances[uint256(ids[i])] +
                    (amounts[i]);
            }
            // when a burn occurs, decrement the total balance for that token id
            if (to == address(0)) {
                _totalBalances[uint256(ids[i])] =
                    _totalBalances[uint256(ids[i])] -
                    (amounts[i]);
            }
        }
    }

    mapping(uint256 => string) internal symbolsOf;
    mapping(uint256 => string) internal namesOf;

    function symbolOf(uint256 _tokenId) external view override returns (string memory out) {
        return symbolsOf[_tokenId];
    }

    function nameOf(uint256 _tokenId) external view override returns (string memory out) {
        return namesOf[_tokenId];
    }

    function setSymbolOf(uint256 _tokenId, string memory _symbolOf) external onlyMinter {
        symbolsOf[_tokenId] = _symbolOf;
    }

    function setNameOf(uint256 _tokenId, string memory _nameOf) external onlyMinter {
        namesOf[_tokenId] = _nameOf;
    }

    function setRoyalty(uint256 tokenId, address receiver, uint256 amount) external onlyOwner {
        royaltyReceiversByHash[tokenId] = receiver;
        royaltyFeesByHash[tokenId] = amount;
    }

}
