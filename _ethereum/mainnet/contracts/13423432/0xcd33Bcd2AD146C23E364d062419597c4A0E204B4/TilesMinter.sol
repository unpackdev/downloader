//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./SafeMath.sol";
import "./AccessControl.sol";
import "./Pausable.sol";
import "./IERC721.sol";
import "./TilesBlocksCore.sol";
import "./TilesPanelsCore.sol";

contract TilesMinter is Pausable {
    
    uint256 public constant BLOCK_PRICE = 5*10**16; //price 0.05 eth
    uint256 public constant EMPTY_PANEL_PRICE_2 = 0;
    uint256 public constant EMPTY_PANEL_PRICE_6 = 0;
    uint256 public constant EMPTY_PANEL_PRICE_4 = 1*10**18;
    uint256 public constant EMPTY_PANEL_PRICE_9 = 15*10**17;
    uint256 public constant EMPTY_PANEL_PRICE_16 = 2*10**18;
    uint256 public constant EMPTY_PANEL_PRICE_25 = 4*10**18;
    uint256 public constant EMPTY_PANEL_PRICE_36 = 8*10**18;

    address internal coreBlocksAddress;
    address internal corePanelsAddress;
    address public adminAddress;
    address internal framAddress;
    address internal pulsAddress;
    bool public panelMintStarted = false;
    uint256 public panelMintStartBlock;
    uint256 public panelBlockLimit = 5*60*24*365; //12 months
    using SafeMath for uint256;

    modifier whenNotPausedOrIsAdmin() {
        require(!paused() || _msgSender() == adminAddress, "Pausable: paused");
        _;
    }

    modifier onlyAdmin() {
        require(_msgSender() == adminAddress, "Only the admin can do this");
        _;
    }

    constructor(address _coreBlocksAddress, address _corePanelsAddress, address _admin, address _framAddress, address _pulsAddress)  {
        coreBlocksAddress = _coreBlocksAddress;
        corePanelsAddress = _corePanelsAddress;
        framAddress = _framAddress;
        pulsAddress = _pulsAddress;
        adminAddress = _admin;

        _pause();

    }

    function pause() public onlyAdmin {
        _pause();
    }

    function unpause() public onlyAdmin {
        _unpause();
    }

    function startPanelMint() public onlyAdmin {
        panelMintStarted = true;
        panelMintStartBlock = block.number;
    }

    function setPanelBlockLimit(uint256 _value) public onlyAdmin {
        panelBlockLimit = _value;
    }

    function _isValidLength(uint256 len) internal pure returns(bool) {
        return (len == 2 ||
                len == 4 ||
                len == 6 ||
                len == 9 ||
                len == 16 ||
                len == 25 ||
                len == 36);
    }

    function getEmptyPanelPrice(uint _size) public pure returns(uint256) {
        if (_size == 2)
            return EMPTY_PANEL_PRICE_2;
        if (_size == 4)
            return EMPTY_PANEL_PRICE_4;
        if (_size == 6)
            return EMPTY_PANEL_PRICE_6;
        if (_size == 9)
            return EMPTY_PANEL_PRICE_9;
        if (_size == 16)
            return EMPTY_PANEL_PRICE_16;
        if (_size == 25)
            return EMPTY_PANEL_PRICE_25;
        if (_size == 36)
            return EMPTY_PANEL_PRICE_36;
        return 0;
    }

    function mintBlocks(uint256 n) payable external whenNotPausedOrIsAdmin {
        require(n<=20, "You can only mint up to 20 in the same transaction");
        uint256 totalMaxBlocks =  TilesBlocksCore(coreBlocksAddress).genesisMintLimit();
        uint256 totalMints = TilesBlocksCore(coreBlocksAddress).totalMints();
        require(totalMints < totalMaxBlocks, "All Blocks were already minted");
        if (totalMaxBlocks -  totalMints < 20)
            n = totalMaxBlocks - totalMints;

        uint price = BLOCK_PRICE.mul(n);
        require (msg.value >= price, "Insuficient ether sent");

        uint returnAmount = msg.value.sub(price);
        TilesBlocksCore(coreBlocksAddress).mintGenesis(msg.sender, n);

        if (returnAmount > 0)
            payable(msg.sender).transfer(returnAmount);
    }

    function burnToMintBlocks(uint256[] memory tokenIds) external whenNotPausedOrIsAdmin {
        uint256 totalMaxBlocks =  TilesBlocksCore(coreBlocksAddress).genesisMintLimit();
        uint256 totalMints = TilesBlocksCore(coreBlocksAddress).totalMints();
        require(totalMints >= totalMaxBlocks, "Burns can only start after all Blocks are minted");
        
        TilesBlocksCore(coreBlocksAddress).burnToMint(tokenIds, msg.sender);
    }

    function isEmergence(address user) public view returns (bool) {
        return IERC721(pulsAddress).balanceOf(user) > 0 ||
                        IERC721(framAddress).balanceOf(user) > 0;
    }

    function mintPanel(string memory _name, string memory _desc, uint16 _size, uint256[] memory _blocksTokenIds) payable external whenNotPausedOrIsAdmin {
        require(block.number > panelMintStartBlock + 10 || _blocksTokenIds.length == 0, " In the first 10 blocks, you can only mint empty panels");
        require(_isValidLength(_size), "Invalid size");
        require(panelMintStarted, "Panel mint hasn't started");
        require(block.number < panelMintStartBlock+panelBlockLimit, "Mint period is over");
        require(validateString(_name, 36), "Name is invalid");
        require(validateString(_desc, 255), "Description is invalid");

        if (_size == _blocksTokenIds.length) {
            if(_size == 2) 
                require(msg.sender == adminAddress, "Only the owner can mint 2x1 Panels");
            if(_size == 6)
                require(isEmergence(msg.sender) || msg.sender == adminAddress, "Only Emergence holders can mint 3x2 Panels");
                
            // all verifications are done in the Panel contract
            TilesPanelsCore(corePanelsAddress).mintGenesis(msg.sender, _name, _desc, _size, _blocksTokenIds);
            require (msg.value == 0, "no payment needed");
        }
        else if (_blocksTokenIds.length == 0) {
            require(_size != 6 && _size != 2, "2x1 and 3x2 Panels cannot be empty");
            uint price = getEmptyPanelPrice(_size);

            require (msg.value == price, "Wrong ether ammout");

            TilesPanelsCore(corePanelsAddress).mintGenesis(msg.sender,  _name, _desc, _size, _blocksTokenIds);
            
        }
        else
            require (_size == _blocksTokenIds.length, "Size differs from blocks count. Partial Panels not allowed");
    }

    function deconstructPanel(uint256 _tokenId) external whenNotPausedOrIsAdmin {
        require(msg.sender == TilesPanelsCore(corePanelsAddress).ownerOf(_tokenId), "Caller is not the owner");
        require(block.number < panelMintStartBlock+panelBlockLimit, "Deconstruct period is over");
        TilesPanelsCore(corePanelsAddress).deconstruct(_tokenId);
    }

    function fillEmptyToken(uint256 _tokenId, string memory _name, string memory _desc, uint256[] memory _blocksTokenIds) external whenNotPausedOrIsAdmin {
        require(block.number < panelMintStartBlock+panelBlockLimit, "Fill period is over");
        require(msg.sender == TilesPanelsCore(corePanelsAddress).ownerOf(_tokenId), "Caller is not the owner");
        require(validateString(_name, 36), "Name is invalid");
        require(validateString(_desc, 255), "Description is invalid");
        TilesPanelsCore(corePanelsAddress).fillEmptyToken(_tokenId,  _name,  _desc, _blocksTokenIds);
    }

    function withdrawEther() external onlyAdmin {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }       

    function validateString(string memory str, uint16 maxChars) public pure returns (bool){
        bytes memory b = bytes(str);
        if(b.length == 0) return true;
        if(b.length > maxChars) return false; // Cannot be longer than maxChars characters
        if(b[0] == 0x20) return false; // Leading space
        if (b[b.length - 1] == 0x20) return false; // Trailing space
        
        bytes1 lastChar = b[0];

        for(uint i; i<b.length; i++){
            bytes1 char = b[i];

            if (char == 0x20 && lastChar == 0x20) return false; // Cannot contain continous spaces

            if(char == 0x3E || char == 0x3C)
                return false;

            lastChar = char;
        }

        return true;
    }
}