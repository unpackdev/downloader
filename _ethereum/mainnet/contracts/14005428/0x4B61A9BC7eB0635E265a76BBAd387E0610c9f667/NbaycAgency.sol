// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "./Ownable.sol";
import "./ERC20.sol";
import "./ERC721.sol";
import "./ReentrancyGuard.sol";

import "./ERC721A.sol";

import "./StakeApe.sol";
import "./IAgency.sol";

import "./console.sol";

interface ITokenBall {
    function mintReward(address recipient, uint amount) external;
    function burnMoney(address recipient, uint amount) external;
}


/**
 * Headquarter of the New Basketball Ape Young Crew Agency
 * Organize matches, stakes the Apes for available for rent, sends rewards, etc
 */
contract NbaycAgency is IAgency, Ownable, ERC721A, ReentrancyGuard {

    address apeAddress;
    address ballAddress;

    bool closed = false;

    mapping(address => bool) admins;

    uint private maxSupply = 5000;
    mapping(uint => StakeApe) idToStakeApe;
    mapping(address => uint[]) ownerToArrTokenIds;

    constructor(address adminAddr, address _ape, address _ball) ERC721A("NBAYCAgency", "NBAYCA", 10, 50000) ReentrancyGuard() {
        admins[adminAddr] = true;
        apeAddress = _ape;
        ballAddress = _ball;
    }

    //
    //// Utility functions
    //

    /** Put Apes into agency. Will transfer 721 tokens to the agency in order to play.
     */
    function putApesToAgency(uint[] memory ids, address owner) override external onlyAdmin {
        require(!closed, "The agency is closed. No more Apes can come in for now ;)");
        for (uint i = 0; i < ids.length; i++) {
            require(IERC721(apeAddress).ownerOf(ids[i]) == owner, "You cannot add an Ape that is not yours ...");
            idToStakeApe[ids[i]] = StakeApe(ids[i], owner, 'N', 0);
            ownerToArrTokenIds[owner].push(ids[i]);
            IERC721(apeAddress).transferFrom(
                owner,
                address(this),
                ids[i]
            );
        }
    }

    /** Transfer back the Apes from the Agency to original owner's wallet.
     */
    function getApesFromAgency(uint[] memory ids, address owner) override external onlyAdmin {
        for (uint i = 0; i < ids.length; i++) {
            require(idToStakeApe[ids[i]].owner == owner, "You cannot get an Ape that is not yours ...");
            require(idToStakeApe[ids[i]].state == 'N', "This Ape is not on bench ... Stop his activity before.");
            delete idToStakeApe[ids[i]];
            remove(ownerToArrTokenIds[owner], ids[i]);
            IERC721(apeAddress).transferFrom(
                address(this), 
                owner, 
                ids[i]
            );
        }
    }

    //
    // Get/Set functions :
    //

    function remove(uint[] storage arr, uint element) private {
        bool r = false;
        for (uint256 i = 0; i < arr.length - 1; i++) {
            if (r) arr[i] = arr[i + 1];
            if (arr[i] == element) r = true;
        }
        arr.pop();
    }

    function setStateForApes(uint[] memory ids, address sender, bytes1 newState) external override onlyAdmin {
        for (uint i=0; i<ids.length; i++) {
            require(idToStakeApe[ids[i]].state != newState, "This ape is already in this state ...");
            require(idToStakeApe[ids[i]].owner == sender, "Must be the original owner of the ape");
            idToStakeApe[ids[i]].state = newState;
            idToStakeApe[ids[i]].stateDate = block.timestamp;
        }
    }

    function stopStateForApe(uint id, address sender) external override onlyAdmin returns(uint) {
        require(idToStakeApe[id].state != 'N', "This ape is doing nothing ...");
        require(idToStakeApe[id].owner == sender, "Must be the original owner of the ape");
        uint duration = (block.timestamp - idToStakeApe[id].stateDate) / 60;
        idToStakeApe[id].state = 'N';
        idToStakeApe[id].stateDate = 0;
        console.log("End of training for %s", id);
        return duration;
    }



    //
    // Admin functions :
    //

    function getOwnerApes(address a) external view override returns(uint[] memory) {
        return ownerToArrTokenIds[a];
    }

    function getApe(uint id) external view override returns(uint256,address,bytes1,uint256) {
        return (idToStakeApe[id].tokenId, idToStakeApe[id].owner, idToStakeApe[id].state, idToStakeApe[id].stateDate);
    }

    function setApeState(uint id, bytes1 state, uint256 date) external override onlyAdmin {
        idToStakeApe[id].state = state;
        idToStakeApe[id].stateDate = date;
    }

    function transferApesBackToOwner() external override onlyAdmin {
        for (uint i = 1; i < maxSupply; i++) {
            if (idToStakeApe[i].owner != address(0)) {
                address owner = idToStakeApe[i].owner;
                delete idToStakeApe[i];
                IERC721(apeAddress).transferFrom(
                    address(this), 
                    owner,
                    i
                );
            }
        }
    }

    // function transferApesToNewContract (address newContract) external onlyAdmin {
    //     //
    //     Address(this).transfer();
    // }

    function setClosed (bool c) public onlyAdmin {
        closed = c;
    }
    
    function setMaxSupply (uint m) public onlyAdmin {
        maxSupply = m;
    }
    
    modifier onlyAdmin {
        require(admins[msg.sender], "Only admins can call this");
        _;
    }

    function setAdmin(address addr) public onlyAdmin {
        admins[addr] = true;
    }
    
    function unsetAdmin(address addr) public onlyAdmin {
        delete admins[addr];
    }

    function setContracts(address _ape, address _ball) external onlyAdmin {
        apeAddress = _ape;
        ballAddress = _ball;
    }
}

