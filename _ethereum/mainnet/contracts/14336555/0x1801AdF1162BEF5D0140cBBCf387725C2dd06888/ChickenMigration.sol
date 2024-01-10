pragma solidity ^0.8.12;

import "./ChickenDAOv1.sol";
import "./ChickenDAOv2.sol";
import "./AccessControlEnumerable.sol";

/* Migrate v1 Chicken DAO to v2 Chicken DAO
*/
contract ChickenMigration is AccessControlEnumerable {

    uint8 maxMigration = 30; 

    ChickenDAOv1 chickenDAOv1 = ChickenDAOv1(0x3724c5A69432268fD7abf6e1b1503c9E24D5291e);
    ChickenDAOv2 chickenDAOv2 = ChickenDAOv2(0xe0962D2E64C5922eA7E8b4967077C4cB7Ea7cbc3);

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function setMaxMigration(uint8 _m) 
    public
    {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "You don't have permission to do this.");
        maxMigration = _m;
    }

    function setV1Contract(address c) 
    public
    {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "You don't have permission to do this.");
        chickenDAOv1 = ChickenDAOv1(c);
    }

    function setV2Contract(address c) 
    public
    {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "You don't have permission to do this.");
        chickenDAOv2 = ChickenDAOv2(c);
    }

    function migrateChickens() 
    public
    {
        uint256 v1Balance = chickenDAOv1.balanceOf(msg.sender);
        if (v1Balance > maxMigration) { v1Balance = maxMigration; }
        for (uint8 i = 0; i < v1Balance; i++) { // migrate
            uint256 index = chickenDAOv1.tokenOfOwnerByIndex(msg.sender, i);
            (string memory c, uint256 x, uint256 y, uint256 z) = readChicken(index);
            uint color = getChickenColor(z);
            chickenDAOv2.migrateNFT(color, msg.sender);
        }
        for (uint8 i = 0; i < v1Balance; i++) { // burn
            uint256 index = chickenDAOv1.tokenOfOwnerByIndex(msg.sender, 0);
            chickenDAOv1.burn(index);
        }
    }

    function getChickenColor(uint256 i) 
    private
    pure
    returns (uint)
    {
        if (i % 100 == 0) {
            return 0;
        }
        else if (i % 13 == 0) {
            return 1;
        }
        else if (i % 12 == 0) {
            return 2;
        }
        else if (i % 11 == 0) {
            return 3;
        }
        else if (i % 3 == 0) {
            return 4;
        }
        else if (i % 2 == 0) {
            return 5;
        }
        else {
            return 6;
        }
    }

    function readChicken(uint256 id) private returns (string memory, uint256, uint256, uint256) 
    {
        return chickenDAOv1.chickens(id);
    }
}