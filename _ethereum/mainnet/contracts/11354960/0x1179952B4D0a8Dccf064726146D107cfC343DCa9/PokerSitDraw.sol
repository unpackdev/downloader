// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IERC721Enumerable.sol";


contract PokerSitDraw is Ownable {

    address public betNFT;
    address public prizeNFT;

    uint public game = 1;

    uint256 public maxParticipants = 12;

    uint256 public participantsNum = 0;

    // Accumalated Funds will be sent to this address
    address public poolAccumalator;

    //Game Locked
    bool public isLocked = false;

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    address public winningAddress;

    mapping(uint256 => mapping(uint256 => address)) public participants;

    uint256 private _status;

    event Game(uint256 game);
    event GameOver(uint256 game);
    event Participate(uint256 indexed game, address indexed participant, uint256 index, uint256 finalIndex);
    event Winner(uint256 indexed game, uint256 index, address participant);
    

    constructor(address _betNFT, address _prizeNFT,  address _poolAccumalator)
    public
    {
        betNFT = _betNFT;
        prizeNFT = _prizeNFT;
        revertZeroAddress(_poolAccumalator);
        poolAccumalator = _poolAccumalator;
        _status = _NOT_ENTERED;
        emit Game(1);

    }

    function sitInPoker() public{
        require(_status != _ENTERED, "reentrant call");
        _status = _ENTERED;
        require(msg.sender == tx.origin, "smart contracts are not allowed");
        require(!isLocked, "Draw is locked");
        IERC721Enumerable enumBetNFT = IERC721Enumerable(betNFT);
        require(checkForNFTBalance(msg.sender, enumBetNFT), "User has no KnightNFT");

        uint id = findTokenId(msg.sender,enumBetNFT);
        enumBetNFT.transferFrom(msg.sender,poolAccumalator,id);

        uint256 index = participantsNum;
        participantsNum = index + 1;

        participants[game][index] = msg.sender;


        if (participantsNum == maxParticipants) {
            _lock();
            if(checkForNFTBalance(address(this),IERC721Enumerable(prizeNFT))){ 
                draw();
                emit GameOver(game);
            }
        }

        _status = _NOT_ENTERED;

        emit Participate(game, msg.sender, index,participantsNum);
        
    }

    function draw() internal {
        require(isLocked == true, "is not locked, draw disabled");
        uint256 winningNumber = _chooseRandomNumber(participantsNum);
        address winner;
        IERC721Enumerable enumPrizeNFT = IERC721Enumerable(prizeNFT);
        winner = participants[game][winningNumber];
        winningAddress = winner;
        game = game + 1;
        participantsNum = 0;
        uint id = findTokenId(address(this), enumPrizeNFT);
        enumPrizeNFT.transferFrom(address(this),winner, id);
        _unlock();
        emit Game(game);
    }

    
    function manualDraw() public onlyOwner {
        require(checkForNFTBalance(address(this),IERC721Enumerable(prizeNFT)),"No prize for draw");
        draw();
    }

    function checkForNFTBalance(address user, IERC721Enumerable nft) internal view returns (bool) {
        if(nft.balanceOf(user) > 0){
            return true;
        }else{
            return false;
        }
    }

    function findTokenId(address findUser, IERC721Enumerable nft) internal view returns (uint tokenId){
        uint nftQty = nft.totalSupply();
         for (uint i = 1; i <= nftQty; i++) {
            address holder = nft.ownerOf(i);
            if (holder == findUser) return i;
        }
    }
    function _chooseRandomNumber(uint _participantsNum) internal view returns (uint256) {
        uint256 seed = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp +
                        block.difficulty +
                        ((
                            uint256(keccak256(abi.encodePacked(block.coinbase)))
                        ) / (now)) +
                        block.gaslimit +
                        ((uint256(keccak256(abi.encodePacked(msg.sender)))) /
                            (now)) +
                        block.number
                )
            )
        );

        return (seed - ((seed / (_participantsNum - 1)) * (_participantsNum - 1)));
    }

    function revertZeroAddress(address _address) private pure {
        require(_address != address(0), "zero address");
    }

    function updatePoolAccumalator(address _poolAccumalator)
        public
        onlyOwner
    {
        revertZeroAddress(_poolAccumalator);
        poolAccumalator = _poolAccumalator;
    }

    function _lock() internal {
        isLocked = true;
    }
    function _unlock() internal {
        isLocked = false;
    }
    function setLock(bool _isLocked) public onlyOwner {
        isLocked = _isLocked;
    }

    function withdrawAllPrizeNFT () public onlyOwner{
        require(checkForNFTBalance(address(this),IERC721Enumerable(prizeNFT)),"contract has no prize");
        IERC721Enumerable enumPrizeNFT  = IERC721Enumerable(prizeNFT);
        uint balance = enumPrizeNFT.balanceOf(address(this));
            for(uint i = 0 ; i < balance ; i++){
                uint id = findTokenId(address(this),enumPrizeNFT);
                enumPrizeNFT.transferFrom(address(this),poolAccumalator,id);
            }
    }

    function withdrawPrizeNFT(uint _id) public onlyOwner{
        require(checkForNFTBalance(address(this),IERC721Enumerable(prizeNFT)),"contract has no prize");
        IERC721Enumerable enumPrizeNFT  = IERC721Enumerable(prizeNFT);
        require(enumPrizeNFT.ownerOf(_id) == address(this), "this contract does not own this Token");
        enumPrizeNFT.transferFrom(address(this),poolAccumalator,_id);
    }

    function changeBetNFTAddress(address _betNFT) public onlyOwner{
        require(participantsNum == 0, "Please draw first");
        betNFT = _betNFT;
    }
    function changePrizeNFTAddress(address _prizeNFT) public onlyOwner{
        require(!checkForNFTBalance(address(this),IERC721Enumerable(prizeNFT)),"withdraw prize nft from contract first");
        prizeNFT = _prizeNFT;
    }
    function changeMaxParticipant(uint _maxParticipants) public onlyOwner{
        maxParticipants = _maxParticipants;
    }
}