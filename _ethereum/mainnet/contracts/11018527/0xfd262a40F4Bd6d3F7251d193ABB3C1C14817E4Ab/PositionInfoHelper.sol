pragma solidity 0.5.16;
pragma experimental ABIEncoderV2;

interface BankConfig {
    function killFactor(address goblin, uint256 debt) external view returns (uint256);
}

interface Bank {
    struct Position {
        address goblin;
        address owner;
        uint256 debtShare;
    }
    
    function positions(uint256 id) external view returns (Position memory);
    function positionInfo(uint256 id) external view returns (uint256 health, uint256 debt);
}

contract PositionInfoHelper {
    Bank public bank;
    BankConfig public config;
    address public owner;
    
    constructor(Bank _bank, BankConfig _config) public {
        bank = _bank;
        config = _config;
        owner = msg.sender;
    }
    
    function set(Bank _bank, BankConfig _config, address _owner) public {
        require(msg.sender == owner);
        bank = _bank;
        config = _config;
        owner = _owner;
    }
    
    struct PosInfo {
        uint256 id;
        address goblin;
        uint256 health;
        uint256 debt;
        uint256 killFactor;
        bool canKill;
    }
    
    function posInfo(uint256 id) public view returns (PosInfo memory) {
        Bank.Position memory pos = bank.positions(id);
        (uint256 health, uint256 debt) = bank.positionInfo(id);
        uint256 killFactor = config.killFactor(pos.goblin, debt);
        return PosInfo({
            id: id,
            goblin: pos.goblin,
            health: health,
            debt: debt,
            killFactor: killFactor,
            canKill: health * killFactor < debt * 10000
        });
    }
    
    function multiPosInfo(uint256[] memory ids) public view returns (PosInfo[] memory) {
        uint256 len = ids.length;
        PosInfo[] memory result = new PosInfo[](len);
        for (uint256 i = 0; i < len; i ++) {
            result[i] = posInfo(ids[i]);
        }
        return result;
    }
}