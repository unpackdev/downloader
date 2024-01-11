// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC20.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ECDSA.sol";

/*
    __________       __               ___________                   __  .__                  
    \______   \____ |  | __ __________\__    ___/___   ____   _____/  |_|  |__   ___________ 
    |     ___/  _ \|  |/ // __ \_  __ \|    | /  _ \ / ___\_/ __ \   __\  |  \_/ __ \_  __ \
    |    |  (  <_> )    <\  ___/|  | \/|    |(  <_> ) /_/  >  ___/|  | |   Y  \  ___/|  | \/
    |____|   \____/|__|_ \\___  >__|   |____| \____/\___  / \___  >__| |___|  /\___  >__|   
                        \/    \/                   /_____/      \/          \/     \/       
 */

contract PokerGold is ERC20, Ownable, ReentrancyGuard {

    event DepositEvent(address account, uint256 value, uint256 timestamp);
    event ClaimEvent(address account, uint256 value, uint256 salt);

    mapping(address=>uint256) public claimMapping;
    address signer;
    bool contractPaused;

    constructor(address signer_) ERC20("PokerTogether Gold", "GOLD") {
        signer = signer_;
    }

    function depositGold(uint256 value_) external nonReentrant contractNotPaused callerIsUser {
        require(value_ >= 10 ** uint256(decimals()), "value must greater than one");
        require(balanceOf(_msgSender()) >= value_, "not enough gold");
        _burn(_msgSender(), value_);
        emit DepositEvent(_msgSender(), value_, block.timestamp);
    }

    function claimGold(uint256 salt_, uint256 value_, bytes memory signature_) external nonReentrant contractNotPaused callerIsUser {
        require(value_ >= 10 ** uint256(decimals()), "value must greater than one");
        require(salt_ > claimMapping[_msgSender()], "salt already used");
        require(verifySignature(salt_, value_, signature_), "invalid signature");
        claimMapping[_msgSender()] = salt_;
        _mint(_msgSender(), value_);
        emit ClaimEvent(_msgSender(), value_, salt_);
    }

    function verifySignature(uint256 salt_, uint256 value_, bytes memory signature_) internal view returns (bool) {
        bytes32 message = ECDSA.toEthSignedMessageHash(keccak256(abi.encodePacked(salt_, value_, _msgSender(), this)));
        return (ECDSA.recover(message, signature_) == signer);
    }

    function changeSigner(address signer_) external onlyOwner{
        signer = signer_;
    }

    function pauseContract(bool pause_) external onlyOwner{
        contractPaused = pause_;   
    }

    function digGold(address account, uint256 value) external onlyOwner nonReentrant{
        value = value * 10 ** uint256(decimals());
        _mint(account, value);
    }

    modifier contractNotPaused() {
        require(!contractPaused, "contract is paused");
        _;
    }

    modifier callerIsUser() {
        require(tx.origin == _msgSender(), "caller is another contract");
        _;
    }
}