// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "./ERC20.sol";
import "./draft-EIP712.sol";
import "./ECDSA.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./MerkleProof.sol";
import "./Ownable.sol";

contract RugDAO is ERC20("RugDAO", "RUGD"), Ownable{
    using SafeMath for uint256;
    using Address for address;

    uint256 public startTime;

    bytes32 public merkleRoot = 0xbefdf724eeba1f8357bfa6191d8e84fed846666c1993cecd43c3662091ce951b;
    uint256 public burnFee = 5;
    uint256 public taxFee = 5;

    mapping (address=>bool) public savedFromRug;
    mapping (address=>bool) public excludedFromTax;
    mapping (address=>bool) public earlyContributors;
    mapping (address=>bool) public contributorClaimed;
    mapping (address=>uint256) public earlyContributorAmount;

    
    // for rug dao
    uint256 public constant MAX_SUPPLY = uint248(1e12 ether);
    uint256 public constant AMOUNT_RUGDAO = (MAX_SUPPLY / 100) * 25;
    address public constant ADDR_RUGDAO = 0xEf4Ef8D5E07E195a62657a1B423eD3A2B89FE4b9;

    // for liquidity providers
    uint256 public constant AMOUNT_LP = (MAX_SUPPLY / 100) * 45;
    address public constant ADDR_LP =
        0x500d7B5Ee07f1D703111C99e2167E8AC8686259A;

    constructor() {
        _mint(ADDR_RUGDAO, AMOUNT_RUGDAO);
        _mint(ADDR_LP, AMOUNT_LP);
        excludedFromTax[msg.sender] = true;
        excludedFromTax[ADDR_LP] = true;
        startTime = block.timestamp;
    }

    function excludeAddressesFromTax(address[] memory _addresses) external onlyOwner{
        for(uint256 i = 0; i < _addresses.length; i++) {
            excludedFromTax[_addresses[i]] = true;
        }
    }

    function setContributorClaims(
        address[] memory _contributorAddresses,
        uint256[] memory _contributorAmounts
    ) external onlyOwner {
        for (uint256 i = 0; i < _contributorAddresses.length; i++) {
            earlyContributors[_contributorAddresses[i]] = true;
            earlyContributorAmount[_contributorAddresses[i]] = _contributorAmounts[i];
        }
    }

    function claim(bytes32[] calldata _merkleProof, uint256 _amount) external {
        require(block.timestamp >= (startTime + 1 days), "Must wait 1 day to claim");
        require(!savedFromRug[msg.sender], "Address has already been saved");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, _amount));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "Invalid Proof");
        savedFromRug[msg.sender] = true;
        _mint(msg.sender, _amount.mul(3));
    }


    function contributorClaim() external {
        require(block.timestamp >= (startTime + 1 days), "Must wait 1 day to claim");
        require(earlyContributors[msg.sender] == true, "Not an early contributor");
        require(!contributorClaimed[msg.sender], "Contributor already claimed");
        contributorClaimed[msg.sender] = true;
        _mint(msg.sender, earlyContributorAmount[msg.sender]);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        if(excludedFromTax[msg.sender] == true) {
            _transfer(_msgSender(), recipient, amount);
        }
        else{
            uint burntAmount = amount.mul(burnFee) / 100;
            uint rugDAOAmount = amount.mul(taxFee) / 100;
            _burn(_msgSender(), burntAmount);
            _transfer(_msgSender(), ADDR_RUGDAO, rugDAOAmount);
            _transfer(_msgSender(), recipient, amount.sub(burntAmount).sub(rugDAOAmount));
        }
        return true;
    }

    // THIS IS THE FUNCTION WHERE THEY STOLE OUR MONEY :(
    function _burnMechanism(address from, address to) internal virtual {
        // SCREW YOU ETHERWRAPPED HONEYPOTTERS
    }
}
