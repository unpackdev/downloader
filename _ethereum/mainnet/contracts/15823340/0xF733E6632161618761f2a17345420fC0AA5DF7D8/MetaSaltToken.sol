// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import "./ERC20Upgradeable.sol";
import "./Initializable.sol";
import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./MerkleProofUpgradeable.sol";

contract MetaSaltToken is Initializable, ERC20Upgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable, PausableUpgradeable {
    using SafeMathUpgradeable for uint256;
    address public erc721Contract;
    address public erc1155Contract;
    bytes32 public merkleRoot;
    uint256 public airdropAmount;
    uint public airdropVersion;
    mapping (address => uint256) public rewards;
    mapping (uint => mapping (address => uint256)) public airdrops;    
    event EventReward(address _to, uint256 _value);
    event EventAirdrop(address _to, uint256 _value, uint _airdropVersion);

    modifier onlyERC721Creator {
      require(msg.sender == erc721Contract, "Not Creator");
      _;
    }

    modifier onlyERC1155Creator {
      require(msg.sender == erc1155Contract, "Not Creator");
      _;
    }

    function initialize(string memory name, string memory symbol, uint256 initialSupply, bytes32 _merkleRoot, uint256 _airdropAmount) public virtual initializer {
        __ERC20_init(name, symbol);
        __Ownable_init();
        _mint(_msgSender(), initialSupply.mul(10 ** 18));
        merkleRoot = _merkleRoot;
        airdropAmount = _airdropAmount;
        airdropVersion = 0;
    }

    function setAirdropAmount(uint256 _airdropAmount) public onlyOwner {        
        airdropAmount = _airdropAmount;        
    }

    function createNewAirdropping(bytes32 _merkleRoot, uint256 _airdropAmount) public onlyOwner {
        merkleRoot = _merkleRoot;
        airdropAmount = _airdropAmount;
        airdropVersion++;
    }

    function claimCreatingReward() external nonReentrant {
        require(rewards[_msgSender()] > 0, "not enough reward balance");
        _mint(_msgSender(), rewards[_msgSender()]);
        rewards[_msgSender()] = 0;
        emit EventReward(_msgSender(), rewards[_msgSender()]);
    }

    function setERC721Creator(address _erc721Contract) public onlyOwner{
        erc721Contract = _erc721Contract;
    }

    function setERC1155Creator(address _erc1155Contract) public onlyOwner{
        erc1155Contract = _erc1155Contract;
    }

    function increaseRewardERC721(address _to,  uint256 _value) external onlyERC721Creator{
        rewards[_to] = rewards[_to].add(_value);
    }   

    function increaseRewardERC1155(address _to,  uint256 _value) external onlyERC1155Creator{
        rewards[_to] = rewards[_to].add(_value);
    }   

    function getReward(address _to) public view returns (uint256) {
        return rewards[_to];
    }   

    function mint(address _to, uint256 _amount) public onlyOwner{
        _mint(_to, _amount);
    }

    function isAirdropped(uint _airdropVersion, address _addr) public view returns (uint256){
        return airdrops[_airdropVersion][_addr];
    }

    function checkValidity(bytes32[] calldata _merkleProof) public view returns (bool){
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProofUpgradeable.verify(_merkleProof, merkleRoot, leaf), "Incorrect proof");
        return true; // Or you can airdrop tokens here
    }

    function airdrop(bytes32[] calldata _merkleProof) public {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProofUpgradeable.verify(_merkleProof, merkleRoot, leaf), "Incorrect proof");
        require(airdrops[airdropVersion][msg.sender] == 0, "You already got an airdrop");
        _mint(msg.sender, airdropAmount);
        airdrops[airdropVersion][msg.sender] = airdropAmount;
        emit EventAirdrop(_msgSender(), airdropAmount, airdropVersion);
    }   

    uint256[50] private __gap;
}