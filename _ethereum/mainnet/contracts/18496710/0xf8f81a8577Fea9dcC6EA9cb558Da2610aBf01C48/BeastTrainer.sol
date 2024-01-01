// SPDX-License-Identifier: WAGDIE
//
//   _          ___        __ ,                             
//  - - /, /,  -   -_,   ,-| ~   -_____    _-_,   ,- _~,    
//    )/ )/ ) (  ~/||   ('||/__,   ' | -,    //  (' /| /    
//    )__)__) (  / ||  (( |||  |  /| |  |`   || ((  ||/=    
//   ~)__)__)  \/==||  (( |||==|  || |==||  ~|| ((  ||      
//    )  )  )  /_ _||   ( / |  , ~|| |  |,   ||  ( / |      
//   /-_/-_/  (  - \\,   -____/   ~-____,  _-_,   -____-    
//                             (                          
//                                                        
//                     ___             ___                
//  _-_ _,,     ,- _~,  -   -_,   -_-/  -   ---___-   -_-/  
//     -/  )   (' /| / (  ~/||   (_ /      (' ||     (_ /   
//    ~||_<   ((  ||/= (  / ||  (_ --_    ((  ||    (_ --_  
//     || \\  ((  ||    \/==||    --_ )  ((   ||      --_ ) 
//     ,/--||  ( / |    /_ _||   _/  ))   (( //      _/  )) 
//    _--_-'    -____- (  - \\, (_-_-       -____-  (_-_-   
//   (                                                      
//
//

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./ERC721URIStorage.sol";
import "./Strings.sol";
import "./Ownable.sol";


contract BeastTrainer is ERC721URIStorage, Ownable {
    IERC721 public wagdie = IERC721(0x659A4BdaAaCc62d2bd9Cb18225D9C89b5B697A5A);
    IERC721 public beast = IERC721(0xD83a76AC28520D22893cC68cdBEc748cD46208cf);

    bool public activeTraining = false;
    uint256 public trainingTimer;
    uint256 private constant TRAINING_DURATION = 17280 minutes;
    address public trainee;
    uint256 public wagdieID;
    uint256 public beastID;
    uint256 private graduationID = 1;

    address public mozredee = 0x15ff9971047096cf3dBd10245E495B362A9F8c72;

    mapping(uint256 => bool) public alumniWAGDIE;
    mapping(uint256 => bool) public alumniBEASTS;

    string public baseURI = "https://fateofwagdie.com/api/bondings/";

    constructor() ERC721("WAGDIE Beast Trainer", "WAGBOND") {}

    function beginTraining(uint256 _wagdieID, uint256 _beastID) external {
        require(!activeTraining, "Training already in progress.");
        require(wagdie.ownerOf(_wagdieID) == msg.sender, "You do not own this WAGDIE.");
        require(beast.ownerOf(_beastID) == msg.sender, "You do not own this Beast.");
        require(!alumniWAGDIE[_wagdieID], "This WAGDIE is already alumni.");
        require(!alumniBEASTS[_beastID], "This Beast is already alumni.");
        
        wagdie.transferFrom(msg.sender, address(this), _wagdieID);
        beast.transferFrom(msg.sender, address(this), _beastID);

        activeTraining = true;
        trainingTimer = block.timestamp + TRAINING_DURATION;
        trainee = msg.sender;
        wagdieID = _wagdieID;
        beastID = _beastID;

        alumniWAGDIE[_wagdieID] = true;
        alumniBEASTS[_beastID] = true;
    }

    function graduate() external {
        require(activeTraining, "There are no trainees ready to graduate.");
        
        if (msg.sender != owner() && msg.sender != mozredee) {
          require(block.timestamp >= trainingTimer, "Training period is not over yet.");}

        wagdie.transferFrom(address(this), trainee, wagdieID);
        beast.transferFrom(address(this), trainee, beastID);

        _mintBondedPair(trainee);

        activeTraining = false;
        trainee = address(0);
    }

    function _mintBondedPair(address _trainee) private {
        string memory tokenURI = string(abi.encodePacked(baseURI, Strings.toString(graduationID)));

        _safeMint(_trainee, graduationID);
        _setTokenURI(graduationID, tokenURI);
        
        graduationID++;
    }

    function updateBaseURI(string memory newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

}
