//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract PreComputeFactory {
    event Deployed(address creationAddress, uint256 salt, bytes bytecode);

    function getBytecode() public pure returns (bytes memory) {
        bytes memory bytecode = type(Transmitter).creationCode;
        return abi.encodePacked(bytecode, abi.encode());
    }

    function getAddress(bytes memory bytecode_, uint256 salt_) public view returns (address) {
        bytes32 hash = keccak256(abi.encodePacked(bytes1(0xff), address(this), salt_, keccak256(bytecode_)));
        return address(uint160(uint256(hash)));
    }

    function deploy(bytes memory bytecode_, uint256 salt_) public payable {
        address addr;

        assembly {
            addr := create2(
                callvalue(), // msg.value
                add(bytecode_, 0x20), // pad by 32 bytes
                mload(bytecode_), // load the size of code contained in the first 32 bytes
                salt_
            )

            if iszero(extcodesize(addr)) {
                revert(0, 0)
            }
        }

        emit Deployed(addr, salt_, bytecode_);
    }

    function keccakTheBytecode(bytes memory bytecode_) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(bytecode_));
    }
}

abstract contract Ownable {

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    address public owner;

    constructor() { 
        owner = msg.sender; 
    }
    
    modifier onlyOwner { 
        require(owner == msg.sender, "onlyOwner not owner!");
        _; 
    }
    
    function transferOwnership(address new_) external onlyOwner {
        address _old = owner;
        owner = new_;
        emit OwnershipTransferred(_old, new_);
    }
}

interface IMTM {
    function messageToMartians() external view returns (string memory);
    // true if usable, false if used
    function getTransponderStatus(uint tokenId_) external view returns (bool); 
}

interface IMartians {
    function ownerOf(uint256 tokenId_) external view returns (address);
}

interface ICS {
    struct Character {
        uint8  race_;
        uint8  renderType_;
        uint16 transponderId_;
        uint16 spaceCapsuleId_;
        uint8  augments_;
        uint16 basePoints_;
        uint16 totalEquipmentBonus_;
    }

    function characters(uint256 tokenId_) external view returns (Character memory);
}

interface IERC721 {
    function ownerOf(uint256 tokenId_) external view returns (address);
}

interface IERC20 {
    function transferFrom(address from_, address to_, uint256 amount_) external
    returns (bool);
}

library TransmitterLib {
    function onlyAllowedCharacters(bytes memory stringBytes_) 
    internal pure returns (bool) {
        uint _strLen = stringBytes_.length;

        for (uint i = 0; i < _strLen;) {
            bytes1 _letterBytes1 = stringBytes_[i];
            bytes1 _bottomBytes = 0x21; // 0x20 is spaces, we don't allow it
            
            // Character Filters
            if ( _letterBytes1 <  _bottomBytes ||
                 _letterBytes1 >  0x7A || 
                 _letterBytes1 == 0x26 || 
                 _letterBytes1 == 0x22 || 
                 _letterBytes1 == 0x3C || 
                 _letterBytes1 == 0x3E) {
                return false;
            }

            unchecked { ++i; }
        }
        return true;
    }
}

