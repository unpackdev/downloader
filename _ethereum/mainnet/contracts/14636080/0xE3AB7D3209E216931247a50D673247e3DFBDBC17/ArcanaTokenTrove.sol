// SPDX-License-Identifier: MIT
/*

 ▄▀▀█▄   ▄▀▀▄▀▀▀▄  ▄▀▄▄▄▄   ▄▀▀█▄   ▄▀▀▄ ▀▄  ▄▀▀█▄
▐ ▄▀ ▀▄ █   █   █ █ █    ▌ ▐ ▄▀ ▀▄ █  █ █ █ ▐ ▄▀ ▀▄
  █▄▄▄█ ▐  █▀▀█▀  ▐ █        █▄▄▄█ ▐  █  ▀█   █▄▄▄█
 ▄▀   █  ▄▀    █    █       ▄▀   █   █   █   ▄▀   █
█   ▄▀  █     █    ▄▀▄▄▄▄▀ █   ▄▀  ▄▀   █   █   ▄▀
▐   ▐   ▐     ▐   █     ▐  ▐   ▐   █    ▐   ▐   ▐
                  ▐                ▐

*/

pragma solidity ^0.8.9;
import "./Math.sol";
import "./Pausable.sol";
import "./ERC20.sol";
import "./IERC721.sol";
import "./Ownable.sol";
import "./AccessControlEnumerable.sol";
import "./IDragonToken.sol";

contract ArcanaTokenTrove is ERC20("ARCANA", "RCANA"), Ownable, IDragonToken, Pausable, AccessControlEnumerable {

    event ClaimedDragon(address indexed _account, uint256 _reward);
    event DragonsSet(address dragons);
    event GenesisSet(address genesis);
    //ArcanaToken begins generating on Wednesday, April 20, 2022
    uint256 constant public FIRST_EPOCH = 1650514419;

    uint256 constant legionRate = 5 ether;
    uint256 constant genesisRate = 20 ether;
    //ArcanaToken will cease to generate Saturday, April 20, 2030 4:20:00 PM
    uint256 constant public LAST_EPOCH = 1902932400;

    IERC721 public dragons;
    IERC721 public genesis;

	mapping(address => uint256) public rewards;
	mapping(address => uint256) public lastUpdate;

    constructor(address _dragons, address _genesis) {
        require(_dragons != address(0), "ADDRESS_ZERO");
        dragons = IERC721(_dragons);
        genesis = IERC721(_genesis);
    }

    function mintArcana(address _owner, uint256 _amount) external onlyOwner {
        _mint(_owner, _amount);
    }

    function burn(address _owner, uint256 _amount) external {
        _burn(_owner, _amount);
    }

    event SetContract(string indexed _contract, address _target);
    event RateChange(string indexed rateType, uint256 _newValue);

    function updateReward(address _from, address _to, uint256 _tokenId) external override {
        require(_from == address(0) || dragons.ownerOf(_tokenId) == _from, "NOT_OWNER_OF_DRAGON");
        require(msg.sender == address(dragons), "ONLY_DRAGONS");

        if (_from != address(0)) {
            if (lastUpdate[_from] > 0 && lastUpdate[_from] < LAST_EPOCH)
                rewards[_from] += _calculateRewards(_from);

            lastUpdate[_from] = block.timestamp;
        }

        if (_to != address(0)) {
            if (lastUpdate[_to] > 0 && lastUpdate[_to] < LAST_EPOCH)
                rewards[_to] += _calculateRewards(_to);

            lastUpdate[_to] = block.timestamp;
        }

    }

    function getClaimableReward(address _account) external view override returns(uint256) {
        return rewards[_account] + _calculateRewards(_account);
    }

    function claimReward() external override {
        require(lastUpdate[msg.sender] < LAST_EPOCH, "PAST_LAST_EPOCH");
        uint256 claimableReward = rewards[msg.sender] + _calculateRewards(msg.sender);
        require(claimableReward > 0, "NOTHING_TO_CLAIM");
        rewards[msg.sender] = 0;
        lastUpdate[msg.sender] = block.timestamp;
        _mint(msg.sender, claimableReward);
        emit ClaimedDragon(msg.sender, claimableReward);
    }

    function _calculateRewards(address _account) internal view returns(uint256) {
        uint256 claimableEpoch = Math.min(block.timestamp, LAST_EPOCH);
        uint256 delta = claimableEpoch - lastUpdate[_account];
        if(delta == claimableEpoch){
            //case if user has never claimed
            uint256 epochPassed =claimableEpoch - FIRST_EPOCH;
            uint256 pendingBasic = dragons.balanceOf(_account)*(epochPassed * legionRate / 86400);
            uint256 pendingGenesis = genesis.balanceOf(_account)*(epochPassed * genesisRate / 86400);
            return pendingBasic + pendingGenesis;
        } else if (delta > 0) {
            //case if user has claimed
            uint256 pendingBasic = dragons.balanceOf(_account) * (legionRate * delta/ 86400);
            uint256 pendingGenesis = genesis.balanceOf(_account) * (genesisRate * delta / 86400);

            return pendingBasic + pendingGenesis;
        }
        return 0;
    }


    function setDragons(address _dragons) external onlyOwner {
        require(_dragons != address(0), "ADDRESS_ZERO");
        dragons = IERC721(_dragons);
        emit DragonsSet(_dragons);
    }

    function setGenesis(address _genesis) external onlyOwner {
        require(_genesis != address(0), "ADDRESS_ZERO");
        genesis = IERC721(_genesis);
        emit GenesisSet(_genesis);
    }


    function pause() external onlyOwner {
        require(!paused(), "ALREADY_PAUSED");
        _pause();
    }

    function unpause() external onlyOwner {
        require(paused(), "ALREADY_UNPAUSED");
        _unpause();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) override internal virtual {
        require(!paused(), "TRANSFER_PAUSED");
        super._beforeTokenTransfer(from, to, amount);
    }

    function decimals() public pure override returns(uint8) {
        return 18;
    }
}
//DRAGONS FLY HIGH FOREVER
