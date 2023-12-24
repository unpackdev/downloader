// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./Ownable.sol";
import "./IERC1155.sol";
import "./IERC721.sol";
import "./IHoodySign.sol";

interface IHoodyGang {
    function ogMigrate(uint256, string memory) external;

    function buildingBlockFreeMint(uint8) external;
}

contract HoodyMigrate is Ownable {
    address public hoodyBuilding;
    address public hoodyOGV1;
    address public hoodyOGV2;
    address public hoodyGang;
    address public hoodySign;

    mapping(uint256 => bool) public isMigrated;

    constructor(
        address _hoodyBuilding,
        address _hoodyGang
    ) Ownable(msg.sender) {
        hoodyBuilding = _hoodyBuilding;
        hoodyGang = _hoodyGang;
    }

    function ogV1Migrate(
        uint256 _ogID,
        string memory _uri,
        bytes memory _signature
    ) public {
        require(
            IERC1155(hoodyOGV1).balanceOf(tx.origin, _ogID) > 0,           //this require is needed on mainnet
            "You don't have that NFT!"
        );
        ogMigrate(_ogID, _uri, _signature);
    }

    function ogV2Migrate(
        uint256 _ogID,
        string memory _uri,
        bytes memory _signature
    ) public {
        require(
            IERC721(hoodyOGV2).ownerOf(_ogID) == msg.sender,
            "You don't have that NFT!"
        );

        ogMigrate(_ogID, _uri, _signature);
    }

    function ogMigrate(
        uint256 _ogID,
        string memory _uri,
        bytes memory _signature
    ) private {
        require(
            IHoodySign(hoodySign).verifyForMigrate(
                msg.sender,
                _ogID,
                _uri,
                _signature
            ),
            "Invalid Signature"
        );
        require(!isMigrated[_ogID], "Already Migrated!");
        IHoodySign(hoodySign).increaseNonce(msg.sender);

        isMigrated[_ogID] = true;
        IHoodyGang(hoodyGang).ogMigrate(_ogID, _uri);
    }

    function freeMint(uint256 _ids, uint8 _amounts) public {
            require(
                IERC1155(hoodyBuilding).balanceOf(msg.sender, _ids) >=
                    _amounts,
                "You have not enough tokens!"
            );
            IERC1155(hoodyBuilding).safeTransferFrom(
                msg.sender,
                owner(),
                _ids,
                _amounts,
                ""
            );
            IHoodyGang(hoodyGang).buildingBlockFreeMint(_amounts);
    }

    function setHoodySign(address _hoodySign) public onlyOwner {
        hoodySign = _hoodySign;
    }

    function setHoodyGang(address _hoodyGang) public onlyOwner {
        hoodyGang = _hoodyGang;
    }

    function setHoodyOGs(
        address _hoodyOGV1,
        address _hoodyOGV2
    ) public onlyOwner {
        hoodyOGV1 = _hoodyOGV1;
        hoodyOGV2 = _hoodyOGV2;
    }
}