contract Transmitter is Ownable {

    /*
        Transmitter:

        Read from MessageToMartians for the current written messages
        Read from MessageToMartains for the transponder status

        Read Transponder and Martian->Transponder for transponder writing

        Mark Transponder / Martian->Transponder as written, and deduct X $MES
    */

    //////////////////////
    ///// Interfaces /////
    //////////////////////
    IMTM public MTM = IMTM(0x8510b7b968F6664136F557b079CE79F72D5b4AAB);

    IMartians public Martians = IMartians(0x680903545Eb03aC212910eF558F438DA3b867590);

    ICS public CS = ICS(0xC7C40032E952F52F1ce7472913CDd8EeC89521c4);

    IERC721 public Transponders = IERC721(0x9d00D9b009Ab80a18013675011c93796d89de6B4);

    IERC20 public MES = IERC20(0x3C2Eb40D25a4b2B5A068a959a40d57D63Dc98B95);

    ///////////////////
    ///// Configs /////
    ///////////////////
    uint256 public costPerCharacter = 1 ether;

    ////////////////////////////////////
    ///// Administrative Functions /////
    ////////////////////////////////////
    function O_setContracts(address mtm_, address martians_, address cs_,
    address transponders_, address mes_) external onlyOwner {
        if (mtm_ != address(0)) MTM = IMTM(mtm_);
        if (martians_ != address(0)) Martians = IMartians(martians_);
        if (cs_ != address(0)) CS = ICS(cs_);
        if (transponders_ != address(0)) Transponders = IERC721(transponders_);
        if (mes_ != address(0)) MES = IERC20(mes_);
    }
    function O_setCostPerCharacter(uint256 costPerCharacter_) external onlyOwner {
        costPerCharacter = costPerCharacter_;
    }
    
    //////////////////////////////
    ///// Validation Helpers /////
    //////////////////////////////
    function getTransponderId(uint256 tokenId_) public view returns (uint256) {
        return CS.characters(tokenId_).transponderId_;
    }

    function transponderIsUsable(uint256 tokenId_) public view returns (bool) {
        if (bytes(transponderToMessage[tokenId_]).length > 0) return false;
        if (MTM.getTransponderStatus(tokenId_) != true) return false;
        return true;
    }

    function transpondersAreUsable(uint256[] calldata tokenIds_) external view returns (bool[] memory) {
        bool[] memory _transpondersUsable = new bool[] (tokenIds_.length);
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            _transpondersUsable[i] = transponderIsUsable(tokenIds_[i]);
        }
        return _transpondersUsable;
    }

    function characterIsUsable(uint256 tokenId_) external view returns (bool) {
        uint256 _transponderId = CS.characters(tokenId_).transponderId_;
        return transponderIsUsable(_transponderId);
    }

    function charactersAreUsable(uint256[] calldata tokenIds_) external view returns (bool[] memory) {
        bool[] memory _charactersUsable = new bool[] (tokenIds_.length);
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            uint256 _transponderId = CS.characters(tokenIds_[i]).transponderId_;
            _charactersUsable[i] = transponderIsUsable(_transponderId);
        }
        return _charactersUsable;
    }

    //////////////////////////
    ///// Write Messages /////
    //////////////////////////
    uint16[] public messages;
    
    mapping(uint256 => string) public transponderToMessage;

    event Transmission(address indexed writer, string message);

    function _writeMessage(uint256 transponderId_, string memory word_) private {
        // The message must be within 32 characters
        bytes memory _wordBytes = bytes(word_); // Transform string to bytes
        require(_wordBytes.length < 33, 
                "Message exceeds 32 characters");
        
        // The message must not contain illegal characters
        require(TransmitterLib.onlyAllowedCharacters(_wordBytes),
                "Message contains illegal characters!");

        // Deduct $MES from user 
        uint256 _totalCost = _wordBytes.length * costPerCharacter;
        
        // NOTE: consider using SafeTransferLib
        require(MES.transferFrom(msg.sender, address(this), _totalCost),
                "$MES Deduction Failed!");

        // Write to transponderToMessage connection
        transponderToMessage[transponderId_] = word_;

        // Write transponderId to messages -- this is used to reconstruct the message
        // We store in this way to save SSTOREs compared to other methods and retain
        // a mapping / connection between transponder to message AND message order.
        messages.push(uint16(transponderId_)); 

        // Emit the Transmission event
        emit Transmission(msg.sender, word_);
    }

    function writeWithTransponder(uint256 tokenId_, string calldata word_) external {
        // Validate ownership of Transponder
        require(msg.sender == Transponders.ownerOf(tokenId_), 
                "Not owner!");

        // Validate that the Transponder hasn't been used before
        require(transponderIsUsable(tokenId_),
                "Transponder has been used!");

        _writeMessage(tokenId_, word_);
    }

    function writeWithCharacter(uint256 tokenId_, string calldata word_) external {
        // Validate ownership of Character
        require(msg.sender == Martians.ownerOf(tokenId_),
                "Not owner!");

        // Retrieve the Transponder ID from Character
        uint256 _transponderId = getTransponderId(tokenId_);

        // Validate that the Transponder hasn't been used before
        require(transponderIsUsable(_transponderId), 
                "Transponder has been used!");

        _writeMessage(_transponderId, word_);
    }

    /////////////////////////
    ///// Read Messages /////
    /////////////////////////
    function readMessagePaginated(uint256 from_, uint256 to_, 
    bool getFirstMessage_) public view returns (string[] memory) {
        
        // Create the length of the message
        uint256 l = to_ - from_ + 1;
        
        // If getFirstMessage_ is TRUE, extend length by 1 and download from MTM
        if (getFirstMessage_) {
            unchecked { 
                l++;
            }
        }

        // Create the loop index
        uint256 _index = getFirstMessage_ ? 1 : 0;

        // Create the string array
        string[] memory _message = new string[] (l);

        // Loop through messages and populate the string array
        for (uint256 i = from_; i <= to_;) {
            // Store the string into _message using string encoding
            _message[_index] = 
                string(abi.encodePacked(transponderToMessage[messages[i]]));
            unchecked { ++i; ++_index; }
        }

        // If we have the first message, insert it in the first index
        if (getFirstMessage_) _message[0] = MTM.messageToMartians();

        // Return the message
        return _message;
    }

    function readMessageAll() external view returns (string[] memory) {
        return readMessagePaginated(0, (messages.length - 1), true);
    }

    function getMessageOrder() external view returns (uint16[] memory) {
        return messages;
    }
}