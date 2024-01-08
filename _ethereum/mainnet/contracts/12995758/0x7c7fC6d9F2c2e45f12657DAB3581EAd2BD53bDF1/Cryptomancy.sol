// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./ERC1155Burnable.sol";

contract Cryptomancy is ERC1155, Ownable, ERC1155Burnable {
    uint256 constant public maxSupply = 1472;

    // mapping of address to multiple ids
    mapping (address => uint16[]) public addressReservations;
    // mapping of id to address
    // mapping (uint16 => address) public reservationAddress;

    // Reservation struct for receiving the tuple of address and ids
    struct Reservation {
        address sigilOwner;
        uint16[] sigilIds;
    }

    constructor() ERC1155("https://cryptomancy.net/mock-api/{id}") {
    }

    // receive the initial set of Reservations
    // these are taken from a snapshot of BSC owners of the original Cryptomancy cards
    // this ensures that only original owners can mint the same card on this chain
    function setReservations(Reservation[] memory reservations) public onlyOwner {
        for (uint i=0; i<reservations.length; i++) {
            address resAddress = reservations[i].sigilOwner;
            uint16[] memory resArray = reservations[i].sigilIds;
            addressReservations[resAddress] = resArray;
        }
    }

    function getReservations(address sigilOwner) external view returns(uint16[] memory) {
        return addressReservations[sigilOwner];
    }

    function mintBatchIds(uint16[] memory ids) public {
        // check that the address provided has at least one reservation
        require(addressReservations[msg.sender].length > 0);
        require(ids.length > 0);
        _mintBatchIds(msg.sender, ids);
    }

    // allow the owner to mint on behalf of another user - in case they don't have enough gas or something
    // does not bypass reservation controls
    function mintBatchOther(address sigilOwner, uint16[] memory ids) public onlyOwner {
        // check that the address provided has at least one reservation
        require(addressReservations[sigilOwner].length > 0);
        require(ids.length > 0);
        _mintBatchIds(sigilOwner, ids);
    }

    function _mintBatchIds(address sigilOwner, uint16[] memory ids) private {
        // take a list of ids and then check each one is owned by the address
        uint256[] memory sigilReservations = new uint256[](ids.length);
        uint256[] memory sigilAmounts = new uint256[](ids.length);
        uint16[] memory ownerReservations = addressReservations[sigilOwner];

        for (uint i=0; i<ids.length; i++) {
            uint16 id = ids[i];
            require(id != 0);
            // check that owner is same as the recipient
            bool owned = false;
            for (uint n=0; n<ownerReservations.length; n++) {
                if (ownerReservations[n] == id) {
                    owned = true;
                    ownerReservations[n] = 0;
                    // set the id to 0 in the original reservation to prevent duplicates
                }
            }
            require(owned == true);
            sigilAmounts[i] = 1;
            sigilReservations[i] = id;
        }

        // check that we actually resolved some legit reservations
        require(sigilReservations.length > 0);
        _mintBatch(sigilOwner, sigilReservations, sigilAmounts, "");

        // update the addressReservations array
        addressReservations[sigilOwner] = ownerReservations;
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    // emergency minting function - allows owner to mint a sigil if something goes wrong with self-minting process
    // bypasses reservation controls, but does not allow minting beyond max supply
    function mint(address account, uint256 id, uint256 amount, bytes memory data)
        public
        onlyOwner
    {
        require(id <= maxSupply);
        _mint(account, id, amount, data);
    }
}
