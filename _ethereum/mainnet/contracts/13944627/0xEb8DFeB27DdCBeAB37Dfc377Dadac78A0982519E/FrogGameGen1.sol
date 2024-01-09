// contracts/FrogGameGen1.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";

//Interfaces
interface ITadpole {
    function burnFrom(address owner, uint amount) external;
    function balanceOf(address _owner) external view returns (uint256); 
}
    
interface IPond {
    function getRandomSnakeOwner() external returns(address);
}

//Contract
contract FrogGame is ERC721Enumerable, Pausable, ReentrancyGuard {
    bytes32 internal entropySauce;

    uint snakeTypeShift = 69000;

    string _baseTokenURI;

    address public owner;

    address constant internal nullAddress = address(0x0);

    ITadpole internal tadpoleContract;
    IPond internal pondContract;

    uint constant gen0TypeShift = 3000;
    uint constant MAX_SUPPLY = 22000;
    uint constant public tadpolePhasePriceIncrease = 25000 ether;
    uint constant public mintPhaseStep = 5000;
    uint constant public maxMintPerTx = 10;

    uint internal _snakesTotal;
    uint internal _frogsTotal;
    uint internal _snakesStolen;
    uint internal _frogsStolen;

    bool public mintAllowed;

    enum creatureType {
        FROG,
        SNAKE
    }

    mapping(address => uint) callerToLastActionBlock;

    /// @dev Constructor
    constructor() ERC721("FrogGame GEN1", "FrogGame GEN1") {
        owner=msg.sender;
    }

    /// @dev Return API endpoint with metadata
    function tokenURI(uint _tokenId) public view override noSameBlockAsAction returns (string memory) {
        require(_exists(_tokenId),"Not minted yet");
        return string(abi.encodePacked(_baseTokenURI, Strings.toString(_tokenId)));
    }

    //  _      _  __                     _      
    // | |    (_)/ _|                   | |     
    // | |     _| |_ ___  ___ _   _  ___| | ___ 
    // | |    | |  _/ _ \/ __| | | |/ __| |/ _ \
    // | |____| | ||  __/ (__| |_| | (__| |  __/
    // |______|_|_| \___|\___|\__, |\___|_|\___|
    //                         __/ |            
    //                        |___/             

    /// @dev Mint new token
    function mint(uint amount) external noCheaters onlyMintAllowed nonReentrant whenNotPaused {
        require(totalSupply() + amount <= MAX_SUPPLY, 'Max supply reached');
        require(amount > 0 && amount <= maxMintPerTx, "Invalid mint amount");

        address tokenReceiver;

        for (uint i = 0; i< amount;i++) {
            tokenReceiver = msg.sender;

            uint newTokenId;
            callerToLastActionBlock[tx.origin] = block.number;
            
            uint tadpolePrice = mintPriceTadpole();

            uint random = _randomize(_rand(), "creatureType", i) % 10000;

            // 10% chance to mint snake
            if (random < 1000) {
                // snakes tokens IDs start with 69K shift
                newTokenId=++_snakesTotal + snakeTypeShift;
            } else {
                // gen1 frogs tokens IDs start with 3K shift (gen0 total)
                newTokenId=++_frogsTotal + gen0TypeShift;
            }

            random = _randomize(_rand(), "stolen", newTokenId) % 10000;

            // 10% chance for token to be stolen
            if (random < 1000) {
                address randomSnakeOwner=pondContract.getRandomSnakeOwner();
                // randomSnakeOwner == nullAddress if no snakes staked in Pond
                if (randomSnakeOwner!=nullAddress) {
                    tokenReceiver=randomSnakeOwner;
                    newTokenId>snakeTypeShift?_snakesStolen++:_frogsStolen++;
                } 
            } 

            tadpoleContract.burnFrom(msg.sender, tadpolePrice);
            
            _mint(tokenReceiver, newTokenId);
        }
    }

    //  _    _ _   _ _ _ _         
    // | |  | | | (_) (_) |        
    // | |  | | |_ _| |_| |_ _   _ 
    // | |  | | __| | | | __| | | |
    // | |__| | |_| | | | |_| |_| |
    //  \____/ \__|_|_|_|\__|\__, |
    //                        __/ |
    //                       |___/ 

    /// @dev Create a bit more of randomness
    function _randomize(uint256 rand, string memory val, uint256 spicy) internal pure returns (uint256) {
        return uint256(keccak256(abi.encode(rand, val, spicy)));
    }

    /// @dev Get random uint
    function _rand() internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(msg.sender, block.timestamp, block.difficulty, block.timestamp, entropySauce)));
    }

    /// @dev Return current $TADPOLE mint price
    function mintPriceTadpole() public view returns (uint) {
        return ((5000+totalSupply())/mintPhaseStep*tadpolePhasePriceIncrease);
    }

    //   ____                              __                  _   _                 
    //  / __ \                            / _|                | | (_)                
    // | |  | |_      ___ __   ___ _ __  | |_ _   _ _ __   ___| |_ _  ___  _ __  ___ 
    // | |  | \ \ /\ / / '_ \ / _ \ '__| |  _| | | | '_ \ / __| __| |/ _ \| '_ \/ __|
    // | |__| |\ V  V /| | | |  __/ |    | | | |_| | | | | (__| |_| | (_) | | | \__ \
    //  \____/  \_/\_/ |_| |_|\___|_|    |_|  \__,_|_| |_|\___|\__|_|\___/|_| |_|___/

    function Pause() external onlyOwner {
        _pause();
    }

    function Unpause() external onlyOwner {
        _unpause();
    }

    /// @dev Set tadpole contract address and init interface with it
    function setTadpoleAddress(address _tadpoleAddress) external onlyOwner {
        tadpoleContract=ITadpole(_tadpoleAddress);
    }

    /// @dev Set pond contract address and init interface with it
    function setPondAddress(address _pondAddress) external onlyOwner {
        pondContract=IPond(_pondAddress);
    }

    /// @dev Set base address for Token URI, should end with leading slash
    function setBaseTokenURI(string memory baseURI_) external onlyOwner {
        _baseTokenURI=baseURI_;
    }

    /// @dev Switch mint allowed flag
    function switchMintAllowed() external onlyOwner {
        mintAllowed=!mintAllowed;
    }

    //  __  __           _ _  __ _               
    // |  \/  |         | (_)/ _(_)              
    // | \  / | ___   __| |_| |_ _  ___ _ __ ___ 
    // | |\/| |/ _ \ / _` | |  _| |/ _ \ '__/ __|
    // | |  | | (_) | (_| | | | | |  __/ |  \__ \
    // |_|  |_|\___/ \__,_|_|_| |_|\___|_|  |___/

    /// @dev Execute if mintAllowed flag set to True
    modifier onlyMintAllowed() {
        require(mintAllowed, 'Mint not allowed');
        _;
    }

    /// @dev Execute if msg.sender = owner
    modifier onlyOwner() {
        require(owner == msg.sender, "Caller is not the owner");
        _;
    }

    /// @dev Execute if tx.origin == msg.sender and caller is not a contract
    modifier noCheaters() {
        uint256 size = 0;
        address acc = msg.sender;
        assembly { size := extcodesize(acc)}

        require(msg.sender == tx.origin , "You're trying to cheat?");
        require(size == 0,                "You're trying to cheat?");
        _;

        // We'll use the last caller hash to add entropy to next caller
        entropySauce = keccak256(abi.encodePacked(acc, block.coinbase));
    }

    /// @dev don't allow view functions in same block as action that changed the state
    modifier noSameBlockAsAction() {
        if (msg.sender!=address(pondContract)) {
            require(callerToLastActionBlock[tx.origin] < block.number, "Please try again on next block");
        }
        _;
    }

    function snakesTotal() external view noSameBlockAsAction returns(uint) {
        return _snakesTotal;
    }

    function frogsTotal() external view noSameBlockAsAction returns(uint) { 
        return _frogsTotal;
    }

    function snakesStolen() external view noSameBlockAsAction returns(uint) { 
        return _snakesStolen;
    }

    function frogsStolen() external view noSameBlockAsAction returns(uint) { 
        return _frogsStolen;
    }
    function tokenOfOwnerByIndex(address _owner, uint256 index) public view virtual override(ERC721Enumerable) noSameBlockAsAction returns (uint256) {
        require(callerToLastActionBlock[_owner] < block.number, "Please try again on next block");
        return super.tokenOfOwnerByIndex(_owner, index);
    }
    
    function balanceOf(address _owner) public view virtual override(ERC721) noSameBlockAsAction returns (uint256) {
        require(callerToLastActionBlock[_owner] < block.number, "Please try again on next block");
        return super.balanceOf(_owner);
    }

    function ownerOf(uint256 tokenId) public view virtual override(ERC721) noSameBlockAsAction returns (address) {
        address addr = super.ownerOf(tokenId);
        require(callerToLastActionBlock[addr] < block.number, "Please try again on next block");
        return addr;
    }

    function walletOfOwner(address _wallet)
        public
        view
        noSameBlockAsAction
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_wallet);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_wallet, i);
        }
        return tokensId;
    }

    function transferFrom(
    address from,
    address to,
    uint256 tokenId
    ) public virtual override {
        if (msg.sender != address(pondContract)) {
            require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        }
        _transfer(from, to, tokenId);
    }

    function transferOwnership(address newOwner) external onlyOwner {
        owner = newOwner;
    }
}