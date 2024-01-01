// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./IERC2981.sol";
import "./Initializable.sol";
import "./Pausable.sol";

import "./ERC1155.sol";
import "./IConfig.sol";
import "./IMintable.sol";
import "./IInitializableNFT.sol";

error NotAMinter();
error NotAnOwner();
error RoyaltyTooLarge();
error NotARoyaltyReceiver();
error EmptyReceiverNonEmptyRoyalty();
error EmptyRoyaltyNonEmptyReceiver();
error NotATokenOwnerOrApproved();
error NotEnoughTokens(uint256 id);
error ExistingId(uint256 id);
error BlacklistedOperator(address operator);
error InvalidOwner();
error IdTooBig(uint256 id, uint256 totalSupply);
error ZeroID();

/// @notice Modified version of solmate's ERC1155 contracts
contract NFTMarketplaceToken is
    ERC1155,
    IMintable,
    Pausable,
    Initializable,
    IInitializableNFT
{
    address public config;
    address public owner;
    uint256 private _supply;

    // Use basis points for royalty
    uint96 constant ROYALTY_DENOMINATOR = 10000;
    string public name;

    struct RoyaltyInfo {
        address receiver;
        uint96 royalty;
    }

    mapping(uint256 => string) private _uris;
    mapping(uint256 => RoyaltyInfo) private _royalties;
    mapping(uint256 => uint256) private _supplies;

    mapping(address => bool) public isOperatorBlacklisted;
    mapping(address => bool) public noAutoApprove;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    modifier onlyMarketplace() {
        if (msg.sender != marketplace()) revert NotAMinter();

        _;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotAnOwner();

        _;
    }

    modifier correctRoyalty(address royaltyReceiver, uint96 royalty) {
        if (royaltyReceiver == address(0) && royalty != 0)
            revert EmptyReceiverNonEmptyRoyalty();
        if (royalty == 0 && royaltyReceiver != address(0))
            revert EmptyRoyaltyNonEmptyReceiver();
        if (royalty > ROYALTY_DENOMINATOR) revert RoyaltyTooLarge();
        _;
    }

    function initialize(
        address _config,
        address _owner,
        uint256 _totalSupply,
        string calldata _name
    ) external override initializer {
        config = _config;
        owner = _owner;
        _supply = _totalSupply;
        name = _name;
    }

    function transferOwnership(address _newOwner) external onlyOwner {
        if (_newOwner == address(0)) revert InvalidOwner();

        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }

    function marketplace() public view returns (address) {
        return IConfig(config).marketplace();
    }

    function isApprovedForAll(
        address account,
        address operator
    ) public view virtual override returns (bool) {
        if (isOperatorBlacklisted[operator]) return false;
        if (msg.sender == marketplace() && !noAutoApprove[account]) return true;

        return super.isApprovedForAll(account, operator);
    }

    function setApprovalForAll(
        address operator,
        bool approved
    ) public virtual override {
        if (isOperatorBlacklisted[operator] && approved == true)
            revert BlacklistedOperator(operator);
        super.setApprovalForAll(operator, approved);
    }

    function exists(uint256 id) public view override returns (bool) {
        return _supplies[id] > 0;
    }

    function totalSupply() external view returns (uint256) {
        return _supply;
    }

    function supply(uint256 id) external view returns (uint256) {
        return _supplies[id];
    }

    function mint(
        address receiver,
        uint256 id,
        uint256 editions,
        string calldata meta,
        address royaltyReceiver,
        uint96 royalty
    )
        external
        onlyMarketplace
        correctRoyalty(royaltyReceiver, royalty)
        whenNotPaused
    {
        if (exists(id)) revert ExistingId(id);
        if (id == 0) revert ZeroID();
        if ((_supply > 0) && (id > _supply)) revert IdTooBig(id, _supply);
        _royalties[id] = RoyaltyInfo(royaltyReceiver, royalty);
        _supplies[id] = editions;

        _setURI(id, meta);
        _mint(receiver, id, editions, "");
    }

    function setRoyalty(
        uint256 id,
        address receiver,
        uint96 rate
    ) external onlyOwner {
        _royalties[id] = RoyaltyInfo(receiver, rate);
    }

    function royaltyInfo(
        uint256 id,
        uint256 price
    ) public view returns (address, uint256) {
        RoyaltyInfo storage royalty = _royalties[id];

        if (royalty.receiver == address(0)) {
            return (address(0), 0);
        }

        return (
            royalty.receiver,
            (price * royalty.royalty) / ROYALTY_DENOMINATOR
        );
    }

    function uri(uint256 id) public view override returns (string memory) {
        return _uris[id];
    }

    function burn(address account, uint256 id, uint256 amount) external {
        if (msg.sender != account && !isApprovedForAll(account, msg.sender))
            revert NotATokenOwnerOrApproved();
        if (balanceOf[account][id] < amount) revert NotEnoughTokens(id);

        unchecked {
            _supplies[id] -= amount;
            balanceOf[account][id] -= amount;
        }
        emit TransferSingle(msg.sender, account, address(0), id, amount);
    }

    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts
    ) external {
        if (msg.sender != account && !isApprovedForAll(account, msg.sender))
            revert NotATokenOwnerOrApproved();

        uint256 idsLength = ids.length; // Saves MLOADs.

        if (idsLength != amounts.length) revert LengthMismatch();

        for (uint256 i = 0; i < idsLength; ) {
            if (balanceOf[account][ids[i]] < amounts[i])
                revert NotEnoughTokens(ids[i]);

            unchecked {
                _supplies[ids[i]] -= amounts[i];
                balanceOf[account][ids[i]] -= amounts[i];
                ++i;
            }
        }

        emit TransferBatch(msg.sender, account, address(0), ids, amounts);
    }

    function enableAutoApprove() external {
        delete noAutoApprove[msg.sender];
    }

    function disableAutoApprove() external {
        noAutoApprove[msg.sender] = true;
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override returns (bool) {
        return
            super.supportsInterface(interfaceId) ||
            interfaceId == type(IERC2981).interfaceId;
    }

    function _setURI(uint256 id, string calldata meta) internal {
        _uris[id] = meta;
        emit URI(meta, id);
    }

    function setBlacklistedOperator(
        address operator,
        bool status
    ) external onlyOwner {
        isOperatorBlacklisted[operator] = status;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}
