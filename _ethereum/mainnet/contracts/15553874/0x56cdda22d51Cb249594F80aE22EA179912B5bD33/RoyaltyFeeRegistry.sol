// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "./IERC165.sol";
import "./Ownable.sol";
import "./IOwnable.sol";

import "./IRoyaltyFeeRegistry.sol";

//  register royalty fee
contract RoyaltyFeeRegistry is IRoyaltyFeeRegistry, Ownable {
    struct FeeInfo {
        address setter;
        address receiver;
        uint256 fee;
    }
       // ERC721 interfaceID
    bytes4 public constant INTERFACE_ID_ERC721 = 0x80ac58cd;

    // ERC1155 interfaceID
    bytes4 public constant INTERFACE_ID_ERC1155 = 0xd9b67a26;

    // ERC2981 interfaceID
    bytes4 public constant INTERFACE_ID_ERC2981 = 0x2a55205a;

    // limit max royalty fee（10,000 = 100%）
    uint256 public royaltyFeeLimit;

    //compile royalty information mapping 
    mapping(address => FeeInfo) private _royaltyFeeInfoCollection;

    event NewRoyaltyFeeLimit(uint256 royaltyFeeLimit);
    event RoyaltyFeeUpdate(address indexed collection, address indexed setter, address indexed receiver, uint256 fee);

    //  initialize royalty fee
    constructor(uint256 _royaltyFeeLimit) {
        // no higher than the upper limit
        require(_royaltyFeeLimit <= 9500, "Royalty fee limit too high");
        royaltyFeeLimit = _royaltyFeeLimit;
    }

    // Update a collection's upper limit of royalty fee
    function updateRoyaltyFeeLimit(uint256 _royaltyFeeLimit) external override onlyOwner {
        // no higher than the upper limit
        require(_royaltyFeeLimit <= 9500, "Royalty fee limit too high");
        royaltyFeeLimit = _royaltyFeeLimit;

        emit NewRoyaltyFeeLimit(_royaltyFeeLimit);
    }

    function updateRoyaltyInfoForCollection(
        address collection,
        address setter,
        address receiver,
        uint256 fee
    ) internal{
        require(fee <= royaltyFeeLimit, "Registry: Royalty fee too high");

        _royaltyFeeInfoCollection[collection] = FeeInfo({setter: setter, receiver: receiver, fee: fee});

        emit RoyaltyFeeUpdate(collection, setter, receiver, fee);
    }

    //
    // function royaltyInfo
    //  @Description: calculate royalty fee
    //  @param address
    //  @param uint256
    //  @return external
    //
    function royaltyInfo(address collection, uint256 amount) external view override returns (address, uint256) {
        return (
        _royaltyFeeInfoCollection[collection].receiver,
        (amount * _royaltyFeeInfoCollection[collection].fee) / 10000
        );
    }
    /*Check collection information*/
    function royaltyFeeInfoCollection(address collection)
    external
    view
    override
    returns (
        address,
        address,
        uint256
    )
    {
        return (
        _royaltyFeeInfoCollection[collection].setter,
        _royaltyFeeInfoCollection[collection].receiver,
        _royaltyFeeInfoCollection[collection].fee
        );
    }


   function updateRoyaltyInfoForCollectionIfSetter(
        address collection,
        address setter,
        address receiver,
        uint256 fee
    ) external {
        address currentSetter = _royaltyFeeInfoCollection[collection].setter;
        require(msg.sender == currentSetter, "Setter: Not the setter");

        updateRoyaltyInfoForCollection(collection, setter, receiver, fee);
    }


        //
    // function checkForCollectionSetter
    //  @Description: Confirm royalty fee seeting information
    //  @param address
    //  @return external Return editor, regarless of admin or owner
    //
    function checkForCollectionSetter(address collection) external view returns (address, uint8) {
        address currentSetter = _royaltyFeeInfoCollection[collection].setter;
        if (currentSetter != address(0)){
            return (currentSetter,0);
        }
        try IERC165(collection).supportsInterface(INTERFACE_ID_ERC2981) returns (bool interfaceSupport) {
            if (interfaceSupport) {
                return (address(0), 1);
            }
        } catch {}

        try IOwnable(collection).owner() returns (address setter) {
            return (setter, 2);
        } catch {
            try IOwnable(collection).admin() returns (address setter) {
                return (setter, 3);
            } catch {
                return (address(0), 4);
            }
        }
    }

    //
    // function updateRoyaltyInfoForCollectionIfAdmin
    //  @Description: Update royalty info if this is the admin of the collection
    //  @param address collection address
    //  @param address  Editor address
    //  @param address  Wallet address receiving royalty fee
    //  @param uint256 royalty fee 500=5%
    //  @return external
    //
    function updateRoyaltyInfoForCollectionIfAdmin(
        address collection,
        address setter,
        address receiver,
        uint256 fee
    ) external {
        //https://eips.ethereum.org/EIPS/eip-2981
        require(!IERC165(collection).supportsInterface(INTERFACE_ID_ERC2981), " Must not be ERC2981");
        require(msg.sender == IOwnable(collection).admin(), " Not the admin");

        _updateRoyaltyInfoForCollectionIfOwnerOrAdmin(collection, setter, receiver, fee);
    }

    //
    // tion updateRoyaltyInfoForCollectionIfOwner
    //  @Description: Update royalty info if this is the owner of the collection
    //  @param address
    //  @param address
    //  @param address
    //  @param uint256
    //  @return external
    //
    function updateRoyaltyInfoForCollectionIfOwner(
        address collection,
        address setter,
        address receiver,
        uint256 fee
    ) external {
        require(!IERC165(collection).supportsInterface(INTERFACE_ID_ERC2981), " Must not be ERC2981");
        require(msg.sender == IOwnable(collection).owner(), " Not the owner");

        _updateRoyaltyInfoForCollectionIfOwnerOrAdmin(collection, setter, receiver, fee);
    }

    //
    // function _updateRoyaltyInfoForCollectionIfOwnerOrAdmin
    //  @Description: Update royalty fee information
    //  @param address
    //  @param address
    //  @param address
    //  @param uint256
    //  @return internal
    //
    function _updateRoyaltyInfoForCollectionIfOwnerOrAdmin(
        address collection,
        address setter,
        address receiver,
        uint256 fee
    ) internal {
        address currentSetter = _royaltyFeeInfoCollection[collection].setter;
        require(currentSetter == address(0), "Already set");

        require(
            (IERC165(collection).supportsInterface(INTERFACE_ID_ERC721) ||
        IERC165(collection).supportsInterface(INTERFACE_ID_ERC1155)),
            " Not Set of ERC721/ERC1155"
        );

        updateRoyaltyInfoForCollection(collection, setter, receiver, fee);
    }
}
