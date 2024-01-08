//SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;
pragma abicoder v2;

import "./StorageSlot.sol";
import "./IERC1155.sol";
import "./Strings.sol";
import "./Account.sol";
import "./MinimalProxy.sol";
import "./IAccount.sol";
import "./IAvatar.sol";
import "./IDava.sol";
import "./IPartCollection.sol";
import "./IFrameCollection.sol";

abstract contract AvatarBase is MinimalProxy, IAvatar, Account {
    using Strings for uint256;

    event PutOn(bytes32 indexed categoryId, address collection, uint256 id);
    event TakeOff(bytes32 indexed categoryId, address collection, uint256 id);

    // DO NOT DECLARE state variables in the proxy contract.
    // If you wanna access to the existing state variables, use _props().
    // If you want to add new variables, design a new struct and allocate a slot for it.

    modifier onlyOwnerOrDava() {
        require(
            msg.sender == owner() || msg.sender == dava(),
            "Avatar: only owner or Dava can call this"
        );
        _;
    }

    receive() external payable override(Proxy, Account) {}

    function dress(Part[] calldata partsOn, bytes32[] calldata partsOff)
        external
        virtual
        override
        onlyOwnerOrDava
    {
        for (uint256 i = 0; i < partsOff.length; i += 1) {
            _takeOff(partsOff[i]);
        }
        for (uint256 i = 0; i < partsOn.length; i += 1) {
            _putOn(partsOn[i]);
        }
    }

    function owner() public view override returns (address) {
        return IDava(dava()).ownerOf(_props().davaId);
    }

    function dava() public view override returns (address) {
        return StorageSlot.getAddressSlot(DAVA_CONTRACT_SLOT).value;
    }

    function davaId() public view override returns (uint256) {
        return _props().davaId;
    }

    function part(bytes32 categoryId)
        public
        view
        override
        returns (Part memory)
    {
        // Try to retrieve from the storage
        Part memory part_ = _props().parts[categoryId];
        if (part_.collection == address(0x0)) {
            return Part(address(0x0), 0);
        }

        // Check the balance
        bool owning = _isEligible(part_);
        // return the part only when the Avatar owns the part or return a null part.
        if (owning) {
            return part_;
        } else {
            return Part(address(0x0), 0);
        }
    }

    function allParts()
        public
        view
        virtual
        override
        returns (Part[] memory parts)
    {
        IDava _dava = IDava(dava());
        bytes32[] memory allCategories = _dava.getAllSupportedCategories();

        parts = new Part[](allCategories.length);
        for (uint256 i = 0; i < allCategories.length; i += 1) {
            parts[i] = part(allCategories[i]);
        }
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(IAvatar).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function version() public pure virtual override returns (string memory);

    function getPFP() external view virtual override returns (string memory);

    function getMetadata()
        external
        view
        virtual
        override
        returns (string memory);

    function _putOn(Part memory part_) internal {
        bytes32 categoryId = IPartCollection(part_.collection).categoryId(
            part_.id
        );
        _props().parts[categoryId] = part_;
        emit PutOn(categoryId, part_.collection, part_.id);
    }

    function _takeOff(bytes32 categoryId) internal {
        Part memory target = _props().parts[categoryId];
        delete _props().parts[categoryId];
        emit TakeOff(categoryId, target.collection, target.id);
    }

    function _isEligible(Part memory part_)
        internal
        view
        virtual
        returns (bool)
    {
        require(
            IDava(dava()).isDavaPart(
                part_.collection,
                IPartCollection(part_.collection).categoryId(part_.id)
            ),
            "Avatar: not a registered part."
        );
        return (IERC1155(part_.collection).balanceOf(address(this), part_.id) >
            0);
    }
}
