// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Initializable.sol";
import "./Context.sol";
import "./AddressUpgradeable.sol";
import "./IERC755.sol";
import "./IERC755Receiver.sol";

abstract contract ERC755 is IERC755, Context, Initializable {
    using AddressUpgradeable for address;

    uint256 internal _tokenId;

    string private _name;
    string private _symbol;
    mapping (uint256 => string) private _tokenURIs;

    mapping (address => mapping(uint256 => address)) private _tokenApprovals;
    mapping (address => mapping(address => bool)) private _operatorApprovals;

    mapping (uint256 => uint256[]) internal _tokenEditions;
    mapping (uint256 => uint256) internal _tokenSupply;

    mapping (uint256 => Structs.Policy[]) internal _rightsByToken;

    function __ERC755_init(string memory tokenName, string memory tokenSymbol) internal {
        _name = tokenName;
        _symbol = tokenSymbol;
    }

    function name() external view override returns (string memory) {
        return _name;
    }

    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    function supportsInterface(bytes4 interfaceId) external pure override returns (bool) {
        return interfaceId == type(IERC755).interfaceId;
    }

    function tokenURI(uint256 tokenId) external view override returns (string memory) {
        require(_exists(tokenId));

        return _tokenURIs[tokenId];
    }

    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId));
        _tokenURIs[tokenId] = _tokenURI;
    }

    function _haveTokenRights(address owner, uint256 tokenId) internal view returns (bool) {
        for (uint256 i = 0; i < _rightsByToken[tokenId].length; i++) {
            if (_rightsByToken[tokenId][i].permission.wallet == owner) {
                return true;
            }
        }
        return false;
    }

    function approve(
        address to,
        uint256 tokenId
    ) external override payable {
        require(
            _exists(tokenId),
            "no token to approve"
        );
        require(
            _haveTokenRights(_msgSender(), tokenId),
            "no rights to approve"
        );

        _approve(_msgSender(), to, tokenId);
    }

    function _approve(
        address from,
        address to,
        uint256 tokenId
    ) internal {
        _tokenApprovals[from][tokenId] = to;
        emit Approval(from, to, tokenId);
    }

    function getApproved(
        address from,
        uint256 tokenId
    ) public view override returns (address operator) {
        require(_exists(tokenId), "token does not exist");

        return _tokenApprovals[from][tokenId];
    }

    function setApprovalForAll(address operator, bool approved) external override {
        _setApprovalForAll(_msgSender(), operator, approved);
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    function _setApprovalForAll(address owner, address operator, bool approved) internal {
        _operatorApprovals[owner][operator] = approved;
    }

    function isApprovedForAll(
        address owner,
        address operator
    ) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        return tokenId > 0 && tokenId <= _tokenId;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        Structs.Policy[] memory policies
    ) internal virtual {}

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        Structs.Policy[] memory policies,
        bytes memory data
    ) external override payable {
        require(_exists(tokenId), "token does not exist");
        require(policies.length > 0, "no rights to transfer");
        require(
            _haveTokenRights(from, tokenId),
            "from has no rights to transfer"
        );
        require(
            from != to,
            "can't transfer to self"
        );
        if (_msgSender() != from) {
            require(
                getApproved(from, tokenId) == _msgSender() ||
                isApprovedForAll(from, _msgSender()),
                "msg sender is not approved nor operator"
            );
        }

        _beforeTokenTransfer(from, to, tokenId, policies);

        for (uint256 i = 0; i < policies.length; i++) {
            require(
                policies[i].permission.wallet == from,
                "right is not owned"
            );

            bool foundTransferRight = false;
            for (uint256 j = 0; j < _rightsByToken[tokenId].length; j++) {
                if (
                    compareStrings(_rightsByToken[tokenId][j].action, policies[i].action) &&
                    _rightsByToken[tokenId][j].permission.wallet == from
                ) {
                    policies[i].target = tokenId;
                    policies[i].permission.role = "ROLE_OWNER";
                    policies[i].permission.wallet = to;
                    _rightsByToken[tokenId][j] = policies[i];
                    foundTransferRight = true;
                }
            }
            require(foundTransferRight, "transfer right is not owned");
        }

        emit Transfer(
            from,
            to,
            tokenId,
            policies,
            block.timestamp
        );
        _afterTokenTransfer(from, to, tokenId, policies);

        if (!_haveTokenRights(from, tokenId)) {
            _tokenApprovals[from][tokenId] = address(0);
        }

        _checkOnERC755Received(from, to, tokenId, policies, data);
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        Structs.Policy[] memory policies
    ) internal virtual {}

    function editions(uint256 tokenId) external override view returns (uint256[] memory) {
        require(_exists(tokenId), "token does not exist");

        return _tokenEditions[tokenId];
    }

    function totalSupply() external override view returns (uint256) {
        return _tokenId;
    }

    function tokenSupply(uint256 tokenId) external override view returns (uint256) {
        require(_exists(tokenId), "token does not exist");

        return _tokenSupply[tokenId];
    }

    function rights(uint256 tokenId) external override view returns (Structs.Policy[] memory) {
        require(_exists(tokenId), "token does not exist");

        return _rightsByToken[tokenId];
    }

    function _checkOnERC755Received(
        address from,
        address to,
        uint256 tokenId,
        Structs.Policy[] memory policies,
        bytes memory _data
    ) private {
        if (to.isContract()) {
            require(
                IERC755Receiver(to).onERC755Received(
                    _msgSender(),
                    from,
                    tokenId,
                    policies,
                    _data
                ) == IERC755Receiver(to).onERC755Received.selector,
                    "receiver is not a IERC755Receiver"
            );
        }
    }

    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
}