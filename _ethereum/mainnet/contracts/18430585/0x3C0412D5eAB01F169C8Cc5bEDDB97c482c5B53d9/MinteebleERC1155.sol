// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

//  =============================================
//   _   _  _  _  _  ___  ___  ___  ___ _    ___
//  | \_/ || || \| ||_ _|| __|| __|| o ) |  | __|
//  | \_/ || || \\ | | | | _| | _| | o \ |_ | _|
//  |_| |_||_||_|\_| |_| |___||___||___/___||___|
//
//  Website: https://minteeble.com
//  Email: minteeble@gmail.com
//
//  =============================================

import "./ERC1155Supply.sol";
import "./AccessControlEnumerable.sol";
import "./ReentrancyGuard.sol";

interface IMinteebleERC1155 is IERC1155 {
    function addId(uint256 _id) external;

    function removeId(uint256 _id) external;

    function getIds() external view returns (uint256[] memory);

    function setURI(string memory _newUri) external;

    function ownerMintForAddress(
        address _recipientAccount,
        uint256 _id,
        uint256 _amount
    ) external;

    function mintForAddress(
        address _recipientAccount,
        uint256 _id,
        uint256 _amount
    ) external payable;

    function airdrop(uint256 _id, address[] memory _accounts) external;

    function setMintPrice(uint256 _id, uint256 _price) external;

    function setMaxSupply(uint256 _id, uint256 _maxSupply) external;

    function mintPrice(uint256 _id) external view returns (uint256);

    function maxSupply(uint256 _id) external view returns (uint256);

    function mint(uint256 _id, uint256 _amount) external payable;

    function setPaused(bool _paused) external;

    function withdrawBalance() external;
}

