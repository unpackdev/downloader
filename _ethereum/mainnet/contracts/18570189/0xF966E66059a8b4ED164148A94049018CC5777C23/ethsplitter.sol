pragma solidity 0.8.20;

// SPDX-License-Identifier: MIT

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract EthSplitter is Ownable {
    
    address public revShareAddress = address(0x7635bfDc1484f29A7e2b33F456a7F61200Fa305a);
    address public teamAddress_1 = address(0x57817BEF1B1D513D097A1d5249422C352cBaE649);
    address public teamAddress_2 = address(0x9ED55BA3B453d4d56404F3b221897F7ceD11Df71);
    address public teamAddress_3 = address(0x86eB8AF55a017c4935A7c08034B53389d4b09DFA);

    
    struct DistributionPercentages {
        uint24 revSharePerc;
        uint24 team1Perc;
        uint24 team2Perc;
        uint24 team3Perc;
    }

    DistributionPercentages public distributionPercs;

    constructor(){
        distributionPercs.revSharePerc = 50;
        distributionPercs.team1Perc = 20;
        distributionPercs.team2Perc = 10;
        distributionPercs.team3Perc = 20;
        require(distributionPercs.revSharePerc + distributionPercs.team1Perc + distributionPercs.team2Perc + distributionPercs.team3Perc == 100, "Must equal 100%");
    }
    

    receive() external payable {
        distributeETH();
    }
    
    function updateRevShareAddress(address _address) external onlyOwner {
        require(_address != address(0), "cannot set to 0 address");
        revShareAddress = _address;
    }

    function updateTeam1Address(address _address) external onlyOwner {
        require(_address != address(0), "cannot set to 0 address");
        teamAddress_1 = _address;
    }

    function updateTeam2Address(address _address) external onlyOwner {
        require(_address != address(0), "cannot set to 0 address");
        teamAddress_2 = _address;
    }

    function updateTeam3Address(address _address) external onlyOwner {
        require(_address != address(0), "cannot set to 0 address");
        teamAddress_3 = _address;
    }

    function updateDistribution(uint24 _revShare, uint24 _team1, uint24 _team2, uint24 _team3) external onlyOwner {
        DistributionPercentages memory distributionPercsMem;
        distributionPercsMem.revSharePerc = _revShare;
        distributionPercsMem.team1Perc = _team1;
        distributionPercsMem.team2Perc = _team2;
        distributionPercsMem.team3Perc = _team3;
        distributionPercs = distributionPercsMem;
        require(distributionPercs.revSharePerc + distributionPercs.team1Perc + distributionPercs.team2Perc + distributionPercs.team3Perc == 100, "Must equal 100%");
    }
    
    function distributeETH() internal {
        DistributionPercentages memory distributionPercsMem = distributionPercs;
        uint256 balance = address(this).balance;
        uint256 revShareAmount = balance * distributionPercsMem.revSharePerc / 100;
        uint256 team1Amount = balance * distributionPercsMem.team1Perc / 100;
        uint256 team2Amount = balance * distributionPercsMem.team2Perc / 100;
        uint256 team3Amount = balance * distributionPercsMem.team3Perc / 100;
        
        bool success;

        if(revShareAmount > 0){
            (success,) = payable(revShareAddress).call{value: revShareAmount}("");
        }

        if(team1Amount > 0){
            (success,) = payable(teamAddress_1).call{value: team1Amount}("");
        }

        if(team2Amount > 0){
            (success,) = payable(teamAddress_2).call{value: team2Amount}("");
        }

        if(team3Amount > 0){
            (success,) = payable(teamAddress_3).call{value: team3Amount}("");
        }
    }

    function withdrawStuckETH() external onlyOwner {
        bool success;
        (success,) = payable(msg.sender).call{value: address(this).balance}("");
    }
    
}