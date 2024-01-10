// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.2;

import "./ERC1155.sol";
import "./AccessControlEnumerable.sol";
import "./Pausable.sol";
import "./ERC1155Burnable.sol";
import "./Ownable.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract RacerKey is
    ERC1155,
    AccessControlEnumerable,
    Pausable,
    ERC1155Burnable,
    Ownable
{
    bytes32 public constant URI_SETTER_ROLE = keccak256("URI_SETTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant REDEEMER_ROLE = keccak256("REDEEMER_ROLE");
    bytes32 public constant SELLER_ROLE = keccak256("SELLER_ROLE");

    uint256 public constant KEY = 1;

    address public sellerAddress;
    address[] private _keyholders;
    mapping(address => bool) public wasKeyHolder;
    mapping(address => uint256) public wantsRedemption;
    mapping(address => uint256) public redeemedKeys;

    address proxyRegistryAddress;

    constructor(address _proxyRegistryAddress)
        ERC1155("ipfs://QmXXRBJ285gvMrhwnJCHysdDLKtnUZKPVJHqJhxtaHLiEJ")
    {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        proxyRegistryAddress = _proxyRegistryAddress;
    }

    // Admin
    function resetWantsRedemption(address redeemer)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        wantsRedemption[redeemer] = 0;
    }

    // URI Setter
    function setURI(string memory newuri) public onlyRole(URI_SETTER_ROLE) {
        _setURI(newuri);
    }

    // Pauser
    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    // Minter
    function mintKeys(address account, uint256 amount)
        public
        onlyRole(MINTER_ROLE)
    {
        _mint(account, KEY, amount, "");
    }

    // Redeemer
    function getAllKeyholders()
        public
        view
        onlyRole(REDEEMER_ROLE)
        returns (address[] memory)
    {
        return _keyholders;
    }

    function getRedeemableKeyholders()
        public
        view
        onlyRole(REDEEMER_ROLE)
        returns (address[] memory, uint256[] memory)
    {
        uint256 length = 0;
        for (uint256 i = 0; i < _keyholders.length; i++) {
            uint256 bal = balanceOf(_keyholders[i], KEY);
            if (bal > 0 && wantsRedemption[_keyholders[i]] > 0) {
                length++;
            }
        }
        address[] memory keyholders = new address[](length);
        uint256[] memory quantities = new uint256[](length);
        uint256 position = 0;
        for (uint256 i = 0; i < _keyholders.length; i++) {
            uint256 bal = balanceOf(_keyholders[i], KEY);
            uint256 requestedRedemption = wantsRedemption[_keyholders[i]];
            if (bal > 0 && requestedRedemption > 0) {
                keyholders[position] = _keyholders[i];
                quantities[position] = requestedRedemption > bal
                    ? bal
                    : requestedRedemption;
                position++;
            }
        }
        return (keyholders, quantities);
    }

    function canRedeemKeys(address[] memory accounts, uint256[] memory amounts)
        public
        view
        returns (bool canRedeem)
    {
        canRedeem = true;
        if (accounts.length != amounts.length) {
            canRedeem = false;
        }

        for (uint256 i = 0; i < accounts.length; i++) {
            if (balanceOf(accounts[i], KEY) < amounts[i]) {
                canRedeem = false;
                break;
            }
        }
    }

    function getRedeemableKeysFromRedemptionList(
        address[] memory accounts,
        uint256[] memory amounts
    )
        public
        view
        onlyRole(REDEEMER_ROLE)
        returns (address[] memory, uint256[] memory)
    {
        require(accounts.length == amounts.length, "array length mismatch");
        uint256 length = 0;
        for (uint256 i = 0; i < accounts.length; i++) {
            if (
                amounts[i] > redeemedKeys[accounts[i]] &&
                balanceOf(accounts[i], KEY) > 0
            ) {
                length++;
            }
        }

        address[] memory keyholders = new address[](length);
        uint256[] memory quantities = new uint256[](length);
        uint256 position = 0;

        // fill arrays
        for (uint256 i = 0; i < accounts.length; i++) {
            uint256 balance = balanceOf(accounts[i], KEY);
            if (amounts[i] > redeemedKeys[accounts[i]] && balance > 0) {
                keyholders[position] = accounts[i];
                quantities[position] = balance < amounts[i]
                    ? balance
                    : amounts[i];
                position++;
            }
        }
        return (keyholders, quantities);
    }

    function setKeysRedeemed(
        address[] memory accounts,
        uint256[] memory amounts
    ) public onlyRole(REDEEMER_ROLE) {
        require(
            canRedeemKeys(accounts, amounts),
            "array length or balance mismatch"
        );

        for (uint256 i = 0; i < accounts.length; i++) {
            _burn(accounts[i], KEY, amounts[i]);
            redeemedKeys[accounts[i]] += amounts[i];
            wantsRedemption[accounts[i]] = wantsRedemption[accounts[i]] >
                amounts[i]
                ? wantsRedemption[accounts[i]] - amounts[i]
                : 0;
        }
    }

    // Seller
    function burnUnsoldKeys() public onlyRole(SELLER_ROLE) {
        uint256 keysToBurn = balanceOf(sellerAddress, KEY);
        burn(sellerAddress, KEY, keysToBurn);
    }

    function isTradable(
        uint256 id,
        uint256 amount,
        address from
    ) public view returns (bool tradable) {
        tradable = true;
        uint256 tradableBalance = balanceOf(from, id);
        if (wantsRedemption[from] >= tradableBalance) {
            tradableBalance = 0;
        } else {
            tradableBalance -= wantsRedemption[from];
        }
        if (tradableBalance < amount) {
            tradable = false;
        }
    }

    function batchIsTradable(
        uint256[] memory ids,
        uint256[] memory amounts,
        address from
    ) public view returns (bool tradable) {
        tradable = true;
        for (uint256 i = 0; i < ids.length; i++) {
            if (!isTradable(ids[i], amounts[i], from)) {
                tradable = false;
                break;
            }
        }
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override whenNotPaused {
        if (
            !hasRole(SELLER_ROLE, operator) && !hasRole(REDEEMER_ROLE, operator)
        ) {
            // only seller or redeemer can transfer keys
            // only redeemed keys tradable if not paused
            require(
                batchIsTradable(ids, amounts, from),
                "This token is not tradable"
            );
        }
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
        if (to != getRoleMember(SELLER_ROLE, 0) && to != address(0)) {
            for (uint256 i = 0; i < ids.length; i++) {
                if (ids[i] == KEY && !wasKeyHolder[to]) {
                    _keyholders.push(to);
                    wasKeyHolder[to] = true;
                    break;
                }
            }
        }
    }

    // Key Holders
    function setWantsRedemption(uint256 amount) public {
        wantsRedemption[_msgSender()] += amount;
    }

    function getAvailableKeys() public view returns (uint256 availableKeys) {
        uint256 bal = balanceOf(_msgSender(), KEY);
        uint256 requests = wantsRedemption[_msgSender()];
        availableKeys = bal > requests ? bal - requests : 0;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155, AccessControlEnumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // Sets new admin and owner
    function setNewAdmin(address newAdmin) public {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "Must have admin role to set new admin"
        );
        revokeRole(DEFAULT_ADMIN_ROLE, getRoleMember(DEFAULT_ADMIN_ROLE, 0));
        _setupRole(DEFAULT_ADMIN_ROLE, newAdmin);
        transferOwnership(newAdmin);
    }

    function isApprovedForAll(address _owner, address _operator)
        public
        view
        override
        returns (bool isOperator)
    {
        // if OpenSea's ERC1155 Proxy Address is detected, auto-return true
        if (_operator == proxyRegistryAddress) {
            return true;
        }
        // otherwise, use the default ERC1155.isApprovedForAll()
        return ERC1155.isApprovedForAll(_owner, _operator);
    }
}
