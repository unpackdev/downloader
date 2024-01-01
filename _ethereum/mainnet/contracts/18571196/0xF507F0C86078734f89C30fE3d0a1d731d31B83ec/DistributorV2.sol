pragma solidity ^0.5.10;

contract iInventory {

    function createFromTemplate(
        uint256 _templateId,
        uint8 _feature1,
        uint8 _feature2,
        uint8 _feature3,
        uint8 _feature4,
        uint8 _equipmentPosition
    )
        public
        returns(uint256);

}

contract DistributeItemsV2 {
    
    modifier onlyAdmin() {
        require(admin == msg.sender, "DISTRIBUTE_ITEMS: Caller is not admin");
        _;
    }

    modifier allowedItem(uint256 _templateId) {
        require(allowed[msg.sender][_templateId], "DISTRIBUTE_ITEMS: Caller is not allowed to claim item");
        _;
    }

    modifier checkIfClaimed(uint256 _templateId) {
        require(!claimed[_templateId][msg.sender], "DISTRIBUTE_ITEMS: Player has already claimed item");
        _;
    }

    modifier checkHolidayItem(uint256 _templateId) {
        require(holidayItems[_templateId] > 0, "DISTRIBUTE_ITEMS: This is not a holiday item");
        require(holidayItems[_templateId] >= uint32(now), "DISTRIBUTE_ITEMS: The time to claim this item has passed"); 
        _;
    }
    
    iInventory inv = iInventory(0x9680223F7069203E361f55fEFC89B7c1A952CDcc);
    
    address private admin;
    
    // address => (_templateId => bool)
    mapping (address => mapping(uint256 => bool)) public allowed;

    // _templateId => player => has the player claimed?
    mapping (uint256 => mapping(address => bool)) public claimed;

    // _templateId => timestamp 
    mapping (uint256 => uint32) public holidayItems; 

    constructor() public {
        admin = msg.sender;
    }
    
    // Admin can add new item allowances
    function addItemAllowance(
        address _player,
        uint256 _templateId,
        bool _allowed
    )
        external
        onlyAdmin
    {
        allowed[_player][_templateId] = _allowed;
    }
    
    // Admin can add new item allowances in bulk 
    function addItemAllowanceForAll(
        address[] calldata _players,
        uint256 _templateId,
        bool _allowed
    )
        external
        onlyAdmin
    {
        for(uint i = 0; i < _players.length; i++) {
            allowed[_players[i]][_templateId] = _allowed;
        }
    }

    // Admin function to add new holiday items 
    function addHolidayItems(
        uint256[] calldata _templateIds,
        uint32 _endTime
    )
        external 
        onlyAdmin
    {
        // Set endTime for all items 
        for(uint i = 0; i < _templateIds.length; i++) {
            holidayItems[_templateIds[i]] = _endTime; 
        }
    }
    
    /*  Player can claim 1x item of _templateId when 
        Admin has set the allowance beforehand */
    function claimItem(
        uint256 _templateId,
        uint8 _equipmentPosition
    )
        external
        allowedItem(_templateId)
    {
        // Reset allowance (only once per allowance)
        allowed[msg.sender][_templateId] = false;
        
        // Materialize
        inv.createFromTemplate(
            _templateId,
            0,
            0,
            0,
            0,
            _equipmentPosition
        );
    }

    /*  Player can claim 1x of item _templateId when
        it is a holiday item and the timestamp for it is 
        in the future. 
        Can be claimed only once per Player. */
    function claimHolidayItem(
        uint256 _templateId,
        uint8 _equipmentPosition
    )
        external 
        checkHolidayItem(_templateId)
        checkIfClaimed(_templateId)
    {
        // Set claimed status 
        claimed[_templateId][msg.sender] = true; 

        // Materialize
        inv.createFromTemplate(
            _templateId,
            0,
            0,
            0,
            0,
            _equipmentPosition
        );
    }
}