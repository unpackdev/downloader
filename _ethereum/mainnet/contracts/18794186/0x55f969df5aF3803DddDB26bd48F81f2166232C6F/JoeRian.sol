// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Ownable.sol";
import "./ERC1155.sol";
import "./ERC2981.sol";
import "./Strings.sol";

contract JoeRian is ERC1155, ERC2981, Ownable {
    using Strings for uint256;

    struct AllowedMinterData {
        address minter;
        bool isAllowed;
    }

    struct OperatorData {
        address operator;
        bool isBlacklisted;
    }

    event AllowedMintersUpdate(address indexed minter, bool indexed isAllowed);
    event OperatorBlacklistUpdate(address indexed operator, bool indexed isBlacklisted);

    error MinterNotAllowed();
    error OperatorNotAllowed();

    string private metadataUriPrefix;

    mapping(address => bool) public allowedMinters;
    mapping(address => bool) public operatorBlacklist;

    constructor(string memory _uriPrefix) ERC1155(_uriPrefix) Ownable(msg.sender) {
        _setDefaultRoyalty(msg.sender, 1000);
    }

    function mint(address _to, uint256 _id, uint256 _value, bytes memory _data) external {
        if (!allowedMinters[msg.sender]) {
            revert MinterNotAllowed();
        }

        // Mint NFTs
        _mint(_to, _id, _value, _data);
    }

    function uri(uint256 _id) public view virtual override returns (string memory) {
        return string.concat(super.uri(0), _id.toString(), '.json');
    }

    // =============================================================
    // Operator Blacklist
    // =============================================================

    function setApprovalForAll(address _operator, bool _approved) public virtual override {
        if (operatorBlacklist[_operator]) {
            revert OperatorNotAllowed();
        }

        super.setApprovalForAll(_operator, _approved);
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _id,
        uint256 _amount,
        bytes memory _data
    ) public virtual override {
        // Token owners will always be allowed to transfer
        if (msg.sender != _from && operatorBlacklist[msg.sender]) {
            revert OperatorNotAllowed();
        }

        super.safeTransferFrom(_from, _to, _id, _amount, _data);
    }

    function safeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] memory _ids,
        uint256[] memory _amounts,
        bytes memory _data
    ) public virtual override {
        // Token owners will always be allowed to transfer
        if (msg.sender != _from && operatorBlacklist[msg.sender]) {
            revert OperatorNotAllowed();
        }

        super.safeBatchTransferFrom(_from, _to, _ids, _amounts, _data);
    }

    // =============================================================
    // Maintenance Operations
    // =============================================================

    function setUriPrefix(string memory _uriPrefix) external onlyOwner {
        _setURI(_uriPrefix);
    }

    function setDefaultRoyalty(address _receiver, uint96 _feeNumerator) external onlyOwner {
        _setDefaultRoyalty(_receiver, _feeNumerator);
    }

    function updateAllowedMinters(AllowedMinterData[] memory _allowedMintersData) public onlyOwner {
        uint256 i = 0;
        for (;;) {
            allowedMinters[_allowedMintersData[i].minter] = _allowedMintersData[i].isAllowed;

            emit AllowedMintersUpdate(_allowedMintersData[i].minter, _allowedMintersData[i].isAllowed);

            if (_allowedMintersData.length == ++i) break;
        }
    }

    function updateOperatorBlacklist(OperatorData[] memory _operatorData) public onlyOwner {
        uint256 i = 0;
        for (;;) {
            operatorBlacklist[_operatorData[i].operator] = _operatorData[i].isBlacklisted;

            emit OperatorBlacklistUpdate(_operatorData[i].operator, _operatorData[i].isBlacklisted);

            if (_operatorData.length == ++i) break;
        }
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view override(ERC1155, ERC2981) returns (bool) {
        return ERC1155.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }
}
