// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "./AddressSet.sol";
import "./ISatellite.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

contract ICHIPowah is Ownable {

    using SafeMath for uint;
    using AddressSet for AddressSet.Set;

    uint public constant PRECISION = 100;

    bytes32 constant NULL_DATA = "";

    // a Constituency contains balance information that can be interpreted by an interpreter
    struct Constituency {
        address interpreter;
        uint16 weight; // 100 = 100%
        bytes32 params;
    }
    // constituency address => details
    mapping(address => Constituency) public constituencies; 
    // interable key set with delete
    AddressSet.Set constituencySet;

    event NewConstituency(address instance, address interpreter, uint16 weight, bytes32 params);
    event UpdateConstituency(address instance, address interpreter, uint16 weight, bytes32 params);
    event DeleteConstituency(address instance);

    /**
     * @notice user voting power reported through a normal ERC20 function 
     * @param user the user to inspect
     * @param powah user's voting power
     */    
    function balanceOf(address user) public view returns(uint powah) {
        uint count = constituencySet.count();
        for(uint i=0; i<count; i++) {
            address instance = constituencySet.keyAtIndex(i);
            Constituency storage c = constituencies[instance];
            powah = powah.add(ISatellite(c.interpreter).getPowah(instance, user, c.params).mul(c.weight).div(PRECISION));
        }
    }

    /**
     * @notice adjusted total supply factor (for computing quorum) is the weight-adjusted sum of all possible votes
     * @param supply the total number of votes possible given circulating supply and weighting
     */
    function totalSupply() public view returns(uint supply) {
        uint count = constituencySet.count();
        for(uint i=0; i<count; i++) {
            address instance = constituencySet.keyAtIndex(i);
            Constituency storage c = constituencies[instance];
            supply = supply.add(ISatellite(c.interpreter).getSupply(instance).mul(c.weight).div(PRECISION));
        }
    }

    /*********************************
     * Discoverable Internal Structure
     *********************************/

    /**
     * @notice count configured constituencies
     * @param count number of constituencies configured
     */
    function constituencyCount() public view returns(uint count) {
        count = constituencySet.count();
    }

    /**
     * @notice enumerate the configured constituencies
     * @param index row number to inspect
     * @param constituency address of the contract where tokens are staked
     */
    function constituencyAtIndex(uint index) public view returns(address constituency) {
        constituency = constituencySet.keyAtIndex(index);
    }

    /*********************************
     * CRUD
     *********************************/

    /**
     * @notice insert a new constituency to start counting as voting power
     * @param constituency address of the contract to inspect
     * @param interpreter address of the satellite that can interact with the type of contract at constituency address 
     * @param weight scaling adjustment to increase/decrease voting power. 100 = 100% is correct in most cases
     */
    function insertConstituency(address constituency, address interpreter, uint16 weight, bytes32 params) external onlyOwner {
        constituencySet.insert(constituency, "ICHIPowah: constituency is already registered.");
        Constituency storage c = constituencies[constituency];
        c.interpreter = interpreter;
        c.weight = weight;
        c.params = params;
        emit NewConstituency(constituency, interpreter, weight, params);
    }

    /**
     * @notice delete a constituency to stop counting as voting power
     * @param constituency address of the contract to stop inspecting
     */
    function deleteConstituency(address constituency) external onlyOwner {
        constituencySet.remove(constituency, "ICHIPowah: unknown instance");
        delete constituencies[constituency];
        emit DeleteConstituency(constituency);
    }

    /**
     * @notice update a constituency by overwriting all values (safe to remove and use 2-step delete, re-add)
     * @param constituency address of the contract to inspect
     * @param interpreter address of the satellite that can interact with the type of contract at constituency address 
     * @param weight scaling adjustment to increase/decrease voting power. 100 = 100% is correct in most cases
     */
    function updateConstituency(address constituency, address interpreter, uint16 weight, bytes32 params) external onlyOwner {
        require(constituencySet.exists(constituency), "ICHIPowah unknown constituency");
        Constituency storage c = constituencies[constituency];
        c.interpreter = interpreter;
        c.weight = weight;
        c.params = params;
        emit UpdateConstituency(constituency, interpreter, weight, params);
    }

}