contract MinteebleERC1155 is
    ERC1155Supply,
    AccessControlEnumerable,
    ReentrancyGuard
{
    bool public paused;
    string public name;
    string public symbol;

    bool freeItemsBuyable;

    bytes4 public constant IMINTEEBLE_ERC1155_INTERFACE_ID =
        type(IMinteebleERC1155).interfaceId;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    struct IdInfo {
        uint256 id;
        uint256 price;
        uint256 maxSupply;
    }

    IdInfo[] public idsInfo;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _uri
    ) ERC1155(_uri) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        name = _name;
        symbol = _symbol;
        paused = true;
        freeItemsBuyable = true;
    }

    modifier requireAdmin(address _account) {
        require(hasRole(DEFAULT_ADMIN_ROLE, _account), "Unauthorized");
        _;
    }

    modifier idExists(uint256 _id) {
        bool idFound = false;
        for (uint256 i = 0; i < idsInfo.length; i++) {
            if (idsInfo[i].id == _id) idFound = true;
        }
        require(idFound, "Id not found");
        _;
    }

    modifier active() {
        require(!paused, "Contract is paused.");
        _;
    }

    function _getIdIndex(uint256 _id) internal view returns (uint256 index) {
        for (uint256 i = 0; i < idsInfo.length; ++i) {
            if (idsInfo[i].id == _id) return i;
        }

        require(false, "Id not found");
    }

    function _addId(uint256 _id) internal {
        for (uint256 i = 0; i < idsInfo.length; i++) {
            require(idsInfo[i].id != _id, "Id already exists");
        }

        IdInfo memory newId = IdInfo(_id, 0, 0);
        idsInfo.push(newId);
    }

    function _removeId(uint256 _id) internal {
        bool idFound = false;

        for (uint256 i = 0; i < idsInfo.length; i++) {
            if (idsInfo[i].id == _id) {
                require(totalSupply(_id) == 0, "Cannot delete id with supply");

                idsInfo[i] = idsInfo[idsInfo.length - 1];
                delete idsInfo[idsInfo.length - 1];
                idsInfo.pop();

                idFound = true;
            }
        }

        require(idFound, "Id not found");
    }

    function addId(uint256 _id) public requireAdmin(msg.sender) {
        _addId(_id);
    }

    function removeId(uint256 _id) public requireAdmin(msg.sender) {
        _removeId(_id);
    }

    function getIds() public view returns (IdInfo[] memory) {
        return idsInfo;
    }

    function setURI(string memory _newUri) public requireAdmin(msg.sender) {
        _setURI(_newUri);
    }

    function setFreeItemsBuyable(
        bool _freeItemsBuyable
    ) public requireAdmin(msg.sender) {
        freeItemsBuyable = _freeItemsBuyable;
    }

    function ownerMintForAddress(
        address _recipientAccount,
        uint256 _id,
        uint256 _amount
    ) public idExists(_id) nonReentrant {
        require(hasRole(MINTER_ROLE, msg.sender), "Minter role required.");
        _mint(_recipientAccount, _id, _amount, "");
    }

    function ownerMintBatchForAddress(
        address _recipientAccount,
        uint256[] memory _ids,
        uint256[] memory _amounts
    ) public nonReentrant {
        require(hasRole(MINTER_ROLE, msg.sender), "Minter role required.");
        _mintBatch(_recipientAccount, _ids, _amounts, "");
    }

    function mintForAddress(
        address _recipientAccount,
        uint256 _id,
        uint256 _amount
    ) public payable idExists(_id) active nonReentrant {
        for (uint256 i = 0; i < idsInfo.length; i++) {
            if (idsInfo[i].id == _id) {
                if (idsInfo[i].maxSupply != 0) {
                    require(
                        totalSupply(_id) + _amount <= idsInfo[i].maxSupply,
                        "Max supply reached"
                    );
                }

                require(
                    idsInfo[i].price != 0 || freeItemsBuyable,
                    "Not for sale"
                );

                require(
                    msg.value >= idsInfo[i].price * _amount,
                    "Insufficient funds"
                );

                _mint(_recipientAccount, _id, _amount, "");
            }
        }
    }

    function mintBatchForAddress(
        address _recipientAccount,
        uint256[] memory _ids,
        uint256[] memory _amounts
    ) public payable active nonReentrant {
        require(_ids.length == _amounts.length, "Invalid input");

        uint256 totalCost;

        for (uint256 i = 0; i < _ids.length; i++) {
            for (uint256 j = 0; j < idsInfo.length; j++) {
                if (idsInfo[j].id == _ids[i]) {
                    if (idsInfo[j].maxSupply != 0) {
                        require(
                            totalSupply(_ids[i]) + _amounts[i] <=
                                idsInfo[j].maxSupply,
                            "Max supply reached"
                        );
                    }

                    require(
                        idsInfo[j].price != 0 || freeItemsBuyable,
                        "Not for sale"
                    );

                    totalCost += idsInfo[j].price * _amounts[i];
                }
            }
        }

        require(msg.value >= totalCost, "Insufficient funds");

        _mintBatch(_recipientAccount, _ids, _amounts, "");
    }

    function airdrop(
        uint256 _id,
        address[] memory _accounts
    ) public requireAdmin(msg.sender) idExists(_id) nonReentrant {
        for (uint256 i; i < _accounts.length; i++) {
            _mint(_accounts[i], _id, 1, "");
        }
    }

    function setMintPrice(
        uint256 _id,
        uint256 _price
    ) public requireAdmin(msg.sender) {
        idsInfo[_getIdIndex(_id)].price = _price;
    }

    function setMaxSupply(
        uint256 _id,
        uint256 _maxSupply
    ) public requireAdmin(msg.sender) {
        require(
            _maxSupply > totalSupply(_id),
            "Max supply can not be less than total supply."
        );

        idsInfo[_getIdIndex(_id)].maxSupply = _maxSupply;
    }

    function mintPrice(uint256 _id) public view returns (uint256) {
        return idsInfo[_getIdIndex(_id)].price;
    }

    function batchMintPrice(
        uint256[] memory _ids
    ) public view returns (uint256[] memory) {
        uint256[] memory prices = new uint256[](_ids.length);

        for (uint256 i = 0; i < _ids.length; i++) {
            prices[i] = idsInfo[_getIdIndex(_ids[i])].price;
        }

        return prices;
    }

    function batchSetMintPrice(
        uint256[] memory _ids,
        uint256[] memory _prices
    ) public requireAdmin(msg.sender) {
        require(_ids.length == _prices.length, "Invalid input");

        for (uint256 i = 0; i < _ids.length; i++) {
            setMintPrice(_ids[i], _prices[i]);
        }
    }

    function maxSupply(uint256 _id) public view returns (uint256) {
        return idsInfo[_getIdIndex(_id)].maxSupply;
    }

    function batchMaxSupply(
        uint256[] memory _ids
    ) public view returns (uint256[] memory) {
        uint256[] memory maxSupplies = new uint256[](_ids.length);

        for (uint256 i = 0; i < _ids.length; i++) {
            maxSupplies[i] = idsInfo[_getIdIndex(_ids[i])].maxSupply;
        }

        return maxSupplies;
    }

    function batchSetMaxSupply(
        uint256[] memory _ids,
        uint256[] memory _maxSupplies
    ) public requireAdmin(msg.sender) {
        require(_ids.length == _maxSupplies.length, "Invalid input");

        for (uint256 i = 0; i < _ids.length; i++) {
            setMaxSupply(_ids[i], _maxSupplies[i]);
        }
    }

    function mint(uint256 _id, uint256 _amount) public payable {
        mintForAddress(msg.sender, _id, _amount);
    }

    function setPaused(bool _paused) public requireAdmin(msg.sender) {
        paused = _paused;
    }

    function withdrawBalance()
        public
        virtual
        requireAdmin(msg.sender)
        nonReentrant
    {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success);
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(ERC1155, AccessControlEnumerable)
        returns (bool)
    {
        return
            interfaceId == type(IMinteebleERC1155).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}
