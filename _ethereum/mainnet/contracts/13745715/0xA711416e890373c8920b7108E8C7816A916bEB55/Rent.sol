//SPDX-License-Identifier: CC-BY-SA-4.0

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./PullPayment.sol";

interface IColors {
    function MAX_COLORS() external returns (uint);

    function ownerOf(uint256 tokenId) external view returns (address);

    function totalSupply() external view returns (uint256);

    function changeColor(
        uint256 tokenId,
        uint32 colorR,
        uint32 colorG,
        uint32 colorB
    ) external;
}

contract Rent is Ownable, PullPayment {
    IColors colorsContract;

    /**
     * Event emitted when a RENTING is effective
     */
    event Rented(
        uint amount,
        address account,
        uint256 indexed tokenId,
        uint duration
    );

    /**
     * Event emitted on RENT SETTINGS change
     */
    event OnRent(
        bool indexed isOnRent,
        uint256 indexed tokenId
    );

    address public colorsAddr;
    uint constant oneDay = 86400;
    uint constant oneYear = 31536000;
    uint constant baseFee = 10000000000000000 wei;
    uint constant slotLength = 5;

    function initColorsContract(address _address) public onlyOwner {
        colorsContract = IColors(_address);
    }

    constructor() Ownable() PullPayment() {}

    struct ColorRentingData {
        bool isOnRent;
        uint[] prices;
        uint[] durations;
    }

    struct ColorRenter {
        uint endLeaseTimeStamp;
        address lessee;
    }

    // Token ID => Renting settings
    mapping(uint => ColorRentingData) private _colorRentings;

    // Token ID => Lessee data
    mapping(uint => ColorRenter) private _colorRenters;

    function setColorRenting(
        uint256 tokenId,
        bool isOnRent,
        uint[] memory prices,
        uint[] memory durations
    ) public {

        require(colorsContract.ownerOf(tokenId) == msg.sender, "Not owner");
        require(prices.length <= slotLength, "Too large");
        require(durations.length <= slotLength, "Too large");
        require(durations.length == prices.length, "Ey");

        for (uint i = 0; i < prices.length; i++) {
            require(prices[i] > 0, 'Higher');
            require(durations[i] >= oneDay, "Min one day");
            require(durations[i] <= oneYear, "Max one year");
        }

        _colorRentings[tokenId] = ColorRentingData(isOnRent, prices, durations);

        emit OnRent(
            isOnRent,
            tokenId
        );
    }

    function getColorRentingData(
        uint256 tokenId
    ) view external returns (
        ColorRentingData memory,
        ColorRenter memory
    ) {
        return (
        _colorRentings[tokenId],
        _colorRenters[tokenId]
        );
    }

    function getRenter(
        uint256 tokenId
    ) view external returns (
        ColorRenter memory
    ) {
        return _colorRenters[tokenId];
    }

    // DIRECT RENTING TO RENT TO KNOWN ADDRESS
    // BASE FEE of 0.01 ETH
    function directRent(
        uint256 tokenId,
        uint rentDuration,
        address lessee
    ) public payable {
        require(tokenId >= 0 && tokenId < colorsContract.MAX_COLORS(), 'Not ID');
        require(colorsContract.totalSupply() == colorsContract.MAX_COLORS(), "Rent inactive");
        require(colorsContract.ownerOf(tokenId) == msg.sender, "Not yours");

        // EndLease is behind in time
        require(_colorRenters[tokenId].endLeaseTimeStamp < block.timestamp, 'Is rented');
        require(rentDuration >= oneDay, "Min one day");
        require(rentDuration <= oneYear, "Max one year");

        require(msg.value >= baseFee, "Ether value wrong");

        _asyncTransfer(owner(), msg.value);

        _colorRenters[tokenId] = ColorRenter(
            rentDuration,
            lessee
        );

        emit Rented(
            baseFee,
            lessee,
            tokenId,
            rentDuration
        );
    }

    function rentCOLOR(
        uint256 tokenId,
        uint slotTypeIndex
    ) public payable {

        require(tokenId >= 0 && tokenId < colorsContract.MAX_COLORS(), 'Not available ID');
        require(slotTypeIndex >= 0 && slotTypeIndex < slotLength, 'Slot error');

        require(_colorRentings[tokenId].prices[slotTypeIndex] > 0, 'Times error');
        require(_colorRentings[tokenId].durations[slotTypeIndex] > 0, 'Duration error');

        require(colorsContract.totalSupply() == colorsContract.MAX_COLORS(), "Rent inactive");
        // Not rent ongoing
        require(colorsContract.ownerOf(tokenId) != msg.sender, 'Is your COLOR');
        // End rent < now = rent is possible
        require(_colorRenters[tokenId].endLeaseTimeStamp < block.timestamp, 'Is yet rented');
        // Color is on rent
        require(_colorRentings[tokenId].isOnRent == true, 'Is not renting');


        uint payment = _colorRentings[tokenId].prices[slotTypeIndex] + _colorRentings[tokenId].prices[slotTypeIndex] / 20;
        require(msg.value >= payment, "Ether value wrong");

        // Add renting
        _colorRenters[tokenId] = ColorRenter(
            _colorRentings[tokenId].durations[slotTypeIndex] + block.timestamp,
            msg.sender
        );

        // Distribute values
        _asyncTransfer(colorsContract.ownerOf(tokenId), _colorRentings[tokenId].prices[slotTypeIndex]);
        _asyncTransfer(owner(), msg.value - _colorRentings[tokenId].prices[slotTypeIndex]);

        emit Rented(
            payment,
            msg.sender,
            tokenId,
            _colorRentings[tokenId].durations[slotTypeIndex]
        );
    }

}
