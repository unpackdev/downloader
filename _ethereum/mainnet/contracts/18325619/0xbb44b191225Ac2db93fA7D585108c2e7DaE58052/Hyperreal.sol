// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

/**
 * @title Hyperreal ERC20 Token Contract
 * @dev Inherits from OpenZeppelin ERC20 and Ownable
 * __, _, _  _,  ____,  ____,  ____,  ____,  ____,  ____, __,
 * |__| (-\_/  (-|__) (-|_,  (-|__) (-|__) (-|_,  (-/_| (-|  
 *_|  |,  _|,   _|     _|__,  _|  \, _|  \, _|__, _/  |, _|__,
 *              https://www.hyperreal.io
 */

import "./ERC20.sol";
import "./Ownable.sol";

contract Hyperreal is ERC20, Ownable {
    uint public lockTimestamp;
    uint public advisorMinted; // Advisors & Personnel
    uint public communityMinted; // Community Contributors
    uint public partnerMinted; // Partnerships
    uint private immutable mintLimit = 100_000_000 * 10 ** decimals();
    mapping(address => uint) public lockedAddresses;

    event AdvisorMinted(address _to, uint _amount);
    event CommunityMinted(address _to, uint _amount);
    event PartnerMinted(address _to, uint _amount);

    /**
     * @notice Sets the contract's name, ticker and current timestamp
     *  mints initial distribution including vested team tokens in contract
     * @param _team The address to send the team's initial token grant to
     */
    constructor(address _team) ERC20("Hyperreal", "DDNA") Ownable(msg.sender) {
        lockTimestamp = block.timestamp;
        _mint(msg.sender, 600_000_000 * 10 ** decimals());
        _mint(_team, 50_000_000 * 10 ** decimals());
        _mint(address(this), 50_000_000 * 10 ** decimals());
    }

    /**
     * @notice Relock team's tokens for another year from the date this is called
     */
    function relockTeamTokens() public onlyOwner {
        lockTimestamp = block.timestamp;
    }

    /**
     * @notice Unlock team's tokens after a year has passed since deployment
     * @param _to The address to send the unlocked team tokens to
     */
    function unlockTeamTokens(address _to) public onlyOwner {
        require (block.timestamp > lockTimestamp + 365 days);
        _transfer(address(this), _to, 50_000_000 * 10 ** decimals());
    }

    /**
     * @notice Mints tokens for advisors and personnel
     * @param _to The address to send newly minted advisor tokens to
     * @param _amount The number of tokens to mint
     */
    function mintAdvisor(address _to, uint _amount) public onlyOwner {
        require(advisorMinted + _amount <= mintLimit, "exceeds mint limit");
        advisorMinted += _amount;
        _mint(_to, _amount);
        emit AdvisorMinted(_to, _amount);
    }

    /**
     * @notice Mints tokens and locks wallet for advisors and personnel
     * @param _to The address to send newly minted advisor tokens to
     * @param _amount The number of tokens to mint
     * @param _timestamp The timestamp that the tokens unlock
     */
    function mintLockedAdvisor(address _to, uint _amount, uint _timestamp) public onlyOwner {
        require(advisorMinted + _amount <= mintLimit, "exceeds mint limit");
        require(balanceOf(_to) == 0, "can not lock existing holder");
        advisorMinted += _amount;
        _mint(_to, _amount);
        emit AdvisorMinted(_to, _amount);
        lockedAddresses[_to] = _timestamp;
    }

    /**
     * @notice Mints tokens for community contributors
     * @param _to The address to send newly minted community tokens to
     * @param _amount The number of tokens to mint
     */
    function mintCommunity(address _to, uint _amount) public onlyOwner {
        require(communityMinted + _amount <= mintLimit, "exceeds mint limit");
        communityMinted += _amount;
        _mint(_to, _amount);
        emit CommunityMinted(_to, _amount);
    }

    /**
     * @notice Mints tokens and locks wallet for community contributors
     * @param _to The address to send newly minted community tokens to
     * @param _amount The number of tokens to mint
     * @param _timestamp The timestamp that the tokens unlock
     */
    function mintLockedCommunity(address _to, uint _amount, uint _timestamp) public onlyOwner {
        require(communityMinted + _amount <= mintLimit, "exceeds mint limit");
        require(balanceOf(_to) == 0, "can not lock existing holder");
        communityMinted += _amount;
        _mint(_to, _amount);
        emit CommunityMinted(_to, _amount);
        lockedAddresses[_to] = _timestamp;
    }

    /**
     * @notice Mints tokens for partners
     * @param _to The address to send newly minted partner tokens to
     * @param _amount The number of tokens to mint
     */
    function mintPartner(address _to, uint _amount) public onlyOwner {
        require(partnerMinted + _amount <= mintLimit, "exceeds mint limit");
        partnerMinted += _amount;
        _mint(_to, _amount);
        emit PartnerMinted(_to, _amount);
    }

    /**
     * @notice Mints tokens and locks wallet for partners
     * @param _to The address to send newly minted partner tokens to
     * @param _amount The number of tokens to mint
     * @param _timestamp The timestamp that the tokens unlock
     */
    function mintLockedPartner(address _to, uint _amount, uint _timestamp) public onlyOwner {
        require(partnerMinted + _amount <= mintLimit, "exceeds mint limit");
        require(balanceOf(_to) == 0, "can not lock existing holder");
        partnerMinted += _amount;
        _mint(_to, _amount);
        emit PartnerMinted(_to, _amount);
        lockedAddresses[_to] = _timestamp;
    }

    /**
     * @dev internal override function to restrict locked addresses
     * @param sender address of the sender of funds
     * @param recipient address of the receiver of funds
     * @param amount amount of funds in wei (18 decimals)
     */
    function _update(address sender, address recipient, uint256 amount) internal override {
        require (lockedAddresses[sender] < block.timestamp, "address is still locked");
        super._update(sender, recipient, amount);
    }

}